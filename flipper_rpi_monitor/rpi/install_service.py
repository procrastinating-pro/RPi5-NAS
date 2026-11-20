#!/usr/bin/env bash
set -euo pipefail

SERVICE_NAME="rpi-flipper-monitor.service"
FLIPPER_MAC="${1:-80:E1:27:23:08:BF}"
SCRIPT_PATH="${2:-$HOME/rpi_sender/rpi_sender.py}"
PYTHON_BIN="$HOME/rpisender/venv/bin/python3"

if [[ ! -f "$SCRIPT_PATH" ]]; then
    echo "Błąd: nie znaleziono pliku $SCRIPT_PATH"
    echo "Użycie: $0 [ADRES_MAC] [ŚCIEŻKA_DO_RPI_SENDER_PY]"
    exit 1
fi

if [[ ! -x "$PYTHON_BIN" ]]; then
    echo "Błąd: nie znaleziono środowiska $PYTHON_BIN"
    exit 1
fi

# Zatrzymanie ewentualnej ręcznej instancji przed startem usługi
pkill -f "rpi_sender.py" 2>/dev/null || true

echo "Tworzenie usługi $SERVICE_NAME (MAC: $FLIPPER_MAC)..."

sudo tee "/etc/systemd/system/$SERVICE_NAME" > /dev/null <<EOF
[Unit]
Description=RPi 5 BLE System Monitor for Flipper Zero
After=bluetooth.target network.target
Wants=bluetooth.target

[Service]
Type=simple
User=$USER
WorkingDirectory=$(dirname "$SCRIPT_PATH")
Environment=PYTHONUNBUFFERED=1
ExecStart=$PYTHON_BIN $SCRIPT_PATH --address $FLIPPER_MAC
Restart=always
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

echo "Aktywacja i uruchamianie usługi..."
sudo systemctl daemon-reload
sudo systemctl enable --now "$SERVICE_NAME"

echo ""
sudo systemctl status "$SERVICE_NAME" --no-pager -l
echo ""
echo "Podgląd logów na żywo: journalctl -u $SERVICE_NAME -f"
