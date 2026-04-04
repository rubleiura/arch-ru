# ==============================================================================
# ПОЛНЫЙ МАСТЕР-ЧЕК-ЛИСТ: НАСТРОЙКА ARCH LINUX ПОСЛЕ УСТАНОВКИ
# Пользователь: Юрий
# Формат: Команды раскомментированы, пояснения в комментариях (#)
# Совместимость: BTRFS + LUKS + LVM + snapper + btrfs-assistant
# ==============================================================================

# ------------------------------------------------------------------------------
# ЭТАП 0: РЕЗЕРВНОЕ КОПИРОВАНИЕ (КРИТИЧНО ВАЖНО)
# ------------------------------------------------------------------------------
# Приоритет: [ОБЯЗАТЕЛЬНО]
# Перед любыми изменениями создайте точку восстановления.

# Проверка файловой системы (должно быть btrfs)
findmnt -o TARGET,FSTYPE / | grep btrfs

# Если Btrfs — создайте снапшот через Btrfs Assistant или вручную
# sudo btrfs subvolume snapshot / /.snapshots/pre-config-backup

# ------------------------------------------------------------------------------
# ЭТАП 1: БАЗОВАЯ ДИАГНОСТИКА И ОБНОВЛЕНИЕ
# ------------------------------------------------------------------------------
# Приоритет: [ОБЯЗАТЕЛЬНО]

# 1.1 Информация о дисках и разделах
lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME,SIZE,MOUNTPOINTS

# 1.2 Список явно установленных пакетов
pacman -Qqet

# 1.3 Проверка "висячих" зависимостей (можно удалить)
pacman -Qtd

# 1.4 Удаление "пакетов-сирот" (ОСВОБОЖДАЕТ МЕСТО!)
# ⚠️ ВНИМАНИЕ: Эта команда удалит все пакеты, которые больше не нужны
# (установленные как зависимости, но не используемые ни одним пакетом)
sudo pacman -Rns $(pacman -Qtdq) 2>/dev/null || echo "✅ Пакетов-сирот не найдено"

# 1.5 Полное обновление системы
sudo pacman -Syu

# ------------------------------------------------------------------------------
# ЭТАП 2: НАСТРОЙКА БРАНДМАУЭРА UFW
# ------------------------------------------------------------------------------
# Приоритет: [ОБЯЗАТЕЛЬНО]
# ⚠️ ВНИМАНИЕ: Настройте правила ДО включения фаервола!

# 2.1 Установка UFW и графической оболочки
sudo pacman -S --noconfirm ufw gufw ufw-extras

# 2.2 Проверка текущего статуса
sudo ufw status

# 2.3 (Опционально) Отключение конфликтующих фаерволов
sudo systemctl stop iptables 2>/dev/null; sudo systemctl disable iptables 2>/dev/null
sudo systemctl stop nftables 2>/dev/null; sudo systemctl disable nftables 2>/dev/null

# 2.4 Установка политик по умолчанию
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 2.5 ⚠️ РАЗРЕШЕНИЕ ДОСТУПА (ВЫПОЛНИТЬ ПЕРЕД ВКЛЮЧЕНИЕМ!) ⚠️
# Выберите ОДИН вариант в зависимости от вашей ситуации:

# ✅ ВАРИАНТ А: ТОЛЬКО ДОМАШНЯЯ СЕТЬ (РЕКОМЕНДУЕТСЯ)
sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp

# ✅ ВАРИАНТ Б: ДОМАШНЯЯ СЕТЬ + ЗАЩИТА ОТ БРУТФОРСА (МАКС. БЕЗОПАСНОСТЬ)
# sudo ufw allow from 192.168.1.0/24 to any port 22 proto tcp
# sudo ufw limit 22/tcp

# ⚙️ ВАРИАНТ В: КОНКРЕТНЫЙ IP (ЕСЛИ НУЖНО ТОЛЬКО С ОДНОГО УСТРОЙСТВА)
# sudo ufw allow from 192.168.1.100 to any port 22 proto tcp

# ⚠️ ВАРИАНТ Г: СТАНДАРТНЫЙ ПОРТ 22 ДЛЯ ВСЕХ (НЕ РЕКОМЕНДУЕТСЯ)
# sudo ufw allow 22/tcp

# 2.6 Проверка правил перед включением
sudo ufw status verbose

# 2.7 Включение брандмауэра
sudo ufw enable

# 2.8 Добавление в автозагрузку
sudo systemctl enable ufw
sudo systemctl start ufw

# 2.9 Включение логирования
sudo ufw logging on

# ------------------------------------------------------------------------------
# ЭТАП 3: НАСТРОЙКА UFW ДЛЯ СЕТЕВЫХ УСТРОЙСТВ
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО] — если есть принтеры, сканеры, МФУ в сети

# 3.1 mDNS (Bonjour/Avahi) — для автообнаружения принтеров (порт 5353/udp)
sudo ufw allow from 192.168.1.0/24 to any port 5353 proto udp comment "mDNS discovery"

# 3.2 SSDP (UPnP) — для обнаружения устройств (порт 1900/udp)
sudo ufw allow from 192.168.1.0/24 to any port 1900 proto udp comment "SSDP/UPnP"

# 3.3 LLMNR — альтернатива mDNS (порт 5355/udp)
sudo ufw allow from 192.168.1.0/24 to any port 5355 proto udp comment "LLMNR"

# 3.4 IPP (Internet Printing Protocol) — современная печать (порт 631/tcp)
sudo ufw allow from 192.168.1.0/24 to any port 631 proto tcp comment "IPP printing"

# 3.5 RAW printing — прямой доступ к принтеру (порт 9100/tcp)
sudo ufw allow from 192.168.1.0/24 to any port 9100 proto tcp comment "RAW printing"

# 3.6 SANE network scanning — стандарт для сканеров (порт 6566/tcp)
sudo ufw allow from 192.168.1.0/24 to any port 6566 proto tcp comment "SANE scanning"

# 3.7 SMB/CIFS для доступа к общим папкам (порты 137-139, 445)
sudo ufw allow from 192.168.1.0/24 to any port 137:139 proto udp comment "NetBIOS datagram"
sudo ufw allow from 192.168.1.0/24 to any port 137:139 proto tcp comment "NetBIOS session"
sudo ufw allow from 192.168.1.0/24 to any port 445 proto tcp comment "SMB file sharing"

# 3.8 Проверка всех правил UFW
sudo ufw status verbose

# 3.9 (Опционально) Настройка SANE для сетевого сканирования
echo "192.168.1.0/24" | sudo tee -a /etc/sane.d/net.conf

# 3.10 Перезапуск службы обнаружения
systemctl restart avahi-daemon

# ------------------------------------------------------------------------------
# ЭТАП 4: БАЗОВОЕ УПРОЧНЕНИЕ БЕЗОПАСНОСТИ
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО, НО РЕКОМЕНДУЕТСЯ]

# 4.1 Отключение kexec (защита от загрузки вредоносного ядра)
echo 'kernel.kexec_load_disabled=1' | sudo tee /etc/sysctl.d/50-kexec.conf

# Проверка применения
cat /etc/sysctl.d/50-kexec.conf

# 4.2 Исключение .snapshots из индексации locate
echo 'PRUNENAMES=".snapshots"' | sudo tee -a /etc/updatedb.conf

# Проверка
grep -E 'PRUNENAMES.*\.snapshots' /etc/updatedb.conf

# 4.3 Запрет генерации core-дампов (предотвращение утечки памяти)
# ⚠️ Пропустите, если вы разработчик и нужны дампы для отладки
echo '* hard core 0' | sudo tee -a /etc/security/limits.conf

# Проверка
grep 'hard core 0' /etc/security/limits.conf

# 4.4 Применение всех sysctl-настроек
sudo sysctl --system

# 4.5 Проверка применения настроек
sysctl kernel.kexec_load_disabled
# Должно быть: kernel.kexec_load_disabled = 1

ulimit -c
# Должно быть: 0

# ------------------------------------------------------------------------------
# ЭТАП 5: НАСТРОЙКА ЗВУКА (ПОЛНАЯ: ALSAMIXER + AMIXER + PIPEWIRE)
# ------------------------------------------------------------------------------
# Приоритет: [ОБЯЗАТЕЛЬНО]
# ⚠️ Звук часто заглушен (Muted) после установки — это нормально!

# 5.1 Установка всех пакетов PipeWire
sudo pacman -S --needed --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber sof-firmware alsa-ucm-conf alsa-utils

# 5.2 Включение сервисов (от имени пользователя, НЕ root!)
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# 5.3 Проверка статуса
systemctl --user status pipewire
systemctl --user status wireplumber

# 5.4 Проверка, что PipeWire заменил PulseAudio
pactl info | grep "Server Name"
# Должно быть: PipeWire PulseAudio

# ------------------------------------------------------------------------------
# 5.5 НАСТРОЙКА ЗВУКА ЧЕРЕЗ ALSAMIXER (КРИТИЧНО ВАЖНО!)
# ------------------------------------------------------------------------------
# ⚠️ Эта настройка визуальная — выполняйте интерактивно!

# Запустить терминальный микшер
alsamixer

# 📌 ИНСТРУКЦИЯ ПО НАВИГАЦИИ В ALSAMIXER:
# ┌─────────────────────────────────────────────────────────────┐
# │ Клавиша  │  Действие                                        │
# ├─────────────────────────────────────────────────────────────┤
# │ F6       │  Выбрать звуковую карту (не PCH/HDMI!)          │
# │ M        │  Заглушить/разглушить канал (MM → 00)           │
# │ ↑ / ↓    │  Увеличить/уменьшить громкость                  │
# │ ← / →    │  Переключиться между каналами                   │
# │ Esc      │  Выйти из alsamixer                             │
# └─────────────────────────────────────────────────────────────┘

# 🔍 КАНАЛЫ, КОТОРЫЕ НУЖНО ПРОВЕРИТЬ:
# • Master      — общая громкость
# • PCM         — громкость воспроизведения
# • Speaker     — встроенные динамики
# • Headphone   — наушники
# • Auto-Mute   — отключите, если звук пропадает при подключении наушников

# 📌 ВАЖНО: Если канал помечен "MM" — он заглушен! Нажмите M для разблокировки (станет "00").

# (Альтернатива) Быстрая разблокировка через командную строку:
amixer set Master unmute
amixer set Master 80%

# Проверка, что звук разблокирован
amixer get Master

# ------------------------------------------------------------------------------
# 5.6 ТЕСТ ЗВУКА
# ------------------------------------------------------------------------------
# Должны быть слышны гудки в левом и правом канале
speaker-test -c 2 -t wav

# ------------------------------------------------------------------------------
# 5.7 PAVUCONTROL — КОГДА НУЖЕН, А КОГДА НЕТ
# ------------------------------------------------------------------------------
# ✅ УСТАНОВИТЕ, ЕСЛИ: i3/sway/hyprland, проблемы со звуком, Bluetooth, тонкая настройка
# ❌ МОЖНО НЕ СТАВИТЬ, ЕСЛИ: GNOME/KDE/XFCE (встроено в панель)

# Установка Pavucontrol (если нужен)
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
# 5.8 УСТАНОВКА EASYEFFECTS СО ВСЕМИ ПЛАГИНАМИ (ПОЛНЫЙ НАБОР)
# ------------------------------------------------------------------------------
# Важно: Установка ВСЕХ плагинов предотвращает появление "серых" неактивных пунктов

sudo pacman -S --needed --noconfirm easyeffects calf lsp-plugins-lv2 zam-plugins-lv2 mda.lv2 yelp

# 5.9 Автоматическая установка пресетов (JackHack96)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/install.sh)"

# 5.10 Проверка установленных пресетов
ls -la ~/.local/share/easyeffects/output/
ls -la ~/.local/share/easyeffects/input/

# 5.11 (Опционально) Оптимизация для игр (низкая задержка)
mkdir -p ~/.config/pipewire/pipewire.conf.d
echo "context.properties = { default.clock.quantum = 512 default.clock.min-quantum = 256 }" > ~/.config/pipewire/pipewire.conf.d/99-low-latency.conf
systemctl --user restart pipewire

# ------------------------------------------------------------------------------
# 5.12 ДИАГНОСТИКА ПРОБЛЕМ СО ЗВУКОМ
# ------------------------------------------------------------------------------

# ❌ НЕТ ЗВУКА ВООБЩЕ:
# 1. Проверьте alsamixer — не стоит ли Mute (MM)
#    Решение: Нажмите M для разблокировки
# 2. Проверьте pavucontrol — выбрано ли правильное устройство
#    Решение: Выберите активное устройство во вкладке "Вывод"
# 3. Проверьте статус сервисов:
systemctl --user status pipewire
#    Решение: systemctl --user restart pipewire
# 4. Для ноутбуков Intel — проверьте sof-firmware:
pacman -Q sof-firmware
#    Решение: sudo pacman -S sof-firmware

# ❌ ЗВУК ТИХИЙ:
# 1. Проверьте все уровни в alsamixer (Master, PCM, Speaker)
#    Решение: amixer set Master 100%
# 2. В EasyEffects добавьте Maximizer: Threshold: -6 dB, Ceiling: -1 dB

# ❌ МИКРОФОН НЕ РАБОТАЕТ:
# 1. В pavucontrol → "Запись" → выберите правильный микрофон
# 2. Добавьте Noise Reduction в EasyEffects

# ❌ BLUETOOTH ПОДКЛЮЧАЕТСЯ, НО НЕТ ЗВУКА:
# 1. В pavucontrol выберите профиль A2DP (не HSP!)
# 2. Перезапустите Bluetooth:
sudo systemctl restart bluetooth

# ❌ ТРЕЩИТ ИЛИ ПРЕРЫВАЕТСЯ ЗВУК:
# 1. Увеличьте квант PipeWire (см. Шаг 5.11): quantum = 1024 вместо 512
# 2. Отключите тяжёлые плагины в EasyEffects
# 3. Проверьте нагрузку на CPU: htop

# ------------------------------------------------------------------------------
# ЭТАП 6: УСТАНОВКА ПРИЛОЖЕНИЙ
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО]

# 6.1 Базовые утилиты
sudo pacman -S --noconfirm doublecmd-qt6 vlc vlc-plugins-all htop cpu-x gparted qbittorrent libreoffice-still-ru hardinfo2 fastfetch hyfetch inxi btop

# 6.2 Включение сервиса hardinfo2
sudo systemctl enable --now hardinfo2.service

# 6.3 Загрузка модулей для датчиков
sudo modprobe -a at24 ee1004 spd5118

# 6.4 Добавление пользователя в группу hardinfo2
sudo usermod -aG hardinfo2 $USER

# 6.5 (Опционально) AUR-помощники и утилиты
yay -S --noconfirm pamac-aur ventoy-bin stacer-bin system-monitoring-center

# 6.6 (Опционально) Темы и настройки загрузчика — ОСТОРОЖНО!
yay -S --noconfirm grub-customizer grub2-theme-arch-leap update-grub

# ------------------------------------------------------------------------------
# ЭТАП 7: НАСТРОЙКА РЕДАКТОРА NANO
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО]

# 7.1 Резервное копирование конфига
sudo cp /etc/nanorc /etc/nanorc.bak.$(date +%F)

# 7.2 Базовые настройки интерфейса (раскомментируем)
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

# 7.3 Цветовая схема (для root/системных файлов)
sudo sed -i 's/^# set titlecolor bold,white,magenta/set titlecolor bold,white,magenta/' /etc/nanorc
sudo sed -i 's/^# set promptcolor black,yellow/set promptcolor black,yellow/' /etc/nanorc
sudo sed -i 's/^# set statuscolor bold,white,magenta/set statuscolor bold,white,magenta/' /etc/nanorc
sudo sed -i 's/^# set errorcolor bold,white,red/set errorcolor bold,white,red/' /etc/nanorc
sudo sed -i 's/^# set spotlightcolor black,orange/set spotlightcolor black,orange/' /etc/nanorc
sudo sed -i 's/^# set selectedcolor lightwhite,cyan/set selectedcolor lightwhite,cyan/' /etc/nanorc
sudo sed -i 's/^# set numbercolor magenta/set numbercolor magenta/' /etc/nanorc

# 7.4 Подключение подсветки синтаксиса
sudo sed -i 's|^# include /usr/share/nano/\*\.nanorc|include /usr/share/nano/*.nanorc|' /etc/nanorc

# 7.5 Проверка результата
grep -E "^set |^include " /etc/nanorc

# ------------------------------------------------------------------------------
# ЭТАП 8: НАСТРОЙКА ZSH И OH MY ZSH
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО]

# 8.1 Установка Zsh
sudo pacman -S --noconfirm zsh

# 8.2 Установка Oh My Zsh
export CHSH=no
export RUNZSH=no
export KEEP_ZSHRC=yes
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended

# 8.3 Установка плагинов
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions

# 8.4 Настройка темы и плагинов
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' ~/.zshrc
sed -i 's/^plugins=(.*)/plugins=(git archlinux extract zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc

# 8.5 Дополнительные настройки
echo 'ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"' >> ~/.zshrc
echo 'ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20' >> ~/.zshrc

# 8.6 Применение изменений
source ~/.zshrc

# 8.7 Смена оболочки на Zsh
chsh -s $(which zsh)

# 8.8 Добавление hyfetch в автозапуск
grep -q "hyfetch" ~/.zshrc || echo "hyfetch" >> ~/.zshrc

# ------------------------------------------------------------------------------
# ЭТАП 9: ВИРТУАЛИЗАЦИЯ VIRTUALBOX
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО]

# 9.1 Проверка версии ядра
uname -r

# 9.2 Установка VirtualBox + модуль ядра
sudo pacman -S virtualbox

# 9.3 Установка гостевых дополнений
sudo pacman -S virtualbox-guest-iso

# 9.4 Добавление пользователя в группу vboxusers
sudo gpasswd -a $USER vboxusers

# 9.5 (Опционально) Отключение уведомлений для Wayland
VBoxManage setextradata global GUI/ShowNotifications 0

# ------------------------------------------------------------------------------
# ЭТАП 10: НАСТРОЙКА ДЛЯ ИГР (LUX-WINE)
# ------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО]

# 10.1 Предварительные требования: проверка Vulkan и установка FUSE
vulkaninfo --summary 2>/dev/null | grep "deviceName"
sudo pacman -S --noconfirm fuse2

# 10.2 Установка lux-wine (с альтернативными зеркалами)
curl -sL lwrap.github.io | bash
# Альтернативы (если основной не работает):
# curl -sL lwrap.website.yandexcloud.net | bash
# curl -sL lux-wine-git.static.hf.space | sed 1d | bash

# 10.3 Перезагрузка терминала и обновление
source ~/.bashrc

# 10.4 Первый запуск и проверка
lwrun --version
lwrun -config
lwrun -winecfg

# 10.5 Управление приложениями
# lwrun -lsapp           # Список установленных игр
# lwrun -runapp "Name"   # Запустить игру из списка
# lwrun -shortcut ~/Games/MyGame/game.exe  # Создать ярлык в меню

# 10.6 Управление версиями Wine/Proton
# lwrun -winemgr         # Менеджер версий (Lutris, GE-Proton, Wine-GE)

# 10.7 Настройка графики и производительности
# - Включить MangoHud: R_Shift + F12 (показать/скрыть)
# - Включить VkBasalt: HOME (вкл/выкл пост-обработку)
# - Настроить резкость FSR: lwrun -config → Графика → FSR

# 10.8 Резервное копирование префикса игры
# lwrun -pfxbackup       # Создать бэкап
# lwrun -pfxbackup xz    # Сжатый бэкап
# lwrun -pfxrestore      # Восстановить из бэкапа

# 10.9 Полезные команды
# lwrun -killwine        # Завершить зависший Wine
# lwrun -openpfx         # Открыть диск C: префикса
# lwrun --update         # Обновить lux-wine
# lwrun --uninstall      # Полное удаление

# ------------------------------------------------------------------------------
# ЭТАП 11: ФИНАЛЬНАЯ ПРОВЕРКА СИСТЕМЫ
# ------------------------------------------------------------------------------

# 11.1 Очистка кэша пакетов
sudo pacman -Sc

# 11.2 Проверка сервисов
systemctl --user status pipewire
systemctl status ufw

# 11.3 Проверка оболочки
echo $SHELL

# 11.4 Создание финального снапшота (если Btrfs)
# sudo btrfs subvolume snapshot / /.snapshots/post-config-complete

# ==============================================================================
# КОНТРОЛЬНЫЙ СПИСОК ЗАВЕРШЕНИЯ
# ==============================================================================
# [ ] Этап 0: Резервное копирование выполнено
# [ ] Этап 1: Система обновлена
# [ ] Этап 2: UFW настроен и включен
# [ ] Этап 3: UFW настроен для сетевых устройств (принтеры, сканеры)
# [ ] Этап 4: Безопасность ядра упрочнена (kexec, core-дампы, .snapshots)
# [ ] Этап 5: Звук работает (PipeWire + alsamixer/amixer + EasyEffects + ВСЕ плагины)
# [ ] Этап 5: Pavucontrol установлен (если нужен для WM/Bluetooth)
# [ ] Этап 6: Приложения установлены
# [ ] Этап 7: Nano настроен (номера строк, табы=4, цвета, подсветка)
# [ ] Этап 8: Zsh настроен (если нужно)
# [ ] Этап 9: VirtualBox установлен (если нужен)
# [ ] Этап 10: lux-wine установлен (для игр)
# [ ] Этап 11: Финальный снапшот создан
# ==============================================================================
