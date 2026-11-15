#!/bin/bash
set -e

# Kolory dla czytelności
GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}     KONFIGURATOR HEADLESS RASPBERRY PI 5 (LAN/NVMe)  ${NC}"
echo -e "${CYAN}======================================================${NC}"

ACTUAL_USER=${SUDO_USER:-$USER}
DEFAULT_BOOT="/media/$ACTUAL_USER/bootfs"
DEFAULT_ROOT="/media/$ACTUAL_USER/rootfs"

echo -e "\n${YELLOW}[*] Wykrywanie partycji nośnika (SD / NVMe)...${NC}"
read -p "Ścieżka do partycji bootfs [$DEFAULT_BOOT]: " BOOT_MNT
BOOT_MNT=${BOOT_MNT:-$DEFAULT_BOOT}

read -p "Ścieżka do partycji rootfs [$DEFAULT_ROOT]: " ROOT_MNT
ROOT_MNT=${ROOT_MNT:-$DEFAULT_ROOT}

if [ ! -d "$BOOT_MNT" ] || [ ! -d "$ROOT_MNT" ]; then
    echo -e "${RED}[!] BŁĄD: Nie znaleziono katalogów $BOOT_MNT lub $ROOT_MNT.${NC}"
    echo "    Upewnij się, że obie partycje są zamontowane (sprawdź poleceniem lsblk)."
    exit 1
fi
echo -e "${GREEN}[OK] Znaleziono obie partycje.${NC}\n"

# ================= PYTANIA KONFIGURACYJNE =================

# 1. SSH
read -p "1. Włączyć serwer SSH przy starcie? (T/n): " OPT_SSH
OPT_SSH=${OPT_SSH:-T}

# 2. Użytkownik
read -p "2. Utworzyć/nadpisać konto użytkownika w userconf.txt? (T/n): " OPT_USER
OPT_USER=${OPT_USER:-T}
if [[ "$OPT_USER" =~ ^[TtYy]$ ]]; then
    read -p "   -> Podaj nazwę użytkownika [tomasz]: " NOWY_USER
    NOWY_USER=${NOWY_USER:-tomasz}
    while true; do
        read -s -p "   -> Podaj hasło dla '$NOWY_USER': " NOWE_HASLO
        echo ""
        if [ -n "$NOWE_HASLO" ]; then break; else echo "      Hasło nie może być puste!"; fi
    done
fi

# 3. Klucz SSH
read -p "3. Dodać Twój lokalny klucz SSH (logowanie bez hasła)? (t/N): " OPT_SSH_KEY
OPT_SSH_KEY=${OPT_SSH_KEY:-N}

# 4. Statyczny IP na LAN (eth0)
read -p "4. Ustawić statyczny adres IP dla kabla LAN (eth0)? (T/n): " OPT_IP
OPT_IP=${OPT_IP:-T}
if [[ "$OPT_IP" =~ ^[TtYy]$ ]]; then
    read -p "   -> Adres IP z maską [192.168.1.250/24]: " STATIC_IP
    STATIC_IP=${STATIC_IP:-192.168.1.250/24}
    read -p "   -> Brama domyślna (Gateway) [192.168.1.1]: " BRAMA
    BRAMA=${BRAMA:-192.168.1.1}
    read -p "   -> Serwery DNS (oddzielone średnikiem) [1.1.1.1;8.8.8.8;]: " DNS
    DNS=${DNS:-1.1.1.1;8.8.8.8;}
fi

# 5. Obsługa Raspberry Pi NVMe HAT+
read -p "5. Włączyć obsługę NVMe HAT+ (PCIe) w config.txt? (T/n): " OPT_NVME
OPT_NVME=${OPT_NVME:-T}
if [[ "$OPT_NVME" =~ ^[TtYy]$ ]]; then
    read -p "   -> Wymusić szybszy tryb PCIe Gen 3 (ok. 800 MB/s zamiast 450 MB/s)? (T/n): " OPT_GEN3
    OPT_GEN3=${OPT_GEN3:-T}
fi

# 6. Hostname
read -p "6. Zmienić nazwę hosta (hostname)? (t/N): " OPT_HOST
OPT_HOST=${OPT_HOST:-N}
if [[ "$OPT_HOST" =~ ^[TtYy]$ ]]; then
    read -p "   -> Podaj nową nazwę hosta [rpi5-nvme]: " NOWY_HOST
    NOWY_HOST=${NOWY_HOST:-rpi5-nvme}
fi

echo -e "\n${CYAN}======================================================${NC}"
echo -e "${YELLOW}[*] Rozpoczynam zapisywanie konfiguracji...${NC}"

# ================= WYKONANIE ZMIAN =================

# 1. Włączenie SSH
if [[ "$OPT_SSH" =~ ^[TtYy]$ ]]; then
    touch "$BOOT_MNT/ssh"
    echo -e "${GREEN}[+] Włączono SSH ($BOOT_MNT/ssh).${NC}"
fi

# 2. Użytkownik
if [[ "$OPT_USER" =~ ^[TtYy]$ ]]; then
    HASH=$(openssl passwd -6 "$NOWE_HASLO")
    echo "${NOWY_USER}:${HASH}" > "$BOOT_MNT/userconf.txt"
    echo -e "${GREEN}[+] Utworzono użytkownika '$NOWY_USER' w userconf.txt.${NC}"
fi

# 3. Klucz SSH
if [[ "$OPT_SSH_KEY" =~ ^[TtYy]$ ]]; then
    USER_HOME=$(eval echo ~$ACTUAL_USER)
    PUB_KEY=""
    if [ -f "$USER_HOME/.ssh/id_ed25519.pub" ]; then
        PUB_KEY="$USER_HOME/.ssh/id_ed25519.pub"
    elif [ -f "$USER_HOME/.ssh/id_rsa.pub" ]; then
        PUB_KEY="$USER_HOME/.ssh/id_rsa.pub"
    fi

    if [ -n "$PUB_KEY" ]; then
        TARGET_SSH_DIR="$ROOT_MNT/home/${NOWY_USER:-pi}/.ssh"
        sudo mkdir -p "$TARGET_SSH_DIR"
        sudo cp "$PUB_KEY" "$TARGET_SSH_DIR/authorized_keys"
        sudo chown -R 1000:1000 "$ROOT_MNT/home/${NOWY_USER:-pi}"
        sudo chmod 700 "$TARGET_SSH_DIR"
        sudo chmod 600 "$TARGET_SSH_DIR/authorized_keys"
        echo -e "${GREEN}[+] Dodano klucz SSH ($PUB_KEY) dla użytkownika.${NC}"
    else
        echo -e "${RED}[!] Nie znaleziono klucza publicznego w $USER_HOME/.ssh/ - pominięto.${NC}"
    fi
fi

# 4. Statyczny IP (LAN - eth0)
if [[ "$OPT_IP" =~ ^[TtYy]$ ]]; then
    NM_DIR="$ROOT_MNT/etc/NetworkManager/system-connections"
    sudo mkdir -p "$NM_DIR"
    CONN_FILE="$NM_DIR/static-eth0.nmconnection"
    UUID_GEN=$(cat /proc/sys/kernel/random/uuid)

    sudo bash -c "cat > '$CONN_FILE'" <<EOF
[connection]
id=static-eth0
uuid=$UUID_GEN
type=ethernet
interface-name=eth0
autoconnect=true
autoconnect-priority=100

[ethernet]

[ipv4]
method=manual
addresses=$STATIC_IP
gateway=$BRAMA
dns=$DNS

[ipv6]
method=auto
EOF
    sudo chown root:root "$CONN_FILE"
    sudo chmod 600 "$CONN_FILE"
    echo -e "${GREEN}[+] Skonfigurowano statyczne IP ($STATIC_IP) dla interfejsu eth0.${NC}"
fi

# 5. Konfiguracja NVMe HAT+ w config.txt
if [[ "$OPT_NVME" =~ ^[TtYy]$ ]]; then
    CONFIG_TXT="$BOOT_MNT/config.txt"
    if ! grep -q "^dtparam=pciex1" "$CONFIG_TXT"; then
        echo "" >> "$CONFIG_TXT"
        echo "# Konfiguracja Raspberry Pi NVMe HAT+" >> "$CONFIG_TXT"
        echo "dtparam=pciex1" >> "$CONFIG_TXT"
    fi
    if [[ "$OPT_GEN3" =~ ^[TtYy]$ ]] && ! grep -q "^dtparam=pciex1_gen=3" "$CONFIG_TXT"; then
        echo "dtparam=pciex1_gen=3" >> "$CONFIG_TXT"
    fi
    echo -e "${GREEN}[+] Dopisano obsługę PCIe NVMe HAT+ do $CONFIG_TXT.${NC}"
fi

# 6. Zmiana Hostname
if [[ "$OPT_HOST" =~ ^[TtYy]$ ]]; then
    echo "$NOWY_HOST" | sudo tee "$ROOT_MNT/etc/hostname" > /dev/null
    sudo sed -i "s/127.0.1.1.*/127.0.1.1\t$NOWY_HOST/g" "$ROOT_MNT/etc/hosts"
    echo -e "${GREEN}[+] Zmieniono nazwę hosta na '$NOWY_HOST'.${NC}"
fi

echo -e "${YELLOW}[*] Synchronizacja buforów zapisu (sync)...${NC}"
sync

IP_CLEAN=$(echo "${STATIC_IP:-192.168.1.250}" | cut -d'/' -f1)
echo -e "${CYAN}======================================================${NC}"
echo -e "${GREEN}[SUKCES] Konfiguracja zakończona!${NC}"
echo -e "Możesz teraz odmontować partycje poleceniem:"
echo -e "  ${YELLOW}sudo umount \"$BOOT_MNT\" \"$ROOT_MNT\"${NC}"
echo -e "Po uruchomieniu RPi 5 połącz się przez:"
echo -e "  ${YELLOW}ssh ${NOWY_USER:-tomasz}@${IP_CLEAN}${NC}"
echo -e "${CYAN}======================================================${NC}"
