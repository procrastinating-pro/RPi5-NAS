#!/usr/bin/env python3
import argparse
import asyncio
import glob
import os
import sys
import psutil
from bleak import BleakClient, BleakScanner

FLIPPER_RX_UUID = "19ed82ae-ed21-4c9d-4145-228e62fe0000"
DEVICE_PREFIX = "RPiMon"
SEND_INTERVAL = 1.5


def read_cpu_temp_x10() -> int:
    try:
        with open("/sys/class/thermal/thermal_zone0/temp", "r") as f:
            return int(f.read().strip()) // 100
    except OSError:
        return 0


def read_nvme_temp_x10() -> int:
    for name_path in glob.glob("/sys/class/hwmon/hwmon*/name"):
        try:
            with open(name_path, "r") as f:
                if f.read().strip().lower().startswith("nvme"):
                    temp_path = os.path.join(os.path.dirname(name_path), "temp1_input")
                    with open(temp_path, "r") as tf:
                        return int(tf.read().strip()) // 100
        except OSError:
            continue
    return 0


def read_uptime_min() -> int:
    try:
        with open("/proc/uptime", "r") as f:
            return int(float(f.read().split()[0]) // 60)
    except OSError:
        return 0


def build_payload() -> bytes:
    cpu_pct = int(round(psutil.cpu_percent(interval=None)))
    cpu_temp = read_cpu_temp_x10()
    mem = psutil.virtual_memory()
    ram_pct = int(round(mem.percent))
    ram_used_mb = int(mem.used // (1024 * 1024))
    ram_total_mb = int(mem.total // (1024 * 1024))
    disk_pct = int(round(psutil.disk_usage("/").percent))
    disk_temp = read_nvme_temp_x10()
    load_x100 = int(round(os.getloadavg()[0] * 100))
    uptime_min = read_uptime_min()

    line = (
        f"{cpu_pct},{cpu_temp},{ram_pct},{ram_used_mb},{ram_total_mb},"
        f"{disk_pct},{disk_temp},{load_x100},{uptime_min}\n"
    )
    return line.encode("ascii")


async def find_flipper(target_addr: str | None) -> str | None:
    if target_addr:
        return target_addr

    devices = await BleakScanner.discover(timeout=5.0)
    for d in devices:
        if d.name and d.name.startswith(DEVICE_PREFIX):
            return d.address
    return None


async def run_loop(target_addr: str | None) -> None:
    psutil.cpu_percent(interval=None)  # pierwsze wywolanie kalibrujace

    while True:
        try:
            addr = await find_flipper(target_addr)
            if not addr:
                print(f"Nie znaleziono '{DEVICE_PREFIX}', ponawiam za 3s...")
                await asyncio.sleep(3)
                continue

            print(f"Laczenie z Flipperem ({addr})...")
            async with BleakClient(addr, timeout=10.0) as client:
                print("Polaczono! Wysylam statystyki.")
                while client.is_connected:
                    payload = build_payload()
                    await client.write_gatt_char(FLIPPER_RX_UUID, payload, response=False)
                    await asyncio.sleep(SEND_INTERVAL)

        except Exception as e:
            print(f"Rozlaczono / blad BLE: {e}. Ponawiam za 3s...")
            await asyncio.sleep(3)


def main() -> None:
    parser = argparse.ArgumentParser(description="Wysyla statystyki RPi 5 do Flipper Zero przez BLE")
    parser.add_argument("--address", help="Adres MAC BLE Flippera (opcjonalnie, przyspiesza laczenie)")
    args = parser.parse_args()

    try:
        asyncio.run(run_loop(args.address))
    except KeyboardInterrupt:
        print("\nZatrzymano.")
        sys.exit(0)


if __name__ == "__main__":
    main()
