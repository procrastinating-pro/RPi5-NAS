# 🍓 Raspbian-Configurator (Raspberry Pi 5 Headless + Docker + Pi-hole + NAS)

Zestaw automatycznych i interaktywnych skryptów Bash pozwalających na szybkie przygotowanie czystego obrazu **Raspberry Pi OS (64-bit)** pod Raspberry Pi 5 (wraz z obsługą **NVMe HAT+**), instalację **Dockera** oraz wdrożenie domowego serwera **Pi-hole** i **NAS (Samba + FileBrowser)**.

---

## 📂 Zawartość repozytorium

| Skrypt | Gdzie uruchamiać? | Opis działania |
| :--- | :--- | :--- |
| **`rpi5_configurator.sh`** | 💻 Na komputerze (np. Ubuntu) z podłączonym nośnikiem (SD/NVMe) | Konfiguruje czysty obraz przed pierwszym uruchomieniem: włącza SSH, tworzy użytkownika, wgrywa klucz SSH, ustawia statyczny IP (NetworkManager) i odblokowuje PCIe Gen 3 dla NVMe HAT+. |
| **`install_docker.sh`** | 🍓 Na Raspberry Pi 5 (przez SSH) | Instaluje najnowszy **Docker Engine** oraz **Docker Compose v2** z oficjalnego repozytorium APT, ustawia rotację logów i dodaje użytkownika do grupy `docker`. |
| **`setup_pihole_nas.sh`** | 🍓 Na Raspberry Pi 5 (przez SSH) | Interaktywny instalator kontenerów: zwalnia port 53 (`systemd-resolved`), tworzy strukturę katalogów i uruchamia **Pi-hole**, serwer **Samba (SMB)** oraz panel WWW **FileBrowser** z własnym hasłem. |

---

## 🚀 Krok 1: Przygotowanie nośnika przed pierwszym startem (`rpi5_configurator.sh`)

Zamiast korzystać z wbudowanego kreatora w Raspberry Pi Imagerze (który bywa zawodny), wgraj czysty obraz **Raspberry Pi OS Lite (64-bit)** na kartę SD lub dysk NVMe (wybierając **NO** przy pytaniu o *OS customisation*).

1. Wyjmij i ponownie podłącz nośnik do komputera, aby system zamontował partycje **`bootfs`** oraz **`rootfs`**.
2. Uruchom interaktywny konfigurator bezpośrednio z terminala:

```bash
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

---

## 🐳 Krok 2: Instalacja Dockera (`install_docker.sh`)

Po zalogowaniu się na Raspberry Pi 5 przez SSH zainstaluj środowisko Docker oraz Docker Compose v2 jedną komendą:

```bash
curl -fsSL https://raw.githubusercontent.com/procrastinating-pro/Raspbian-Configurator/refs/heads/main/install_docker.sh | bash && newgrp docker
```

**Co robi skrypt:**
* Dodaje oficjalny klucz GPG i repozytorium Dockera dla architektury `arm64`.
* Instaluje pakiety `docker-ce`, `docker-ce-cli`, `containerd.io`, `docker-buildx-plugin` oraz `docker-compose-plugin`.
* Konfiguruje plik `/etc/docker/daemon.json` z limitem rozmiaru logów (`max-size: 10m`, `max-file: 3`), co chroni dysk przed zapełnieniem.
* Dodaje bieżącego użytkownika do grupy `docker`.

*Weryfikacja poprawności instalacji:*

```bash
docker run --rm hello-world
```

---

## 🛡️ Krok 3: Instalacja Pi-hole + NAS (`setup_pihole_nas.sh`)

Aby uruchomić blokowanie reklam w sieci lokalnej (Pi-hole) oraz serwer plików NAS (Samba + FileBrowser), wykonaj na Raspberry Pi 5:

```bash
bash <(curl -fsSL https://raw.githubusercontent.com/procrastinating-pro/Raspbian-Configurator/refs/heads/main/setup_pihole_nas.sh)
```

*(Uwaga: Użycie składni `bash <(curl ...)` jest wymagane, ponieważ skrypt działa interaktywnie i pobiera od Ciebie hasła oraz ścieżki z klawiatury).*

**Co robi skrypt:**
1. Sprawdza, czy port `53` jest zajęty przez `systemd-resolved` i w razie potrzeby automatycznie go zwalnia.
2. Tworzy folder dla udostępnianych plików NAS (domyślnie `/srv/nas/pliki`) oraz folder konfiguracji kontenerów (`~/docker/pihole-nas`).
3. Generuje plik `docker-compose.yml` dopasowany do Twoich ustawień.
4. Inicjalizuje bazę danych **FileBrowsera** i tworzy konto administratora z Twoim własnym hasłem (wymagane min. 12 znaków).
5. Uruchamia wszystkie kontenery w tle (`restart: unless-stopped`).

---

## 🌐 Dostęp do usług po instalacji

Przy założeniu domyślnego adresu IP `192.168.1.250` oraz domyślnych portów z konfiguratora:

* **Panel administracyjny Pi-hole:**
  * Adres: `http://192.168.1.250:8080/admin`
  * Logowanie: Hasło podane podczas konfiguracji Pi-hole.
* **Dysk sieciowy NAS (Samba / SMB):**
  * **Linux (Ubuntu / menedżer plików):** `smb://192.168.1.250/DyskNAS`
  * **Windows (Eksplorator plików):** `\\192.168.1.250\DyskNAS`
  * Logowanie: Użytkownik i hasło Samby podane w konfiguratorze.
* **Zarządzanie plikami NAS przez przeglądarkę (FileBrowser):**
  * Adres: `http://192.168.1.250:8081`
  * Logowanie: Użytkownik (domyślnie `admin`) oraz własne hasło (min. 12 znaków) ustawione w konfiguratorze.

---

## 🛠️ Przydatne komendy diagnostyczne

* **Sprawdzenie statusu uruchomionych kontenerów:**

```bash
docker ps
```

* **Podgląd logów poszczególnych kontenerów:**

```bash
docker logs pihole
docker logs samba-nas
docker logs filebrowser-nas
```

* **Restart lub zatrzymanie wszystkich usług:**

```bash
cd ~/docker/pihole-nas
docker compose restart
# lub zatrzymanie:
docker compose down
```

* **Ręczna zmiana hasła do FileBrowsera z poziomu terminala:**

```bash
cd ~/docker/pihole-nas
docker compose stop filebrowser
docker compose run --rm filebrowser users update admin --password "TwojeNoweHaslo123" --database /database/filebrowser.db
docker compose start filebrowser
```