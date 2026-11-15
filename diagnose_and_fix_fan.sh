#!/bin/bash
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}[!] Uruchom skrypt z uprawnieniami roota: sudo ./diagnose_and_fix_fan.sh${NC}"
    exit 1
fi

clear
echo -e "${CYAN}================================================================${NC}"
echo -e "${CYAN}  DIAGNOSTYKA I RESET KONFIGURACJI WENTYLATORA (BOOTFS + ROOTFS) ${NC}"
echo -e "${CYAN}================================================================${NC}"

# ------------------------------------------------------------------------------
# KROK 1: Sprawdzenie zamontowanych nośników (Konflikt SD vs NVMe)
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[1/6] Analiza zamontowanych partycji (SD vs NVMe)...${NC}"
lsblk -o NAME,SIZE,TYPE,FSTYPE,LABEL,MOUNTPOINT | grep -E "NAME|mmcblk|nvme" || true

BOOT_DEV=$(findmnt -n -o SOURCE /boot/firmware 2>/dev/null || findmnt -n -o SOURCE /boot 2>/dev/null || echo "nieznany")
ROOT_DEV=$(findmnt -n -o SOURCE / 2>/dev/null || echo "nieznany")
echo -e " -> Aktywny bootfs : ${CYAN}$BOOT_DEV${NC}"
echo -e " -> Aktywny rootfs : ${CYAN}$ROOT_DEV${NC}"

if [ -b /dev/mmcblk0 ] && [ -b /dev/nvme0n1 ]; then
    echo -e "${RED}[!] UWAGA: Wykryto jednocześnie kartę MicroSD (/dev/mmcblk0) oraz dysk NVMe (/dev/nvme0n1)!${NC}"
    echo -e "    Bootloader RPi 5 może czytać config.txt z innego nośnika niż ten zamontowany w /boot/firmware."
fi

# ------------------------------------------------------------------------------
# KROK 2: Skanowanie aktywnego BOOTFS (config.txt oraz cmdline.txt)
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[2/6] Skanowanie partycji BOOTFS (config.txt / cmdline.txt)...${NC}"
for cfg in /boot/firmware/config.txt /boot/config.txt /boot/firmware/cmdline.txt /boot/cmdline.txt; do
    if [ -f "$cfg" ]; then
        echo -e " -> Plik: ${CYAN}$cfg${NC}"
        MATCHES=$(grep -niE "fan|pwm|cooling|thermal|gpio" "$cfg" | grep -v "^[0-9]*:#" || true)
        if [ -n "$MATCHES" ]; then
            echo "$MATCHES" | sed 's/^/    /'
        else
            echo "    (Brak aktywnych wpisów dotyczących wentylatora)"
        fi
    fi
done

# Jeśli istnieje niezamontowana pierwsza partycja na drugim nośniku (SD lub NVMe), sprawdźmy ją!
for other_part in /dev/mmcblk0p1 /dev/nvme0n1p1; do
    if [ -b "$other_part" ] && [ "$other_part" != "$BOOT_DEV" ]; then
        echo -e "\n${YELLOW}[!] Wykryto drugą partycję bootfs ($other_part) - sprawdzam jej zawartość...${NC}"
        TMP_MNT=$(mktemp -d)
        if mount -o ro "$other_part" "$TMP_MNT" 2>/dev/null; then
            if [ -f "$TMP_MNT/config.txt" ]; then
                echo -e " -> Wpisy w ${RED}$other_part/config.txt${NC}:"
                grep -niE "fan|pwm|cooling|thermal|gpio" "$TMP_MNT/config.txt" | grep -v "^[0-9]*:#" | sed 's/^/    /' || echo "    (Brak)"
            fi
            umount "$TMP_MNT"
        fi
        rmdir "$TMP_MNT"
    fi
done

# ------------------------------------------------------------------------------
# KROK 3: Skanowanie partycji ROOTFS (/etc, systemd, udev, cron, skrypty)
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[3/6] Skanowanie partycji ROOTFS (/etc, udev, systemd, cron)...${NC}"

echo -e " -> Szukanie reguł i skryptów w /etc, /usr/local/bin, /usr/local/sbin:"
FOUND_FILES=$(grep -rnwl '/etc/' '/usr/local/bin/' '/usr/local/sbin/' '/var/spool/cron/' \
    -e 'cooling_fan' -e 'pwm1' -e 'cooling_device0' -e 'fan_temp0' -e 'nvme-fan' -e 'rpi-fan' 2>/dev/null || true)

if [ -n "$FOUND_FILES" ]; then
    for f in $FOUND_FILES; do
        if [[ "$f" != *"rpi-temp"* ]] && [[ "$f" != *"diagnose_and_fix_fan"* ]]; then
            echo -e "    ${RED}[ZNALEZIONO]${NC} $f:"
            grep -nE 'cooling_fan|pwm1|cooling_device0|fan_temp|nvme-fan' "$f" 2>/dev/null | head -n 5 | sed 's/^/        /' || true
        fi
    done
else
    echo -e "    ${GREEN}(Nie znaleziono ukrytych wpisów w /etc ani /usr/local)${NC}"
fi

# ------------------------------------------------------------------------------
# KROK 4: Czyszczenie ROOTFS i przywrócenie czystego config.txt na BOOTFS
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[4/6] Czyszczenie usług i przywracanie fabrycznej konfiguracji...${NC}"

for srv in nvme-fan-guard.service rpi-fan.service fan-control.service pwm-fan.service; do
    if systemctl list-unit-files | grep -q "^$srv"; then
        systemctl stop "$srv" 2>/dev/null || true
        systemctl disable "$srv" 2>/dev/null || true
        rm -f "/etc/systemd/system/$srv"
        echo -e " -> Usunięto usługę: $srv"
    fi
done
rm -f /usr/local/sbin/nvme-fan-guard.sh
systemctl daemon-reload

if grep -rlqE "cooling_fan|pwm1|cooling_device" /etc/udev/rules.d/ 2>/dev/null; then
    for rule in $(grep -rlE "cooling_fan|pwm1|cooling_device" /etc/udev/rules.d/); do
        mv "$rule" "${rule}.disabled_bak"
        echo -e " -> Wyłączono regułę udev: $rule (zmieniono na .disabled_bak)"
    done
    udevadm control --reload-rules && udevadm trigger
fi

CONFIG_TXT="/boot/firmware/config.txt"
[ ! -f "$CONFIG_TXT" ] && CONFIG_TXT="/boot/config.txt"

if [ -f "$CONFIG_TXT" ]; then
    cp "$CONFIG_TXT" "${CONFIG_TXT}.clean_backup"
    sed -i '/# === KONFIGURACJA ACTIVE COOLER ===/,/# === KONIEC ACTIVE COOLER ===/d' "$CONFIG_TXT"
    sed -i '/^dtparam=cooling_fan/d' "$CONFIG_TXT"
    sed -i '/^dtparam=fan_temp/d' "$CONFIG_TXT"
    sed -i '/^dtoverlay=pwm-fan/d' "$CONFIG_TXT"
    sed -i '/^dtoverlay=gpio-fan/d' "$CONFIG_TXT"

    cat >> "$CONFIG_TXT" << 'EOF'

# === KONFIGURACJA ACTIVE COOLER ===
dtparam=cooling_fan=on
dtparam=fan_temp0=50000,fan_temp0_hyst=5000,fan_temp0_speed=75
dtparam=fan_temp1=60000,fan_temp1_hyst=5000,fan_temp1_speed=125
dtparam=fan_temp2=67500,fan_temp2_hyst=5000,fan_temp2_speed=175
dtparam=fan_temp3=75000,fan_temp3_hyst=5000,fan_temp3_speed=250
# === KONIEC ACTIVE COOLER ===
EOF
    echo -e "${GREEN}[+] Przywrócono czystą konfigurację Active Coolera w $CONFIG_TXT.${NC}"
fi

# ------------------------------------------------------------------------------
# KROK 5: Test sprzętowy rejestru PWM (0 vs 255) i czujnika Halla
# ------------------------------------------------------------------------------
echo -e "\n${YELLOW}[5/6] Test sprzętowy linii PWM (sprawdzanie reakcji wentylatora)...${NC}"
PWM_FILE=$(ls /sys/devices/platform/cooling_fan/hwmon/*/pwm1 2>/dev/null | head -n 1 || true)
RPM_FILE=$(ls /sys/devices/platform/cooling_fan/hwmon/*/fan1_input 2>/dev/null | head -n 1 || true)

if [ -n "$PWM_FILE" ] && [ -n "$RPM_FILE" ]; then
    echo "step_wise" > /sys/class/thermal/thermal_zone0/policy 2>/dev/null || true
    echo 0 > /sys/class/thermal/cooling_device0/cur_state 2>/dev/null || true
    echo 1 > "${PWM_FILE}_enable" 2>/dev/null || true

    echo -e " -> Wymuszam PWM = 0 (0% mocy) i czekam 4 sekundy..."
    echo 0 > "$PWM_FILE"
    sleep 4
    RPM_AT_0=$(cat "$RPM_FILE")
    echo -e "    Obroty przy PWM=0   : ${CYAN}${RPM_AT_0} RPM${NC}"

    echo -e " -> Wymuszam PWM = 255 (100% mocy) i czekam 4 sekundy..."
    echo 255 > "$PWM_FILE"
    sleep 4
    RPM_AT_255=$(cat "$RPM_FILE")
    echo -e "    Obroty przy PWM=255 : ${CYAN}${RPM_AT_255} RPM${NC}"

    echo 0 > "$PWM_FILE"
    echo 2 > "${PWM_FILE}_enable" 2>/dev/null || true
else
    echo -e "${RED}[!] Nie znaleziono urządzenia /sys/devices/platform/cooling_fan!${NC}"
fi

# ------------------------------------------------------------------------------
# KROK 6: Podsumowanie i werdykt (z listą przyczyn sprzętowych)
# ------------------------------------------------------------------------------
echo -e "\n${CYAN}================================================================${NC}"
echo -e "${YELLOW}[6/6] WERDYKT DIAGNOSTYCZNY:${NC}"
if [ -n "$RPM_AT_0" ] && [ "$RPM_AT_0" -lt 1000 ]; then
    echo -e "${GREEN}[SUKCES!] Wentylator reaguje na sterowanie i zatrzymał się (${RPM_AT_0} RPM)!${NC}"
    echo -e "Wykonaj teraz: ${YELLOW}sudo reboot${NC}"
elif [ -n "$RPM_AT_255" ] && [ "$RPM_AT_255" -lt 1000 ]; then
    echo -e "${YELLOW}[ODWRÓCONA POLARYZACJA] Wentylator zatrzymał się przy PWM=255 zamiast PWM=0!${NC}"
    echo -e "Po restarcie (sudo reboot) czysta konfiguracja config.txt przywróci właściwą polaryzację."
else
    echo -e "${RED}[BŁĄD SPRZĘTOWY / BRAK REAKCJI NA LINII PWM]${NC}"
    echo -e "Wentylator kręci się na maksymalnych obrotach (${RPM_AT_0} RPM) niezależnie od sygnału (PWM=0 oraz PWM=255)."
    echo -e "\n${YELLOW}MOŻLIWE PRZYCZYNY (od najbardziej prawdopodobnych):${NC}"
    echo -e "  ${RED}1. Uszkodzenie samej płytki Raspberry Pi 5 (RP1 / gniazdo FAN):${NC}"
    echo -e "     - Uszkodzone wyjście PWM w kontrolerze I/O RP1 lub zimny lut pod 4-pinowym gniazdem FAN na laminacie RPi 5."
    echo -e "     - Objawy: System poprawnie odczytuje obroty (pin TACH działa, np. ~9500 RPM), ale fizyczna ścieżka"
    echo -e "       sygnału sterującego PWM jest martwa, przez co wentylator pracuje w trybie awaryjnym (100% mocy)."
    echo -e "     - Zweryfikuj stan pinu w RP1 komendą: ${CYAN}pinctrl get | grep -i fan${NC}"
    echo -e "  ${YELLOW}2. Brak styku na 4. pinie (niebieski przewód PWM) we wtyczce JST-SH:${NC}"
    echo -e "     - Wtyczka Active Coolera nie została dociśnięta do końca w gnieździe FAN lub skrajny pin w gnieździe jest wygięty."
    echo -e "  ${YELLOW}3. Uszkodzony sam wentylator Active Coolera:${NC}"
    echo -e "     - Przerwany niebieski przewód PWM we wiązce lub spalony tranzystor sterujący wewnątrz rotora."
    echo -e "  ${YELLOW}4. Konflikt dwóch partycji bootfs (Karta SD + dysk NVMe jednocześnie):${NC}"
    echo -e "     - Jeśli w slocie nadal znajduje się karta MicroSD, bootloader może ładować stary config.txt z innego nośnika"
    echo -e "       (sprawdź wynik z Kroku 1 i Kroku 2 powyżej oraz wykonaj ${CYAN}sudo reboot${NC})."
fi
echo -e "${CYAN}================================================================${NC}"
