#==============================================================================
# 🐧 ПОЛНЫЙ МАСТЕР-ЧЕК-ЛИСТ: НАСТРОЙКА ARCH LINUX ПОСЛЕ УСТАНОВКИ
#==============================================================================
# 📌 Пользователь: Юрий
# 📌 Формат: Все пояснения в комментариях (#), команды открыты и готовы к копированию.
# 📌 Совместимость: BTRFS + LUKS + LVM + snapper + btrfs-assistant
# 💡 Инструкция: Отмечайте [x] выполненные этапы. Команды копируйте по одной.
#==============================================================================







#------------------------------------------------------------------------------
# [ ] ЭТАП 0: РЕЗЕРВНОЕ КОПИРОВАНИЕ И БАЗОВЫЕ УТИЛИТЫ
#------------------------------------------------------------------------------
# 🎯 Зачем: Установка yay, настройка Btrfs и снапшотов.
# ⚠️ Важно: Выполняется ПОСЛЕ первой загрузки в установленную систему.
# 👤 Выполняется: От имени обычного пользователя с sudo правами.
# 💡 Примечание: Для визуальных тестов должна быть запущена графическая сессия.

# 0.1 УСТАНОВКА YAY (AUR HELPER)
# Клонируем репозиторий yay, собираем и устанавливаем пакет.
# После установки удаляем исходники для чистоты системы.
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
rm -rf yay

# 0.2 НАСТРОЙКА BTRFS И SNAPPER
# Установка официальных пакетов для работы с Btrfs и снапшотами.
sudo pacman -Syy
sudo pacman -Sy --needed --noconfirm snapper snap-pac btrfsmaintenance btrfs-assistant
# Установка дополнительных утилит из AUR (требуется yay).
yay -Syy
yay -Sy --noconfirm snapper-support snapper-tools
# Включение таймера автоматического создания снапшотов.
sudo systemctl enable --now snapper-timeline.timer

# 📌 ДЕЙСТВИЯ ПОЛЬЗОВАТЕЛЯ:
# [ ] 1. Запустите 'Btrfs Assistant' из меню приложений.
# [ ] 2. Настройте расписание снапшотов (Timeline).
# [ ] 3. При обновлении системы снапшоты будут создаваться автоматически.
# [ ] 4. В меню GRUB появятся пункты для отката (rollback).








#------------------------------------------------------------------------------
# [ ] ЭТАП 1: ДИАГНОСТИКА ВИДЕОКАРТ И ДРАЙВЕРОВ
#------------------------------------------------------------------------------
# Приоритет: [ОБЯЗАТЕЛЬНО]
# ⚠️ Важно: Выполняется ПОСЛЕ первой загрузки в установленную систему.
# 👤 Выполняется: От имени обычного пользователя с sudo правами.
# 💡 Примечание: Для визуальных тестов должна быть запущена графическая сессия!

# 1.1 ДИАГНОСТИКА (ТЕКСТОВАЯ)
# Проверка статуса драйвера NVIDIA (только для NVIDIA). Ожидаемый результат: Таблица с информацией о карте и температуре.
nvidia-smi
# Проверка поддержки Vulkan (все карты). Ожидаемый результат: Название вашей видеокарты (deviceName).
vulkaninfo --summary | grep "deviceName"
# Проверка аппаратного декодирования видео (VA-API). Ожидаемый результат: Список поддерживаемых профилей.
vainfo
# Проверка активного OpenGL рендерера. Ожидаемый результат: Строка "OpenGL renderer: ..." с названием GPU.
glxinfo | grep "OpenGL renderer"

# 1.2 ВИЗУАЛЬНЫЕ ТЕСТЫ (GUI)
# ⚠️ ВАЖНО: Выполняйте команды по одной. Закрывайте окно теста перед запуском следующего.
# Тест 1: Базовая анимация OpenGL
glxgears
# Тест 2: Vulkan-куб (Интегрированная карта)
vkcube
# Тест 3: Полный бенчмарк производительности
glmark2
# Тест 4: Экспресс-проверка дискретной карты (Гибриды). Запускает куб принудительно на GPU #1.
switcherooctl launch --gpu 1 vkcube
# Тест 5: Бенчмарк на дискретной карте
switcherooctl launch --gpu 1 glmark2
# Тест 6: Панель управления NVIDIA на дискретной карте
switcherooctl launch --gpu 1 nvidia-settings








#------------------------------------------------------------------------------
# [ ] ЭТАП 2: НАСТРОЙКА БРАНДМАУЭРА UFW
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# [ ] ЭТАП 3: НАСТРОЙКА UFW ДЛЯ СЕТЕВЫХ УСТРОЙСТВ
#------------------------------------------------------------------------------
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








#------------------------------------------------------------------------------
# [ ] ЭТАП 4: БАЗОВОЕ УПРОЧНЕНИЕ БЕЗОПАСНОСТИ
#------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО, НО РЕКОМЕНДУЕТСЯ]

# 4.1 Отключение kexec (защита от загрузки вредоносного ядра)
echo 'kernel.kexec_load_disabled=1' | sudo tee /etc/sysctl.d/50-kexec.conf
# Проверка применения
cat /etc/sysctl.d/50-kexec.conf

# 4.2 Исключение .snapshots из индексации locate
echo 'PRUNENAMES=".snapshots"' | sudo tee -a /etc/updatedb.conf
# Проверка
grep -E 'PRUNENAMES.*.snapshots' /etc/updatedb.conf

# 4.3 Запрет генерации core-дампов (предотвращение утечки памяти)
# ⚠️ Пропустите, если вы разработчик и нужны дампы для отладки
echo '* hard core 0' | sudo tee -a /etc/security/limits.conf
# Проверка
grep 'hard core 0' /etc/security/limits.conf

# 4.4 Применение всех sysctl-настроек
sudo sysctl --system
# 4.5 Проверка применения настроек
sysctl kernel.kexec_load_disabled
ulimit -c








#------------------------------------------------------------------------------
# [ ] ЭТАП 5: НАСТРОЙКА ЗВУКА (ПОЛНАЯ: ALSAMIXER + AMIXER + PIPEWIRE)
#------------------------------------------------------------------------------
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

# 5.5 НАСТРОЙКА ЗВУКА ЧЕРЕЗ ALSAMIXER (КРИТИЧНО ВАЖНО!)
# ⚠️ Эта настройка визуальная — выполняйте интерактивно!
# ✅ ИСПРАВЛЕНО: Описание отделено от команды, опечатка устранена.
# Запустить терминальный микшер
alsamixer

# 📌 ИНСТРУКЦИЯ ПО НАВИГАЦИИ В ALSAMIXER:
# F6       →  Выбрать звуковую карту (не PCH/HDMI!)
# M        →  Заглушить/разглушить канал (MM → 00)
# ↑ / ↓    →  Увеличить/уменьшить громкость
# ← / →    →  Переключиться между каналами
# Esc      →  Выйти из alsamixer

# 🔍 КАНАЛЫ, КОТОРЫЕ НУЖНО ПРОВЕРИТЬ:
# Master      — общая громкость
# PCM         — громкость воспроизведения
# Speaker     — встроенные динамики
# Headphone   — наушники
# Auto-Mute   — отключите, если звук пропадает при подключении наушников
# 📌 ВАЖНО: Если канал помечен "MM" — он заглушен! Нажмите M для разблокировки (станет "00").

# (Альтернатива) Быстрая разблокировка через командную строку:
amixer set Master unmute
amixer set Master 80%
# Проверка, что звук разблокирован
amixer get Master

# 5.6 ТЕСТ ЗВУКА
# Должны быть слышны гудки в левом и правом канале
speaker-test -c 2 -t wav

# 5.7 PAVUCONTROL — КОГДА НУЖЕН, А КОГДА НЕТ
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

# 5.8 УСТАНОВКА EASYEFFECTS СО ВСЕМИ ПЛАГИНАМИ (ПОЛНЫЙ НАБОР)
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

# 5.12 ДИАГНОСТИКА ПРОБЛЕМ СО ЗВУКОМ (СПРАВОЧНО)
# ❌ НЕТ ЗВУКА ВООБЩЕ:
# 1. Проверьте alsamixer — не стоит ли Mute (MM). Решение: Нажмите M для разблокировки
# 2. Проверьте pavucontrol — выбрано ли правильное устройство. Решение: Выберите активное устройство во вкладке "Вывод"
# 3. Проверьте статус сервисов: systemctl --user status pipewire. Решение: systemctl --user restart pipewire
# 4. Для ноутбуков Intel — проверьте sof-firmware: pacman -Q sof-firmware. Решение: sudo pacman -S sof-firmware
# ❌ ЗВУК ТИХИЙ:
# 1. Проверьте все уровни в alsamixer. Решение: amixer set Master 100%
# 2. В EasyEffects добавьте Maximizer: Threshold: -6 dB, Ceiling: -1 dB
# ❌ МИКРОФОН НЕ РАБОТАЕТ:
# 1. В pavucontrol → "Запись" → выберите правильный микрофон
# 2. Добавьте Noise Reduction в EasyEffects
# ❌ BLUETOOTH ПОДКЛЮЧАЕТСЯ, НО НЕТ ЗВУКА:
# 1. В pavucontrol выберите профиль A2DP (не HSP!)
# 2. Перезапустите Bluetooth: sudo systemctl restart bluetooth
# ❌ ТРЕЩИТ ИЛИ ПРЕРЫВАЕТСЯ ЗВУК:
# 1. Увеличьте квант PipeWire: quantum = 1024 вместо 512
# 2. Отключите тяжёлые плагины в EasyEffects
# 3. Проверьте нагрузку на CPU: htop








#------------------------------------------------------------------------------
# [ ] ЭТАП 6: УСТАНОВКА ПРИЛОЖЕНИЙ
#------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО]
# ✅ ИСПРАВЛЕНО: Все описания закомментированы и отделены от команд.

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








#------------------------------------------------------------------------------
# [ ] ЭТАП 7: НАСТРОЙКА РЕДАКТОРА NANO
#------------------------------------------------------------------------------
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
sudo sed -i 's|^# include /usr/share/nano/.nanorc|include /usr/share/nano/.nanorc|' /etc/nanorc
# 7.5 Проверка результата
grep -E "^set |^include " /etc/nanorc








#------------------------------------------------------------------------------
# [ ] ЭТАП 8: НАСТРОЙКА ZSH И OH MY ZSH
#------------------------------------------------------------------------------
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
sed -i 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc
sed -i 's/^plugins=(.)/plugins=(git archlinux extract zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc
# 8.5 Дополнительные настройки
echo 'ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"' >> ~/.zshrc
echo 'ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20' >> ~/.zshrc
# 8.6 Применение изменений
source ~/.zshrc
# 8.7 Смена оболочки на Zsh
chsh -s $(which zsh)
# 8.8 Добавление hyfetch в автозапуск
grep -q "hyfetch" ~/.zshrc || echo "hyfetch" >> ~/.zshrc








#------------------------------------------------------------------------------
# [ ] ЭТАП 9: НАСТРОЙКА ТЕМЫ GRUB
#------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО]
# ⚙️ Установка
git clone --depth 1 https://github.com/VandalByte/darkmatter-grub2-theme.git && cd darkmatter-grub2-theme
sudo python3 darkmatter-theme.py --install
# ❌ Удаление
# sudo python3 darkmatter-theme.py --uninstall








#------------------------------------------------------------------------------
# [ ] ЭТАП 10: ВИРТУАЛИЗАЦИЯ VIRTUALBOX
#------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО]

# 10.1 Проверка версии ядра
uname -r
# 10.2 Установка VirtualBox + модуль ядра
sudo pacman -S virtualbox
# 10.3 Установка гостевых дополнений
sudo pacman -S virtualbox-guest-iso
# 10.4 Добавление пользователя в группу vboxusers
sudo gpasswd -a $USER vboxusers
# 10.5 (Опционально) Отключение уведомлений для Wayland
VBoxManage setextradata global GUI/ShowNotifications 0








#------------------------------------------------------------------------------
# [ ] ЭТАП 11: НАСТРОЙКА ДЛЯ ИГР (LUX-WINE)
#------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО]

# 11.1 Предварительные требования: проверка Vulkan и установка FUSE
vulkaninfo --summary 2>/dev/null | grep "deviceName"
sudo pacman -S --noconfirm fuse2
# 11.2 Установка lux-wine (с альтернативными зеркалами)
curl -sL lwrap.github.io | bash
# Альтернативы (если основной не работает):
# curl -sL lwrap.website.yandexcloud.net | bash
# curl -sL lux-wine-git.static.hf.space | sed 1d | bash
# 11.3 Перезагрузка терминала и обновление
source ~/.bashrc
# 11.4 Первый запуск и проверка
lwrun --version
lwrun -config
lwrun -winecfg
# 11.5 Управление приложениями
lwrun -lsapp           # Список установленных игр
lwrun -runapp "Name"   # Запустить игру из списка
lwrun -shortcut ~/Games/MyGame/game.exe  # Создать ярлык в меню
# 11.6 Управление версиями Wine/Proton
lwrun -winemgr         # Менеджер версий (Lutris, GE-Proton, Wine-GE)
# 11.7 Настройка графики и производительности
# - Включить MangoHud: R_Shift + F12 (показать/скрыть)
# - Включить VkBasalt: HOME (вкл/выкл пост-обработку)
# - Настроить резкость FSR: lwrun -config → Графика → FSR
# 11.8 Резервное копирование префикса игры
lwrun -pfxbackup       # Создать бэкап
lwrun -pfxbackup xz    # Сжатый бэкап
lwrun -pfxrestore      # Восстановить из бэкапа
# 11.9 Полезные команды
lwrun -killwine        # Завершить зависший Wine
lwrun -openpfx         # Открыть диск C: префикса
lwrun --update         # Обновить lux-wine
lwrun --uninstall      # Полное удаление








#------------------------------------------------------------------------------
# [ ] ЭТАП 12: ЭНЕРГОСБЕРЕЖЕНИЕ И ОПТИМИЗАЦИЯ ПАМЯТИ
#------------------------------------------------------------------------------
# Приоритет: [РЕКОМЕНДУЕТСЯ ДЛЯ НОУТБУКОВ И ГИБРИДНОЙ ГРАФИКИ]
# 💡 Включает: TLP для управления питанием, ZRAM для сжатия памяти.
# ⚠️ Важно: TLP и ZRAM улучшают автономность и предотвращают фризы при нехватке RAM.
# 📌 Примечание: Для стационарных ПК можно пропустить TLP, но ZRAM полезен всегда.

# 12.1 УСТАНОВКА TLP (УПРАВЛЕНИЕ ПИТАНИЕМ)
# Установка TLP и утилит для мониторинга батареи.
sudo pacman -S --needed --noconfirm tlp tlp-rdw tlpui smartmontools
# Включение службы TLP.
sudo systemctl enable --now tlp.service
# Проверка статуса TLP. Ожидаемый результат: "TLP status: enabled"
sudo tlp-stat -s

# 12.2 НАСТРОЙКА ZRAM (СЖАТАЯ ПАМЯТЬ)
# Установка генератора ZRAM.
sudo pacman -S --needed --noconfirm zram-generator
# Создание конфигурации ZRAM с алгоритмом LZ4 (быстрый и эффективный).
sudo mkdir -p /etc/systemd/zram-generator.conf.d
echo -e "[zram0]\nzram-size = min(ram, 8192)\ncompression-algorithm = lz4" | sudo tee /etc/systemd/zram-generator.conf.d/zram.conf
# Применение настроек и запуск ZRAM.
sudo systemctl daemon-reload
sudo systemctl start systemd-zram-setup@zram0.service
# Проверка работы ZRAM. Ожидаемый результат: строка с /dev/zram0 и алгоритмом lz4.
zramctl








#------------------------------------------------------------------------------
# [ ] ЭТАП 13: НАСТРОЙКА ГЕОЛОКАЦИИ
#------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО]
# 💡 Включает: Geoclue для определения местоположения в приложениях.
# 📌 Примечание: Требуется для корректной работы часовых поясов, погоды и карт.

# Установка службы геолокации.
sudo pacman -S --needed --noconfirm geoclue
# Настройка доступа для приложений. ✅ ИСПРАВЛЕНО: Используется корректный паттерн ^[wifi] для поиска секции.
sudo sed -i '/^[wifi]/a url=https://api.ipapi.com/api/geo' /etc/geoclue/geoclue.conf
# Перезапуск службы.
sudo systemctl restart geoclue
# Проверка статуса. Ожидаемый результат: "active (running)"
systemctl status geoclue








#------------------------------------------------------------------------------
# [ ] ЭТАП 14: ФИНАЛЬНАЯ ПРОВЕРКА СИСТЕМЫ
#------------------------------------------------------------------------------
# Приоритет: [ЗАВЕРШАЮЩИЙ]
# 💡 Выполняется после завершения всех настроек.
# 📌 Включает: Очистку кэша, проверку сервисов, создание финального снапшота.

# 14.1 ОЧИСТКА КЭША ПАКЕТОВ
# Удаление кэша старых версий пакетов для экономии места.
sudo pacman -Sc

# 14.2 ПРОВЕРКА КРИТИЧЕСКИХ СЕРВИСОВ
# Проверка статуса PipeWire (аудио). Ожидаемый результат: "active (running)"
systemctl --user status pipewire
# Проверка статуса брандмауэра. Ожидаемый результат: "active (running)"
systemctl status ufw

# 14.3 ПРОВЕРКА ОБОЛОЧКИ
# Проверка текущей оболочки пользователя. Ожидаемый результат: /bin/zsh или /bin/bash
echo $SHELL

# 14.4 СОЗДАНИЕ ФИНАЛЬНОГО СНЭПШОТА
# Создание точки восстановления после полной настройки системы.
# Позволяет быстро откатиться к "чистому" настроенному состоянию.
sudo btrfs subvolume snapshot / /.snapshots/post-config-complete
# Проверка создания снапшота. Ожидаемый результат: в списке присутствует "post-config-complete"
sudo btrfs subvolume list /

#------------------------------------------------------------------------------
# ✅ КОНТРОЛЬНЫЙ СПИСОК ЗАВЕРШЕНИЯ
#------------------------------------------------------------------------------
# [ ] Этап 0: Резервное копирование и Btrfs настроены
# [ ] Этап 1: Диагностика видеокарт выполнена
# [ ] Этап 2: UFW настроен и включен
# [ ] Этап 3: UFW настроен для сетевых устройств (принтеры, сканеры)
# [ ] Этап 4: Безопасность ядра упрочнена (kexec, core-дампы, .snapshots)
# [ ] Этап 5: Звук работает (PipeWire + alsamixer + EasyEffects)
# [ ] Этап 6: Приложения установлены
# [ ] Этап 7: Nano настроен
# [ ] Этап 8: Zsh настроен (если нужно)
# [ ] Этап 9: Тема GRUB установлена (если нужно)
# [ ] Этап 10: VirtualBox установлен (если нужно)
# [ ] Этап 11: lux-wine установлен (если нужно)
# [ ] Этап 12: Энергосбережение и ZRAM настроены
# [ ] Этап 13: Геолокация настроена
# [ ] Этап 14: Финальная проверка выполнена, снапшот создан
#==============================================================================
# 🎉 Система полностью настроена и готова к работе.
# 📌 Рекомендуется перезагрузить компьютер для применения всех изменений.
#==============================================================================
