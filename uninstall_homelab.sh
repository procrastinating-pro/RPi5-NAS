#!/bin/bash
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${RED}======================================================${NC}"
echo -e "${RED}     DEINSTALATOR DOCKER HOMELAB (RPi 5)              ${NC}"
echo -e "${RED}======================================================${NC}"
echo -e "${YELLOW}UWAGA: Ten skrypt bezpowrotnie usunie wszystkie kontenery,${NC}"
echo -e "${YELLOW}sieci Dockera oraz pliki konfiguracyjne z Twojego Raspberry Pi.${NC}"

read -p "Czy na pewno chcesz kontynuować? (Wpisz 'TAK' dużymi literami, aby potwierdzić): " CONFIRM1

if [ "$CONFIRM1" != "TAK" ]; then
    echo -e "${GREEN}Deinstalacja anulowana.${NC}"
    exit 0
fi

ACTUAL_USER=${SUDO_USER:-$USER}
DOCKER_DIR="/home/$ACTUAL_USER/docker/homelab"
NAS_DIR="/srv/nas/pliki"

echo -e "\n${CYAN}[1/4] Zatrzymywanie i usuwanie kontenerów Docker...${NC}"
if [ -f "$DOCKER_DIR/docker-compose.yml" ]; then
    cd "$DOCKER_DIR"
    sudo docker compose down -v || true
else
    echo -e "${YELLOW}Brak pliku docker-compose.yml w $DOCKER_DIR. Próba ręcznego usunięcia...${NC}"
    sudo docker rm -f pihole samba-nas filebrowser-nas twingate-connector vaultwarden watchtower 2>/dev/null || true
fi

echo -e "\n${CYAN}[2/4] Czyszczenie nieużywanych sieci i obrazów Dockera (prune)...${NC}"
sudo docker network prune -f
sudo docker image prune -a -f

echo -e "\n${CYAN}[3/4] Usuwanie plików konfiguracyjnych z $DOCKER_DIR...${NC}"
if [ -d "$DOCKER_DIR" ]; then
    sudo rm -rf "$DOCKER_DIR"
    echo -e "${GREEN}Katalog $DOCKER_DIR został usunięty.${NC}"
else
    echo -e "${YELLOW}Katalog $DOCKER_DIR nie istnieje.${NC}"
fi

echo -e "\n${RED}[4/4] DANE Z DYSKU NAS (/srv/nas/pliki)${NC}"
echo -e "${YELLOW}Obecnie na dysku znajdują się wszystkie Twoje pliki i foldery udostępniane przez Sambę oraz FileBrowsera.${NC}"
read -p "Czy chcesz RÓWNIEŻ usunąć całą zawartość NAS ($NAS_DIR)? (Wpisz 'USUN_DANE' aby wykasować): " CONFIRM2

if [ "$CONFIRM2" == "USUN_DANE" ]; then
    if [ -d "$NAS_DIR" ]; then
        sudo rm -rf "$NAS_DIR"
        echo -e "${GREEN}Katalog NAS ($NAS_DIR) został wykasowany.${NC}"
    else
        echo -e "${YELLOW}Katalog $NAS_DIR nie istnieje.${NC}"
    fi
else
    echo -e "${GREEN}Zachowano dane na dysku NAS w $NAS_DIR.${NC}"
fi

# Zatrzymanie zwalniania portu 53 jeśli pihole było używane (przywrócenie DNSStubListener)
if systemctl is-active --quiet systemd-resolved; then
    echo -e "\n${CYAN}[*] Przywracanie domyślnej konfiguracji systemd-resolved (port 53)...${NC}"
    sudo sed -i 's/DNSStubListener=no/#DNSStubListener=yes/g' /etc/systemd/resolved.conf || true
    sudo systemctl restart systemd-resolved || true
fi

echo -e "\n${RED}======================================================${NC}"
echo -e "${GREEN}[SUKCES] Środowisko Homelab zostało poprawnie odinstalowane.${NC}"
echo -e "${RED}======================================================${NC}"
