#!/bin/bash
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}     KONFIGURATOR DOCKER MEDIA STACK (RPi 5 - BASH)   ${NC}"
echo -e "${CYAN}======================================================${NC}"

ACTUAL_USER=${SUDO_USER:-$USER}
USER_UID=$(id -u "$ACTUAL_USER")
USER_GID=$(id -g "$ACTUAL_USER")
DEFAULT_IP=$(hostname -I | awk '{print $1}')
DEFAULT_IP=${DEFAULT_IP:-192.168.1.250}

# ================= 1. WSPÓLNE ŚCIEŻKI I SIEĆ =================
echo -e "\n${YELLOW}[*] KROK 1: Konfiguracja sieci i katalogów głównych:${NC}"
read -p "1. Adres IP Twojego Raspberry Pi [$DEFAULT_IP]: " RPI_IP
RPI_IP=${RPI_IP:-$DEFAULT_IP}

read -p "2. Katalog główny dla plików Mediów i Pobrań [/srv/nas/pliki]: " NAS_DIR
NAS_DIR=${NAS_DIR:-/srv/nas/pliki}

read -p "3. Katalog konfiguracji Dockera [/home/$ACTUAL_USER/docker/mediastack]: " DOCKER_DIR
DOCKER_DIR=${DOCKER_DIR:-/home/$ACTUAL_USER/docker/mediastack}

# ================= 2. WYBÓR KONTENERÓW (T/N) =================
echo -e "\n${YELLOW}[*] KROK 2: Wybierz kontenery Media Stack do zainstalowania (T/n):${NC}"
read -p "   -> [1/6] Jellyfin (Serwer wideo i multimediów - port 8096)? [T/n]: " OPT_JF
OPT_JF=${OPT_JF:-T}

read -p "   -> [2/6] qBittorrent (Klient torrent WebUI - port 8085)? [T/n]: " OPT_QB
OPT_QB=${OPT_QB:-T}

read -p "   -> [3/6] Prowlarr (Menedżer indekserów dla *arr - port 9696)? [T/n]: " OPT_PROWLARR
OPT_PROWLARR=${OPT_PROWLARR:-T}

read -p "   -> [4/6] Sonarr (Automatyzacja seriali - port 8989)? [T/n]: " OPT_SONARR
OPT_SONARR=${OPT_SONARR:-T}

read -p "   -> [5/6] Radarr (Automatyzacja filmów - port 7878)? [T/n]: " OPT_RADARR
OPT_RADARR=${OPT_RADARR:-T}

read -p "   -> [6/6] Bazarr (Automatyczne napisy do filmów i seriali - port 6767)? [T/n]: " OPT_BAZARR
OPT_BAZARR=${OPT_BAZARR:-T}

# ================= 3. INFORMACJA PRAWNA I KONFIGURACJA QBITTORRENT =================
if [[ "$OPT_QB" =~ ^[TtYy]$ ]]; then
    echo -e "\n${RED}======================================================${NC}"
    echo -e "${RED}  [!] WAŻNA INFORMACJA PRAWNA DOT. QBITTORRENT (P2P)  ${NC}"
    echo -e "${RED}======================================================${NC}"
    echo -e "${YELLOW}1. Legalność narzędzia:${NC}"
    echo -e "   Sam klient qBittorrent i protokół BitTorrent są w pełni legalne"
    echo -e "   (służą m.in. do pobierania obrazów ISO Linux, domeny publicznej"
    echo -e "   oraz materiałów na otwartych licencjach Creative Commons)."
    echo -e "${YELLOW}2. Automatyczne udostępnianie (seedowanie):${NC}"
    echo -e "   Protokół BitTorrent (P2P) domyślnie WYSYŁA pobrane fragmenty"
    echo -e "   pliku innym użytkownikom już w trakcie pobierania – nie da się"
    echo -e "   tego w 100% zablokować ustawieniami ani zaporą Dockera."
    echo -e "${YELLOW}3. Prawo autorskie w Polsce (Ustawa o prawie autorskim):${NC}"
    echo -e "   - Samo pobranie rozpowszechnionego filmu/serialu na własny użytek"
    echo -e "     (art. 23) nie stanowi przestępstwa."
    echo -e "   - ${RED}Rozpowszechnianie (udostępnianie/seedowanie) utworów chronionych${NC}"
    echo -e "     ${RED}bez licencji jest NIELEGALNE (art. 116) i podlega odpowiedzialności${NC}"
    echo -e "     ${RED}karnej oraz cywilnej.${NC}"
    echo -e "   - Dozwolony użytek NIE obejmuje programów komputerowych ani gier."
    echo -e "${YELLOW}4. Odpowiedzialność:${NC}"
    echo -e "   Użytkownik ponosi wyłączną odpowiedzialność za sposób korzystania"
    echo -e "   z klienta P2P oraz status prawny pobieranych plików."
    echo -e "${RED}======================================================${NC}"

    read -p "Czy rozumiesz powyższe zasady i chcesz zainstalować qBittorrent? [t/N]: " OPT_QB_CONFIRM
    OPT_QB_CONFIRM=${OPT_QB_CONFIRM:-N}

    if [[ "$OPT_QB_CONFIRM" =~ ^[TtYy]$ ]]; then
        echo -e "\n${YELLOW}[*] Konfiguracja qBittorrent:${NC}"
        read -p "   -> Port panelu WWW qBittorrent [8085]: " QB_PORT
        QB_PORT=${QB_PORT:-8085}
    else
        OPT_QB="N"
        echo -e "${YELLOW}[i] Pominięto instalację qBittorrent. Pozostałe wybrane usługi zostaną zainstalowane.${NC}"
    fi
fi

if ! [[ "$OPT_JF$OPT_QB$OPT_PROWLARR$OPT_SONARR$OPT_RADARR$OPT_BAZARR" =~ [TtYy] ]]; then
    echo -e "\n${RED}[!] Nie wybrano żadnego kontenera do instalacji. Przerywam.${NC}"
    exit 0
fi

echo -e "\n${CYAN}======================================================${NC}"

# ================= 4. PRZYGOTOWANIE KATALOGÓW (TRASH-GUIDES HARDLINKS) =================
echo -e "${YELLOW}[1/3] Tworzenie struktury katalogów w $NAS_DIR oraz $DOCKER_DIR...${NC}"
# Wspólna struktura dla hardlinków między klientem pobierania (/data/downloads) a Radarr/Sonarr/Bazarr/Jellyfin (/data/media)
sudo mkdir -p "$NAS_DIR"/{media/{movies,tv,music},downloads/{complete,incomplete}}
sudo chown -R "$ACTUAL_USER:$ACTUAL_USER" "$(dirname "$NAS_DIR")"
sudo chmod -R 775 "$NAS_DIR"

mkdir -p "$DOCKER_DIR"

cat > "$DOCKER_DIR/docker-compose.yml" <<EOF
services:
EOF

# ================= 5. GENEROWANIE USŁUG W DOCKER-COMPOSE =================
echo -e "${YELLOW}[2/3] Generowanie pliku docker-compose.yml dla wybranych usług...${NC}"

# --- JELLYFIN ---
if [[ "$OPT_JF" =~ ^[TtYy]$ ]]; then
    mkdir -p "$DOCKER_DIR/jellyfin/config" "$DOCKER_DIR/jellyfin/cache"
    sudo chown -R "$USER_UID:$USER_GID" "$DOCKER_DIR/jellyfin"
    cat >> "$DOCKER_DIR/docker-compose.yml" <<EOF

  jellyfin:
    container_name: jellyfin
    image: lscr.io/linuxserver/jellyfin:latest
    environment:
      - PUID=${USER_UID}
      - PGID=${USER_GID}
      - TZ=Europe/Warsaw
    ports:
      - "8096:8096"
    volumes:
      - './jellyfin/config:/config'
      - './jellyfin/cache:/cache'
      - '${NAS_DIR}/media:/data/media'
    devices:
      - /dev/dri:/dev/dri
    restart: unless-stopped
EOF
fi

# --- QBITTORRENT ---
if [[ "$OPT_QB" =~ ^[TtYy]$ ]]; then
    mkdir -p "$DOCKER_DIR/qbittorrent"
    sudo chown -R "$USER_UID:$USER_GID" "$DOCKER_DIR/qbittorrent"
    cat >> "$DOCKER_DIR/docker-compose.yml" <<EOF

  qbittorrent:
    container_name: qbittorrent
    image: lscr.io/linuxserver/qbittorrent:latest
    environment:
      - PUID=${USER_UID}
      - PGID=${USER_GID}
      - TZ=Europe/Warsaw
      - WEBUI_PORT=${QB_PORT}
      - TORRENTING_PORT=6881
    ports:
      - "${QB_PORT}:${QB_PORT}"
      - "6881:6881"
      - "6881:6881/udp"
    volumes:
      - './qbittorrent:/config'
      - '${NAS_DIR}/downloads:/data/downloads'
    restart: unless-stopped
EOF
fi

# --- PROWLARR ---
if [[ "$OPT_PROWLARR" =~ ^[TtYy]$ ]]; then
    mkdir -p "$DOCKER_DIR/prowlarr"
    sudo chown -R "$USER_UID:$USER_GID" "$DOCKER_DIR/prowlarr"
    cat >> "$DOCKER_DIR/docker-compose.yml" <<EOF

  prowlarr:
    container_name: prowlarr
    image: lscr.io/linuxserver/prowlarr:latest
    environment:
      - PUID=${USER_UID}
      - PGID=${USER_GID}
      - TZ=Europe/Warsaw
    ports:
      - "9696:9696"
    volumes:
      - './prowlarr:/config'
    restart: unless-stopped
EOF
fi

# --- SONARR ---
if [[ "$OPT_SONARR" =~ ^[TtYy]$ ]]; then
    mkdir -p "$DOCKER_DIR/sonarr"
    sudo chown -R "$USER_UID:$USER_GID" "$DOCKER_DIR/sonarr"
    cat >> "$DOCKER_DIR/docker-compose.yml" <<EOF

  sonarr:
    container_name: sonarr
    image: lscr.io/linuxserver/sonarr:latest
    environment:
      - PUID=${USER_UID}
      - PGID=${USER_GID}
      - TZ=Europe/Warsaw
    ports:
      - "8989:8989"
    volumes:
      - './sonarr:/config'
      - '${NAS_DIR}:/data'
    restart: unless-stopped
EOF
fi

# --- RADARR ---
if [[ "$OPT_RADARR" =~ ^[TtYy]$ ]]; then
    mkdir -p "$DOCKER_DIR/radarr"
    sudo chown -R "$USER_UID:$USER_GID" "$DOCKER_DIR/radarr"
    cat >> "$DOCKER_DIR/docker-compose.yml" <<EOF

  radarr:
    container_name: radarr
    image: lscr.io/linuxserver/radarr:latest
    environment:
      - PUID=${USER_UID}
      - PGID=${USER_GID}
      - TZ=Europe/Warsaw
    ports:
      - "7878:7878"
    volumes:
      - './radarr:/config'
      - '${NAS_DIR}:/data'
    restart: unless-stopped
EOF
fi

# --- BAZARR ---
if [[ "$OPT_BAZARR" =~ ^[TtYy]$ ]]; then
    mkdir -p "$DOCKER_DIR/bazarr"
    sudo chown -R "$USER_UID:$USER_GID" "$DOCKER_DIR/bazarr"
    cat >> "$DOCKER_DIR/docker-compose.yml" <<EOF

  bazarr:
    container_name: bazarr
    image: lscr.io/linuxserver/bazarr:latest
    environment:
      - PUID=${USER_UID}
      - PGID=${USER_GID}
      - TZ=Europe/Warsaw
    ports:
      - "6767:6767"
    volumes:
      - './bazarr:/config'
      - '${NAS_DIR}/media:/data/media'
    restart: unless-stopped
EOF
fi

echo -e "${GREEN}[+] Plik $DOCKER_DIR/docker-compose.yml został wygenerowany.${NC}"

# ================= 6. URUCHOMIENIE KONTENERÓW =================
cd "$DOCKER_DIR"
echo -e "${YELLOW}[3/3] Uruchamianie wybranych kontenerów Media Stack w tle...${NC}"
sudo docker compose up -d

echo -e "\n${CYAN}======================================================${NC}"
echo -e "${GREEN}[SUKCES] Wybrane usługi Media Stack działają w tle!${NC}"
echo -e "Katalog danych:      ${YELLOW}${NAS_DIR}${NC} (w tym /media/movies, /media/tv, /downloads)"
echo -e "Plik Compose:        ${YELLOW}${DOCKER_DIR}/docker-compose.yml${NC}"
echo -e "------------------------------------------------------"
[[ "$OPT_JF" =~ ^[TtYy]$ ]]       && echo -e "Jellyfin:     http://${RPI_IP}:8096 (Foldery: /data/media/movies oraz /data/media/tv)"
[[ "$OPT_QB" =~ ^[TtYy]$ ]]       && echo -e "qBittorrent:  http://${RPI_IP}:${QB_PORT} (Domyślny login: admin, hasło tymczasowe: sudo docker logs qbittorrent)"
[[ "$OPT_PROWLARR" =~ ^[TtYy]$ ]] && echo -e "Prowlarr:     http://${RPI_IP}:9696"
[[ "$OPT_SONARR" =~ ^[TtYy]$ ]]   && echo -e "Sonarr:       http://${RPI_IP}:8989 (Root Folder: /data/media/tv)"
[[ "$OPT_RADARR" =~ ^[TtYy]$ ]]   && echo -e "Radarr:       http://${RPI_IP}:7878 (Root Folder: /data/media/movies)"
[[ "$OPT_BAZARR" =~ ^[TtYy]$ ]]   && echo -e "Bazarr:       http://${RPI_IP}:6767"
echo -e "${CYAN}======================================================${NC}"
