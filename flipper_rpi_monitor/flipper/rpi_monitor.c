#include <furi.h>
#include <furi_hal.h>
#include <furi_hal_bt.h>
#include <bt/bt_service/bt.h>
#include <profiles/serial_profile.h>
#include <gui/gui.h>
#include <input/input.h>
#include <storage/storage.h>

#include <stdio.h>
#include <stdlib.h>
#include <string.h>

#define TAG "RpiMonitor"
#define BT_SERIAL_BUFFER_SIZE 128
#define DATA_TIMEOUT_MS 6000

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
    FuriMessageQueue* event_queue;
    FuriMutex* mutex;
    Bt* bt;
    FuriHalBleProfileBase* ble_serial_profile;
    volatile bool connected;
    RpiStats stats;
    char rx_buf[BT_SERIAL_BUFFER_SIZE];
    size_t rx_len;
} RpiMonitorApp;

static int clamp_pct(int val) {
    if(val < 0) return 0;
    if(val > 100) return 100;
    return val;
}

static void parse_stats_line(RpiMonitorApp* app, const char* line) {
    int cpu, ctemp, ram, r_used, r_tot, dsk, dtemp, load, upm;
    int parsed = sscanf(
        line,
        "%d,%d,%d,%d,%d,%d,%d,%d,%d",
        &cpu,
        &ctemp,
        &ram,
        &r_used,
        &r_tot,
        &dsk,
        &dtemp,
        &load,
        &upm);

    if(parsed == 9) {
        furi_mutex_acquire(app->mutex, FuriWaitForever);
        app->stats.cpu_pct = clamp_pct(cpu);
        app->stats.cpu_temp_x10 = ctemp;
        app->stats.ram_pct = clamp_pct(ram);
        app->stats.ram_used_mb = r_used;
        app->stats.ram_total_mb = r_tot;
        app->stats.disk_pct = clamp_pct(dsk);
        app->stats.disk_temp_x10 = dtemp;
        app->stats.load_x100 = load;
        app->stats.uptime_min = upm;
        app->stats.last_rx_tick = furi_get_tick();
        app->stats.has_data = true;
        furi_mutex_release(app->mutex);

        view_port_update(app->view_port);
    }
}

static uint16_t bt_serial_callback(SerialServiceEvent event, void* ctx) {
    RpiMonitorApp* app = ctx;

    if(event.type == SerialServiceEventTypeDataReceived) {
        for(size_t i = 0; i < event.data.size; i++) {
            char c = (char)event.data.buffer[i];
            if(c == '\n' || c == '\r') {
                if(app->rx_len > 0) {
                    app->rx_buf[app->rx_len] = '\0';
                    parse_stats_line(app, app->rx_buf);
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
    app->connected = (status == BtStatusConnected);
    view_port_update(app->view_port);
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

    bool fresh = st.has_data && ((furi_get_tick() - st.last_rx_tick) < furi_ms_to_ticks(DATA_TIMEOUT_MS));

    canvas_clear(canvas);

    // Pasek naglowka
    canvas_set_color(canvas, ColorBlack);
    canvas_draw_box(canvas, 0, 0, 128, 12);
    canvas_set_color(canvas, ColorWhite);
    canvas_set_font(canvas, FontSecondary);
    canvas_draw_str(canvas, 3, 9, "RPi 5 Monitor");

    const char* status_str = "WAIT";
    if(!app->ble_serial_profile) {
        status_str = "BT OFF";
    } else if(app->connected && fresh) {
        status_str = "LIVE";
    } else if(app->connected) {
        status_str = "BLE OK";
    }
    canvas_draw_str_aligned(canvas, 125, 9, AlignRight, AlignBottom, status_str);

    canvas_set_color(canvas, ColorBlack);

    if(!st.has_data) {
        canvas_set_font(canvas, FontPrimary);
        canvas_draw_str_aligned(canvas, 64, 30, AlignCenter, AlignCenter, "Czekam na RPi 5...");
        canvas_set_font(canvas, FontSecondary);
        canvas_draw_str_aligned(
            canvas,
            64,
            45,
            AlignCenter,
            AlignCenter,
            app->connected ? "Polaczono, brak danych" : "Szukaj BLE: RPiMon");
        canvas_draw_str_aligned(canvas, 64, 59, AlignCenter, AlignCenter, "[Back] Wyjscie");
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

    // Stopka: Load + Uptime (lub ostrzezenie o utracie sygnalu)
    canvas_draw_line(canvas, 0, 51, 128, 51);
    if(!fresh) {
        canvas_draw_str_aligned(canvas, 64, 62, AlignCenter, AlignBottom, "Brak nowych danych...");
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

    // 1. Konfiguracja GUI
    app->view_port = view_port_alloc();
    view_port_draw_callback_set(app->view_port, render_callback, app);
    view_port_input_callback_set(app->view_port, input_callback, app);

    app->gui = furi_record_open(RECORD_GUI);
    gui_add_view_port(app->gui, app->view_port, GuiLayerFullscreen);

    // 2. Start BLE Serial
    app->bt = furi_record_open(RECORD_BT);
    bt_disconnect(app->bt);
    furi_delay_ms(200);
    bt_keys_storage_set_storage_path(app->bt, APP_DATA_PATH(".bt_rpi.keys"));

    BleProfileSerialParams params = {
        .device_name_prefix = "RPiMon",
        .mac_xor = 0x0002,
    };
    app->ble_serial_profile = bt_profile_start(app->bt, ble_profile_serial, &params);
    if(app->ble_serial_profile) {
        bt_set_status_changed_callback(app->bt, bt_status_changed_callback, app);
        ble_profile_serial_set_event_callback(
            app->ble_serial_profile, BT_SERIAL_BUFFER_SIZE, bt_serial_callback, app);
        furi_hal_bt_start_advertising();
    }

    // 3. Glowna petla zdarzen
    InputEvent event;
    bool running = true;
    while(running) {
        if(furi_message_queue_get(app->event_queue, &event, 500) == FuriStatusOk) {
            if(event.type == InputTypeShort && event.key == InputKeyBack) {
                running = false;
            }
        }
        view_port_update(app->view_port);
    }

    // 4. Sprzatanie i przywrocenie domyslnego BLE
    if(app->ble_serial_profile) {
        ble_profile_serial_set_event_callback(app->ble_serial_profile, 0, NULL, NULL);
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
    furi_mutex_free(app->mutex);
    furi_message_queue_free(app->event_queue);
    free(app);

    return 0;
}
