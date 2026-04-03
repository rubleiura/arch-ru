# ==============================================================================
# ПОЛНЫЙ МАСТЕР-ЧЕК-ЛИСТ: НАСТРОЙКА ARCH LINUX ПОСЛЕ УСТАНОВКИ (ВЕРСИЯ 4.0)
# Пользователь: Юрий
# Включает: Система + UFW + Сетевые устройства + Безопасность + Звук + Nano + Zsh + Приложения + lux-wine
# Формат: Команды раскомментированы, пояснения в комментариях (#)
# Совместимость: BTRFS + LUKS + LVM + snapper + btrfs-assistant
# ==============================================================================





# ------------------------------------------------------------------------------
# РЕЗЕРВНОЕ КОПИРОВАНИЕ (КРИТИЧНО ВАЖНО)
# ------------------------------------------------------------------------------
# Приоритет: [ОБЯЗАТЕЛЬНО]
# Перед любыми изменениями создайте точку восстановления.
# Проверка файловой системы (должно быть btrfs)
findmnt -o TARGET,FSTYPE / | grep btrfs

# Если Btrfs — создайте снапшот через Btrfs Assistant или вручную
# sudo btrfs subvolume snapshot / /.snapshots/pre-config-backup





# ------------------------------------------------------------------------------
# БАЗОВАЯ ДИАГНОСТИКА И ОБНОВЛЕНИЕ
# ------------------------------------------------------------------------------
# Приоритет: [ОБЯЗАТЕЛЬНО]

# Информация о дисках и разделах
lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME,SIZE,MOUNTPOINTS

# Список явно установленных пакетов
pacman -Qqet

# Проверка "висячих" зависимостей (можно удалить)
pacman -Qtd

# Полное обновление системы
sudo pacman -Syu





# ------------------------------------------------------------------------------
# НАСТРОЙКА БРАНДМАУЭРА UFW
# ------------------------------------------------------------------------------
# Приоритет: [ОБЯЗАТЕЛЬНО]
# ⚠️ ВНИМАНИЕ: Настройте правила ДО включения фаервола!

# Установка UFW и графической оболочки
sudo pacman -S --noconfirm ufw gufw ufw-extras

# Проверка текущего статуса
sudo ufw status

# (Опционально) Отключение конфликтующих фаерволов
sudo systemctl stop iptables 2>/dev/null; sudo systemctl disable iptables 2>/dev/null
sudo systemctl stop nftables 2>/dev/null; sudo systemctl disable nftables 2>/dev/null

# Установка политик по умолчанию
sudo ufw default deny incoming
sudo ufw default allow outgoing

# ⚠️ РАЗРЕШЕНИЕ ДОСТУПА (ВЫПОЛНИТЬ ПЕРЕД ВКЛЮЧЕНИЕМ!) ⚠️
# Выберите ОДИН вариант в зависимости от вашей ситуации:

# ✅ ВАРИАНТ А: ТОЛЬКО ДОМАШНЯЯ СЕТЬ (РЕКОМЕНДУЕТСЯ)
# Разрешает доступ только из вашей локальной сети (192.168.1.x)
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp

# ✅ ВАРИАНТ Б: ДОМАШНЯЯ СЕТЬ + ЗАЩИТА ОТ БРУТФОРСА (МАКС. БЕЗОПАСНОСТЬ)
# sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
# sudo ufw limit 22/tcp

# ⚙️ ВАРИАНТ В: КОНКРЕТНЫЙ IP (ЕСЛИ НУЖНО ТОЛЬКО С ОДНОГО УСТРОЙСТВА)
# sudo ufw allow from 192.168.1.100 to any port 22 proto tcp

# ⚠️ ВАРИАНТ Г: СТАНДАРТНЫЙ ПОРТ 22 ДЛЯ ВСЕХ (НЕ РЕКОМЕНДУЕТСЯ)
# sudo ufw allow 22/tcp

# Проверка правил перед включением
sudo ufw status verbose

# Включение брандмауэра
sudo ufw enable

# Добавление в автозагрузку
sudo systemctl enable ufw
sudo systemctl start ufw

# Включение логирования
sudo ufw logging on

# ------------------------------------------------------------------------------
# НАСТРОЙКА UFW ДЛЯ СЕТЕВЫХ УСТРОЙСТВ
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО] — если есть принтеры, сканеры, МФУ в сети
# Совместимо с: Домашняя сеть 192.168.1.0/24

# mDNS (Bonjour/Avahi) — для автообнаружения принтеров (порт 5353/udp)
sudo ufw allow from 192.168.1.0/24 to any port 5353 proto udp comment "mDNS discovery"

# SSDP (UPnP) — для обнаружения устройств (порт 1900/udp)
sudo ufw allow from 192.168.1.0/24 to any port 1900 proto udp comment "SSDP/UPnP"

# LLMNR — альтернатива mDNS в некоторых сетях (порт 5355/udp)
sudo ufw allow from 192.168.1.0/24 to any port 5355 proto udp comment "LLMNR"

# IPP (Internet Printing Protocol) — современная печать (порт 631/tcp)
sudo ufw allow from 192.168.1.0/24 to any port 631 proto tcp comment "IPP printing"

# RAW printing (AppSocket/JetDirect) — прямой доступ к принтеру (порт 9100/tcp)
sudo ufw allow from 192.168.1.0/24 to any port 9100 proto tcp comment "RAW printing"

# SANE network scanning — стандарт для сканеров в Linux (порт 6566/tcp)
sudo ufw allow from 192.168.1.0/24 to any port 6566 proto tcp comment "SANE scanning"

# SMB/CIFS для доступа к общим папкам (порты 137-139, 445)
sudo ufw allow from 192.168.1.0/24 to any port 137:139 proto udp comment "NetBIOS datagram"
sudo ufw allow from 192.168.1.0/24 to any port 137:139 proto tcp comment "NetBIOS session"
sudo ufw allow from 192.168.1.0/24 to any port 445 proto tcp comment "SMB file sharing"

# Проверка всех правил UFW
sudo ufw status verbose

# (Опционально) Настройка SANE для сетевого сканирования
echo "192.168.1.0/24" | sudo tee -a /etc/sane.d/net.conf

# Перезапуск службы обнаружения
systemctl restart avahi-daemon





# ------------------------------------------------------------------------------
# БАЗОВОЕ УПРОЧНЕНИЕ БЕЗОПАСНОСТИ
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО, НО РЕКОМЕНДУЕТСЯ]
# Совместимо с: BTRFS + LVM + LUKS + snapper + btrfs-assistant

# Отключение kexec (защита от загрузки вредоносного ядра)
echo 'kernel.kexec_load_disabled=1' | sudo tee /etc/sysctl.d/50-kexec.conf

# Проверка применения
cat /etc/sysctl.d/50-kexec.conf

# Исключение .snapshots из индексации locate
# Предотвращает утечку информации о структуре снапшотов
echo 'PRUNENAMES=".snapshots"' | sudo tee -a /etc/updatedb.conf

# Проверка
grep -E 'PRUNENAMES.*\.snapshots' /etc/updatedb.conf

# Запрет генерации core-дампов (предотвращение утечки памяти)
# ⚠️ Пропустите, если вы разработчик и нужны дампы для отладки
echo '* hard core 0' | sudo tee -a /etc/security/limits.conf

# Проверка
grep 'hard core 0' /etc/security/limits.conf

# Применение всех sysctl-настроек
sudo sysctl --system

# Проверка применения настроек
sysctl kernel.kexec_load_disabled
# Должно быть: kernel.kexec_load_disabled = 1

ulimit -c
# Должно быть: 0





# ------------------------------------------------------------------------------
# НАСТРОЙКА ЗВУКА (PIPEWIRE + EASYEFFECTS)
# ------------------------------------------------------------------------------
# Приоритет: [ОБЯЗАТЕЛЬНО]

# Установка всех пакетов PipeWire
sudo pacman -S --needed --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber sof-firmware alsa-ucm-conf alsa-utils

# Включение сервисов (от имени пользователя, НЕ root!)
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# Проверка статуса
systemctl --user status pipewire
systemctl --user status wireplumber

# Проверка, что PipeWire заменил PulseAudio
pactl info | grep "Server Name"
# Должно быть: PipeWire PulseAudio

# Разблокировка звука (часто заглушен по умолчанию)
amixer set Master unmute
amixer set Master 80%

# Тест звука (должны быть слышны гудки)
speaker-test -c 2 -t wav

# ------------------------------------------------------------------------------
# PAVUCONTROL — КОГДА НУЖЕН, А КОГДА НЕТ
# ------------------------------------------------------------------------------
# ✅ УСТАНОВИТЕ, ЕСЛИ: i3/sway/hyprland, проблемы со звуком, Bluetooth, тонкая настройка
# ❌ МОЖНО НЕ СТАВИТЬ, ЕСЛИ: GNOME/KDE/XFCE (встроено в панель)

# Установка Pavucontrol (если нужен по таблице выше)
sudo pacman -S --needed --noconfirm pavucontrol

# Запуск Pavucontrol
pavucontrol

# 📌 ВКЛАДКИ PAVUCONTROL:
# 1. "Устройства вывода" → Выберите правильные динамики/наушники
# 2. "Воспроизведение" → Громкость по отдельным приложениям
# 3. "Запись" → Настройка микрофона
# 4. "Конфигурация" → Выберите профиль устройства (важно для Bluetooth!)
# 5. "Ввод" → Настройка источников записи

# ------------------------------------------------------------------------------
# УСТАНОВКА EASYEFFECTS СО ВСЕМИ ПЛАГИНАМИ (ПОЛНЫЙ НАБОР)
# ------------------------------------------------------------------------------
# Важно: Установка ВСЕХ плагинов предотвращает появление "серых" 
# неактивных пунктов в меню и обеспечивает работу готовых пресетов.

sudo pacman -S --needed --noconfirm easyeffects calf lsp-plugins-lv2 zam-plugins-lv2 mda.lv2 yelp

# Автоматическая установка пресетов (JackHack96)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/install.sh)"

# Проверка установленных пресетов
ls -la ~/.local/share/easyeffects/output/
ls -la ~/.local/share/easyeffects/input/

# (Опционально) Оптимизация для игр (низкая задержка)
mkdir -p ~/.config/pipewire/pipewire.conf.d
echo "context.properties = { default.clock.quantum = 512 default.clock.min-quantum = 256 }" > ~/.config/pipewire/pipewire.conf.d/99-low-latency.conf
systemctl --user restart pipewire





# ------------------------------------------------------------------------------
# УСТАНОВКА ПРИЛОЖЕНИЙ
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО] — выберите нужное

# Базовые утилиты
sudo pacman -S --noconfirm doublecmd-qt6 vlc vlc-plugins-all htop cpu-x gparted qbittorrent libreoffice-still-ru hardinfo2 fastfetch hyfetch inxi

# Включение сервиса hardinfo2
sudo systemctl enable --now hardinfo2.service

# Загрузка модулей для датчиков
sudo modprobe -a at24 ee1004 spd5118

# Добавление пользователя в группу hardinfo2
sudo usermod -aG hardinfo2 $USER

# (Опционально) AUR-помощники и утилиты
yay -S --noconfirm pamac-aur ventoy-bin stacer-bin system-monitoring-center

# (Опционально) Темы и настройки загрузчика — ОСТОРОЖНО!
yay -S --noconfirm grub-customizer grub2-theme-arch-leap update-grub





# ------------------------------------------------------------------------------
# НАСТРОЙКА РЕДАКТОРА NANO
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО]
# Исходное состояние: все опции в /etc/nanorc закомментированы

# Резервное копирование конфига
sudo cp /etc/nanorc /etc/nanorc.bak.$(date +%F)

# Базовые настройки интерфейса (раскомментируем)
sudo sed -i 's/^# set autoindent/set autoindent/' /etc/nanorc
sudo sed -i 's/^# set linenumbers/set linenumbers/' /etc/nanorc
sudo sed -i 's/^# set softwrap/set softwrap/' /etc/nanorc
sudo sed -i 's/^# set tabstospaces/set tabstospaces/' /etc/nanorc
sudo sed -i 's/^# set tabsize [0-9]*/set tabsize 4/' /etc/nanorc
sudo sed -i 's/^# set trimblanks/set trimblanks/' /etc/nanorc
sudo sed -i 's/^# set unix/set unix/' /etc/nanorc
sudo sed -i 's/^# set constantshow/set constantshow/' /etc/nanorc
sudo sed -i 's/^# set indicator/set indicator/' /etc/nanorc
sudo sed -i 's/^# set smarthome/set smarthome/' /etc/nanorc
sudo sed -i 's/^# set quickblank/set quickblank/' /etc/nanorc

# Цветовая схема (для root/системных файлов)
sudo sed -i 's/^# set titlecolor bold,white,magenta/set titlecolor bold,white,magenta/' /etc/nanorc
sudo sed -i 's/^# set promptcolor black,yellow/set promptcolor black,yellow/' /etc/nanorc
sudo sed -i 's/^# set statuscolor bold,white,magenta/set statuscolor bold,white,magenta/' /etc/nanorc
sudo sed -i 's/^# set errorcolor bold,white,red/set errorcolor bold,white,red/' /etc/nanorc
sudo sed -i 's/^# set spotlightcolor black,orange/set spotlightcolor black,orange/' /etc/nanorc
sudo sed -i 's/^# set selectedcolor lightwhite,cyan/set selectedcolor lightwhite,cyan/' /etc/nanorc
sudo sed -i 's/^# set numbercolor magenta/set numbercolor magenta/' /etc/nanorc

# Подключение подсветки синтаксиса
sudo sed -i 's|^# include /usr/share/nano/\*\.nanorc|include /usr/share/nano/*.nanorc|' /etc/nanorc

# Проверка результата
grep -E "^set |^include " /etc/nanorc





# ------------------------------------------------------------------------------
# НАСТРОЙКА ZSH И OH MY ZSH
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО]

# Установка Zsh
sudo pacman -S --noconfirm zsh

# Установка Oh My Zsh
export CHSH=no
export RUNZSH=no
export KEEP_ZSHRC=yes
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# Установка плагинов
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# Настройка темы и плагинов
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' ~/.zshrc
sed -i 's/^plugins=(.*)/plugins=(git archlinux extract zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc

# Дополнительные настройки
echo 'ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"' >> ~/.zshrc
echo 'ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20' >> ~/.zshrc

# Применение изменений
source ~/.zshrc

# Смена оболочки на Zsh
chsh -s $(which zsh)

# Добавление hyfetch в автозапуск
grep -q "hyfetch" ~/.zshrc || echo "hyfetch" >> ~/.zshrc





# ------------------------------------------------------------------------------
# СКРИПТ "10 БЛИЖАЙШИХ СТРАН ПО IP" (ЛЕГКАЯ ВЕРСИЯ)
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО] — для демонстрации или проверки геолокации

# Установка зависимостей (только python и requests)
sudo pacman -S --noconfirm python python-requests

# Создание скрипта
cat > ~/light_countries.py << 'EOF'
import requests
import math
import sys

CAPITALS = {
    "Afghanistan": (34.5553, 69.2075), "Albania": (41.3275, 19.8187), "Algeria": (36.7538, 3.0588),
    "Andorra": (42.5063, 1.5218), "Angola": (-8.8390, 13.2894), "Argentina": (-34.6037, -58.3816),
    "Armenia": (40.1792, 44.4991), "Australia": (-35.2809, 149.1300), "Austria": (48.2082, 16.3738),
    "Azerbaijan": (40.4093, 49.8671), "Bahamas": (25.0585, -77.3512), "Bahrain": (26.2285, 50.5860),
    "Bangladesh": (23.8103, 90.4125), "Barbados": (13.0969, -59.6145), "Belarus": (53.9006, 27.5590),
    "Belgium": (50.8503, 4.3517), "Belize": (17.2510, -88.7590), "Benin": (6.4969, 2.6283),
    "Bhutan": (27.4728, 89.6390), "Bolivia": (-16.5000, -68.1500), "Bosnia and Herzegovina": (43.8563, 18.4131),
    "Botswana": (-24.6282, 25.9231), "Brazil": (-15.8267, -47.9218), "Brunei": (4.9031, 114.9398),
    "Bulgaria": (42.6977, 23.3219), "Burkina Faso": (12.3686, -1.5271), "Burundi": (-3.3761, 29.3600),
    "Cambodia": (11.5621, 104.8880), "Cameroon": (3.8480, 11.5021), "Canada": (45.4215, -75.6972),
    "Cape Verde": (14.9177, -23.5092), "Central African Republic": (4.3612, 18.5550), "Chad": (12.1348, 15.0557),
    "Chile": (-33.4489, -70.6693), "China": (39.9042, 116.4074), "Colombia": (4.7110, -74.0721),
    "Comoros": (-11.7172, 43.3470), "Congo": (-4.2634, 15.2429), "Costa Rica": (9.9281, -84.0907),
    "Croatia": (45.8150, 15.9819), "Cuba": (23.1136, -82.3666), "Cyprus": (35.1856, 33.3823),
    "Czech Republic": (50.0755, 14.4378), "Denmark": (55.6761, 12.5683), "Djibouti": (11.5721, 43.1456),
    "Dominica": (15.3010, -61.3870), "Dominican Republic": (18.4861, -69.9312), "Ecuador": (-0.1807, -78.4678),
    "Egypt": (30.0444, 31.2357), "El Salvador": (13.6929, -89.2182), "Equatorial Guinea": (3.7523, 8.7371),
    "Eritrea": (15.3229, 38.9251), "Estonia": (59.4370, 24.7536), "Ethiopia": (9.0320, 38.7469),
    "Fiji": (-18.1416, 178.4419), "Finland": (60.1699, 24.9384), "France": (48.8566, 2.3522),
    "Gabon": (0.4162, 9.4673), "Gambia": (13.4549, -16.5790), "Georgia": (41.7151, 44.8271),
    "Germany": (52.5200, 13.4050), "Ghana": (5.6037, -0.1870), "Greece": (37.9838, 23.7275),
    "Grenada": (12.0561, -61.7488), "Guatemala": (14.6248, -90.5328), "Guinea": (9.5092, -13.7122),
    "Guinea-Bissau": (11.8636, -15.5989), "Guyana": (6.8013, -58.1551), "Haiti": (18.5392, -72.3350),
    "Honduras": (14.0723, -87.1921), "Hungary": (47.4979, 19.0402), "Iceland": (64.1466, -21.9426),
    "India": (28.6139, 77.2090), "Indonesia": (-6.2088, 106.8456), "Iran": (35.6892, 51.3890),
    "Iraq": (33.3128, 44.3615), "Ireland": (53.3498, -6.2603), "Israel": (31.7683, 35.2137),
    "Italy": (41.9028, 12.4964), "Jamaica": (18.0179, -76.8099), "Japan": (35.6762, 139.6503),
    "Jordan": (31.9454, 35.9284), "Kazakhstan": (51.1605, 71.4704), "Kenya": (-1.2921, 36.8219),
    "Kiribati": (1.3292, 172.9823), "Kuwait": (29.3759, 47.9774), "Kyrgyzstan": (42.8746, 74.5698),
    "Laos": (17.9689, 102.6137), "Latvia": (56.9496, 24.1052), "Lebanon": (33.8938, 35.5018),
    "Lesotho": (-29.3151, 27.4869), "Liberia": (6.3156, -10.8074), "Libya": (32.8872, 13.1913),
    "Liechtenstein": (47.1410, 9.5209), "Lithuania": (54.6872, 25.2797), "Luxembourg": (49.6116, 6.1319),
    "Madagascar": (-18.8792, 47.5079), "Malawi": (-13.9833, 33.7703), "Malaysia": (3.1390, 101.6869),
    "Maldives": (4.1755, 73.5093), "Mali": (12.6392, -8.0029), "Malta": (35.8989, 14.5146),
    "Marshall Islands": (7.1164, 171.1845), "Mauritania": (18.0735, -15.9582), "Mauritius": (-20.1609, 57.5012),
    "Mexico": (19.4326, -99.1332), "Micronesia": (6.9177, 158.1850), "Moldova": (47.0105, 28.8638),
    "Monaco": (43.7384, 7.4246), "Mongolia": (47.9077, 106.8832), "Montenegro": (42.4304, 19.2594),
    "Morocco": (34.0209, -6.8416), "Mozambique": (-25.9653, 32.5892), "Myanmar": (16.8661, 96.1951),
    "Namibia": (-22.5609, 17.0658), "Nauru": (-0.5228, 166.9315), "Nepal": (27.7172, 85.3240),
    "Netherlands": (52.3702, 4.8952), "New Zealand": (-41.2865, 174.7762), "Nicaragua": (12.1150, -86.2362),
    "Niger": (13.5127, 2.1128), "Nigeria": (9.0765, 7.3986), "North Korea": (39.0392, 125.7625),
    "North Macedonia": (41.9973, 21.4280), "Norway": (59.9139, 10.7522), "Oman": (23.5880, 58.3829),
    "Pakistan": (33.6844, 73.0479), "Palau": (7.3419, 134.4789), "Panama": (8.9824, -79.5199),
    "Papua New Guinea": (-9.4431, 147.1803), "Paraguay": (-25.2637, -57.5759), "Peru": (-12.0464, -77.0428),
    "Philippines": (14.5995, 120.9842), "Poland": (52.2297, 21.0122), "Portugal": (38.7223, -9.1393),
    "Qatar": (25.2854, 51.5310), "Romania": (44.4268, 26.1025), "Russia": (55.7558, 37.6173),
    "Rwanda": (-1.9403, 29.8739), "Saint Kitts and Nevis": (17.3578, -62.7830), "Saint Lucia": (14.0101, -60.9875),
    "Saint Vincent and the Grenadines": (13.1579, -61.2248), "Samoa": (-13.8333, -171.7667),
    "San Marino": (43.9424, 12.4578), "Sao Tome and Principe": (0.3302, 6.7333), "Saudi Arabia": (24.7136, 46.6753),
    "Senegal": (14.7167, -17.4677), "Serbia": (44.7866, 20.4489), "Seychelles": (-4.6796, 55.4920),
    "Sierra Leone": (8.4606, -13.2317), "Singapore": (1.3521, 103.8198), "Slovakia": (48.1486, 17.1077),
    "Slovenia": (46.0569, 14.5058), "Solomon Islands": (-9.4456, 159.9729), "Somalia": (2.0469, 45.3182),
    "South Africa": (-25.7479, 28.2293), "South Korea": (37.5665, 126.9780), "South Sudan": (4.8594, 31.5713),
    "Spain": (40.4168, -3.7038), "Sri Lanka": (6.9271, 79.8612), "Sudan": (15.5007, 32.5599),
    "Suriname": (5.8520, -55.2038), "Sweden": (59.3293, 18.0686), "Switzerland": (46.9480, 7.4474),
    "Syria": (33.5138, 36.2765), "Taiwan": (25.0330, 121.5654), "Tajikistan": (38.5598, 68.7870),
    "Tanzania": (-6.7924, 39.2083), "Thailand": (13.7563, 100.5018), "Timor-Leste": (-8.5569, 125.5603),
    "Togo": (6.1256, 1.2246), "Tonga": (-21.1789, -175.1982), "Trinidad and Tobago": (10.6596, -61.5089),
    "Tunisia": (36.8065, 10.1815), "Turkey": (39.9334, 32.8597), "Turkmenistan": (37.9601, 58.3261),
    "Tuvalu": (-8.5167, 179.2167), "Uganda": (0.3476, 32.5825), "Ukraine": (50.4501, 30.5234),
    "United Arab Emirates": (24.4539, 54.3773), "United Kingdom": (51.5074, -0.1278),
    "United States": (38.9072, -77.0369), "Uruguay": (-34.9011, -56.1645), "Uzbekistan": (41.2995, 69.2401),
    "Vanuatu": (-17.7333, 168.3273), "Vatican City": (41.9029, 12.4534), "Venezuela": (10.4806, -66.9036),
    "Vietnam": (21.0285, 105.8542), "Yemen": (15.3694, 44.1910), "Zambia": (-15.3875, 28.3228),
    "Zimbabwe": (-17.8252, 31.0335)
}

def haversine(lat1, lon1, lat2, lon2):
    R = 6371
    phi1, phi2 = math.radians(lat1), math.radians(lat2)
    d_phi = math.radians(lat2 - lat1)
    d_lambda = math.radians(lon2 - lon1)
    a = math.sin(d_phi/2)**2 + math.cos(phi1)*math.cos(phi2)*math.sin(d_lambda/2)**2
    return 2 * R * math.atan2(math.sqrt(a), math.sqrt(1-a))

def get_ip_location():
    print("🌐 Определение местоположения по IP...")
    try:
        resp = requests.get('http://ip-api.com/json/', timeout=5)
        data = resp.json()
        if data['status'] == 'fail':
            raise Exception("API error")
        return float(data['lat']), float(data['lon']), data.get('country', 'Unknown')
    except Exception as e:
        print(f"❌ Ошибка: {e}")
        sys.exit(1)

def main():
    my_lat, my_lon, my_country = get_ip_location()
    print(f"✅ Вы находитесь: {my_country} ({my_lat}, {my_lon})\n")
    
    distances = []
    for country, (cap_lat, cap_lon) in CAPITALS.items():
        if country == my_country:
            continue
        dist = haversine(my_lat, my_lon, cap_lat, cap_lon)
        distances.append((country, dist))
    
    distances.sort(key=lambda x: x[1])
    
    print(f"{'#':<3} {'Страна':<25} {'Расстояние до столицы (км)':<10}")
    print("-" * 45)
    
    for i, (country, dist) in enumerate(distances[:10], 1):
        print(f"{i:<3} {country:<25} {dist:.2f}")
    
    print("-" * 45)
    print("✅ Готово! (Легкая версия)")

if __name__ == "__main__":
    main()
EOF

# 7.3 Запуск скрипта
python ~/light_countries.py

# 7.4 (Опционально) Сохранение результата
python ~/light_countries.py > ~/countries_result.txt





# ------------------------------------------------------------------------------
# ВИРТУАЛИЗАЦИЯ VIRTUALBOX
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО] — только если нужна виртуализация

# Проверка версии ядра
uname -r

# Установка VirtualBox + модуль ядра (выберите подходящий при установке!)
sudo pacman -S virtualbox

# Установка гостевых дополнений
sudo pacman -S virtualbox-guest-iso

# Добавление пользователя в группу vboxusers
sudo gpasswd -a $USER vboxusers

# (Опционально) Отключение уведомлений для Wayland
VBoxManage setextradata global GUI/ShowNotifications 0





# ------------------------------------------------------------------------------
# НАСТРОЙКА ДЛЯ ИГР (LUX-WINE)
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО] — если планируете запускать Windows-игры
# Сайт проекта: https://github.com/VHSgunzo/lux-wine

# Предварительные требования: проверка Vulkan и установка FUSE
vulkaninfo --summary 2>/dev/null | grep "deviceName"
sudo pacman -S --noconfirm fuse2

# ------------------------------------------------------------------------------
# УСТАНОВКА LUX-WINE (С АЛЬТЕРНАТИВНЫМИ ЗЕРКАЛАМИ)
# ------------------------------------------------------------------------------
# Все команды ниже устанавливают lux-wine в ~/home/user/LuxWine
# Установка происходит БЕЗ root-прав в ваш домашний каталог.

# ✅ ОСНОВНОЙ ИСТОЧНИК (попробуйте первым)
curl -sL lwrap.github.io | bash

# ⚙️ АЛЬТЕРНАТИВА 1: Yandex Cloud Mirror (если основной не работает)
# curl -sL lwrap.website.yandexcloud.net | bash

# ⚙️ АЛЬТЕРНАТИВА 2: Hugging Face Spaces Mirror
# curl -sL lux-wine-git.static.hf.space | sed 1d | bash

# ⚙️ АЛЬТЕРНАТИВА 3: Прямая ссылка на GitHub (если зеркала не работают)
# curl -sL https://raw.githubusercontent.com/VHSgunzo/lux-wine/main/install.sh | bash

# Перезагрузите терминал или выполните:
source ~/.bashrc

# Перезагрузите компьютер
reboot

# Выполните обновление всей конфигурации Lux Wine
lwrun -update all

# Первый запуск и проверка
lwrun --version
lwrun -config
lwrun -winecfg

# Запуск игры (пример)
# lwrun ~/Games/MyGame/game.exe

# Управление приложениями
# lwrun -lsapp           # Список установленных игр
# lwrun -runapp "Name"   # Запустить игру из списка
# lwrun -shortcut ~/Games/MyGame/game.exe  # Создать ярлык в меню

# Управление версиями Wine/Proton
# lwrun -winemgr         # Менеджер версий (Lutris, GE-Proton, Wine-GE)

# Настройка графики и производительности
# - Включить MangoHud: R_Shift + F12 (показать/скрыть)
# - Включить VkBasalt: HOME (вкл/выкл пост-обработку)
# - Настроить резкость FSR: lwrun -config → Графика → FSR

# Резервное копирование префикса игры
# lwrun -pfxbackup       # Создать бэкап
# lwrun -pfxbackup xz    # Сжатый бэкап
# lwrun -pfxrestore      # Восстановить из бэкапа

# Полезные команды
# lwrun -killwine        # Завершить зависший Wine
# lwrun -openpfx         # Открыть диск C: префикса
# lwrun --update         # Обновить lux-wine
# lwrun --uninstall      # Полное удаление





# ------------------------------------------------------------------------------
# ФИНАЛЬНАЯ ПРОВЕРКА СИСТЕМЫ
# ------------------------------------------------------------------------------

# 9.1 Очистка кэша пакетов
sudo pacman -Sc

# Проверка сервисов
systemctl --user status pipewire
systemctl status ufw

# Проверка оболочки
echo $SHELL

# Создание финального снапшота (если Btrfs)
# sudo btrfs subvolume snapshot / /.snapshots/post-config-complete





# ==============================================================================
# КОНТРОЛЬНЫЙ СПИСОК ЗАВЕРШЕНИЯ
# ==============================================================================
# [ ] Система обновлена
# [ ] UFW настроен и включен
# [ ] Доступ разрешён только для домашней сети (безопасность)
# [ ] UFW настроен для сетевых устройств (принтеры, сканеры)
# [ ] Безопасность ядра упрочнена (kexec, core-дампы, .snapshots)
# [ ] Звук работает (PipeWire + EasyEffects + ВСЕ плагины)
# [ ] Pavucontrol установлен (если нужен для WM/Bluetooth)
# [ ] Приложения установлены
# [ ] Nano настроен (номера строк, табы=4, цвета, подсветка)
# [ ] Zsh настроен (если нужно)
# [ ] Скрипт стран работает
# [ ] lux-wine установлен (для игр)
# [ ] Финальный снапшот создан
# ==============================================================================
