#!/bin/bash
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

TARGET_USER=${SUDO_USER:-$USER}

echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}  INSTALACJA DOCKERA + AUTO-MAINTENANCE (RPi 5 ARM64) ${NC}"
echo -e "${CYAN}======================================================${NC}"

echo -e "\n${YELLOW}[1/6] Pełna aktualizacja systemu, czyszczenie i zależności...${NC}"
export DEBIAN_FRONTEND=noninteractive
sudo apt-get update -y
sudo apt-get full-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold"
sudo apt-get install -y ca-certificates curl
sudo apt-get autoremove -y
sudo apt-get autoclean -y

echo -e "\n${YELLOW}[2/6] Konfiguracja harmonogramu Auto-Update/Clean (Cron + NVMe TRIM)...${NC}"
sudo bash -c 'cat > /etc/cron.d/auto-system-maintenance' << 'EOF'
SHELL=/bin/bash
PATH=/usr/local/sbin:/usr/local/bin:/sbin:/bin:/usr/sbin:/usr/bin

# Codziennie o 03:30: update, upgrade, autoremove, autoclean oraz czyszczenie starych obrazów Dockera (całość logowana do /var/log/auto-update.log)
30 3 * * * root (echo "=== AUTO-UPDATE START: $(date) ===" && DEBIAN_FRONTEND=noninteractive apt-get update -y && DEBIAN_FRONTEND=noninteractive apt-get full-upgrade -y -o Dpkg::Options::="--force-confdef" -o Dpkg::Options::="--force-confold" && apt-get autoremove -y && apt-get autoclean -y && docker image prune -af && echo "=== AUTO-UPDATE KONIEC: $(date) ===") >> /var/log/auto-update.log 2>&1
EOF
sudo chmod 644 /etc/cron.d/auto-system-maintenance

# Aktywacja FSTRIM dla dysku NVMe
sudo systemctl enable fstrim.timer
sudo systemctl start fstrim.timer
echo -e "${GREEN}[+] Skonfigurowano automatyczne aktualizacje (Codziennie o 03:30) oraz NVMe TRIM.${NC}"

# Sprawdzenie czy Docker jest już zainstalowany
if command -v docker &> /dev/null; then
    echo -e "\n${GREEN}[✓] Wykryto zainstalowanego Dockera ($(docker --version)).${NC}"
    echo -e "${YELLOW}[3/6] Pomijanie dodawania klucza GPG i repozytorium...${NC}"
    echo -e "${YELLOW}[4/6] Pomijanie instalacji pakietów Docker Engine...${NC}"
else
    echo -e "\n${YELLOW}[3/6] Dodawanie oficjalnego klucza GPG i repozytorium Dockera...${NC}"
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    echo \
      "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
      $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
      sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

    sudo apt-get update

    echo -e "\n${YELLOW}[4/6] Instalacja Docker Engine, CLI oraz Docker Compose v2...${NC}"
    sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin
fi

echo -e "\n${YELLOW}[5/6] Konfiguracja rotacji logów (/etc/docker/daemon.json)...${NC}"
sudo mkdir -p /etc/docker
sudo bash -c 'cat > /etc/docker/daemon.json' <<EOF
{
  "log-driver": "json-file",
  "log-opts": {
    "max-size": "10m",
    "max-file": "3"
  }
}
EOF

sudo systemctl enable docker
sudo systemctl restart docker

echo -e "\n${YELLOW}[6/6] Sprawdzanie przynależności użytkownika '$TARGET_USER' do grupy docker...${NC}"
if id -nG "$TARGET_USER" | grep -qw "docker"; then
    echo -e "${GREEN}[✓] Użytkownik '$TARGET_USER' należy już do grupy docker.${NC}"
else
    sudo usermod -aG docker "$TARGET_USER"
    echo -e "${GREEN}[+] Dodano użytkownika '$TARGET_USER' do grupy docker.${NC}"
fi

echo -e "\n${CYAN}======================================================${NC}"
echo -e "${GREEN}[SUKCES] Docker oraz Auto-Maintenance skonfigurowane!${NC}"
sudo docker --version
sudo docker compose version
echo -e "${CYAN}======================================================${NC}"
echo -e "Aby używać polecenia 'docker' bez 'sudo' w obecnej sesji, wpisz:"
echo -e "  ${YELLOW}newgrp docker${NC} (lub wyloguj się i zaloguj ponownie przez SSH)."
