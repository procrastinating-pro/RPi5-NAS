#!/bin/bash
set -e

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

TARGET_USER=${SUDO_USER:-$USER}

echo -e "${CYAN}======================================================${NC}"
echo -e "${CYAN}     AUTOMATYCZNA INSTALACJA DOCKERA (RPi 5 ARM64)    ${NC}"
echo -e "${CYAN}======================================================${NC}"

echo -e "\n${YELLOW}[1/5] Aktualizacja pakietów i instalacja zależności...${NC}"
sudo apt-get update
sudo apt-get install -y ca-certificates curl

echo -e "\n${YELLOW}[2/5] Dodawanie oficjalnego klucza GPG i repozytorium Dockera...${NC}"
sudo install -m 0755 -d /etc/apt/keyrings
sudo curl -fsSL https://download.docker.com/linux/debian/gpg -o /etc/apt/keyrings/docker.asc
sudo chmod a+r /etc/apt/keyrings/docker.asc

echo \
  "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/debian \
  $(. /etc/os-release && echo "$VERSION_CODENAME") stable" | \
  sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

sudo apt-get update

echo -e "\n${YELLOW}[3/5] Instalacja Docker Engine, CLI oraz Docker Compose v2...${NC}"
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

echo -e "\n${YELLOW}[4/5] Konfiguracja rotacji logów (/etc/docker/daemon.json)...${NC}"
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

echo -e "\n${YELLOW}[5/5] Dodawanie użytkownika '$TARGET_USER' do grupy docker...${NC}"
sudo usermod -aG docker "$TARGET_USER"

echo -e "\n${CYAN}======================================================${NC}"
echo -e "${GREEN}[SUKCES] Docker został zainstalowany i skonfigurowany!${NC}"
sudo docker --version
sudo docker compose version
echo -e "${CYAN}======================================================${NC}"
echo -e "Aby używać polecenia 'docker' bez 'sudo' w obecnej sesji, wpisz:"
echo -e "  ${YELLOW}newgrp docker${NC} (lub wyloguj się i zaloguj ponownie przez SSH)."
