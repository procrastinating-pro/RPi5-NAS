#!/usr/bin/env python3
import argparse
import asyncio
import glob
import os
import sys
import psutil
from bleak import BleakClient, BleakScanner

FLIPPER_RX_UUID = "19ed82ae-ed21-4c9d-4145-228e62fe0000"
DEVICE_PREFIX = "rpimon"
SEND_INTERVAL = 1.5
CHUNK_SIZE = 20


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


async def scan_all() -> None:
    print("Skanuje urzadzenia BLE przez 6 sekund...")
    found = await BleakScanner.discover(timeout=6.0, return_adv=True)
    if not found:
        print("Nie wykryto zadnych urzadzen BLE (sprawdz czy Bluetooth na RPi jest wlaczony).")
        return
    for addr, (dev, adv) in found.items():
        name = dev.name or adv.local_name or "(brak nazwy)"
        uuids = ", ".join(adv.service_uuids) if adv.service_uuids else "-"
        print(f"  {addr}  |  {name}  |  UUIDs: {uuids}")


async def find_flipper(target_addr: str | None) -> str | None:
    if target_addr:
        return target_addr

    found = await BleakScanner.discover(timeout=6.0, return_adv=True)
    for addr, (dev, adv) in found.items():
        name = (dev.name or adv.local_name or "").lower()
        if DEVICE_PREFIX in name:
            print(f"Znaleziono Flippera: {dev.name or adv.local_name} ({addr})")
            return addr
    return None


async def send_chunked(client: BleakClient, payload: bytes) -> None:
    print("TX:", payload.decode("ascii").strip())
    for i in range(0, len(payload), CHUNK_SIZE):
        await client.write_gatt_char(
            FLIPPER_RX_UUID,
            payload[i : i + CHUNK_SIZE],
            response=True,
        )


async def run_loop(target_addr: str | None) -> None:
    psutil.cpu_percent(interval=None)

    while True:
        try:
            addr = await find_flipper(target_addr)
            if not addr:
                print("Nie znaleziono 'RPiMon' w eterze (sprawdz status ADV na Flipperze). Ponawiam za 3s...")
                await asyncio.sleep(3)
                continue

            print(f"Laczenie z Flipperem ({addr})...")
            async with BleakClient(addr, timeout=15.0) as client:
                print("Polaczono! Wysylam statystyki.")
                while client.is_connected:
                    payload = build_payload()
                    await send_chunked(client, payload)
                    await asyncio.sleep(SEND_INTERVAL)

        except Exception as e:
            msg = str(e)
            print(f"Rozlaczono / blad BLE: {msg}")
            if "Authentication" in msg or "Encryption" in msg or "NotPermitted" in msg:
                print("Wskazowka: sparuj Flippera jednorazowo przez bluetoothctl (pair + trust).")
            await asyncio.sleep(3)


def main() -> None:
    parser = argparse.ArgumentParser(description="Wysyla statystyki RPi 5 do Flipper Zero przez BLE")
    parser.add_argument("--address", help="Adres MAC BLE Flippera (opcjonalnie, przyspiesza laczenie)")
    parser.add_argument("--scan", action="store_true", help="Wypisz wszystkie widoczne urzadzenia BLE i zakoncz")
    args = parser.parse_args()

    try:
        if args.scan:
            asyncio.run(scan_all())
        else:
            asyncio.run(run_loop(args.address))
    except KeyboardInterrupt:
        print("\nZatrzymano.")
        sys.exit(0)


if __name__ == "__main__":
    main()
