#!/bin/bash
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${RED}======================================================${NC}"
echo -e "${RED}   DEINSTALATOR DOCKER HOMELAB / MEDIA STACK (RPi 5)  ${NC}"
echo -e "${RED}======================================================${NC}"

echo -e "\n${YELLOW}Wybierz zakres deinstalacji:${NC}"
echo -e "  ${CYAN}1)${NC} Tylko ${YELLOW}HomeLab & NAS${NC} (Pi-hole, Samba, FileBrowser, Twingate, Vaultwarden, Watchtower)"
echo -e "  ${CYAN}2)${NC} Tylko ${YELLOW}Media Stack${NC}   (Jellyfin, qBittorrent, Prowlarr, Sonarr, Radarr, Bazarr)"
echo -e "  ${RED}3)${NC} ${RED}Oba środowiska${NC}      (HomeLab & NAS + Media Stack)"
echo -e "  ${GREEN}4)${NC} Anuluj\n"

read -p "Wybierz opcję [1-4]: " CHOICE

case "$CHOICE" in
    1)
        REMOVE_HOMELAB=true
        REMOVE_MEDIA=false
        SCOPE_LABEL="HomeLab & NAS (~/docker/homelab)"
        ;;
    2)
        REMOVE_HOMELAB=false
        REMOVE_MEDIA=true
        SCOPE_LABEL="Media Stack (~/docker/mediastack)"
        ;;
    3)
        REMOVE_HOMELAB=true
        REMOVE_MEDIA=true
        SCOPE_LABEL="OBA środowiska (HomeLab & NAS + Media Stack)"
        ;;
    *)
        echo -e "${GREEN}Deinstalacja anulowana.${NC}"
        exit 0
        ;;
esac

echo -e "\n${YELLOW}UWAGA: Ten skrypt bezpowrotnie usunie kontenery oraz pliki konfiguracyjne dla:${NC}"
echo -e "  -> ${RED}${SCOPE_LABEL}${NC}\n"

read -p "Czy na pewno chcesz kontynuować? (Wpisz 'TAK' dużymi literami, aby potwierdzić): " CONFIRM1

if [ "$CONFIRM1" != "TAK" ]; then
    echo -e "${GREEN}Deinstalacja anulowana.${NC}"
    exit 0
fi

ACTUAL_USER=${SUDO_USER:-$USER}
HOMELAB_DIR="/home/$ACTUAL_USER/docker/homelab"
MEDIA_DIR="/home/$ACTUAL_USER/docker/mediastack"
NAS_DIR="/srv/nas/pliki"

# ================= 1. ZATRZYMYWANIE I USUWANIE KONTENERÓW =================
echo -e "\n${CYAN}[1/4] Zatrzymywanie i usuwanie wybranych kontenerów Docker...${NC}"

if [ "$REMOVE_HOMELAB" = true ]; then
    echo -e "${YELLOW} -> Usuwanie stosu HomeLab & NAS...${NC}"
    if [ -f "$HOMELAB_DIR/docker-compose.yml" ]; then
        (cd "$HOMELAB_DIR" && sudo docker compose down -v) || true
    else
        echo -e "${YELLOW}    Brak pliku docker-compose.yml w $HOMELAB_DIR. Próba ręcznego usunięcia...${NC}"
        sudo docker rm -f pihole samba-nas filebrowser-nas twingate-connector vaultwarden watchtower 2>/dev/null || true
    fi
fi

if [ "$REMOVE_MEDIA" = true ]; then
    echo -e "${YELLOW} -> Usuwanie stosu Media Stack...${NC}"
    if [ -f "$MEDIA_DIR/docker-compose.yml" ]; then
        (cd "$MEDIA_DIR" && sudo docker compose down -v) || true
    else
        echo -e "${YELLOW}    Brak pliku docker-compose.yml w $MEDIA_DIR. Próba ręcznego usunięcia...${NC}"
        sudo docker rm -f jellyfin qbittorrent prowlarr sonarr radarr bazarr 2>/dev/null || true
    fi
fi

# ================= 2. CZYSZCZENIE SIECI I OBRAZÓW =================
echo -e "\n${CYAN}[2/4] Czyszczenie nieużywanych sieci i obrazów Dockera (prune)...${NC}"
sudo docker network prune -f
sudo docker image prune -a -f

# ================= 3. USUWANIE KATALOGÓW KONFIGURACYJNYCH =================
echo -e "\n${CYAN}[3/4] Usuwanie plików konfiguracyjnych Dockera...${NC}"

if [ "$REMOVE_HOMELAB" = true ]; then
    if [ -d "$HOMELAB_DIR" ]; then
        sudo rm -rf "$HOMELAB_DIR"
        echo -e "${GREEN}[+] Katalog $HOMELAB_DIR został usunięty.${NC}"
    else
        echo -e "${YELLOW}[i] Katalog $HOMELAB_DIR nie istnieje.${NC}"
    fi
fi

if [ "$REMOVE_MEDIA" = true ]; then
    if [ -d "$MEDIA_DIR" ]; then
        sudo rm -rf "$MEDIA_DIR"
        echo -e "${GREEN}[+] Katalog $MEDIA_DIR został usunięty.${NC}"
    else
        echo -e "${YELLOW}[i] Katalog $MEDIA_DIR nie istnieje.${NC}"
    fi
fi

# ================= 4. DANE NA DYSKU NAS =================
echo -e "\n${RED}[4/4] DANE NA DYSKU NAS ($NAS_DIR)${NC}"

if [ "$REMOVE_HOMELAB" = false ] && [ "$REMOVE_MEDIA" = true ]; then
    echo -e "${YELLOW}Wybrano usunięcie wyłącznie Media Stacka. Pozostałe pliki NAS pozostaną nienaruszone.${NC}"
    read -p "Czy chcesz RÓWNIEŻ usunąć foldery mediów i pobrań ($NAS_DIR/media oraz $NAS_DIR/downloads)? (Wpisz 'USUN_MEDIA' aby wykasować): " CONFIRM_MEDIA

    if [ "$CONFIRM_MEDIA" == "USUN_MEDIA" ]; then
        sudo rm -rf "$NAS_DIR/media" "$NAS_DIR/downloads"
        echo -e "${GREEN}[+] Katalogi $NAS_DIR/media oraz $NAS_DIR/downloads zostały wykasowane.${NC}"
    else
        echo -e "${GREEN}[+] Zachowano pliki mediów i pobrań w $NAS_DIR.${NC}"
    fi
else
    echo -e "${YELLOW}Obecnie na dysku znajdują się wszystkie Twoje pliki i foldery udostępniane przez NAS.${NC}"
    read -p "Czy chcesz RÓWNIEŻ usunąć całą zawartość NAS ($NAS_DIR)? (Wpisz 'USUN_DANE' aby wykasować): " CONFIRM2

    if [ "$CONFIRM2" == "USUN_DANE" ]; then
        if [ -d "$NAS_DIR" ]; then
            sudo rm -rf "$NAS_DIR"
            echo -e "${GREEN}[+] Katalog NAS ($NAS_DIR) został wykasowany.${NC}"
        else
            echo -e "${YELLOW}[i] Katalog $NAS_DIR nie istnieje.${NC}"
        fi
    else
        echo -e "${GREEN}[+] Zachowano dane na dysku NAS w $NAS_DIR.${NC}"
    fi
fi

# ================= 5. PRZYWRÓCENIE PORTU 53 (TYLKO PRZY USUWANIU HOMELAB) =================
if [ "$REMOVE_HOMELAB" = true ] && systemctl is-active --quiet systemd-resolved; then
    echo -e "\n${CYAN}[*] Przywracanie domyślnej konfiguracji systemd-resolved (port 53)...${NC}"
    sudo sed -i 's/DNSStubListener=no/#DNSStubListener=yes/g' /etc/systemd/resolved.conf || true
    sudo systemctl restart systemd-resolved || true
fi

echo -e "\n${RED}======================================================${NC}"
echo -e "${GREEN}[SUKCES] Wybrany zakres (${SCOPE_LABEL}) został odinstalowany.${NC}"
echo -e "${RED}======================================================${NC}"
