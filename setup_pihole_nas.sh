#!/bin/bash
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

clear
echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}     KONFIGURATOR DOCKER: PI-HOLE + NAS + WATCHTOWER  ${NC}"
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

read -p "6. Lokalne domeny DNS (oddzielone spacją) [nas.home pihole.home rpi.home]: " LOCAL_DOMAINS
LOCAL_DOMAINS=${LOCAL_DOMAINS:-"nas.home pihole.home rpi.home"}

echo -e "\n${YELLOW}[*] Konfiguracja NAS (Samba + FileBrowser):${NC}"
read -p "7. Nazwa udziału sieciowego (widoczna w LAN) [DyskNAS]: " SHARE_NAME
SHARE_NAME=${SHARE_NAME:-DyskNAS}

read -p "8. Login do dysku sieciowego Samba [$ACTUAL_USER]: " SAMBA_USER
SAMBA_USER=${SAMBA_USER:-$ACTUAL_USER}

while true; do
    read -s -p "9. Hasło do dysku sieciowego Samba: " SAMBA_PASS
    echo ""
    if [ -n "$SAMBA_PASS" ]; then break; else echo -e "${RED}   Hasło nie może być puste!${NC}"; fi
done

read -p "10. Zainstalować też panel WWW do plików (FileBrowser)? (T/n): " OPT_FB
OPT_FB=${OPT_FB:-T}
if [[ "$OPT_FB" =~ ^[TtYy]$ ]]; then
    read -p "   -> Port dla FileBrowsera [8081]: " FB_PORT
    FB_PORT=${FB_PORT:-8081}
    read -p "   -> Login administratora FileBrowsera [admin]: " FB_USER
    FB_USER=${FB_USER:-admin}
    while true; do
        read -s -p "   -> Hasło do FileBrowsera (min. 12 znaków) [zostaw puste, aby użyć hasła Samby]: " FB_PASS
        echo ""
        FB_PASS=${FB_PASS:-$SAMBA_PASS}
        if [ ${#FB_PASS} -ge 12 ]; then
            break
        else
            echo -e "${RED}   [!] FileBrowser wymaga hasła o długości minimum 12 znaków! Podaj dłuższe hasło.${NC}"
        fi
    done
fi

echo -e "\n${YELLOW}[*] Konfiguracja automatycznych aktualizacji (Watchtower):${NC}"
read -p "11. Dodać kontener Watchtower (auto-update obrazów i czyszczenie o 04:00)? (T/n): " OPT_WT
OPT_WT=${OPT_WT:-T}

echo -e "\n${CYAN}======================================================${NC}"

# ================= KROK 1: ZWALNIANIE PORTU 53 =================
echo -e "${YELLOW}[1/5] Sprawdzanie czy port 53 (DNS) jest wolny...${NC}"
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
echo -e "${YELLOW}[2/5] Tworzenie struktury katalogów...${NC}"
sudo mkdir -p "$NAS_DIR"
sudo chown -R "$ACTUAL_USER:$ACTUAL_USER" "$(dirname "$NAS_DIR")"
sudo chmod -R 775 "$NAS_DIR"

mkdir -p "$DOCKER_DIR/etc-pihole"
mkdir -p "$DOCKER_DIR/etc-dnsmasq.d"

# Tworzenie wpisów w custom.list (dla kompatybilności z Pi-hole v5) oraz przygotowanie zmiennych dla v6 i extra_hosts
rm -f "$DOCKER_DIR/etc-pihole/custom.list"
EXTRA_HOSTS_YAML=""
FTL_HOSTS_LIST=""

for dom in $LOCAL_DOMAINS; do
    echo "${RPI_IP} ${dom}" >> "$DOCKER_DIR/etc-pihole/custom.list"
    EXTRA_HOSTS_YAML="${EXTRA_HOSTS_YAML}      - \"${dom}:${RPI_IP}\"\n"
    if [ -z "$FTL_HOSTS_LIST" ]; then
        FTL_HOSTS_LIST="${RPI_IP} ${dom}"
    else
        FTL_HOSTS_LIST="${FTL_HOSTS_LIST},${RPI_IP} ${dom}"
    fi
done

if [[ "$OPT_FB" =~ ^[TtYy]$ ]]; then
    mkdir -p "$DOCKER_DIR/filebrowser"
    sudo chown -R "$USER_UID:$USER_GID" "$DOCKER_DIR/filebrowser"
fi
echo -e "${GREEN}[+] Utworzono katalogi w $NAS_DIR oraz $DOCKER_DIR.${NC}"

# ================= KROK 3: GENEROWANIE DOCKER-COMPOSE =================
echo -e "${YELLOW}[3/5] Generowanie pliku docker-compose.yml...${NC}"

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
      FTLCONF_dns_hosts: '${FTL_HOSTS_LIST}'
    extra_hosts:
$(echo -ne "$EXTRA_HOSTS_YAML")
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
      - './filebrowser:/database'
    command: --database /database/filebrowser.db
    restart: unless-stopped
EOF
fi

if [[ "$OPT_WT" =~ ^[TtYy]$ ]]; then
cat >> "$DOCKER_DIR/docker-compose.yml" <<EOF

  watchtower:
    container_name: watchtower
    image: containrrr/watchtower:latest
    environment:
      - TZ=Europe/Warsaw
      - WATCHTOWER_CLEANUP=true
      - WATCHTOWER_INCLUDE_STOPPED=true
      - WATCHTOWER_SCHEDULE=0 0 4 * * *
    volumes:
      - /var/run/docker.sock:/var/run/docker.sock
    restart: unless-stopped
EOF
fi

echo -e "${GREEN}[+] Plik docker-compose.yml został zapisany (z lokalnymi domenami DNS).${NC}"

# ================= KROK 4: INICJALIZACJA BAZY FILEBROWSERA =================
cd "$DOCKER_DIR"

if [[ "$OPT_FB" =~ ^[TtYy]$ ]]; then
    echo -e "${YELLOW}[4/5] Konfiguracja konta '$FB_USER' w bazie FileBrowsera...${NC}"
    sudo docker compose stop filebrowser >/dev/null 2>&1 || true
    sudo rm -f "$DOCKER_DIR/filebrowser/filebrowser.db"

    sudo docker compose run --rm filebrowser config init --database /database/filebrowser.db >/dev/null
    sudo docker compose run --rm filebrowser config set --address 0.0.0.0 --root /srv --database /database/filebrowser.db >/dev/null
    sudo docker compose run --rm filebrowser users add "$FB_USER" "$FB_PASS" --perm.admin --database /database/filebrowser.db >/dev/null
    echo -e "${GREEN}[+] Utworzono konto '$FB_USER' z Twoim własnym hasłem.${NC}"
else
    echo -e "${YELLOW}[4/5] Pominięto instalację FileBrowsera.${NC}"
fi

# ================= KROK 5: URUCHOMIENIE KONTENERÓW =================
echo -e "${YELLOW}[5/5] Uruchamianie kontenerów w tle...${NC}"
sudo docker compose up -d

FIRST_DOM=$(echo "$LOCAL_DOMAINS" | awk '{print $1}')
SECOND_DOM=$(echo "$LOCAL_DOMAINS" | awk '{print $2}')
FIRST_DOM=${FIRST_DOM:-$RPI_IP}
SECOND_DOM=${SECOND_DOM:-$FIRST_DOM}

echo -e "\n${CYAN}======================================================${NC}"
echo -e "${GREEN}[SUKCES] Pi-hole oraz NAS działają w tle!${NC}"
echo -e "------------------------------------------------------"
echo -e "1. ${CYAN}Panel Pi-hole:${NC}      http://${RPI_IP}:${PIHOLE_PORT}/admin (lub http://${SECOND_DOM}:${PIHOLE_PORT}/admin)"
echo -e "2. ${CYAN}NAS (Ubuntu/Linux):${NC} smb://${RPI_IP}/${SHARE_NAME} (lub smb://${FIRST_DOM}/${SHARE_NAME})"
echo -e "3. ${CYAN}NAS (Windows):${NC}      \\\\${RPI_IP}\\${SHARE_NAME} (lub \\\\${FIRST_DOM}\\${SHARE_NAME})"
if [[ "$OPT_FB" =~ ^[TtYy]$ ]]; then
    echo -e "4. ${CYAN}FileBrowser (WWW):${NC}  http://${RPI_IP}:${FB_PORT} (lub http://${FIRST_DOM}:${FB_PORT})"
fi
if [[ "$OPT_WT" =~ ^[TtYy]$ ]]; then
    echo -e "5. ${CYAN}Watchtower:${NC}         Aktywny (Auto-update codziennie o 04:00)"
fi
echo -e "6. ${CYAN}Lokalne domeny DNS:${NC} ${LOCAL_DOMAINS} -> ${RPI_IP}"
echo -e "${CYAN}======================================================${NC}"
