# 🍓 RPi5-PARRY (Raspberry Pi 5 Headless + Docker HomeLab + NAS + Auto-Maintenance)

Zestaw automatycznych i interaktywnych skryptów Bash pozwalających na szybkie przygotowanie czystego obrazu **Raspberry Pi OS (64-bit)** pod Raspberry Pi 5 (wraz z obsługą **NVMe HAT+**), bezobsługową aktualizację systemu, optymalizację krzywej chłodzenia (**Active Cooler + NVMe Heatsink Guard**), instalację **Dockera** oraz modułowe wdrożenie domowego serwera **HomeLab & NAS** (**Pi-hole**, **Samba**, **FileBrowser**, **Twingate**, **Vaultwarden** oraz **Watchtower**).

## 🛠️ Sprzęt użyty w projekcie (Hardware)

Projekt został zaprojektowany i zoptymalizowany pod kątem następującej konfiguracji sprzętowej:

* **Płyta główna:** Raspberry Pi 5
* **Adapter PCIe:** Raspberry Pi M.2 HAT+
* **Dysk systemowy i NAS:** Raspberry Pi SSD (NVMe PCIe Gen 3) + dodatkowe radiatory chłodzące na dysku
* **Chłodzenie procesora i obudowy:** Raspberry Pi Active Cooler (sterowany hybrydowo na podstawie temperatury CPU oraz czujnika S.M.A.R.T. dysku NVMe)
* **Zasilanie:** Oficjalny zasilacz Raspberry Pi 27W USB-C PD (5.1V / 5A)
* **Obudowa:** Dedykowana, podwyższona obudowa drukowana w 3D (projekt parametryczny w OpenSCAD mieszczący M.2 HAT+, wysokie radiatory na NVMe, uniesioną nakładkę z logo *Badge* oraz wciskane nóżki z TPU)

## 📂 Zawartość repozytorium

| Plik / Skrypt | Gdzie uruchamiać? | Opis działania | 
| ----- | ----- | ----- | 
| **`rpi5_configurator.sh`** | 💻 Na komputerze (np. Ubuntu) z podłączonym nośnikiem (SD/NVMe) | Konfiguruje czysty obraz przed pierwszym uruchomieniem: włącza SSH, tworzy użytkownika, wgrywa klucz SSH, ustawia statyczny IP (NetworkManager) i odblokowuje PCIe Gen 3 dla NVMe HAT+. | 
| **`install_docker.sh`** | 🍓 Na Raspberry Pi 5 (przez SSH) | Aktualizuje system, włącza `fstrim.timer` dla NVMe, ustawia codzienny Auto-Update/Clean w Cronie (03:30), instaluje **Docker Engine** oraz **Docker Compose v2** (z pominięciem, jeśli jest już zainstalowany) i konfiguruje rotację logów. | 
| **`setup_homelab.sh`** | 🍓 Na Raspberry Pi 5 (przez SSH) | Interaktywny kreator kontenerów (Czysty Bash `[T/n]`): pozwala wybrać i skonfigurować dowolną kombinację 5 usług + Watchtower: **Pi-hole**, **Samba (SMB)**, **FileBrowser**, **Twingate Connector**, **Vaultwarden** oraz **Watchtower** (auto-update o 04:00). | 
| **`uninstall_homelab.sh`** | 🍓 Na Raspberry Pi 5 (przez SSH) | Bezpieczny deinstalator środowiska HomeLab (z podwójnym potwierdzeniem): zatrzymuje i usuwa kontenery, czyści obrazy i sieci Dockera, kasuje katalog `~/docker/homelab`, przywraca domyślny stan `systemd-resolved` (port 53) oraz opcjonalnie usuwa dane z dysku NAS (`/srv/nas/pliki`). | 
| **`setup_cooler.sh`** | 🍓 Na Raspberry Pi 5 (przez SSH) | Konfigurator chłodzenia **Active Cooler**: ustawia krzywą wentylatora w `config.txt`, instaluje usługę `nvme-fan-guard` (przyspieszającą wentylator, gdy dysk NVMe z radiatorem nagrzewa się podczas transferów NAS) oraz dodaje polecenie diagnostyczne `rpi-temp`. | 
| **`diagnose_and_fix_fan.sh`** | 🍓 Na Raspberry Pi 5 (przez SSH) | Narzędzie diagnostyczno-naprawcze dla **Active Coolera**: skanuje partycje `bootfs` oraz `rootfs` (w tym konflikty SD vs NVMe), czyści błędne reguły `udev`/`systemd`, przywraca czystą konfigurację w `config.txt` i wykonuje sprzętowy test linii PWM (`0` vs `255`). | 
| **`rpi5_nvme_case.scad`** | 💻 Na komputerze (OpenSCAD) | Parametryczny model 3D podwyższonej obudowy z miejscem na M.2 HAT+, radiatory NVMe, przedłużoną komorą na taśmę PCIe, uniesionym dachem z logo (*Badge*) oraz nóżkami dystansowymi pod druk z elastycznego TPU. | 

## 🚀 Krok 1: Przygotowanie nośnika przed pierwszym startem (`rpi5_configurator.sh`)

Zamiast korzystać z wbudowanego kreatora w Raspberry Pi Imagerze (który bywa zawodny), wgraj czysty obraz **Raspberry Pi OS Lite (64-bit)** na kartę SD lub dysk NVMe (wybierając **NO** przy pytaniu o *OS customisation*).

1. Wyjmij i ponownie podłącz nośnik do komputera, aby system zamontował partycje **`bootfs`** oraz **`rootfs`**.

2. Uruchom interaktywny konfigurator bezpośrednio z terminala:

```bash
bash <(curl -fsSL [https://raw.githubusercontent.com/procrastinating-pro/RPi5-PARRY/refs/heads/main/rpi5_configurator.sh](https://raw.githubusercontent.com/procrastinating-pro/RPi5-PARRY/refs/heads/main/rpi5_configurator.sh))
```

**Co możesz skonfigurować w kreatorze:**

* Aktywację serwera SSH (`bootfs/ssh`).
* Utworzenie nowego konta użytkownika i zaszyfrowanego hasła (`userconf.txt`).
* Automatyczne skopiowanie Twojego klucza publicznego (`~/.ssh/id_ed25519.pub` lub `id_rsa.pub`) dla logowania bez hasła.
* Ustawienie statycznego adresu IP dla portu LAN (`eth0`) – domyślnie `192.168.1.250/24`.
* Włączenie obsługi **Raspberry Pi NVMe HAT+** (`dtparam=pciex1`) oraz wymuszenie szybszego trybu **PCIe Gen 3** (`dtparam=pciex1_gen=3`).
* Zmianę nazwy hosta (`hostname`).

3. Po zakończeniu pracy skryptu odmontuj partycje, przełóż nośnik do Raspberry Pi 5, podłącz kabel LAN oraz zasilanie:

```bash
sudo umount /media/$USER/bootfs /media/$USER/rootfs
```

4. Po około 60–90 sekundach połącz się z płytką przez SSH:

```bash
ssh twoj_login@192.168.1.250
```

*(Jeśli musisz zlokalizować płytkę w sieci lokalnej, użyj szybkiego skanowania Nmap dla portu SSH):*

```bash
nmap -p 22 -T4 -n 192.168.1.0/24 --open
```

## 🐳 Krok 2: Instalacja Dockera i Auto-Maintenance (`install_docker.sh`)

Po zalogowaniu się na Raspberry Pi 5 przez SSH zainstaluj środowisko Docker, Docker Compose v2 oraz harmonogram automatycznej konserwacji systemu jedną komendą:

```bash
curl -fsSL [https://raw.githubusercontent.com/procrastinating-pro/RPi5-PARRY/refs/heads/main/install_docker.sh](https://raw.githubusercontent.com/procrastinating-pro/RPi5-PARRY/refs/heads/main/install_docker.sh) | bash && newgrp docker
```

**Co robi skrypt:**

* Wykonuje pełną, bezobsługową aktualizację systemu (`full-upgrade`, `autoremove`, `autoclean`).
* Tworzy zadanie w `/etc/cron.d/auto-system-maintenance`, które **codziennie o 03:30 w nocy** aktualizuje pakiety systemowe, czyści zbędne zależności i usuwa nieużywane obrazy Dockera (`docker image prune -af`), zapisując pełny przebieg ze znacznikami czasu do `/var/log/auto-update.log`.
* Aktywuje usługę `fstrim.timer` dbającą o kondycję i wydajność dysku NVMe.
* Sprawdza, czy Docker jest już zainstalowany – jeśli nie, dodaje oficjalny klucz GPG i repozytorium Dockera dla architektury `arm64`, po czym instaluje pakiety `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` oraz `docker-compose-plugin`.
* Konfiguruje plik `/etc/docker/daemon.json` z limitem rozmiaru logów (`max-size: 10m`, `max-file: 3`), co chroni dysk przed zapełnieniem.
* Dodaje bieżącego użytkownika do grupy `docker` (jeśli jeszcze do niej nie należy).

*Weryfikacja poprawności instalacji:*

```bash
docker run --rm hello-world
```

## 🛡️ Krok 3: Instalacja usług HomeLab & NAS (`setup_homelab.sh`)

Aby uruchomić wybrane usługi domowego serwera (z możliwością wyboru `[T/n]` dla każdego kontenera), wykonaj na Raspberry Pi 5:

```bash
bash <(curl -fsSL [https://raw.githubusercontent.com/procrastinating-pro/RPi5-PARRY/refs/heads/main/setup_homelab.sh](https://raw.githubusercontent.com/procrastinating-pro/RPi5-PARRY/refs/heads/main/setup_homelab.sh))
```

*(Uwaga: Użycie składni `bash <(curl ...)` jest wymagane, ponieważ skrypt działa interaktywnie i pobiera od Ciebie wybór kontenerów, hasła, tokeny oraz ścieżki z klawiatury).*

**Dostępne kontenery do wyboru w kreatorze `[1/5 – 5/5 + Extra]`:**

1. **Pi-hole:** Blokowanie reklam w całej sieci LAN oraz lokalny serwer DNS (automatycznie zwalnia port `53` z `systemd-resolved` i konfiguruje lokalne domeny `.home`).
2. **Samba NAS:** Dysk sieciowy SMB/CIFS widoczny w systemach Windows, Linux oraz macOS.
3. **FileBrowser:** Nowoczesny menedżer plików NAS przez przeglądarkę WWW (automatycznie inicjalizuje bazę i tworzy konto administratora z hasłem o dł. min. 12 znaków).
4. **Twingate Connector:** Bezpieczny, zdalny dostęp Zero-Trust spoza domu w trybie `network_mode: host` (bez konieczności przekierowywania portów na routerze i z pełną obsługą lokalnych domen `.home`).
5. **Vaultwarden:** Lekki, lokalny serwer menedżera haseł kompatybilny z oficjalnymi aplikacjami Bitwarden.
* **\[Extra\] Watchtower:** Automatyczna aktualizacja wszystkich uruchomionych kontenerów i czyszczenie starych obrazów codziennie o 04:00 rano (z wymuszonym `DOCKER_API_VERSION=1.44`).

### ⚠️ Ważne: Konfiguracja DNS na routerze

Aby blokowanie reklam przez **Pi-hole** oraz lokalne domeny (`.home`) działały automatycznie na wszystkich urządzeniach w domu (telefonach, telewizorach, komputerach):

1. Zaloguj się do panelu administracyjnego swojego routera.
2. Przejdź do ustawień sieci lokalnej (**LAN / DHCP Server**).
3. Jako **Podstawowy serwer DNS (Primary DNS)** wpisz statyczny adres IP swojego Raspberry Pi (domyślnie `192.168.1.250`).
4. Pole **Zapasowy serwer DNS (Secondary DNS)** pozostaw **puste** (jeśli wpiszesz tam np. `8.8.8.8` lub `1.1.1.1`, część zapytań ominie Pi-hole, reklamy będą się wyświetlać, a lokalne domeny `nas.home` nie będą działać).
5. Zapisz ustawienia i zrestartuj połączenie Wi-Fi/LAN na urządzeniach, aby pobrały nową konfigurację z routera.

### 🌍 Lokalne domeny DNS (Konfiguracja w `docker-compose.yml`)

Skrypt `setup_homelab.sh` automatycznie pyta o lokalne domeny podczas instalacji Pi-hole (domyślnie: `nas.home pihole.home rpi.home vault.home`) i dopisuje je bezpośrednio do pliku `~/docker/homelab/docker-compose.yml`.

Jeśli w przyszłości zechcesz dodać kolejne własne domeny, wystarczy wyedytować plik `~/docker/homelab/docker-compose.yml` (sekcja `extra_hosts` oraz `FTLCONF_dns_hosts` w usłudze `pihole`) i przeładować kontenery komendą `docker compose up -d`.

*(Wskazówka: Używaj końcówek `.home`, `.lan` lub `.internal`. Unikaj końcówki `.local`, która jest zarezerwowana dla protokołu mDNS/Avahi i może powodować opóźnienia).*

## ❄️ Krok 4: Optymalizacja chłodzenia Active Cooler i NVMe (`setup_cooler.sh`)

W zamkniętej obudowie z nakładką M.2 HAT+ i radiatorami na dysku SSD Gen 3 domyślna krzywa wentylatora (start od 50°C CPU) jest zbyt pasywna. Aby zapewnić optymalny obieg powietrza wokół radiatora NVMe oraz cichą pracę, uruchom konfigurator chłodzenia:

```bash
bash <(curl -fsSL [https://raw.githubusercontent.com/procrastinating-pro/RPi5-PARRY/refs/heads/main/setup_cooler.sh](https://raw.githubusercontent.com/procrastinating-pro/RPi5-PARRY/refs/heads/main/setup_cooler.sh))
```

**Co robi skrypt:**

* Ustawia w `/boot/firmware/config.txt` zoptymalizowaną krzywą dla **Raspberry Pi Active Cooler**.
* Instaluje pakiet `nvme-cli` oraz usługę systemową `nvme-fan-guard.service`, która odczytuje temperaturę dysku SSD i automatycznie reguluje obroty wentylatora podczas dużych transferów plików przez NAS (nawet gdy sam procesor RPi 5 jest chłodny).
* Tworzy polecenie diagnostyczne `rpi-temp`, pozwalające w dowolnej chwili sprawdzić temperatury oraz obroty wentylatora.

## 🌐 Dostęp do usług po instalacji

Przy założeniu domyślnego adresu IP `192.168.1.250` oraz domyślnych lokalnych domen DNS:

| Usługa | Adres w sieci LAN / Domena `.home` | Domyślne logowanie / Uwagi | 
| ----- | ----- | ----- | 
| **Pi-hole** | `http://pihole.home:8080/admin` (`http://192.168.1.250:8080/admin`) | Hasło podane w konfiguratorze Pi-hole. | 
| **Samba NAS (SMB)** | Linux: `smb://nas.home/DyskNAS` / Windows: `\\nas.home\DyskNAS` | Login i hasło Samby podane w konfiguratorze. | 
| **FileBrowser** | `http://nas.home:8081` (`http://192.168.1.250:8081`) | Login: `admin` + własne hasło (min. 12 znaków). | 
| **Vaultwarden** | `http://vault.home:8222` (`http://192.168.1.250:8222`) | Utwórz konto w przeglądarce (wymaga HTTPS/Twingate dla WebCrypto). | 
| **Twingate** | Działa w tle (`network_mode: host`) | Logi połączenia: `sudo docker logs twingate-connector`. | 
| **Watchtower** | Działa w tle (harmonogram Cron `04:00`) | Logi aktualizacji: `sudo docker logs watchtower`. | 

## 🗑️ Całkowita deinstalacja i czyszczenie środowiska (`uninstall_homelab.sh`)

Jeśli chcesz zresetować całe środowisko Docker HomeLab, usunąć wszystkie kontenery oraz ich konfigurację i zacząć od czystego stanu, uruchom skrypt deinstalacyjny:

```bash
bash <(curl -fsSL [https://raw.githubusercontent.com/procrastinating-pro/RPi5-PARRY/refs/heads/main/uninstall_homelab.sh](https://raw.githubusercontent.com/procrastinating-pro/RPi5-PARRY/refs/heads/main/uninstall_homelab.sh))
```

**Zabezpieczenia i etapy działania deinstalatora:**

1. **Potwierdzenie usunięcia kontenerów (`TAK`):** Skrypt zatrzymuje i usuwa wszystkie kontenery (`docker compose down -v`), czyści nieużywane sieci oraz pobrane obrazy (`docker image prune -a -f`), kasuje katalog konfiguracyjny `~/docker/homelab` i przywraca domyślne ustawienia `systemd-resolved` dla portu `53`.
2. **Ochrona danych na dysku NAS (`USUN_DANE`):** Twoje prywatne pliki i dane w `/srv/nas/pliki` są domyślnie **chronione**. Zostaną usunięte wyłącznie wtedy, gdy w drugim kroku jawnie wpiszesz z klawiatury frazę `USUN_DANE`.

## 🛠️ Przydatne komendy diagnostyczne

* **Sprawdzenie temperatury CPU, dysku NVMe oraz obrotów Active Coolera:**

```bash
rpi-temp
# lub podgląd na żywo co 2 sekundy:
watch -n 2 rpi-temp
```

* **Pełna diagnostyka i reset konfiguracji wentylatora (w przypadku pracy na 100% obrotów):**
  Jeśli wentylator nie reaguje na zmiany temperatury, uruchom skrypt diagnostyczny, który przeskanuje partycje `bootfs` i `rootfs`, usunie konflikty i przetestuje sprzętowo linię PWM (`PWM=0` vs `PWM=255`):

```bash
sudo bash <(curl -fsSL [https://raw.githubusercontent.com/procrastinating-pro/RPi5-PARRY/refs/heads/main/diagnose_and_fix_fan.sh](https://raw.githubusercontent.com/procrastinating-pro/RPi5-PARRY/refs/heads/main/diagnose_and_fix_fan.sh))
```

* **Sprawdzenie czy nocny Auto-Update systemu (03:30) został przeprowadzony:**

```bash
# 1. Podgląd pełnego logu z nocnej aktualizacji (update, full-upgrade, autoremove, autoclean, docker prune):
tail -n 50 /var/log/auto-update.log

# 2. Sprawdzenie w logach systemowych (journalctl), czy zadanie Cron wystartowało punktualnie o 03:30:
sudo journalctl --since "03:29:00" --until "03:45:00" | grep -iE "cron|apt|upgrade|autoremove|autoclean"

# 3. Historia faktycznie zaktualizowanych lub usuniętych pakietów APT:
tail -n 30 /var/log/apt/history.log
```

* **Sprawdzenie czy aktualizacja kontenerów Docker (Watchtower o 04:00) została przeprowadzona:**

```bash
# 1. Logi działania kontenera Watchtower:
docker logs watchtower

# 2. Sprawdzenie dokładnej daty utworzenia/aktualizacji poszczególnych kontenerów:
docker inspect --format='{{.Name}} -> Utworzony: {{.Created}}' \$(docker ps -a -q)

# 3. Ręczne wymuszenie natychmiastowego sprawdzenia i aktualizacji wszystkich kontenerów (test jednorazowy):
sudo docker run --rm -e DOCKER_API_VERSION=1.44 -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --run-once
```

* **Sprawdzenie statusu uruchomionych kontenerów:**

```bash
docker ps
```

* **Podgląd logów poszczególnych kontenerów:**

```bash
docker logs pihole
docker logs samba-nas
docker logs filebrowser-nas
docker logs vaultwarden
docker logs twingate-connector
```

* **Restart lub zatrzymanie wszystkich usług:**

```bash
cd ~/docker/homelab
docker compose restart
# lub zatrzymanie:
docker compose down
```

* **Ręczna zmiana hasła do FileBrowsera z poziomu terminala:**

```bash
cd ~/docker/homelab
docker compose stop filebrowser
docker compose run --rm filebrowser users update admin --password "TwojeNoweHaslo123" --database /database/filebrowser.db
docker compose start filebrowser
```

## 📄 Licencja

Projekt jest udostępniany na warunkach licencji **MIT**. Szczegółowe informacje znajdują się w pliku [LICENSE.md](LICENSE.md).
