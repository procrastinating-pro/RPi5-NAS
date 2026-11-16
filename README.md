# 🍓 Raspbian-Configurator (Raspberry Pi 5 Headless + Docker + Pi-hole + NAS + Auto-Maintenance)

Zestaw automatycznych i interaktywnych skryptów Bash pozwalających na szybkie przygotowanie czystego obrazu **Raspberry Pi OS (64-bit)** pod Raspberry Pi 5 (wraz z obsługą **NVMe HAT+**), bezobsługową aktualizację systemu, optymalizację krzywej chłodzenia (**Active Cooler + NVMe Heatsink Guard**), instalację **Dockera** oraz wdrożenie domowego serwera **Pi-hole**, **NAS (Samba + FileBrowser)** i **Watchtower**.

## 🛠️ Sprzęt użyty w projekcie (Hardware)

Projekt został zaprojektowany i zoptymalizowany pod kątem następującej konfiguracji sprzętowej:

* **Płyta główna:** Raspberry Pi 5

* **Adapter PCIe:** Raspberry Pi M.2 HAT+

* **Dysk systemowy i NAS:** Raspberry Pi SSD (NVMe PCIe Gen 3) + dodatkowe radiatory chłodzące na dysku

* **Chłodzenie procesora i obudowy:** Raspberry Pi Active Cooler (sterowany hybrydowo na podstawie temperatury CPU oraz czujnika S.M.A.R.T. dysku NVMe)

* **Zasilanie:** Oficjalny zasilacz Raspberry Pi 27W USB-C PD (5.1V / 5A)

* **Obudowa:** Dedykowana, podwyższona obudowa drukowana w 3D (projekt parametryczny w OpenSCAD mieszczący M.2 HAT+ wraz z wysokimi radiatorami na NVMe)

## 📂 Zawartość repozytorium

| Plik / Skrypt | Gdzie uruchamiać? | Opis działania | 
| ----- | ----- | ----- | 
| **`rpi5_configurator.sh`** | 💻 Na komputerze (np. Ubuntu) z podłączonym nośnikiem (SD/NVMe) | Konfiguruje czysty obraz przed pierwszym uruchomieniem: włącza SSH, tworzy użytkownika, wgrywa klucz SSH, ustawia statyczny IP (NetworkManager) i odblokowuje PCIe Gen 3 dla NVMe HAT+. | 
| **`install_docker.sh`** | 🍓 Na Raspberry Pi 5 (przez SSH) | Aktualizuje system, włącza `fstrim.timer` dla NVMe, ustawia codzienny Auto-Update/Clean w Cronie (03:30), instaluje **Docker Engine** oraz **Docker Compose v2** (z pominięciem, jeśli jest już zainstalowany) i konfiguruje rotację logów. | 
| **`setup_pihole_nas.sh`** | 🍓 Na Raspberry Pi 5 (przez SSH) | Interaktywny instalator kontenerów: zwalnia port 53 (`systemd-resolved`), tworzy strukturę katalogów, konfiguruje **lokalne domeny DNS** i uruchamia **Pi-hole**, serwer **Samba (SMB)**, panel WWW **FileBrowser** oraz **Watchtower** (auto-update kontenerów o 04:00). | 
| **`setup_cooler.sh`** | 🍓 Na Raspberry Pi 5 (przez SSH) | Konfigurator chłodzenia **Active Cooler**: ustawia krzywą wentylatora w `config.txt`, instaluje usługę `nvme-fan-guard` (przyspieszającą wentylator, gdy dysk NVMe z radiatorem nagrzewa się podczas transferów NAS) oraz dodaje polecenie diagnostyczne `rpi-temp`. | 
| **`diagnose_and_fix_fan.sh`** | 🍓 Na Raspberry Pi 5 (przez SSH) | Narzędzie diagnostyczno-naprawcze dla **Active Coolera**: skanuje partycje `bootfs` oraz `rootfs` (w tym konflikty SD vs NVMe), czyści błędne reguły `udev`/`systemd`, przywraca czystą konfigurację w `config.txt` i wykonuje sprzętowy test linii PWM (`0` vs `255`). | 
| **`rpi5_nvme_case.scad`** | 💻 Na komputerze (OpenSCAD) | Parametryczny model 3D podwyższonej obudowy z miejscem na M.2 HAT+, radiatory NVMe, wyprowadzeniem portów i grawerowanym logo na górnej pokrywie. | 

## 🚀 Krok 1: Przygotowanie nośnika przed pierwszym startem (`rpi5_configurator.sh`)

Zamiast korzystać z wbudowanego kreatora w Raspberry Pi Imagerze (który bywa zawodny), wgraj czysty obraz **Raspberry Pi OS Lite (64-bit)** na kartę SD lub dysk NVMe (wybierając **NO** przy pytaniu o *OS customisation*).

1. Wyjmij i ponownie podłącz nośnik do komputera, aby system zamontował partycje **`bootfs`** oraz **`rootfs`**.

2. Uruchom interaktywny konfigurator bezpośrednio z terminala:

```
bash <(curl -fsSL https://raw.githubusercontent.com/procrastinating-pro/Raspbian-Configurator/refs/heads/main/rpi5_configurator.sh)

```

**Co możesz skonfigurować w kreatorze:**

* Aktywację serwera SSH (`bootfs/ssh`).

* Utworzenie nowego konta użytkownika i zaszyfrowanego hasła (`userconf.txt`).

* Automatyczne skopiowanie Twojego klucza publicznego (`~/.ssh/id_ed25519.pub` lub `id_rsa.pub`) dla logowania bez hasła.

* Ustawienie statycznego adresu IP dla portu LAN (`eth0`) – domyślnie `192.168.1.250/24`.

* Włączenie obsługi **Raspberry Pi NVMe HAT+** (`dtparam=pciex1`) oraz wymuszenie szybszego trybu **PCIe Gen 3** (`dtparam=pciex1_gen=3`).

* Zmianę nazwy hosta (`hostname`).

3. Po zakończeniu pracy skryptu odmontuj partycje, przełóż nośnik do Raspberry Pi 5, podłącz kabel LAN oraz zasilanie:

```
sudo umount /media/$USER/bootfs /media/$USER/rootfs

```

4. Po około 60–90 sekundach połącz się z płytką przez SSH:

```
ssh twoj_login@192.168.1.250

```

*(Jeśli musisz zlokalizować płytkę w sieci lokalnej, użyj szybkiego skanowania Nmap dla portu SSH):*

```
nmap -p 22 -T4 -n 192.168.1.0/24 --open

```

## 🐳 Krok 2: Instalacja Dockera i Auto-Maintenance (`install_docker.sh`)

Po zalogowaniu się na Raspberry Pi 5 przez SSH zainstaluj środowisko Docker, Docker Compose v2 oraz harmonogram automatycznej konserwacji systemu jedną komendą:

```
curl -fsSL https://raw.githubusercontent.com/procrastinating-pro/Raspbian-Configurator/refs/heads/main/install_docker.sh | bash && newgrp docker

```

**Co robi skrypt:**

* Wykonuje pełną, bezobsługową aktualizację systemu (`full-upgrade`, `autoremove`, `autoclean`).

* Tworzy zadanie w `/etc/cron.d/auto-system-maintenance`, które **codziennie o 03:30 w nocy** aktualizuje pakiety systemowe, czyści zbędne zależności i usuwa nieużywane obrazy Dockera (`docker image prune -af`), zapisując pełny przebieg ze znacznikami czasu do `/var/log/auto-update.log`.

* Aktywuje usługę `fstrim.timer` dbającą o kondycję i wydajność dysku NVMe.

* Sprawdza, czy Docker jest już zainstalowany – jeśli nie, dodaje oficjalny klucz GPG i repozytorium Dockera dla architektury `arm64`, po czym instaluje pakiety `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` oraz `docker-compose-plugin`.

* Konfiguruje plik `/etc/docker/daemon.json` z limitem rozmiaru logów (`max-size: 10m`, `max-file: 3`), co chroni dysk przed zapełnieniem.

* Dodaje bieżącego użytkownika do grupy `docker` (jeśli jeszcze do niej nie należy).

*Weryfikacja poprawności instalacji:*

```
docker run --rm hello-world

```

## 🛡️ Krok 3: Instalacja Pi-hole + NAS + Watchtower (`setup_pihole_nas.sh`)

Aby uruchomić blokowanie reklam w sieci lokalnej (Pi-hole), serwer plików NAS (Samba + FileBrowser) oraz automatyczne aktualizacje kontenerów (Watchtower), wykonaj na Raspberry Pi 5:

```
bash <(curl -fsSL https://raw.githubusercontent.com/procrastinating-pro/Raspbian-Configurator/refs/heads/main/setup_pihole_nas.sh)

```

*(Uwaga: Użycie składni `bash <(curl ...)` jest wymagane, ponieważ skrypt działa interaktywnie i pobiera od Ciebie hasła oraz ścieżki z klawiatury).*

**Co robi skrypt:**

1. Sprawdza, czy port `53` jest zajęty przez `systemd-resolved` i w razie potrzeby automatycznie go zwalnia.

2. Tworzy folder dla udostępnianych plików NAS (domyślnie `/srv/nas/pliki`) oraz folder konfiguracji kontenerów (`~/docker/pihole-nas`).

3. Konfiguruje **lokalne domeny DNS** (domyślnie `nas.home`, `pihole.home`, `rpi.home`), wstrzykując je bezpośrednio do pliku `docker-compose.yml` (`extra_hosts` oraz `FTLCONF_dns_hosts`) i `custom.list` (pełna kompatybilność z Pi-hole v5 i v6).

4. Generuje plik `docker-compose.yml` dopasowany do Twoich ustawień (wraz z opcjonalnym kontenerem **Watchtower**, który codziennie o 04:00 rano aktualizuje obrazy i czyści stare warstwy).

5. Inicjalizuje bazę danych **FileBrowsera** i tworzy konto administratora z Twoim własnym hasłem (wymagane min. 12 znaków).

6. Uruchamia wszystkie kontenery w tle (`restart: unless-stopped`).

### ⚠️ Ważne: Konfiguracja DNS na routerze

Aby blokowanie reklam przez **Pi-hole** oraz lokalne domeny (`.home`) działały automatycznie na wszystkich urządzeniach w domu (telefonach, telewizorach, komputerach):

1. Zaloguj się do panelu administracyjnego swojego routera.

2. Przejdź do ustawień sieci lokalnej (**LAN / DHCP Server**).

3. Jako **Podstawowy serwer DNS (Primary DNS)** wpisz statyczny adres IP swojego Raspberry Pi (domyślnie `192.168.1.250`).

4. Pole **Zapasowy serwer DNS (Secondary DNS)** pozostaw **puste** (jeśli wpiszesz tam np. `8.8.8.8` lub `1.1.1.1`, część zapytań ominie Pi-hole, reklamy będą się wyświetlać, a lokalne domeny `nas.home` nie będą działać).

5. Zapisz ustawienia i zrestartuj połączenie Wi-Fi/LAN na urządzeniach, aby pobrały nową konfigurację z routera.

### 🌍 Lokalne domeny DNS (Konfiguracja w `docker-compose.yml`)

Skrypt `setup_pihole_nas.sh` automatycznie pyta o lokalne domeny podczas instalacji (domyślnie: `nas.home pihole.home rpi.home`) i dopisuje je bezpośrednio do `docker-compose.yml`.

Jeśli w przyszłości zechcesz dodać kolejne własne domeny, wystarczy wyedytować plik `~/docker/pihole-nas/docker-compose.yml` (sekcja `extra_hosts` oraz `FTLCONF_dns_hosts` w usłudze `pihole`) i przeładować kontener komendą `docker compose up -d`.

*(Wskazówka: Używaj końcówek `.home`, `.lan` lub `.internal`. Unikaj końcówki `.local`, która jest zarezerwowana dla protokołu mDNS/Avahi i może powodować opóźnienia).*

## ❄️ Krok 4: Optymalizacja chłodzenia Active Cooler i NVMe (`setup_cooler.sh`)

W zamkniętej obudowie z nakładką M.2 HAT+ i radiatorami na dysku SSD Gen 3 domyślna krzywa wentylatora (start od 50°C CPU) jest zbyt pasywna. Aby zapewnić optymalny obieg powietrza wokół radiatora NVMe oraz cichą pracę, uruchom konfigurator chłodzenia:

```
bash <(curl -fsSL https://raw.githubusercontent.com/procrastinating-pro/Raspbian-Configurator/refs/heads/main/setup_cooler.sh)

```

**Co robi skrypt:**

* Ustawia w `/boot/firmware/config.txt` zoptymalizowaną krzywą dla **Raspberry Pi Active Cooler**.

* Instaluje pakiet `nvme-cli` oraz usługę systemową `nvme-fan-guard.service`, która odczytuje temperaturę dysku SSD i automatycznie reguluje obroty wentylatora podczas dużych transferów plików przez NAS (nawet gdy sam procesor RPi 5 jest chłodny).

* Tworzy polecenie diagnostyczne `rpi-temp`, pozwalające w dowolnej chwili sprawdzić temperatury oraz obroty wentylatora.

## 🌐 Dostęp do usług po instalacji

Przy założeniu domyślnego adresu IP `192.168.1.250` oraz domyślnych lokalnych domen DNS:

* **Panel administracyjny Pi-hole:**

  * Adres WWW: `http://pihole.home:8080/admin` (lub `http://192.168.1.250:8080/admin`)

  * Logowanie: Hasło podane podczas konfiguracji Pi-hole.

* **Dysk sieciowy NAS (Samba / SMB):**

  * **Linux (Ubuntu / menedżer plików):** `smb://nas.home/DyskNAS` (lub `smb://192.168.1.250/DyskNAS`)

  * **Windows (Eksplorator plików):** `\\nas.home\DyskNAS` (lub `\\192.168.1.250\DyskNAS`)

  * Logowanie: Użytkownik i hasło Samby podane w konfiguratorze.

* **Zarządzanie plikami NAS przez przeglądarkę (FileBrowser):**

  * Adres WWW: `http://nas.home:8081` (lub `http://192.168.1.250:8081`)

  * Logowanie: Użytkownik (domyślnie `admin`) oraz własne hasło (min. 12 znaków) ustawione w konfiguratorze.

## 🛠️ Przydatne komendy diagnostyczne

* **Sprawdzenie temperatury CPU, dysku NVMe oraz obrotów Active Coolera:**

```
rpi-temp
# lub podgląd na żywo co 2 sekundy:
watch -n 2 rpi-temp

```

* **Pełna diagnostyka i reset konfiguracji wentylatora (w przypadku pracy na 100% obrotów):**
  Jeśli wentylator nie reaguje na zmiany temperatury, uruchom skrypt diagnostyczny, który przeskanuje partycje `bootfs` i `rootfs`, usunie konflikty i przetestuje sprzętowo linię PWM (`PWM=0` vs `PWM=255`):

```
sudo bash <(curl -fsSL https://raw.githubusercontent.com/procrastinating-pro/Raspbian-Configurator/refs/heads/main/diagnose_and_fix_fan.sh)

```

* **Sprawdzenie czy nocny Auto-Update systemu (03:30) został przeprowadzony:**

```
# 1. Podgląd pełnego logu z nocnej aktualizacji (update, full-upgrade, autoremove, autoclean, docker prune):
tail -n 50 /var/log/auto-update.log

# 2. Sprawdzenie w logach systemowych (journalctl), czy zadanie Cron wystartowało punktualnie o 03:30:
sudo journalctl --since "03:29:00" --until "03:45:00" | grep -iE "cron|apt|upgrade|autoremove|autoclean"

# 3. Historia faktycznie zaktualizowanych lub usuniętych pakietów APT:
tail -n 30 /var/log/apt/history.log

```

* **Sprawdzenie czy aktualizacja kontenerów Docker (Watchtower o 04:00) została przeprowadzona:**

```
# 1. Logi działania kontenera Watchtower:
docker logs watchtower

# 2. Sprawdzenie dokładnej daty utworzenia/aktualizacji poszczególnych kontenerów:
docker inspect --format='{{.Name}} -> Utworzony: {{.Created}}' $(docker ps -a -q)

# 3. Ręczne wymuszenie natychmiastowego sprawdzenia i aktualizacji wszystkich kontenerów (test jednorazowy):
sudo docker run --rm -e DOCKER_API_VERSION=1.44 -v /var/run/docker.sock:/var/run/docker.sock containrrr/watchtower --run-once

```

* **Sprawdzenie statusu uruchomionych kontenerów:**

```
docker ps

```

* **Podgląd logów poszczególnych kontenerów:**

```
docker logs pihole
docker logs samba-nas
docker logs filebrowser-nas

```

* **Restart lub zatrzymanie wszystkich usług:**

```
cd ~/docker/pihole-nas
docker compose restart
# lub zatrzymanie:
docker compose down

```

* **Ręczna zmiana hasła do FileBrowsera z poziomu terminala:**

```
cd ~/docker/pihole-nas
docker compose stop filebrowser
docker compose run --rm filebrowser users update admin --password "TwojeNoweHaslo123" --database /database/filebrowser.db
docker compose start filebrowser

```

## 📄 Licencja

Projekt jest udostępniany na warunkach licencji **MIT**. Szczegółowe informacje znajdują się w pliku [LICENSE.md](LICENSE.md).