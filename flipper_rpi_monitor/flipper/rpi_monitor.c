#include <furi.h>
#include <furi_hal.h>
#include <furi_hal_bt.h>
#include <furi_hal_version.h>
#include <bt/bt_service/bt.h>
#include <profiles/serial_profile.h>
#include <services/serial_service.h>
#include <gui/gui.h>
#include <input/input.h>
#include <storage/storage.h>
#include <notification/notification_messages.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TAG "RpiMonitor"
#define BT_SERIAL_BUFFER_SIZE 128
#define DATA_TIMEOUT_MS 6000

// --- Wlasny profil BLE Serial (bezposrednio na BleServiceSerial) ---
typedef struct {
    FuriHalBleProfileBase base;
    BleServiceSerial* serial_svc;
} RpiBleProfile;

static const FuriHalBleProfileTemplate rpi_ble_profile;

static FuriHalBleProfileBase* rpi_ble_start(FuriHalBleProfileParams params) {
    UNUSED(params);
    RpiBleProfile* profile = malloc(sizeof(RpiBleProfile));
    profile->base.config = &rpi_ble_profile;
    profile->serial_svc = ble_svc_serial_start();
    return &profile->base;
}

static void rpi_ble_stop(FuriHalBleProfileBase* profile) {
    furi_check(profile);
    furi_check(profile->config == &rpi_ble_profile);
    RpiBleProfile* rpi_profile = (RpiBleProfile*)profile;
    ble_svc_serial_stop(rpi_profile->serial_svc);
    free(rpi_profile);
}

static void rpi_ble_get_gap_config(GapConfig* target_config, FuriHalBleProfileParams params) {
    UNUSED(params);
    ble_profile_serial->get_gap_config(target_config, NULL);

    target_config->mac_address[0] ^= 0x02;
    target_config->mac_address[1] ^= 0x05;

    const char* name = furi_hal_version_get_name_ptr();
    snprintf(
        target_config->adv_name + 1,
        sizeof(target_config->adv_name) - 1,
        "RPiMon %s",
        name ? name : "Zero");
}

static const FuriHalBleProfileTemplate rpi_ble_profile = {
    .start = rpi_ble_start,
    .stop = rpi_ble_stop,
    .get_gap_config = rpi_ble_get_gap_config,
};
// -------------------------------------------------------------------

typedef struct {
    int cpu_pct;
    int cpu_temp_x10;
    int ram_pct;
    int ram_used_mb;
    int ram_total_mb;
    int disk_pct;
    int disk_temp_x10;
    int load_x100;
    int uptime_min;
    uint32_t last_rx_tick;
    bool has_data;
} RpiStats;

typedef struct {
    Gui* gui;
    ViewPort* view_port;
    NotificationApp* notification;
    FuriMessageQueue* event_queue;
    FuriMutex* mutex;
    Bt* bt;
    FuriHalBleProfileBase* ble_serial_profile;
    volatile BtStatus bt_status;
    volatile uint32_t rx_bytes;
    RpiStats stats;
    char rx_buf[BT_SERIAL_BUFFER_SIZE];
    size_t rx_len;
    char pending_line[BT_SERIAL_BUFFER_SIZE];
    bool line_ready;
} RpiMonitorApp;

static int clamp_pct(int val) {
    if(val < 0) return 0;
    if(val > 100) return 100;
    return val;
}

static bool parse_csv_9(const char* line, int out[9]) {
    const char* p = line;
    for(int i = 0; i < 9; i++) {
        char* end = NULL;
        long val = strtol(p, &end, 10);
        if(end == p) return false;
        out[i] = (int)val;
        if(i < 8) {
            if(*end != ',') return false;
            p = end + 1;
        }
    }
    return true;
}

static void process_pending_line(RpiMonitorApp* app) {
    char local_line[BT_SERIAL_BUFFER_SIZE];
    bool has_line = false;

    furi_mutex_acquire(app->mutex, FuriWaitForever);
    if(app->line_ready) {
        memcpy(local_line, app->pending_line, sizeof(local_line));
        app->line_ready = false;
        has_line = true;
    }
    furi_mutex_release(app->mutex);

    if(!has_line) return;

    int v[9];
    if(parse_csv_9(local_line, v)) {
        furi_mutex_acquire(app->mutex, FuriWaitForever);
        app->stats.cpu_pct = clamp_pct(v[0]);
        app->stats.cpu_temp_x10 = v[1];
        app->stats.ram_pct = clamp_pct(v[2]);
        app->stats.ram_used_mb = v[3];
        app->stats.ram_total_mb = v[4];
        app->stats.disk_pct = clamp_pct(v[5]);
        app->stats.disk_temp_x10 = v[6];
        app->stats.load_x100 = v[7];
        app->stats.uptime_min = v[8];
        app->stats.last_rx_tick = furi_get_tick();
        app->stats.has_data = true;
        furi_mutex_release(app->mutex);

        notification_message(app->notification, &sequence_display_backlight_on);
    }
}

static uint16_t bt_serial_callback(SerialServiceEvent event, void* ctx) {
    RpiMonitorApp* app = ctx;

    if(event.event == SerialServiceEventTypeDataReceived) {
        app->rx_bytes += event.data.size;
        for(size_t i = 0; i < event.data.size; i++) {
            char c = (char)event.data.buffer[i];
            if(c == '\n' || c == '\r') {
                if(app->rx_len > 0) {
                    app->rx_buf[app->rx_len] = '\0';
                    if(furi_mutex_acquire(app->mutex, 10) == FuriStatusOk) {
                        memcpy(app->pending_line, app->rx_buf, app->rx_len + 1);
                        app->line_ready = true;
                        furi_mutex_release(app->mutex);
                    }
                    app->rx_len = 0;
                }
            } else if(app->rx_len < sizeof(app->rx_buf) - 1) {
                app->rx_buf[app->rx_len++] = c;
            } else {
                app->rx_len = 0;
            }
        }
    }

    return BT_SERIAL_BUFFER_SIZE;
}

static void bt_status_changed_callback(BtStatus status, void* ctx) {
    RpiMonitorApp* app = ctx;
    app->bt_status = status;
}

static void draw_progress_bar(Canvas* canvas, uint8_t x, uint8_t y, uint8_t w, uint8_t h, int pct) {
    canvas_draw_frame(canvas, x, y, w, h);
    uint8_t fill_w = (uint8_t)(((w - 2) * clamp_pct(pct)) / 100);
    if(fill_w > 0) {
        canvas_draw_box(canvas, x + 1, y + 1, fill_w, h - 2);
    }
}

static void render_callback(Canvas* canvas, void* ctx) {
    RpiMonitorApp* app = ctx;
    RpiStats st;

    furi_mutex_acquire(app->mutex, FuriWaitForever);
    st = app->stats;
    furi_mutex_release(app->mutex);

    BtStatus status = app->bt_status;
    bool connected = (status == BtStatusConnected);
    bool fresh =
        st.has_data && ((furi_get_tick() - st.last_rx_tick) < furi_ms_to_ticks(DATA_TIMEOUT_MS));

    canvas_clear(canvas);

    // Pasek naglowka
    canvas_set_color(canvas, ColorBlack);
    canvas_draw_box(canvas, 0, 0, 128, 12);
    canvas_set_color(canvas, ColorWhite);
    canvas_set_font(canvas, FontSecondary);
    canvas_draw_str(canvas, 3, 9, "RPi 5 Monitor");

    const char* status_str = "ADV";
    if(!app->ble_serial_profile || status == BtStatusOff || status == BtStatusUnavailable) {
        status_str = "BT OFF";
    } else if(connected && fresh) {
        status_str = "LIVE";
    } else if(connected) {
        status_str = "BLE OK";
    }
    canvas_draw_str_aligned(canvas, 125, 9, AlignRight, AlignBottom, status_str);

    canvas_set_color(canvas, ColorBlack);

    if(!st.has_data) {
        char rx_str[32];
        canvas_set_font(canvas, FontPrimary);
        canvas_draw_str_aligned(canvas, 64, 27, AlignCenter, AlignCenter, "Czekam na RPi 5...");
        canvas_set_font(canvas, FontSecondary);
        if(!app->ble_serial_profile) {
            canvas_draw_str_aligned(
                canvas, 64, 41, AlignCenter, AlignCenter, "Wlacz BT w Settings");
        } else if(connected) {
            snprintf(rx_str, sizeof(rx_str), "Polaczono | RX: %lu B", (unsigned long)app->rx_bytes);
            canvas_draw_str_aligned(canvas, 64, 41, AlignCenter, AlignCenter, rx_str);
        } else {
            canvas_draw_str_aligned(
                canvas, 64, 41, AlignCenter, AlignCenter, "Rozglaszam: RPiMon");
        }
        canvas_draw_str_aligned(
            canvas, 64, 58, AlignCenter, AlignCenter, "[OK] Re-ADV  [Back] Wyjdz");
        return;
    }

    char buf[32];

    // Wiersz 1: CPU
    canvas_draw_str(canvas, 2, 23, "CPU");
    draw_progress_bar(canvas, 24, 15, 44, 8, st.cpu_pct);
    snprintf(buf, sizeof(buf), "%d%%", st.cpu_pct);
    canvas_draw_str(canvas, 71, 23, buf);
    snprintf(buf, sizeof(buf), "%d.%dC", st.cpu_temp_x10 / 10, abs(st.cpu_temp_x10 % 10));
    canvas_draw_str_aligned(canvas, 126, 23, AlignRight, AlignBottom, buf);

    // Wiersz 2: RAM
    canvas_draw_str(canvas, 2, 35, "RAM");
    draw_progress_bar(canvas, 24, 27, 44, 8, st.ram_pct);
    snprintf(buf, sizeof(buf), "%d%%", st.ram_pct);
    canvas_draw_str(canvas, 71, 35, buf);
    int ram_used_g10 = (st.ram_used_mb * 10) / 1024;
    int ram_tot_g = (st.ram_total_mb + 512) / 1024;
    snprintf(buf, sizeof(buf), "%d.%d/%dG", ram_used_g10 / 10, ram_used_g10 % 10, ram_tot_g);
    canvas_draw_str_aligned(canvas, 126, 35, AlignRight, AlignBottom, buf);

    // Wiersz 3: Dysk + temp NVMe
    canvas_draw_str(canvas, 2, 47, "DSK");
    draw_progress_bar(canvas, 24, 39, 44, 8, st.disk_pct);
    snprintf(buf, sizeof(buf), "%d%%", st.disk_pct);
    canvas_draw_str(canvas, 71, 47, buf);
    if(st.disk_temp_x10 > 0) {
        snprintf(buf, sizeof(buf), "%d.%dC", st.disk_temp_x10 / 10, abs(st.disk_temp_x10 % 10));
    } else {
        snprintf(buf, sizeof(buf), "--.-C");
    }
    canvas_draw_str_aligned(canvas, 126, 47, AlignRight, AlignBottom, buf);

    // Stopka: Load + Uptime
    canvas_draw_line(canvas, 0, 51, 128, 51);
    if(!fresh) {
        canvas_draw_str_aligned(canvas, 64, 62, AlignCenter, AlignBottom, "Brak danych [OK] Re-ADV");
    } else {
        snprintf(buf, sizeof(buf), "Load: %d.%02d", st.load_x100 / 100, abs(st.load_x100 % 100));
        canvas_draw_str(canvas, 2, 62, buf);

        int days = st.uptime_min / (60 * 24);
        int hours = (st.uptime_min / 60) % 24;
        int mins = st.uptime_min % 60;
        if(days > 0) {
            snprintf(buf, sizeof(buf), "Up: %dd %dh", days, hours);
        } else if(hours > 0) {
            snprintf(buf, sizeof(buf), "Up: %dh %dm", hours, mins);
        } else {
            snprintf(buf, sizeof(buf), "Up: %dm", mins);
        }
        canvas_draw_str_aligned(canvas, 126, 62, AlignRight, AlignBottom, buf);
    }
}

static void input_callback(InputEvent* input_event, void* ctx) {
    RpiMonitorApp* app = ctx;
    furi_message_queue_put(app->event_queue, input_event, FuriWaitForever);
}

int32_t rpi_monitor_app(void* p) {
    UNUSED(p);

    RpiMonitorApp* app = malloc(sizeof(RpiMonitorApp));
    furi_check(app);
    memset(app, 0, sizeof(RpiMonitorApp));

    app->event_queue = furi_message_queue_alloc(8, sizeof(InputEvent));
    app->mutex = furi_mutex_alloc(FuriMutexTypeNormal);
    app->bt_status = BtStatusUnavailable;
    app->notification = furi_record_open(RECORD_NOTIFICATION);

    // 1. Konfiguracja GUI
    app->view_port = view_port_alloc();
    view_port_draw_callback_set(app->view_port, render_callback, app);
    view_port_input_callback_set(app->view_port, input_callback, app);

    app->gui = furi_record_open(RECORD_GUI);
    gui_add_view_port(app->gui, app->view_port, GuiLayerFullscreen);

    // 2. Start profilu BLE Serial (bezposrednia rejestracja callbacku)
    app->bt = furi_record_open(RECORD_BT);
    bt_disconnect(app->bt);
    furi_delay_ms(200);
    bt_keys_storage_set_storage_path(app->bt, APP_DATA_PATH(".bt_rpi.keys"));

    app->ble_serial_profile = bt_profile_start(app->bt, &rpi_ble_profile, NULL);
    if(app->ble_serial_profile) {
        RpiBleProfile* rpi_prof = (RpiBleProfile*)app->ble_serial_profile;
        app->bt_status = BtStatusAdvertising;
        bt_set_status_changed_callback(app->bt, bt_status_changed_callback, app);
        ble_svc_serial_set_callbacks(
            rpi_prof->serial_svc, BT_SERIAL_BUFFER_SIZE, bt_serial_callback, app);
        furi_hal_bt_start_advertising();
    }

    // 3. Glowna petla zdarzen
    InputEvent event;
    bool running = true;

    while(running) {
        if(furi_message_queue_get(app->event_queue, &event, 200) == FuriStatusOk) {
            if(event.type == InputTypeShort) {
                if(event.key == InputKeyBack) {
                    running = false;
                } else if(event.key == InputKeyOk && app->ble_serial_profile) {
                    bt_disconnect(app->bt);
                    furi_delay_ms(150);
                    app->bt_status = BtStatusAdvertising;
                    furi_hal_bt_start_advertising();
                }
            }
        }

        process_pending_line(app);
        view_port_update(app->view_port);
    }

    // 4. Bezpieczne sprzatanie
    if(app->ble_serial_profile) {
        RpiBleProfile* rpi_prof = (RpiBleProfile*)app->ble_serial_profile;
        ble_svc_serial_set_callbacks(rpi_prof->serial_svc, 0, NULL, NULL);
    }
    bt_set_status_changed_callback(app->bt, NULL, NULL);
    bt_disconnect(app->bt);
    furi_delay_ms(200);
    bt_keys_storage_set_default_path(app->bt);
    bt_profile_restore_default(app->bt);
    furi_record_close(RECORD_BT);

    gui_remove_view_port(app->gui, app->view_port);
    view_port_free(app->view_port);
    furi_record_close(RECORD_GUI);
    furi_record_close(RECORD_NOTIFICATION);
    furi_mutex_free(app->mutex);
    furi_message_queue_free(app->event_queue);
    free(app);

    return 0;
}
