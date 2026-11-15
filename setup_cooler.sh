#!/bin/bash
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}  ACTIVE COOLER + NVMe HEATSINK GUARD (RPi 5 Gen 3)   ${NC}"
echo -e "${CYAN}======================================================${NC}"

if [ -f "/boot/firmware/config.txt" ]; then
    CONFIG_TXT="/boot/firmware/config.txt"
elif [ -f "/boot/config.txt" ]; then
    CONFIG_TXT="/boot/config.txt"
else
    echo -e "${RED}[!] BŁĄD: Nie znaleziono pliku config.txt!${NC}"
    exit 1
fi

echo -e "\n${YELLOW}Wybierz tryb współpracy Active Coolera z radiatorem NVMe:${NC}"
echo -e "  ${GREEN}1) Hybrydowy: CPU + Strażnik Radiatorów NVMe (REKOMENDOWANY)${NC}"
echo -e "     -> Lekki przewiew w obudowie od 38°C CPU + aktywne przyspieszanie"
echo -e "        wentylatora, gdy sam dysk NVMe nagrzeje się podczas transferów NAS."
echo -e "  ${CYAN}2) Tylko sprzętowy: Stały obieg pod radiatory (Airflow)${NC}"
echo -e "     -> Konfiguracja wyłącznie w config.txt (bez usługi w tle)."
echo -e "        Wentylator startuje od 38°C, zapewniając ciągłą konwekcję."
echo -e "  ${RED}3) Przywróć ustawienia fabryczne (usuń strażnika i profil)${NC}\n"

read -p "Wybierz opcję [1-3, domyślnie 1]: " MODE
MODE=${MODE:-1}

echo -e "\n${YELLOW}[1/4] Instalacja narzędzia nvme-cli...${NC}"
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -qq
sudo apt-get install -y -qq nvme-cli >/dev/null
echo -e "${GREEN}[+] Pakiet nvme-cli zainstalowany.${NC}"

echo -e "\n${YELLOW}[2/4] Konfiguracja bazowej krzywej w $CONFIG_TXT...${NC}"
if [ ! -f "${CONFIG_TXT}.bak" ]; then
    sudo cp "$CONFIG_TXT" "${CONFIG_TXT}.bak"
fi

# Usunięcie poprzednich wpisów
sudo sed -i '/# === KONFIGURACJA ACTIVE COOLER ===/,/# === KONIEC ACTIVE COOLER ===/d' "$CONFIG_TXT"
sudo sed -i '/^dtparam=cooling_fan/d' "$CONFIG_TXT"
sudo sed -i '/^dtparam=fan_temp/d' "$CONFIG_TXT"

if [ "$MODE" == "1" ] || [ "$MODE" == "2" ]; then
    # Start od 38°C na 28% mocy (PWM 72) wymusza powolny, bezgłośny ruch powietrza 
    # wokół żeberek radiatora NVMe wewnątrz obudowy.
    sudo bash -c "cat >> '$CONFIG_TXT'" <<EOF

# === KONFIGURACJA ACTIVE COOLER ===
dtparam=cooling_fan=on
dtparam=fan_temp0=38000,fan_temp0_hyst=3000,fan_temp0_speed=72
dtparam=fan_temp1=48000,fan_temp1_hyst=4000,fan_temp1_speed=115
dtparam=fan_temp2=58000,fan_temp2_hyst=4000,fan_temp2_speed=175
dtparam=fan_temp3=68000,fan_temp3_hyst=5000,fan_temp3_speed=255
# === KONIEC ACTIVE COOLER ===
EOF
    echo -e "${GREEN}[+] Zapisano krzywą bazową w $CONFIG_TXT (wymuszony obieg dla radiatora od 38°C).${NC}"
else
    echo -e "${GREEN}[+] Przywrócono domyślne parametry w $CONFIG_TXT.${NC}"
fi

echo -e "\n${YELLOW}[3/4] Konfiguracja usługi NVMe Thermal Guard...${NC}"
if [ "$MODE" == "1" ]; then
    # Skrypt monitorujący temperaturę NVMe i podbijający nawiew na radiator
    sudo bash -c 'cat > /usr/local/sbin/nvme-fan-guard.sh' << 'EOF'
#!/bin/bash
# Strażnik temperatury radiatora NVMe dla Raspberry Pi 5

THERMAL_COOLING="/sys/class/thermal/cooling_device0/cur_state"

while true; do
    if [ -e /dev/nvme0n1 ] && [ -w "$THERMAL_COOLING" ]; then
        # Pobranie temperatury dysku NVMe w stopniach Celsjusza
        NVME_T=$(nvme smart-log /dev/nvme0n1 2>/dev/null | grep -i "^temperature" | awk '{print $3}' | tr -d '[:alpha:]')
        CPU_T_RAW=$(cat /sys/class/thermal/thermal_zone0/temp 2>/dev/null || echo 0)
        CPU_T=$(( CPU_T_RAW / 1000 ))

        if [[ "$NVME_T" =~ ^[0-9]+$ ]]; then
            # Jeśli dysk NVMe jest gorący podczas dużego zapisu przez NAS, 
            # a CPU jest chłodne, wymuszamy wyższy bieg wentylatora dla przedmuchu radiatora:
            if [ "$NVME_T" -ge 62 ] || [ "$CPU_T" -ge 68 ]; then
                echo 4 > "$THERMAL_COOLING"   # 100% obrotów
            elif [ "$NVME_T" -ge 56 ] || [ "$CPU_T" -ge 58 ]; then
                echo 3 > "$THERMAL_COOLING"   # ~70% obrotów
            elif [ "$NVME_T" -ge 50 ] || [ "$CPU_T" -ge 48 ]; then
                echo 2 > "$THERMAL_COOLING"   # ~45% obrotów
            elif [ "$NVME_T" -ge 42 ] || [ "$CPU_T" -ge 38 ]; then
                echo 1 > "$THERMAL_COOLING"   # ~28% obrotów (stały lekki przedmuch radiatora)
            fi
        fi
    fi
    sleep 10
done
EOF
    sudo chmod +x /usr/local/sbin/nvme-fan-guard.sh

    sudo bash -c 'cat > /etc/systemd/system/nvme-fan-guard.service' << 'EOF'
[Unit]
Description=NVMe Heatsink Thermal Guard for RPi 5 Active Cooler
After=multi-user.target

[Service]
Type=simple
ExecStart=/usr/local/sbin/nvme-fan-guard.sh
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

    sudo systemctl daemon-reload
    sudo systemctl enable nvme-fan-guard.service
    sudo systemctl restart nvme-fan-guard.service
    echo -e "${GREEN}[+] Usługa nvme-fan-guard.service została uruchomiona (chroni dysk NVMe pod obciążeniem).${NC}"
else
    if systemctl is-active --quiet nvme-fan-guard.service; then
        sudo systemctl stop nvme-fan-guard.service
        sudo systemctl disable nvme-fan-guard.service
        sudo rm -f /etc/systemd/system/nvme-fan-guard.service /usr/local/sbin/nvme-fan-guard.sh
        sudo systemctl daemon-reload
        echo -e "${YELLOW}[i] Wyłączono i usunięto usługę nvme-fan-guard.service.${NC}"
    else
        echo -e "${YELLOW}[i] Pominięto instalację usługi w tle.${NC}"
    fi
fi

echo -e "\n${YELLOW}[4/4] Aktualizacja narzędzia diagnostycznego 'rpi-temp'...${NC}"
sudo bash -c 'cat > /usr/local/bin/rpi-temp' << 'EOF'
#!/bin/bash
CPU_TEMP=$(vcgencmd measure_temp | cut -d'=' -f2)
FAN_RPM=$(cat /sys/devices/platform/cooling_fan/hwmon/*/fan1_input 2>/dev/null || echo "0")
FAN_PWM=$(cat /sys/devices/platform/cooling_fan/hwmon/*/pwm1 2>/dev/null || echo "0")
FAN_STATE=$(cat /sys/class/thermal/cooling_device0/cur_state 2>/dev/null || echo "?")
FAN_PCT=$(( FAN_PWM * 100 / 255 ))

if command -v nvme &> /dev/null && [ -e /dev/nvme0n1 ]; then
    NVME_TEMP=$(sudo nvme smart-log /dev/nvme0n1 2>/dev/null | grep -i "^temperature" | awk '{print $3 "°C"}' || echo "Brak danych")
else
    NVME_TEMP="Nie wykryto"
fi

GUARD_STATUS=$(systemctl is-active nvme-fan-guard.service 2>/dev/null || echo "inactive")

echo "=================================================="
echo " 🌡️  Temperatura CPU       : $CPU_TEMP"
echo " 💾 Temperatura NVMe (SSD): $NVME_TEMP"
echo " 🌀 Active Cooler         : ${FAN_RPM} RPM (${FAN_PCT}% PWM | Bieg: ${FAN_STATE}/4)"
echo " 🛡️  NVMe Heatsink Guard   : $GUARD_STATUS"
echo "=================================================="
EOF
sudo chmod +x /usr/local/bin/rpi-temp

echo -e "\n${CYAN}======================================================${NC}"
echo -e "${GREEN}[SUKCES] Chłodzenie CPU i radiatora NVMe skonfigurowane!${NC}"
echo -e "Sprawdź status w dowolnym momencie wpisując: ${YELLOW}rpi-temp${NC}"
echo -e "Zalecany restart w celu przeładowania parametrów DT: ${YELLOW}sudo reboot${NC}"
echo -e "${CYAN}======================================================${NC}"
