#!/bin/bash
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}     KONFIGURATOR DOCKER: PI-HOLE + NAS (SAMBA/WWW)   ${NC}"
echo -e "${CYAN}======================================================${NC}"

ACTUAL_USER=${SUDO_USER:-$USER}
USER_UID=$(id -u "$ACTUAL_USER")
USER_GID=$(id -g "$ACTUAL_USER")
DEFAULT_IP=$(hostname -I | awk '{print $1}')
DEFAULT_IP=${DEFAULT_IP:-192.168.1.250}

# ================= PYTANIA KONFIGURACYJNE =================

echo -e "\n${YELLOW}[*] Konfiguracja sieci i katalogów:${NC}"
read -p "1. Adres IP Twojego Raspberry Pi [$DEFAULT_IP]: " RPI_IP
RPI_IP=${RPI_IP:-$DEFAULT_IP}

read -p "2. Katalog główny dla plików NAS [/srv/nas/pliki]: " NAS_DIR
NAS_DIR=${NAS_DIR:-/srv/nas/pliki}

read -p "3. Katalog konfiguracji Dockera [/home/$ACTUAL_USER/docker/pihole-nas]: " DOCKER_DIR
DOCKER_DIR=${DOCKER_DIR:-/home/$ACTUAL_USER/docker/pihole-nas}

echo -e "\n${YELLOW}[*] Konfiguracja Pi-hole:${NC}"
read -p "4. Port panelu WWW Pi-hole [8080]: " PIHOLE_PORT
PIHOLE_PORT=${PIHOLE_PORT:-8080}

while true; do
    read -s -p "5. Hasło do panelu WWW Pi-hole: " PIHOLE_PASS
    echo ""
    if [ -n "$PIHOLE_PASS" ]; then break; else echo -e "${RED}   Hasło nie może być puste!${NC}"; fi
done

echo -e "\n${YELLOW}[*] Konfiguracja NAS (Samba + FileBrowser):${NC}"
read -p "6. Nazwa udziału sieciowego (widoczna w LAN) [DyskNAS]: " SHARE_NAME
SHARE_NAME=${SHARE_NAME:-DyskNAS}

read -p "7. Login do dysku sieciowego Samba [$ACTUAL_USER]: " SAMBA_USER
SAMBA_USER=${SAMBA_USER:-$ACTUAL_USER}

while true; do
    read -s -p "8. Hasło do dysku sieciowego Samba: " SAMBA_PASS
    echo ""
    if [ -n "$SAMBA_PASS" ]; then break; else echo -e "${RED}   Hasło nie może być puste!${NC}"; fi
done

read -p "9. Zainstalować też panel WWW do plików (FileBrowser)? (T/n): " OPT_FB
OPT_FB=${OPT_FB:-T}
if [[ "$OPT_FB" =~ ^[TtYy]$ ]]; then
    read -p "   -> Port dla FileBrowsera [8081]: " FB_PORT
    FB_PORT=${FB_PORT:-8081}
fi

echo -e "\n${CYAN}======================================================${NC}"

# ================= KROK 1: ZWALNIANIE PORTU 53 =================
echo -e "${YELLOW}[1/4] Sprawdzanie czy port 53 (DNS) jest wolny...${NC}"
if sudo ss -tulnp | grep -q ":53 "; then
    echo -e "${YELLOW}[!] Wykryto usługę zajmującą port 53. Zwalnianie portu...${NC}"
    if systemctl is-active --quiet systemd-resolved; then
        sudo sed -i 's/#DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
        sudo sed -i 's/DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
        sudo rm -f /etc/resolv.conf
        echo "nameserver 1.1.1.1" | sudo tee /etc/resolv.conf > /dev/null
        echo "nameserver 8.8.8.8" | sudo tee -a /etc/resolv.conf > /dev/null
        sudo systemctl restart systemd-resolved
        echo -e "${GREEN}[+] Wyłączono DNSStubListener w systemd-resolved.${NC}"
    else
        echo -e "${RED}[!] Uwaga: Inny proces zajmuje port 53 (sprawdź: sudo ss -tulnp | grep :53).${NC}"
    fi
else
    echo -e "${GREEN}[OK] Port 53 jest wolny.${NC}"
fi

# ================= KROK 2: TWORZENIE KATALOGÓW =================
echo -e "${YELLOW}[2/4] Tworzenie struktury katalogów...${NC}"
sudo mkdir -p "$NAS_DIR"
sudo chown -R "$ACTUAL_USER:$ACTUAL_USER" "$(dirname "$NAS_DIR")"
sudo chmod -R 775 "$NAS_DIR"

mkdir -p "$DOCKER_DIR/etc-pihole"
mkdir -p "$DOCKER_DIR/etc-dnsmasq.d"

if [[ "$OPT_FB" =~ ^[TtYy]$ ]]; then
    mkdir -p "$DOCKER_DIR/filebrowser"
    touch "$DOCKER_DIR/filebrowser/database.db"
fi
echo -e "${GREEN}[+] Utworzono katalogi w $NAS_DIR oraz $DOCKER_DIR.${NC}"

# ================= KROK 3: GENEROWANIE DOCKER-COMPOSE =================
echo -e "${YELLOW}[3/4] Generowanie pliku docker-compose.yml...${NC}"

cat > "$DOCKER_DIR/docker-compose.yml" <<EOF
services:
  pihole:
    container_name: pihole
    image: pihole/pihole:latest
    ports:
      - "53:53/tcp"
      - "53:53/udp"
      - "${PIHOLE_PORT}:80/tcp"
    environment:
      TZ: 'Europe/Warsaw'
      WEBPASSWORD: '${PIHOLE_PASS}'
      FTLCONF_webserver_api_password: '${PIHOLE_PASS}'
      FTLCONF_LOCAL_IPV4: '${RPI_IP}'
      FTLCONF_dns_listeningMode: 'all'
    volumes:
      - './etc-pihole:/etc/pihole'
      - './etc-dnsmasq.d:/etc/dnsmasq.d'
    cap_add:
      - NET_ADMIN
    restart: unless-stopped

  samba:
    container_name: samba-nas
    image: dperson/samba:latest
    ports:
      - "139:139/tcp"
      - "445:445/tcp"
    environment:
      TZ: 'Europe/Warsaw'
      USERID: '${USER_UID}'
      GROUPID: '${USER_GID}'
    volumes:
      - '${NAS_DIR}:/mount:z'
    command: '-u "${SAMBA_USER};${SAMBA_PASS}" -s "${SHARE_NAME};/mount;yes;no;no;${SAMBA_USER}" -p'
    restart: unless-stopped
EOF

if [[ "$OPT_FB" =~ ^[TtYy]$ ]]; then
cat >> "$DOCKER_DIR/docker-compose.yml" <<EOF

  filebrowser:
    container_name: filebrowser-nas
    image: filebrowser/filebrowser:latest
    user: "${USER_UID}:${USER_GID}"
    ports:
      - "${FB_PORT}:80"
    volumes:
      - '${NAS_DIR}:/srv'
      - './filebrowser/database.db:/database.db'
    restart: unless-stopped
EOF
fi

echo -e "${GREEN}[+] Plik docker-compose.yml został zapisany.${NC}"

# ================= KROK 4: URUCHOMIENIE KONTENERÓW =================
echo -e "${YELLOW}[4/4] Pobieranie obrazów i uruchamianie kontenerów...${NC}"
cd "$DOCKER_DIR"
sudo docker compose up -d

echo -e "\n${CYAN}======================================================${NC}"
echo -e "${GREEN}[SUKCES] Pi-hole oraz NAS działają w tle!${NC}"
echo -e "------------------------------------------------------"
echo -e "1. ${CYAN}Panel Pi-hole:${NC}      http://${RPI_IP}:${PIHOLE_PORT}/admin"
echo -e "2. ${CYAN}NAS (Ubuntu/Linux):${NC} smb://${RPI_IP}/${SHARE_NAME} (Login: ${SAMBA_USER})"
echo -e "3. ${CYAN}NAS (Windows):${NC}      \\\\${RPI_IP}\\${SHARE_NAME}"
if [[ "$OPT_FB" =~ ^[TtYy]$ ]]; then
    echo -e "4. ${CYAN}FileBrowser (WWW):${NC}  http://${RPI_IP}:${FB_PORT}"
    echo -e "   *(Hasło startowe dla użytkownika 'admin' sprawdzisz komendą: docker logs filebrowser-nas)*"
fi
echo -e "${CYAN}======================================================${NC}"
