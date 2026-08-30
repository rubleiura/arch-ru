#==============================================================================
# 🐧 ПОЛНЫЙ МАСТЕР-ЧЕК-ЛИСТ: НАСТРОЙКА ARCH LINUX ПОСЛЕ УСТАНОВКИ
#==============================================================================
# 📌 Пользователь: Юрий
# 📌 Формат: Все пояснения в комментариях (#), команды открыты и готовы к копированию.
# 📌 Совместимость: BTRFS + LUKS + LVM + snapper + btrfs-assistant
# 💡 Инструкция: Отмечайте [x] выполненные этапы. Команды копируйте по одной.
#==============================================================================







################################################################################
# [ ] ЭТАП 0: РЕЗЕРВНОЕ КОПИРОВАНИЕ И БАЗОВЫЕ УТИЛИТЫ
################################################################################
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

# 0.3 Приоритет: [ОБЯЗАТЕЛЬНО ДЛЯ SSD]
# ⚠️ Важно: Выполняется ПОСЛЕ первой загрузки в установленную систему.
# Включить еженедельную очистку SSD (TRIM) для сохранения скорости диска
sudo systemctl enable fstrim.timer








################################################################################
# [ ] ЭТАП 1: УСТАНОВКА ВИДЕО-ДРАЙВЕРОВ
################################################################################
# 🎯 Зачем: Установка видео-драйверов на чистую систему с базовыми драйверами.
# ⚠️ Важно: Выполняется ПОСЛЕ первой загрузки в установленную систему.
# 1.1 chwd-arch-git — Утилита сканирует компоненты вашего компьютера и определяет правильные драйверы.
yay -S --noconfirm chwd-arch-git
# 1.2 Установка видео-драйверов
# Пример:
# Проверяем необходимую конфигурацию компьютера:
chwd --list
# forename@MAIBENBEN  ~  chwd --list
# > 0000:06:00.0 (0300:1002:1681) VGA compatible controller Advanced Micro Devices, Inc. [AMD/ATI]:

# ╭──────────┬───────────╮
# │ Имя      ┆ Приоритет │
# ╞══════════╪═══════════╡
# │ amd      ┆ 4         │
# ├╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌┤
# │ fallback ┆ 3         │
# ╰──────────┴───────────╯

# > 0000:01:00.0 (0300:10de:25a2) VGA compatible controller NVIDIA Corporation:

# ╭────────────────────────┬───────────╮
# │ Имя                    ┆ Приоритет │
# ╞════════════════════════╪═══════════╡
# │ nvidia-open-dkms.prime ┆ 11        │ Для компьютеров с гибридной графикой
# ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌┤
# │ nvidia-open-dkms       ┆ 10        │ Для компьютеров с единственной видео картой NVIDIA
# ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌┤
# │ fallback               ┆ 3         │
# ╰────────────────────────┴───────────╯

# forename@MAIBENBEN  ~ 

# В данной проверке выявилась гибридая графика AMD/NVIDIA компьютера
# Установка видео драйверов при данном результате:
sudo chwd --install amd
sudo chwd --install nvidia-open-dkms.prime

# После установки проверяем:
chwd --list-installed
# Пример:

# forename@MAIBENBEN  ~  chwd --list-installed
# > Установленные профили:

# ╭────────────────────────┬───────────╮
# │ Имя                    ┆ Приоритет │
# ╞════════════════════════╪═══════════╡
# │ nvidia-open-dkms.prime ┆ 11        │
# ├╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌╌┼╌╌╌╌╌╌╌╌╌╌╌┤
# │ amd                    ┆ 4         │
# ╰────────────────────────┴───────────╯

#  forename@MAIBENBEN  ~ 
# Все необходимые видео драйвера установлены!!!!
# Обязательное действие(ПЕРЕЗАГРУЗКА)
reboot

# 1.3 НАСТРОЙКА ГИБЕРНАЦИИ В КОМПЬЮТЕРАХ С NVIDIA
# ⚠️ Важно помнить, настройка гибернации на компьютерах с NVIDIA сложный вопрос.
# Каждый компьютер требует свой подход и настройки
# ⚠️ ИНСТРУКЦИЯ:
# ❗ Правильный выбор вариантов зависит от конфигурации компьютера
# ✅ Вариант А - Компьютеры с единственной видеокартой (NVIDIA dGPU)
# ✅ Вариант Б - Компьютеры с двумя видеокартами (Intel/AMD iGPU + NVIDIA dGPU)
# • Удалите символ # только перед командами, которые нужно выполнить
# • Удалите не нужный вариант, что-бы не было путаницы и ошибок
# ⚠️ Важно: Выполняется с правами администратора
sudo su

#------------------------------------------------------------------------------
# >>> [ВАРИАНТ А] NVIDIA (ОДИНОЧНАЯ, ДЕСКТОП / ПК) <<<
#------------------------------------------------------------------------------

# --- Настройки ядра и модулей (ТОЛЬКО ДЛЯ ОДИНОЧНОЙ NVIDIA) ---
# 📋 1. Добавить параметр ядра nvidia-drm.modeset=1 в GRUB (обязательно для Wayland)
# sed -i -E 's/^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"/\1 nvidia-drm.modeset=1"/' /etc/default/grub
#
# 📋 2. Конфигурация модулей (modprobe) для сохранения VRAM при сне/гибернации
# echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia.conf
# echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" >> /etc/modprobe.d/nvidia.conf
# echo "options nvidia NVreg_TemporaryFilePath=/var/tmp" >> /etc/modprobe.d/nvidia.conf
#
# 📋 3. Включение системных служб управления сном/гибернацией (обязательно для ПК)
# systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service
#
# 📋 4. Пересобрать initramfs и обновить GRUB
# mkinitcpio -P
# grub-mkconfig -o /boot/grub/grub.cfg
#------------------------------------------------------------------------------
# >>> [ВАРИАНТ Б] ГИБРИДНАЯ ГРАФИКА (Intel/AMD iGPU + NVIDIA dGPU) <<<
#------------------------------------------------------------------------------

# 📋 1. Настройка параметров ядра (GRUB) – ОБЯЗАТЕЛЬНО ДЛЯ ГИБРИДА!
# Добавляем:
#   - nvidia-drm.modeset=1 (обязательно для Wayland и корректного переключения видеорежимов)
#   - nvidia.NVreg_PreserveVideoMemoryAllocations=0 (предотвращает kernel panic при пробуждении,
#     запрещая драйверу сохранять состояние VRAM, так как dGPU на ноутбуке обесточивается)
#   - resume_offset=0 (критически важен, если используется Swap-файл на BTRFS; безвреден для Swap-раздела)
# sed -i -E 's/^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"/\1 nvidia-drm.modeset=1 nvidia.NVreg_PreserveVideoMemoryAllocations=0 resume_offset=0"/' /etc/default/grub

# 📋 2. Добавление модуля nvme в initramfs (КРИТИЧНО ДЛЯ ГИБЕРНАЦИИ НА NVME)
# Добавляет nvme к уже существующим модулям (например, btrfs) для корректного пробуждения.
# sed -i "s/^MODULES=(\(.*\))/MODULES=(\1 nvme)/" /etc/mkinitcpio.conf

# 📋 3. Пересборка initramfs и обновление GRUB
# mkinitcpio -P
# grub-mkconfig -o /boot/grub/grub.cfg

# Обязательное действие(ПЕРЕЗАГРУЗКА)
# reboot






################################################################################
# [ ] ЭТАП 2: ДИАГНОСТИКА ВИДЕОКАРТ И ДРАЙВЕРОВ
################################################################################
# Приоритет: [ОБЯЗАТЕЛЬНО]
# ⚠️ Важно: Выполняется ПОСЛЕ первой загрузки в установленную систему.
# 👤 Выполняется: От имени обычного пользователя с sudo правами.
# 💡 Примечание: Для визуальных тестов должна быть запущена графическая сессия!

#------------------------------------------------------------------------------
# ПАКЕТЫ ДЛЯ ТЕСТИРОВАНИЯ
#------------------------------------------------------------------------------
# 📦 vulkan-tools    : Утилита vulkaninfo для диагностики Vulkan.
# 📦 libva-utils     : Утилита vainfo для проверки видео-ускорения (VA-API).
# 📦 mesa-utils      : Утилита glxinfo для проверки OpenGL.
# 📦 glmark2         : Бенчмарк производительности графики.
sudo pacman -Sy --noconfirm vulkan-tools libva-utils mesa-utils glmark2
# Обязательное действие(ПЕРЕЗАГРУЗКА)
reboot

#------------------------------------------------------------------------------
# 2.1 ДИАГНОСТИКА (ТЕКСТОВАЯ)
#------------------------------------------------------------------------------
# Проверка статуса драйвера NVIDIA (только для NVIDIA). Ожидаемый результат: Таблица с информацией о карте и температуре.
nvidia-smi
# Проверка поддержки Vulkan (все карты). Ожидаемый результат: Название вашей видеокарты (deviceName).
vulkaninfo --summary | grep "deviceName"
# Проверка аппаратного декодирования видео (VA-API). Ожидаемый результат: Список поддерживаемых профилей.
vainfo
# Проверка активного OpenGL рендерера. Ожидаемый результат: Строка "OpenGL renderer: ..." с названием GPU.
glxinfo | grep "OpenGL renderer"

#------------------------------------------------------------------------------
# 2.2 ВИЗУАЛЬНЫЕ ТЕСТЫ (GUI)
#------------------------------------------------------------------------------
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
# Тест 6: Бенчмарки UNIGINE
# Эффективно используются для определения стабильности работы аппаратного обеспечения ПК (процессора, видеокарты, блока питания, системы охлаждения) в условиях экстремальных нагрузок, а также для разгона.
# Ссылка для скачивания приложений UNIGINE для теста:
https://benchmark.unigine.com/







################################################################################
# [ ] ЭТАП 3: НАСТРОЙКА БРАНДМАУЭРА UFW
################################################################################
# Приоритет: [ОБЯЗАТЕЛЬНО]
# ⚠️ ВНИМАНИЕ: Настройте правила ДО включения фаервола!

# 3.1 Установка UFW и графической оболочки
sudo pacman -S --noconfirm ufw gufw ufw-extras
# 3.2 Проверка текущего статуса
sudo ufw status
# 3.3 (Опционально) Отключение конфликтующих фаерволов
sudo systemctl stop iptables 2>/dev/null; sudo systemctl disable iptables 2>/dev/null
sudo systemctl stop nftables 2>/dev/null; sudo systemctl disable nftables 2>/dev/null
# 3.4 Установка политик по умолчанию
sudo ufw default deny incoming
sudo ufw default allow outgoing

# 3.5 ⚠️ РАЗРЕШЕНИЕ ДОСТУПА (ВЫПОЛНИТЬ ПЕРЕД ВКЛЮЧЕНИЕМ!) ⚠️
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

# 3.6 Проверка правил перед включением
sudo ufw status verbose
# 3.7 Включение брандмауэра
sudo ufw enable
# 3.8 Добавление в автозагрузку
sudo systemctl enable ufw
sudo systemctl start ufw
# 3.9 Включение логирования
sudo ufw logging on

################################################################################
# [ ] ЭТАП 4: НАСТРОЙКА UFW ДЛЯ СЕТЕВЫХ УСТРОЙСТВ
################################################################################
# Приоритет: [ОПЦИОНАЛЬНО] — если есть принтеры, сканеры, МФУ в сети

# 4.1 mDNS (Bonjour/Avahi) — для автообнаружения принтеров (порт 5353/udp)
sudo ufw allow from 192.168.1.0/24 to any port 5353 proto udp comment "mDNS discovery"
# 4.2 SSDP (UPnP) — для обнаружения устройств (порт 1900/udp)
sudo ufw allow from 192.168.1.0/24 to any port 1900 proto udp comment "SSDP/UPnP"
# 4.3 LLMNR — альтернатива mDNS (порт 5355/udp)
sudo ufw allow from 192.168.1.0/24 to any port 5355 proto udp comment "LLMNR"
# 4.4 IPP (Internet Printing Protocol) — современная печать (порт 631/tcp)
sudo ufw allow from 192.168.1.0/24 to any port 631 proto tcp comment "IPP printing"
# 4.5 RAW printing — прямой доступ к принтеру (порт 9100/tcp)
sudo ufw allow from 192.168.1.0/24 to any port 9100 proto tcp comment "RAW printing"
# 4.6 SANE network scanning — стандарт для сканеров (порт 6566/tcp)
sudo ufw allow from 192.168.1.0/24 to any port 6566 proto tcp comment "SANE scanning"
# 4.7 SMB/CIFS для доступа к общим папкам (порты 137-139, 445)
sudo ufw allow from 192.168.1.0/24 to any port 137:139 proto udp comment "NetBIOS datagram"
sudo ufw allow from 192.168.1.0/24 to any port 137:139 proto tcp comment "NetBIOS session"
sudo ufw allow from 192.168.1.0/24 to any port 445 proto tcp comment "SMB file sharing"
# 4.8 Проверка всех правил UFW
sudo ufw status verbose
# 4.9 (Опционально) Настройка SANE для сетевого сканирования
echo "192.168.1.0/24" | sudo tee -a /etc/sane.d/net.conf
# 4.10 Перезапуск службы обнаружения
systemctl restart avahi-daemon








################################################################################
# [ ] ЭТАП 5: БАЗОВОЕ УПРОЧНЕНИЕ БЕЗОПАСНОСТИ
################################################################################
# Приоритет: [ОПЦИОНАЛЬНО, НО РЕКОМЕНДУЕТСЯ]

# 5.1 Отключение kexec (защита от загрузки вредоносного ядра)
echo 'kernel.kexec_load_disabled=1' | sudo tee /etc/sysctl.d/50-kexec.conf
# Проверка применения
cat /etc/sysctl.d/50-kexec.conf

# 5.2 Исключение .snapshots из индексации locate
echo 'PRUNENAMES=".snapshots"' | sudo tee -a /etc/updatedb.conf
# Проверка
grep -E 'PRUNENAMES.*.snapshots' /etc/updatedb.conf

# 5.3 Запрет генерации core-дампов (предотвращение утечки памяти)
# ⚠️ Пропустите, если вы разработчик и нужны дампы для отладки
echo '* hard core 0' | sudo tee -a /etc/security/limits.conf
# Проверка
grep 'hard core 0' /etc/security/limits.conf

# 5.4 Применение всех sysctl-настроек
sudo sysctl --system
# 5.5 Проверка применения настроек
sysctl kernel.kexec_load_disabled
ulimit -c








################################################################################
# [ ] ЭТАП 6: НАСТРОЙКА ЗВУКА (ПОЛНАЯ: ALSAMIXER + AMIXER + PIPEWIRE)
################################################################################
# Приоритет: [ОБЯЗАТЕЛЬНО]
# ⚠️ Звук часто заглушен (Muted) после установки — это нормально!

# 6.1 Установка всех пакетов PipeWire
sudo pacman -S --needed --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber sof-firmware alsa-ucm-conf alsa-utils
# 6.2 Включение сервисов (от имени пользователя, НЕ root!)
systemctl --user enable --now pipewire pipewire-pulse wireplumber
# 6.3 Проверка статуса
systemctl --user status pipewire
systemctl --user status wireplumber
# 6.4 Проверка, что PipeWire заменил PulseAudio
pactl info | grep "Server Name"
# Должно быть: PipeWire PulseAudio

# 6.5 НАСТРОЙКА ЗВУКА ЧЕРЕЗ ALSAMIXER (КРИТИЧНО ВАЖНО!)
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

# 6.6 ТЕСТ ЗВУКА
# Должны быть слышны гудки в левом и правом канале
speaker-test -c 2 -t wav

# 6.7 PAVUCONTROL — КОГДА НУЖЕН, А КОГДА НЕТ
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

# 6.8 УСТАНОВКА EASYEFFECTS СО ВСЕМИ ПЛАГИНАМИ (ПОЛНЫЙ НАБОР)
# Важно: Установка ВСЕХ плагинов предотвращает появление "серых" неактивных пунктов
sudo pacman -S --needed --noconfirm easyeffects calf lsp-plugins-lv2 zam-plugins-lv2 mda.lv2 yelp
# 6.9 Автоматическая установка пресетов (JackHack96)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/install.sh)"
# 6.10 Проверка установленных пресетов
ls -la ~/.local/share/easyeffects/output/
ls -la ~/.local/share/easyeffects/input/
# 6.11 (Опционально) Оптимизация для игр (низкая задержка)
mkdir -p ~/.config/pipewire/pipewire.conf.d
echo "context.properties = { default.clock.quantum = 512 default.clock.min-quantum = 256 }" > ~/.config/pipewire/pipewire.conf.d/99-low-latency.conf
systemctl --user restart pipewire

# 6.12 ДИАГНОСТИКА ПРОБЛЕМ СО ЗВУКОМ (СПРАВОЧНО)
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








# ################################################################################
# # [ ] ЭТАП 7: УСТАНОВКА ПРИЛОЖЕНИЙ
# ################################################################################
# Приоритет: [ОПЦИОНАЛЬНО]
# ✅ ИСПРАВЛЕНО: Все описания закомментированы и отделены от команд.
# 7.1 Базовые утилиты
clear
sudo pacman -Syy
sudo pacman -S --noconfirm doublecmd-qt6 vlc vlc-plugins-all htop cpu-x gparted qbittorrent libreoffice-still-ru hardinfo2 inxi btop
# 7.2 Включение сервиса hardinfo2
sudo systemctl enable --now hardinfo2.service
# 7.3 Загрузка модулей для датчиков
sudo modprobe -a at24 ee1004 spd5118
# 7.4 Добавление пользователя в группу hardinfo2
sudo usermod -aG hardinfo2 $USER
# 7.5 (Опционально) AUR-помощники и утилиты
yay -S --noconfirm pamac-aur ventoy-bin stacer-bin system-monitoring-center
# 7.6 (Опционально) Темы и настройки загрузчика — ОСТОРОЖНО!
# #------------------------------------------------------------------------------
# # 🎨 УСТАНОВКА И НАСТРОЙКА ТЕМЫ GRUB ARCH-LEAP
# #------------------------------------------------------------------------------
# 🔧 ШАГ 1: Установка пакетов
yay -S --noconfirm grub-customizer grub2-theme-arch-leap update-grub

# 🔧 ШАГ 2: Проверка установки темы
# Тема устанавливается в директорию /boot/grub/themes/arch-leap
ls -la /boot/grub/themes/arch-leap/theme.txt

# 🔧 ШАГ 3: Активация темы GRUB
sudo nano /etc/default/grub
#
# Найдите строку (или добавьте, если отсутствует) и раскомментируйте (уберите #):
GRUB_THEME="/boot/grub/themes/arch-leap/theme.txt"
#
# 💡 ДОПОЛНИТЕЛЬНЫЕ ПАРАМЕТРЫ (рекомендуется проверить):
# Разрешение экрана для графического меню GRUB (укажите ваше разрешение)
GRUB_GFXMODE=1920x1080,1024x768,auto
# Сохранение разрешения для загрузки Linux
GRUB_GFXPAYLOAD_LINUX=keep

# 🔧 ШАГ 4: Обновление конфигурации GRUB
# После редактирования /etc/default/grub ОБЯЗАТЕЛЬНО обновите grub.cfg
sudo grub-mkconfig -o /boot/grub/grub.cfg
#
# ✅ ОЖИДАЕМЫЙ ВЫВОД (ищите строку):
# Found theme: /boot/grub/themes/arch-leap/theme.txt
#
# ⚠️ ВОЗМОЖНЫЕ ПРОБЛЕМЫ И РЕШЕНИЯ:
# ❌ ПРОБЛЕМА 1: Тема не отображается после перезагрузки
# ✅ Решение: Проверьте, что в /etc/default/grub НЕТ символа # перед GRUB_THEME.
# Проверьте путь: ls /boot/grub/themes/
#
# ❌ ПРОБЛЕМА 2: Чёрный экран вместо темы
# ✅ Решение: Проверьте GRUB_GFXMODE в /etc/default/grub.
# Попробуйте установить конкретное разрешение: GRUB_GFXMODE=1920x1080
# Добавьте: GRUB_GFXPAYLOAD_LINUX=keep

# 🔧 ШАГ 5: Перезагрузка
reboot






################################################################################
# [ ] ЭТАП 8: НАСТРОЙКА РЕДАКТОРА NANO
################################################################################
# Приоритет: [ОПЦИОНАЛЬНО]

# ==============================================================================
# ШАГ 1: БЕЗОПАСНОСТЬ (Резервные копии)
# ==============================================================================
# 💾 Создание резервных копий
sudo cp /etc/nanorc /etc/nanorc.backup_$(date +%F) 2>/dev/null || true
cp ~/.nanorc ~/.nanorc.backup_$(date +%F) 2>/dev/null || true

# ==============================================================================
# ШАГ 2: СИСТЕМНЫЙ ФАЙЛ (/etc/nanorc)
# ==============================================================================
# ⚙️ Обновление системного файла /etc/nanorc..."
sudo tee /etc/nanorc > /dev/null << 'SYSEOF'
# Базовые настройки для всех пользователей системы (nano 9.0)
# ВАЖНО: В nano 9.0 комментарии (#) пишутся ТОЛЬКО с начала новой строки!

set mouse
set linenumbers
set tabsize 4
set softwrap
set regexp
set historylog
set backup
set autoindent
set smarthome

# Подключаем стандартные синтаксисы, встроенные в CachyOS/Arch
include /usr/share/nano/*.nanorc
SYSEOF

# ==============================================================================
# ШАГ 3: ПОЛЬЗОВАТЕЛЬСКИЙ ФАЙЛ (~/.nanorc)
# ==============================================================================
# 🎨 Создание красочного пользовательского файла ~/.nanorc
cat << 'USEREOF' > ~/.nanorc
# ============================================================================
# КОНФИГУРАЦИЯ GNU nano 9.0 (CachyOS)
# Автор: rublev (Юрий)
# ============================================================================
#
# ⚠️ ПРАВИЛА nano 9.0 (ЗАПОМНИТЕ ПЕРЕД РЕДАКТИРОВАНИЕМ):
# 1. Комментарии (#) пишутся ТОЛЬКО с начала новой строки.
#    НЕЛЬЗЯ: set mouse  # комментарий  <-- вызовет ошибку!
# 2. УСТАРЕВШИЕ опции (удалены в nano 9.0): ruler, suspend, smooth, zap.
# 3. Директива «color» ОБЯЗАТЕЛЬНО должна быть внутри «syntax» или «extendsyntax».
# 4. matchbrackets требует аргумент: set matchbrackets "(<[{)>]}"
# ============================================================================

# --- РАЗДЕЛ 1: ЭРГОНОМИКА И ИНТЕРФЕЙС ---
set mouse                 # Поддержка мыши (клик, выделение, прокрутка)
set linenumbers           # Номера строк слева
set tabsize 4             # Размер табуляции (современный стандарт)
set softwrap              # Мягкий перенос длинных строк (не ломает файл)
set regexp                # Расширенные регулярные выражения в поиске (Ctrl+W)
set historylog            # Сохранять историю поиска между сессиями
set backup                # Создавать резервные копии файлов с суффиксом ~
set autoindent            # Сохранять отступ при переходе на новую строку
set smarthome             # Клавиша Home ведёт к первому непробельному символу
set multibuffer           # Разрешить открытие нескольких файлов (Ctrl+R -> Ctrl+T)
set nonewlines            # Не добавлять пустую строку в конец файла при сохранении
set nohelp                # Скрыть нижнюю панель подсказок (экономит 2 строки экрана)
set matchbrackets "(<[{)>]}"  # Подсвечивать парные скобки

# --- РАЗДЕЛ 2: КРАСОЧНАЯ ТЕМА (через extendsyntax) ---
# Формат: extendsyntax <имя_языка> color <цвет_текста>,<цвет_фона> "<регулярное_выражение>"
# Доступные цвета: red, green, blue, magenta, cyan, yellow, white, black
# Доступные атрибуты: bold, italic, dim, underline, blink, reverse

# PYTHON
extendsyntax python color brightmagenta,black "(^|[[:space:]])#.*$"
extendsyntax python color brightgreen,black "\"(\\.|[^\"])*\""
extendsyntax python color brightgreen,black "'(\\.|[^'])*'"
extendsyntax python color brightyellow,black "\b[0-9]+\b"
extendsyntax python color bold,brightcyan,black "\b(def|class|import|from|as|try|except|finally|with|yield|return|if|elif|else|for|while|in|lambda|and|or|not|True|False|None)\b"

# SHELL / BASH
extendsyntax sh color brightmagenta,black "(^|[[:space:]])#.*$"
extendsyntax sh color brightgreen,black "\"(\\.|[^\"])*\""
extendsyntax sh color brightyellow,black "\b[0-9]+\b"
extendsyntax sh color bold,brightcyan,black "\b(if|then|else|elif|fi|for|while|do|done|case|esac|function|return|local|echo|exit|export)\b"

# C / C++
extendsyntax c color brightmagenta,black "(^|[[:space:]])//.*$"
extendsyntax c color brightmagenta,black "/\*.*\*/"
extendsyntax c color brightgreen,black "\"(\\.|[^\"])*\""
extendsyntax c color brightyellow,black "\b[0-9]+\b"
extendsyntax c color bold,brightcyan,black "\b(if|else|for|while|do|return|int|char|float|double|void|struct|typedef|class|public|private|protected|namespace|include|define)\b"

# HTML / XML
extendsyntax html color brightblue,black "<[a-zA-Z0-9_\-]+[^>]*>"
extendsyntax html color brightmagenta,black "</[a-zA-Z0-9_\-]+>"
extendsyntax html color brightgreen,black "\"(\\.|[^\"])*\""

# SQL
extendsyntax sql color bold,brightmagenta,black "\b(SELECT|FROM|WHERE|INSERT|UPDATE|DELETE|JOIN|CREATE|TABLE|INTO|VALUES|SET|DROP|ALTER|INDEX|GROUP|BY|ORDER|HAVING|LIMIT)\b"
extendsyntax sql color brightgreen,black "'(\\.|[^'])*'"
extendsyntax sql color brightyellow,black "\b[0-9]+\b"

# JSON
extendsyntax json color brightblue,black "\"(\\.|[^\"])*\"\s*:"
extendsyntax json color brightgreen,black ":\s*\"(\\.|[^\"])*\""
extendsyntax json color brightyellow,black "\b[0-9]+\b"
extendsyntax json color bold,brightcyan,black "\b(true|false|null)\b"

# MARKDOWN
extendsyntax markdown color bold,brightyellow,black "^#{1,6}\s+.*$"
extendsyntax markdown color brightmagenta,black "\*\*[^*]+\*\*"
extendsyntax markdown color brightgreen,black "\*[^*]+\*"
extendsyntax markdown color brightblue,black "`[^`]+`"
extendsyntax markdown color underline,brightcyan,black "\[[^]]+\]\([^)]+\)"

# --- РАЗДЕЛ 3: УНИВЕРСАЛЬНАЯ ПОДСВЕТКА ДЛЯ СИСТЕМНЫХ ФАЙЛОВ ---
# Решает проблему файлов без расширений (grub, fstab, hosts, environment и т.д.)
syntax "system_configs" "^/etc/.*|/etc/hosts$|/etc/fstab$|/etc/environment$|/etc/locale.gen$|/etc/sudoers$|.*\.conf$|.*\.cfg$"

color brightmagenta,black "(^|[[:space:]])#.*$"
color brightgreen,black "\"(\\.|[^\"])*\""
color brightgreen,black "'(\\.|[^'])*'"
color brightyellow,black "\b[0-9]+\b"
color bold,brightcyan,black "\b(true|false|yes|no|on|off|enable|disable|default|auto|manual|GRUB_[A-Z_]+)\b"
color bold,brightblue,black "^[A-Za-z_][A-Za-z0-9_]*="
USEREOF

# ==============================================================================
# ШАГ 4: СИНХРОНИЗАЦИЯ С ROOT (для работы sudo nano)
# ==============================================================================
# 🔑 Синхронизация настроек для sudo nano
# Удаляем старую символическую ссылку, если она есть, чтобы избежать ошибок
sudo rm -f /root/.nanorc
# Создаем полноценную физическую копию (самый надежный способ)
sudo cp ~/.nanorc /root/.nanorc

# ✅ НАСТРОЙКА ЗАВЕРШЕНА УСПЕШНО!
# 🚀 Проверьте результат: nano ~/.nanorc
# 🚀 Проверьте sudo: sudo nano /etc/default/grub








################################################################################
# [ ] ЭТАП 9: НАСТРОЙКА ZSH И OH MY ZSH
################################################################################
# Приоритет: [ОПЦИОНАЛЬНО]

# 9.1 Установка Zsh
sudo pacman -Syy
sudo pacman -S --noconfirm zsh fastfetch hyfetch
# 9.2 Установка Oh My Zsh
sh -c "$(wget https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh -O -)"
# 9.3 Установка плагинов
### Настройка подсветки синтаксиса на Zsh
git clone https://github.com/zsh-users/zsh-syntax-highlighting.git
mv zsh-syntax-highlighting ~/.oh-my-zsh/plugins
echo "source ~/.oh-my-zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" >> ~/.zshrc
#   Настройка автозаполнения на Zsh
git clone https://github.com/zsh-users/zsh-autosuggestions
mv zsh-autosuggestions ~/.oh-my-zsh/custom/plugins
# 9.4 Настройка темы и плагинов
sed -i 's/^ZSH_THEME="robbyrussell"/ZSH_THEME="agnoster"/' ~/.zshrc
sed -i 's/^plugins=(.)/plugins=(git archlinux extract zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc
sed -i 's/^#* *plugins=.*/plugins=(git archlinux extract sudo themes zsh-navigation-tools zsh-autosuggestions)/' ~/.zshrc
# 9.5 Дополнительные настройки
echo 'ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"' >> ~/.zshrc
echo 'ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20' >> ~/.zshrc
# 9.6 Применение изменений
source ~/.zshrc
# 9.7 Смена оболочки на Zsh
chsh -s $(which zsh)
# 9.8 Добавление hyfetch в автозапуск
grep -q "hyfetch" ~/.zshrc || echo "hyfetch" >> ~/.zshrc








################################################################################
# [ ] ЭТАП 10: ВИРТУАЛИЗАЦИЯ VIRTUALBOX
################################################################################
# Приоритет: [ОПЦИОНАЛЬНО]

# 10.1 Проверка версии ядра
uname -r
# 10.2 Установка VirtualBox + модуль ядра
sudo pacman -S virtualbox
# 10.3 Установка гостевых дополнений
sudo pacman -S virtualbox-guest-iso
# 10.4 Добавление пользователя в группу vboxusers
sudo gpasswd -a $USER vboxusers
# Обязательное действие(ПЕРЕЗАГРУЗКА)
reboot







################################################################################
# [ ] ЭТАП 11: НАСТРОЙКА ДЛЯ ИГР (WINE / PROTON / LUX-WINE)
################################################################################
# Приоритет: [ОПЦИОНАЛЬНО]
# 🎯 Зачем: Установка слоя совместимости для запуска Windows-игр и приложений.
# ⚠️ ВАЖНО: Выберите ОДИН основной вариант установки:
#
#   ВАРИАНТ A — классический Wine из официальных репозиториев Arch Linux.
#              Подходит, если нужен системный Wine + winetricks + protontricks.
#              Требует установки zenity для графического интерфейса winetricks.
#
#   ВАРИАНТ B — Lux-Wine (Изолированная среда на базе runimage).
#              Подходит, если нужен удобный менеджер Wine/Proton для игр.
#              Это самодостаточная среда, в ней уже есть свои драйверы, библиотеки
#              и GUI. Пакеты wine, zenity и системный steam НЕ ТРЕБУЮТСЯ.
#
# ❗ Не устанавливайте оба варианта одновременно.
# 💡 Перед выполнением этапа убедитесь, что выполнены ЭТАП 1 и ЭТАП 2.


#------------------------------------------------------------------------------
# 11.0 БАЗОВАЯ ПРОВЕРКА ПЕРЕД УСТАНОВКОЙ ИГРОВОГО СЛОЯ
#------------------------------------------------------------------------------
# ℹ️ Зачем: Проверить, что работает Vulkan и 32-битные библиотеки.
#
# Проверка Vulkan:
vulkaninfo --summary 2>/dev/null | grep "deviceName" || echo "❌ Vulkan не найден. Сначала установите видеодрайверы."
#
# Проверка 32-битных Vulkan-библиотек (важно для Steam/Proton):
pacman -Qs lib32-vulkan
#


#------------------------------------------------------------------------------
# >>> [ВАРИАНТ A] КЛАССИЧЕСКИЙ WINE (ОФИЦИАЛЬНЫЕ ПАКЕТЫ ARCH LINUX) <<<
#------------------------------------------------------------------------------
# ℹ️ Назначение: Установка системного Wine и инструментов для настройки игр.
# ⚠️ Если вы выбираете ВАРИАНТ B (Lux-Wine), пропустите этот блок.
#
# 📦 wine-staging — Wine с дополнительными патчами, лучше подходит для игр.
# 📦 wine-gecko — движок Gecko для отображения веб-контента в Wine.
# 📦 wine-mono — реализация .NET Framework для Wine.
# 📦 winetricks — скрипт для установки библиотек: DirectX,vcrun, dotnet и др.
# 📦 protontricks — winetricks для префиксов Steam Proton.
# 📦 zenity — GUI для winetricks, удобные галочки для выбора компонентов.
#
# 11.1.1 Установка Wine и инструментов
sudo pacman -S --needed --noconfirm wine-staging wine-gecko wine-mono winetricks protontricks zenity
#
# 11.1.2 Проверка установки
wine --version
winetricks --version
#
# 11.1.3 Создание игрового префикса
# ℹ️ Зачем: Отдельный префикс для игр, чтобы не засорять системный.
WINEPREFIX=~/Games/wine-prefix wine winecfg
#
# 11.1.4 Переходите к пункту 11.3 (ЧЕК-ЛИСТ WINETRICKS) для установки библиотек.
#


#------------------------------------------------------------------------------
# >>> [ВАРИАНТ B] LUX-WINE (ИЗОЛИРОВАННАЯ СРЕДА НА БАЗЕ RUNIMAGE) <<<
#------------------------------------------------------------------------------
# ℹ️ Назначение: Установка удобного игрового окружения Lux-Wine.
# 💡 Это полностью изолированная среда. В ней уже есть свои библиотеки,
#    инструменты и графический интерфейс. Пакет zenity НЕ требуется!
# ⚠️ Требования: Архитектура x86_64, ядро Linux 4.18+ (с user namespaces).
# ⚠️ Если вы выбрали ВАРИАНТ A, пропустите этот блок.
# 📌 Инструкция: Удалите символ # только перед командами этого варианта.
#
# 11.2.1 Установка lux-wine (с альтернативными зеркалами)
curl -sL lwrap.github.io | bash
# Альтернативы (если основной не работает):
curl -sL lwrap.website.yandexcloud.net | bash
curl -sL lux-wine-git.static.hf.space | sed 1d | bash
#
# 11.2.2 Перезагрузка оболочки и инициализация
source ~/.bashrc
lwrun -init            # Принудительная инициализация префикса
lwrun --version        # Проверка версии
lwrun -config          # Общие настройки среды
lwrun -winecfg         # Настройки Wine
#
# 11.2.3 Управление Windows-приложениями (Ярлыки и настройки)
lwrun -lsapp           # Список установленных игр/приложений
lwrun -runapp "Name"   # Запустить приложение из списка (или по номеру)
lwrun -shortcut ~/Games/MyGame/game.exe  # Создать ярлык в системном меню
lwrun -rmapp "Name"    # Удалить ярлык приложения из системного меню
lwrun -appcfg "Name"   # Индивидуальные настройки приложения (переменные среды)
#
# 11.2.4 Управление версиями Wine/Proton и префиксом
lwrun -winemgr         # Менеджер версий (GE-Proton, Wine-GE, Lutris и др.)
lwrun -clearpfx        # Полная очистка префикса (сброс к дефолтному состоянию)
lwrun --install        # Принудительная переустановка/восстановление Lux-Wine
#
# 11.2.5 Встроенные системные утилиты Windows (Запуск внутри префикса)
lwrun -explorer        # Проводник Windows (для ручного копирования файлов)
lwrun -regedit         # Редактор реестра Windows
lwrun -taskmgr         # Диспетчер задач Windows
lwrun -uninstaller     # Мастер установки/удаления программ
lwrun -cmd             # Командная строка Windows (cmd.exe)
lwrun -control         # Панель управления Windows
#
# 11.2.6 Winetricks (Установка библиотек и шрифтов)
# Запуск графического интерфейса winetricks прямо из терминала:
lwrun -winetricks
# Или установка конкретных компонентов в одну строку (пример):
lwrun -winetricks corefontsvcrun2019 dxvk
#
# 11.2.7 Настройка графики и флагов "на лету"
# - Включить MangoHud: R_Shift + F12 (показать/скрыть)
# - Включить VkBasalt: HOME (вкл/выкл пост-обработку)
# - Настроить резкость FSR: lwrun -config → Графика → FSR
# 💡 Флаги библиотек при запуске игры (включают/отключают функции "на лету"):
# Пример запуска: lwrun dxvk vkd3d eac battleye "/путь/к_игре/game.exe"
#
# 11.2.8 Резервное копирование префикса игры
lwrun -pfxbackup       # Создать бэкап префикса
lwrun -pfxbackup xz    # Создать сжатый бэкап префикса
lwrun -pfxrestore      # Восстановить префикс из бэкапа
lwrun -backupmnt       # Смонтировать бэкап для ручного изменения файлов
lwrun -backupunmnt     # Размонтировать бэкап
#
# 11.2.9 Управление процессами и полезные команды
lwrun -killwine        # Завершить все зависшие процессы Wine
lwrun -killexe         # Завершить только запущенный .exe
lwrun -killtray        # Завершить процесс трея (иконки в трее)
lwrun -openpfx         # Открыть диск C: префикса в файловом менеджере
lwrun --update         # Проверить и установить обновления Lux-Wine
lwrun -update all      # Обновить сам Lux-Wine и все установленные компоненты
lwrun --uninstall      # Полное удаление Lux-Wine из системы
#
# 11.2.10 УСТАНОВКА LINUX-ПРИЛОЖЕНИЙ ВНУТРЬ КОНТЕЙНЕРА (ФИЧА RUNIMAGE)
# ℹ️ Lux-Wine изолирует не только Wine, но и позволяет устанавливать нативные
#    Linux-программы (Discord, Telegram) прямо в контейнер, не засоряя систему.
#    Внутри контейнера доступны репозитории Arch и Chaotic-AUR.
# Установка приложения (например, discord) в контейнер (не требует sudo):
RIM_DINTEG=1 runimage-lw pac -Sy discord
# Запуск установленного в контейнер приложения:
runimage-lw discord
#
# 11.2.11 Переходите к пункту 11.3 (ЧЕК-ЛИСТ WINETRICKS).
#


#------------------------------------------------------------------------------
# 11.3 ЧЕК-ЛИСТ НАСТРОЙКИ WINETRICKS (ДЛЯ ИГР WINDOWS 10 / 11)
#------------------------------------------------------------------------------
# ℹ️ Назначение: Установка библиотек и компонентов Windows для игр.
# 💡 Подходит для обоих вариантов (Wine и Lux-Wine).
# ⚠️ ВАЖНО: Не устанавливайте все компоненты сразу! Устанавливайте группами.
#  Все параметры заносятся в пресете в файле winetricks.log

# Пример:

vkd3d
dxvk

#
# ШАГ 1: ПОДГОТОВКА И БАЗОВАЯ НАСТРОЙКА WINECFG
#   - Для варианта A: выполните в терминале:
WINEPREFIX=~/Games/wine-prefix winetricks
#   - Для варианта B: выполните в терминале: lwrun -winetricks
#   - Выбрать "Select the default wineprefix" -> "Run winecfg".
#   - Вкладка "Приложения" (Applications) -> Версия Windows:
#     Windows 10 (Универсально, рекомендуется для 95% игр).
#     Windows 11 (Только если игра вышла после 2021 г. и строго требует её).
#   - Вкладка "Графика" (Graphics):
#     Включить: "Разрешить менеджеру окон управлять окнами Wine".
#     Включить: "Разрешить менеджеру окон декорировать окна".
#   - Нажать "Применить", затем "ОК".
#
# ШАГ 2: УСТАНОВКА ШРИФТОВ (Раздел "Install a font")
#   Устраняет "квадраты", иероглифы и вылеты лаунчеров из-за отсутствия текста.
corefonts — базовые шрифты MS (Arial, Times New Roman, Courier и др.).
tahoma — критически важен для интерфейсов старых игр и установщиков.
allfonts — (опционально) ставит абсолютно все шрифты, если текст всё ещё сбоит.
#
# ШАГ 3: УСТАНОВКА БИБЛИОТЕК И РАНТАЙМОВ (Раздел "Install a Windows DLL...")
#   Самый важный этап. Набор разделен по категориям для удобства поиска.
#
#   Графика и рендеринг (Обязательно):
d3dx9 — библиотеки DirectX 9.
d3dx10 — библиотеки DirectX 10.
d3dx11 — библиотеки DirectX 11.
dxvk — транслятор DX9/10/11 в Vulkan (критично для FPS в Linux).
vkd3d — транслятор DX12 в Vulkan (необходим для современных игр).
#
#   Среда выполнения Visual C++ (Обязательно все):
vcrun2005
vcrun2008
vcrun2010
vcrun2012
vcrun2013
vcrun2015 (илиvcrun2022, если доступен — включает в себя 2015-2022).
#
#   Платформа .NET Framework (Для лаунчеров, модов и лаунчеров Paradox/Rockstar):
dotnet40
dotnet48 (устанавливать строго ПОСЛЕ dotnet40, не ставить версии 2.0/3.5).
#
#   Звук и аудио-движки:
faudio — современная библиотека звука для новых игр.
xact — аудио-движок для корректных звуковых эффектов в старых играх.
#
#   Ввод и интерфейс:
dinput8 — улучшает отзывчивость мыши и совместимость с геймпадами.
gdiplus — библиотека отрисовки 2D для корректных меню и лаунчеров.
#
#   Физика (Опционально):
physx — устанавливать только для игр с поддержкой Nvidia PhysX.
#
#   Мультимедиа и видео (Чинит черные экраны вместо заставок):
wmp11 — Windows Media Player 11 (кодеки для кат-сцен).
amstream — фильтры DirectShow для старых игровых видеороликов.
lavfilters — набор современных аудио/видео декодеров.
#
# ШАГ 4: ФИНАЛЬНАЯ ПРОВЕРКА
#   - После установки всех компонентов перезапустите префикс.
#   - В Winetricks выберите "Clean up" (если доступно) для удаления кэша инсталляторов.
#
# ❗ ВАЖНОЕ ПРАВИЛО: Не отмечайте всё подряд галочками одновременно!
# Устанавливайте компоненты группами (сначала шрифты, затемvcrun, затем DirectX),
# чтобы Winetricks не завис в процессе настройки.
#


#------------------------------------------------------------------------------
# 11.4 MANGOHUD И VKBASALT (ОПЦИОНАЛЬНО)
#------------------------------------------------------------------------------
# ℹ️ Зачем: Отображение FPS и пост-обработка для игр.
# 💡 Для Lux-Wine MangoHud и VkBasalt уже доступны через горячие клавиши (см. 11.2.7).
#    Но если вы хотите использовать их системно (для Steam или классического Wine), установите пакеты.
#
# 11.4.1 Установка MangoHud и VkBasalt
sudo pacman -S --needed --noconfirm mangohud vkbasalt
#
# 11.4.2 Включение в играх (Steam):
# Параметры запуска игры:
mangohud gamemoderun %command%
#


#------------------------------------------------------------------------------
# 11.5 STEAM И PROTON
#------------------------------------------------------------------------------
# ℹ️ Зачем: Настройка Steam для запуска Windows-игр через Proton.
# ⚠️ ВАЖНО: Действия зависят от выбранного вами варианта установки!
#
# >>> [ДЛЯ ВАРИАНТА A] КЛАССИЧЕСКИЙ WINE <<<
# ℹ️ Вам нужно установить системный пакет Steam и включить в нём Proton.
# ⚠️ Если вы выбрали Вариант Б (Lux-Wine), пропустите команды ниже.
#
# 11.5.1 Установка Steam из официальных репозиториев Arch Linux
sudo pacman -S --needed --noconfirm steam
#
# 11.5.2 Включение Proton в Steam
# 1. Запустите Steam.
# 2. Перейдите: Steam -> Настройки -> Совместимость (Compatibility).
# 3. Включите галочку "Enable Steam Play for all other titles".
# 4. Выберите версию Proton (рекомендуется Proton Experimental).
#
# 11.5.3 (Опционально) Установка Proton-GE (кастомная версия с доп. патчами)
yay -S --needed --noconfirm protonup
# Запустите утилиту для скачивания свежей версии Proton-GE:
protonup
#
# >>> [ДЛЯ ВАРИАНТА Б] LUX-WINE <<<
# ℹ️ Steam уже АВТОМАТИЧЕСКИ установлен внутри изолированной среды Lux-Wine!
# 📦 Устанавливать системный пакет `steam` через pacman НЕ ТРЕБУЕТСЯ.
# 🚀 Запускайте Steam через графическое меню Lux-Wine или через ярлык на рабочем столе.
# ⚙️ Настройка версий Proton и Wine производится внутри самого Lux-Wine:
lwrun -winemgr         # Менеджер версий (Lutris, GE-Proton, Wine-GE)
lwrun -config          # Общие настройки среды
#


#------------------------------------------------------------------------------
# 11.6 GAMEMODE (ИГРОВОЙ РЕЖИМ)
#------------------------------------------------------------------------------
# ℹ️ Зачем: Повышение производительности во время игр.
# 💡 GameMode переключает CPU в режим высокой производительности на время игры.
#
# 11.6.1 Установка GameMode
sudo pacman -S --needed --noconfirm gamemode
#
# 11.6.2 Добавление пользователя в группу gamemode
sudo usermod -aG gamemode $USER
#
# 11.6.3 Обязательная перезагрузка
reboot
# ⚠️ После перезагрузки переходите к пункту 11.7.
#
# 11.6.4 Финальная проверка (после перезагрузки)
gamemoded -t
#
# Как правильно запустить игру с GameMode:
# В параметрах запуска Steam: gamemoderun mangohud %command%
# В терминале для Lux-Wine: gamemoderun lwrun "/путь/к_игре/game.exe"
# Для классического Wine:
gamemoderun wine "/путь/к_игре/game.exe"
#


#------------------------------------------------------------------------------
# 11.7 ФИНАЛЬНАЯ ПРОВЕРКА ИГРОВОГО СЛОЯ
#------------------------------------------------------------------------------
# ℹ️ Зачем: Убедиться, что все игровые компоненты работают.
#
# 11.7.1 Проверка Wine (для варианта A)
wine --version
#
# 11.7.2 Проверка Lux-Wine (для варианта B)
lwrun --version
#
# 11.7.3 Проверка GameMode
gamemoded -t
#
# 11.7.4 Проверка Vulkan
vulkaninfo --summary | grep "deviceName"
#
# 11.7.5 Создание финального снапшота (опционально)
# 💡 Рекомендуется создать снапшот после настройки игр.
sudo btrfs subvolume snapshot / /.snapshots/post-gaming-setup
sudo btrfs subvolume list /
#
################################################################################







# ===============================================================================
# [ ] ЭТАП 12: ПОЛНОЕ РУКОВОДСТВО-ЧЕКЛИСТ ПО УСТАНОВКЕ И НАСТРОЙКЕ TLP ДЛЯ ARCH LINUX
# ===============================================================================
# ⚠️ Данный файл содержит пошаговый алгоритм развертывания энергосбережения.
# Конфигурация включает три альтернативных способа настройки на ваш выбор:
# Часть 1 — через графический интерфейс, Часть 2 — с помощью nano и
# Часть 3 — с помощью команд.
# ===============================================================================

# ===============================================================================
# ЧАСТЬ 1: ИНСТРУКЦИЯ ДЛЯ НОВИЧКОВ — ГРАФИЧЕСКИЙ ИНТЕРФЕЙС TLPUI
# ===============================================================================
# Способ визуальной настройки кликами мыши. Полное разделение по CPU, GPU и сну.
# ===============================================================================

# -------------------------------------------------------------------------------
# ПОДГОТОВИТЕЛЬНЫЙ ШАГ: УСТАНОВКА И ЗАПУСК СЛУЖБ
# -------------------------------------------------------------------------------
# 1. Удаляем power-profiles-daemon, так как он конфликтует с TLP на уровне ядра:
sudo systemctl disable --now power-profiles-daemon
sudo pacman -Rns power-profiles-daemon

# 2. Установка TLP, графической оболочки и официального модуля мастера сетей tlp-rdw:
sudo pacman -S tlp tlp-rdw tlp-pd tlpui

# 3. [ДЛЯ ГИБРИДНЫХ СИСТЕМ: INTEL+NVIDIA / AMD+NVIDIA] Ставим switcheroo-control:
sudo pacman -S switcheroo-control

# 4. Активируем службы в системе для автозапуска.
sudo systemctl enable tlp.service
sudo systemctl enable --now tlp-pd.service
sudo systemctl enable --now NetworkManager-dispatcher.service

# 5. [ДЛЯ ГИБРИДНЫХ СИСТЕМ: INTEL+NVIDIA / AMD+NVIDIA] Запускаем демон switcheroo:
sudo systemctl enable --now switcheroo-control.service


# -------------------------------------------------------------------------------
# ПОШАГОВАЯ НАСТРОЙКА В ОКНЕ ПРОГРАММЫ
# -------------------------------------------------------------------------------
tlpui

# ШАГ 1: Настройка логики работы профилей (Вкладка "General")
# - "TLP_AUTO_SWITCH" -> выберите значение "2" (Smart-переключение).
# - "TLP_PROFILE_AC" -> выберите "PRF" (Performance — максимальная мощность).
# - "TLP_PROFILE_BAT" -> выберите "BAL" (Balanced — баланс от батареи).
# - "TLP_PROFILE_DEFAULT" -> выберите "BAL".

# ШАГ 2: РАЗДЕЛЕНИЕ ПО ПРОЦЕССОРАМ (Вкладка "Processor")
#
# ---> ЕСЛИ У ВАС ПРОЦЕССОР AMD (Ryzen):
#      - В пунктах CPU_DRIVER_OPMODE для _AC, _BAT и _SAV выберите значение "active".
#      - В пункте "CPU_SCALING_GOVERNOR_ON_AC" выберите регулятор "performance".
#      - В пунктах "_ON_BAT" and "_ON_SAV" выберите "powersave".
#      - Настройте аппаратные политики (EPP):
#        "CPU_ENERGY_PERF_POLICY_ON_AC" -> выберите "performance" или "balance_performance".
#        "CPU_ENERGY_PERF_POLICY_ON_BAT" -> выберите "balance_power".
#        "CPU_ENERGY_PERF_POLICY_ON_SAV" -> выберите "power".
#      - В пунктах CPU_BOOST для _AC и _BAT выберите "1" (Core Boost включен), для _SAV — "0".
#
# ---> ЕСЛИ У ВАС ПРОЦЕССОР INTEL (Core / Core Ultra):
#      - В пунктах CPU_DRIVER_OPMODE для _AC, _BAT и _SAV выберите значение "active".
#      - Регуляторы частот для Intel оставьте по умолчанию ("powersave"), так как процессор полностью управляется через политики EPP/EPB.
#      - Настройте аппаратные политики (EPP/EPB):
#        "CPU_ENERGY_PERF_POLICY_ON_AC" -> выберите "performance".
#        "CPU_ENERGY_PERF_POLICY_ON_BAT" -> выберите "balance_power".
#        "CPU_ENERGY_PERF_POLICY_ON_SAV" -> выберите "power".
#      - Ограничьте максимальную производительность ядер Intel P-State в процентах:
#        "CPU_MAX_PERF_ON_AC" -> впишите "100" | "CPU_MAX_PERF_ON_BAT" -> впишите "80" | "CPU_MAX_PERF_ON_SAV" -> впишите "60"
#      - В пунктах CPU_BOOST для _AC и _BAT выберите "1" (Turbo Boost включен), для _SAV — "0".

# ШАГ 3: Защита аккумулятора от износа (Вкладка "Battery Care")
# - Найдите блок вашей основной батареи (обычно называется BAT0).
# - В строки "START_CHARGE_THRESH_BAT0" впишите "75", а в "STOP_CHARGE_THRESH_BAT0" впишите "80".

# ШАГ 4: Сетки и мастер радиоустройств TLP-RDW (Вкладки "Radio" и "Radio Wizard (RDW)")
# - Вкладка "Radio" -> "DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE" -> впишите: wifi bluetooth wwan
# - Вкладка "Radio" -> "RESTORE_DEVICE_STATE_ON_STARTUP" -> переключите в "1" (True).
# - Вкладка "Radio Device Wizard (RDW)" -> в пункты LAN_CONNECT и LAN_DISCONNECT впишите строго: wifi

# ШАГ 5: ПРЕДОТВРАЩЕНИЕ ЗАВИСАНИЯ BLUETOOTH-МЫШИ И ТАЧПАДА ПОСЛЕ СНА
# - Вкладка "USB" -> Найдите пункт "USB_EXCLUDE_BTUSB" -> выберите значение "1" (True).
#   (Это запретит TLP обесточивать контроллер Bluetooth, защищая мышь от отключения после сна).
# - Настройка тачпада (сенсорной панели) производится в зависимости от графики на Шаге 6.

# ШАГ 6: РАЗДЕЛЕНИЕ ПО КОНФИГУРАЦИЯМ ВИДЕОКАРТ И ТАЧПАДА (Вкладка "Runtime PM")
# Настройки шины данных (Вкладка "PCIe") выполняются одинаково для всех ПК:
# - "PCIE_ASPM_ON_AC" -> выберите "performance" | "_ON_BAT" -> "powersave" | "_ON_SAV" -> "powersupersave".
#
# Настройте черный список драйверов сна (RUNTIME_PM_DRIVER_DENYLIST), чтобы видеокарты
# засыпали правильно, а тачпад (i2c_hid, psmouse, elan_i2c) не отключался после сна:
#
# ---> СЦЕНАРИЙ 1: ОДИНОЧНАЯ КАРТА INTEL / AMD / NVIDIA (Где в ПК всего 1 видеокарта)
#      - "RUNTIME_PM_DRIVER_DENYLIST" -> добавьте драйверы тачпада: amdgpu mei_me nouveau nvidia xhci_hcd i2c_hid psmouse elan_i2c
#      - "RUNTIME_PM_ON_BAT" -> выберите "auto".
#
# ---> СЦЕНАРИЙ 2: ГИБРИДНАЯ ГРАФИКА INTEL + NVIDIA (Две видеокарты)
#      - "RUNTIME_PM_DRIVER_DENYLIST" -> удалите nvidia/nouveau, добавьте тачпад: amdgpu mei_me xhci_hcd i2c_hid psmouse elan_i2c
#      - "RUNTIME_PM_ON_BAT" -> выберите "auto".
#
# ---> СЦЕНАРИЙ 3: ГИБРИДНАЯ ГРАФИКА AMD + NVIDIA (Две видеокарты)
#      - "RUNTIME_PM_DRIVER_DENYLIST" -> удалите amdgpu/nvidia/nouveau, добавьте тачпад: mei_me xhci_hcd i2c_hid psmouse elan_i2c
#      - "RUNTIME_PM_ON_BAT" -> выберите "auto".

# ШАГ 7: Сохранение изменений
# - Нажмите большую кнопку "Save" на верхней панели инструментов TLPUI. Введите root-пароль.


# -------------------------------------------------------------------------------
# ПРИМЕНЕНИЕ, ДИАГНОСТИКА И СБРОС НАСТРОЕК
# -------------------------------------------------------------------------------
sudo tlp start
sudo tlp-stat -s
sudo tlp-stat --udev
switcherooctl list

# РЕЖИМ СБРОСА НАСТРОЕК ЧЕРЕЗ ИНТЕРФЕЙС TLPUI:
# 1. На панели инструментов TLPUI нажмите "File" -> "Reset to defaults".
# 2. Нажмите кнопку "Save". В терминале выполните: sudo tlp start







## ===============================================================================
# ЧАСТЬ 2: ИНСТРУКЦИЯ ДЛЯ ПРОДВИНУТЫХ ПОЛЬЗОВАТЕЛЕЙ — РЕДАКТОР NANO
# ===============================================================================
# Ручная правка файла /etc/tlp.conf. Где изначально все строки закомментированы (#).
# ===============================================================================

# -------------------------------------------------------------------------------
# ПОДГОТОВИТЕЛЬНЫЙ ШАГ: УСТАНОВКА И ЗАПУСК СЛУЖБ
# -------------------------------------------------------------------------------
sudo systemctl disable --now power-profiles-daemon
sudo pacman -Rns power-profiles-daemon
sudo pacman -S tlp tlp-rdw tlp-pd tlpui

# [ДЛЯ ГИБРИДНЫХ СИСТЕМ: INTEL+NVIDIA / AMD+NVIDIA] Установка службы переключения:
sudo pacman -S switcheroo-control

sudo systemctl enable tlp.service
sudo systemctl enable --now tlp-pd.service
sudo systemctl enable --now NetworkManager-dispatcher.service

# [ДЛЯ ГИБРИДНЫХ СИСТЕМ] Активация службы графики:
sudo systemctl enable --now switcheroo-control.service


# -------------------------------------------------------------------------------
# ПОШАГОВОЕ РЕДАКТИРОВАНИЕ КОНФИГУРАЦИИ
# -------------------------------------------------------------------------------
sudo nano /etc/tlp.conf

# Используйте Ctrl+W для поиска строк. ОБЯЗАТЕЛЬНО УДАЛЯЙТЕ символ # в начале строки,
# чтобы активировать параметр, и меняйте значения:

# === [БЛОК 1: ОБЩИЕ ПАРАМЕТРЫ ДЛЯ ВСЕХ ПК] ===
# TLP_AUTO_SWITCH=2
# TLP_PROFILE_AC=PRF
# TLP_PROFILE_BAT=BAL
# TLP_PROFILE_DEFAULT=BAL
# START_CHARGE_THRESH_BAT0=75
# STOP_CHARGE_THRESH_BAT0=80
# DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE="bluetooth wifi wwan"
# RESTORE_DEVICE_STATE_ON_STARTUP=1
# DEVICES_TO_DISABLE_ON_LAN_CONNECT="wifi"
# DEVICES_TO_ENABLE_ON_LAN_DISCONNECT="wifi"
# PCIE_ASPM_ON_AC=performance
# PCIE_ASPM_ON_BAT=powersave
# PCIE_ASPM_ON_SAV=powersupersave
# RUNTIME_PM_ON_AC=on
# RUNTIME_PM_ON_BAT=auto

# --- Защита Bluetooth-мыши от отключения после сна ---
# USB_EXCLUDE_BTUSB=1


# === [БЛОК 2: РАЗДЕЛЕНИЕ ПО ПРОЦЕССОРАМ] ===
# Раскомментируйте ТОЛЬКО ту группу параметров, которая соответствует вашему CPU:

# ---> ВАРИАНТ А: ЕСЛИ У ВАС ПРОЦЕССОР AMD (Ryzen)
# CPU_DRIVER_OPMODE_ON_AC=active
# CPU_DRIVER_OPMODE_ON_BAT=active
# CPU_DRIVER_OPMODE_ON_SAV=active
# CPU_SCALING_GOVERNOR_ON_AC=performance
# CPU_SCALING_GOVERNOR_ON_BAT=powersave
# CPU_SCALING_GOVERNOR_ON_SAV=powersave
# CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance
# CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
# CPU_ENERGY_PERF_POLICY_ON_SAV=power
# CPU_BOOST_ON_AC=1
# CPU_BOOST_ON_BAT=1
# CPU_BOOST_ON_SAV=0

# ---> ВАРИАНТ Б: ЕСЛИ У ВАС ПРОЦЕССОР INTEL
# CPU_DRIVER_OPMODE_ON_AC=active
# CPU_DRIVER_OPMODE_ON_BAT=active
# CPU_DRIVER_OPMODE_ON_SAV=active
# CPU_ENERGY_PERF_POLICY_ON_AC=performance
# CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power
# CPU_ENERGY_PERF_POLICY_ON_SAV=power
# CPU_MIN_PERF_ON_AC=0
# CPU_MAX_PERF_ON_AC=100
# CPU_MIN_PERF_ON_BAT=0
# CPU_MAX_PERF_ON_BAT=80
# CPU_MIN_PERF_ON_SAV=0
# CPU_MAX_PERF_ON_SAV=60
# CPU_BOOST_ON_AC=1
# CPU_BOOST_ON_BAT=1
# CPU_BOOST_ON_SAV=0


# === [БЛОК 3: РАЗДЕЛЕНИЕ ПО КОНФИГУРАЦИЯМ ВИДЕОКАРТ И ЗАЩИТА ТАЧПАДА] ===
# Найдите параметр RUNTIME_PM_DRIVER_DENYLIST, раскомментируйте и измените его.
# Драйверы i2c_hid, psmouse и elan_i2c защищают тачпад ноутбуков MAIBENBEN от зависания.

# ---> ДЛЯ ОДИНАРНЫХ ВИДЕОКАРТ (Где в ПК всего 1 видеокарта Intel, AMD или NVIDIA):
# RUNTIME_PM_DRIVER_DENYLIST="amdgpu mei_me nouveau nvidia xhci_hcd i2c_hid psmouse elan_i2c"

# ---> ДЛЯ ГИБРИДНЫХ СИСТЕМ INTEL + NVIDIA (Две видеокарты):
# RUNTIME_PM_DRIVER_DENYLIST="amdgpu mei_me xhci_hcd i2c_hid psmouse elan_i2c"

# ---> ДЛЯ ГИБРИДНЫХ СИСТЕМ AMD + NVIDIA (Две видеокарты):
# RUNTIME_PM_DRIVER_DENYLIST="mei_me xhci_hcd i2c_hid psmouse elan_i2c"

# ШАГ 3: Сохранение и закрытие файла
# - Нажмите Ctrl+O -> Enter для сохранения. Нажмите Ctrl+X для выхода из Nano.


# -------------------------------------------------------------------------------
# ПРИМЕНЕНИЕ, КОНТРОЛЬ СНА И ПРАВИЛЬНЫЙ СБРОС НАСТРОЕК В ARCH LINUX
# -------------------------------------------------------------------------------
sudo tlp start
sudo tlp-stat -s
sudo tlp-stat --udev
tlp-rdw
switcherooctl list

# РЕЖИМ ПРАВИЛЬНОГО ПОЛНОГО СБРОСА НАСТРОЕК В ARCH LINUX:
# 1. Полностью останавливаем и выключаем запущенные в фоне службы:
sudo systemctl disable --now tlp.service tlp-pd.service NetworkManager-dispatcher.service

# 2. Физически удаляем измененный конфигурационный файл с диска:
sudo rm -f /etc/tlp.conf

# 3. Заставляем pacman начисто перезаписать файл конфигурации оригиналом из репозитория:
sudo pacman -S --noconfirm tlp tlp-rdw tlpui

# 4. Активируем и запускаем службы заново:
sudo systemctl enable tlp.service
sudo systemctl enable --now tlp-pd.service NetworkManager-dispatcher.service
sudo tlp start







# ===============================================================================
# ЧАСТЬ 3: ИНСТРУКЦИЯ ДЛЯ СКРИПТОВ И АВТОМАТИЗАЦИИ — УТИЛИТА SED
# ===============================================================================
# Скриптовая модификация файла. Команды sed раскомментируют строки исходного конфига.
# Данный файл является полным и не содержит сокращений.
# ===============================================================================

# -------------------------------------------------------------------------------
# ПОДГОТОВИТЕЛЬНЫЙ ШАГ: УСТАНОВКА И ЗАПУСК СЛУЖБ
# -------------------------------------------------------------------------------
sudo systemctl disable --now power-profiles-daemon
sudo pacman -Rns --noconfirm power-profiles-daemon
sudo pacman -S --noconfirm tlp tlp-rdw tlp-pd

# [ДЛЯ ГИБРИДНЫХ СИСТЕМ: INTEL+NVIDIA / AMD+NVIDIA] Установка switcheroo-control:
sudo pacman -S --noconfirm switcheroo-control
sudo systemctl enable --now switcheroo-control.service

sudo systemctl enable tlp.service
sudo systemctl enable --now tlp-pd.service
sudo systemctl enable --now NetworkManager-dispatcher.service


# -------------------------------------------------------------------------------
# БЛОК ЗАМЕНЫ КОМАНД ЧЕРЕЗ СТРИМ-РЕДАКТОР SED (РАСКОММЕНТИРОВАНИЕ)
# -------------------------------------------------------------------------------

# === [БЛОК 1: ОБЩИЕ БАЗОВЫЕ НАСТРОЙКИ ДЛЯ ВСЕХ ТИПОВ ПК] ===
# (Профили работы, пороги заряда батареи, радиоустройства, шина PCIe и защита мыши)

sudo sed -i 's/^#TLP_AUTO_SWITCH=.*/TLP_AUTO_SWITCH=2/' /etc/tlp.conf
sudo sed -i 's/^#TLP_PROFILE_AC=.*/TLP_PROFILE_AC=PRF/' /etc/tlp.conf
sudo sed -i 's/^#TLP_PROFILE_BAT=.*/TLP_PROFILE_BAT=BAL/' /etc/tlp.conf
sudo sed -i 's/^#TLP_PROFILE_DEFAULT=.*/TLP_PROFILE_DEFAULT=BAL/' /etc/tlp.conf
sudo sed -i 's/^#START_CHARGE_THRESH_BAT0=.*/START_CHARGE_THRESH_BAT0=75/' /etc/tlp.conf
sudo sed -i 's/^#STOP_CHARGE_THRESH_BAT0=.*/STOP_CHARGE_THRESH_BAT0=80/' /etc/tlp.conf
sudo sed -i 's/^#DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE=.*/DEVICES_TO_DISABLE_ON_BAT_NOT_IN_USE="bluetooth wifi wwan"/' /etc/tlp.conf
sudo sed -i 's/^#RESTORE_DEVICE_STATE_ON_STARTUP=.*/RESTORE_DEVICE_STATE_ON_STARTUP=1/' /etc/tlp.conf
sudo sed -i 's/^#DEVICES_TO_DISABLE_ON_LAN_CONNECT=.*/DEVICES_TO_DISABLE_ON_LAN_CONNECT="wifi"/' /etc/tlp.conf
sudo sed -i 's/^#DEVICES_TO_ENABLE_ON_LAN_DISCONNECT=.*/DEVICES_TO_ENABLE_ON_LAN_DISCONNECT="wifi"/' /etc/tlp.conf
sudo sed -i 's/^#PCIE_ASPM_ON_AC=.*/PCIE_ASPM_ON_AC=performance/' /etc/tlp.conf
sudo sed -i 's/^#PCIE_ASPM_ON_BAT=.*/PCIE_ASPM_ON_BAT=powersave/' /etc/tlp.conf
sudo sed -i 's/^#PCIE_ASPM_ON_SAV=.*/PCIE_ASPM_ON_SAV=powersupersave/' /etc/tlp.conf
sudo sed -i 's/^#RUNTIME_PM_ON_AC=.*/RUNTIME_PM_ON_AC=on/' /etc/tlp.conf
sudo sed -i 's/^#RUNTIME_PM_ON_BAT=.*/RUNTIME_PM_ON_BAT=auto/' /etc/tlp.conf

# Защита беспроводной Bluetooth-мыши от отключения и зависания после сна:
sudo sed -i 's/^#USB_EXCLUDE_BTUSB=.*/USB_EXCLUDE_BTUSB=1/' /etc/tlp.conf


# === [БЛОК 2: АВТОМАТИЗАЦИЯ НАСТРОЕК ПРОЦЕССОРА] ===
# ВНИМАНИЕ: Оставьте в вашем .sh скрипте только ОДИН из двух блоков ниже.

# ---> ПОДБЛОК ДЛЯ СИСТЕМ НА БАЗЕ AMD (Ryzen):
# sudo sed -i 's/^#CPU_DRIVER_OPMODE_ON_AC=.*/CPU_DRIVER_OPMODE_ON_AC=active/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_DRIVER_OPMODE_ON_BAT=.*/CPU_DRIVER_OPMODE_ON_BAT=active/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_DRIVER_OPMODE_ON_SAV=.*/CPU_DRIVER_OPMODE_ON_SAV=active/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_SCALING_GOVERNOR_ON_AC=.*/CPU_SCALING_GOVERNOR_ON_AC=performance/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_SCALING_GOVERNOR_ON_BAT=.*/CPU_SCALING_GOVERNOR_ON_BAT=powersave/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_SCALING_GOVERNOR_ON_SAV=.*/CPU_SCALING_GOVERNOR_ON_SAV=powersave/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC=balance_performance/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_ENERGY_PERF_POLICY_ON_BAT=.*/CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_ENERGY_PERF_POLICY_ON_SAV=.*/CPU_ENERGY_PERF_POLICY_ON_SAV=power/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_BOOST_ON_AC=.*/CPU_BOOST_ON_AC=1/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_BOOST_ON_BAT=.*/CPU_BOOST_ON_BAT=1/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_BOOST_ON_SAV=.*/CPU_BOOST_ON_SAV=0/' /etc/tlp.conf

# ---> ПОДБЛОК ДЛЯ СИСТЕМ НА БАЗЕ INTEL:
# sudo sed -i 's/^#CPU_DRIVER_OPMODE_ON_AC=.*/CPU_DRIVER_OPMODE_ON_AC=active/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_DRIVER_OPMODE_ON_BAT=.*/CPU_DRIVER_OPMODE_ON_BAT=active/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_DRIVER_OPMODE_ON_SAV=.*/CPU_DRIVER_OPMODE_ON_SAV=active/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_ENERGY_PERF_POLICY_ON_AC=.*/CPU_ENERGY_PERF_POLICY_ON_AC=performance/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_ENERGY_PERF_POLICY_ON_BAT=.*/CPU_ENERGY_PERF_POLICY_ON_BAT=balance_power/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_ENERGY_PERF_POLICY_ON_SAV=.*/CPU_ENERGY_PERF_POLICY_ON_SAV=power/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_MIN_PERF_ON_AC=.*/CPU_MIN_PERF_ON_AC=0/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_MAX_PERF_ON_AC=.*/CPU_MAX_PERF_ON_AC=100/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_MIN_PERF_ON_BAT=.*/CPU_MIN_PERF_ON_BAT=0/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_MAX_PERF_ON_BAT=.*/CPU_MAX_PERF_ON_BAT=80/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_MIN_PERF_ON_SAV=.*/CPU_MIN_PERF_ON_SAV=0/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_MAX_PERF_ON_SAV=.*/CPU_MAX_PERF_ON_SAV=60/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_BOOST_ON_AC=.*/CPU_BOOST_ON_AC=1/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_BOOST_ON_BAT=.*/CPU_BOOST_ON_BAT=1/' /etc/tlp.conf
# sudo sed -i 's/^#CPU_BOOST_ON_SAV=.*/CPU_BOOST_ON_SAV=0/' /etc/tlp.conf


# === [БЛОК 3: АВТОМАТИЗАЦИЯ НАСТРОЕК ВИДЕОКАРТ И ЗАЩИТА ТАЧПАДА] ===
# Выберите строго одну команду sed в зависимости от архитектуры вашего ноутбука.
# Драйверы i2c_hid, psmouse и elan_i2c предотвращают отключение сенсорной панели.

# ---> ДЛЯ ОДИНАРНЫХ ВИДЕОКАРТ (Только Intel, только AMD или только NVIDIA):
# sudo sed -i 's/^#RUNTIME_PM_DRIVER_DENYLIST=.*/RUNTIME_PM_DRIVER_DENYLIST="amdgpu mei_me nouveau nvidia xhci_hcd i2c_hid psmouse elan_i2c"/' /etc/tlp.conf

# ---> ДЛЯ ГИБРИДНЫХ СИСТЕМ С ДВУМЯ ВИДЕОКАРТАМИ (Intel+NVIDIA):
# sudo sed -i 's/^#RUNTIME_PM_DRIVER_DENYLIST=.*/RUNTIME_PM_DRIVER_DENYLIST="amdgpu mei_me xhci_hcd i2c_hid psmouse elan_i2c"/' /etc/tlp.conf

# ---> ДЛЯ ГИБРИДНЫХ СИСТЕМ С ДВУМЯ ВИДЕОКАРТАМИ (AMD+NVIDIA):
# sudo sed -i 's/^#RUNTIME_PM_DRIVER_DENYLIST=.*/RUNTIME_PM_DRIVER_DENYLIST="mei_me xhci_hcd i2c_hid psmouse elan_i2c"/' /etc/tlp.conf


# -------------------------------------------------------------------------------
# ПРИМЕНЕНИЕ И ДИАГНОСТИКА
# -------------------------------------------------------------------------------
sudo tlp start
sudo tlp-stat -s
sudo tlp-stat --udev
tlp-rdw

# [ДЛЯ ГИБРИДНЫХ СИСТЕМ С 2 ВИДЕОКАРТАМИ]
switcherooctl list


# -------------------------------------------------------------------------------
# РАЗДЕЛ: НАДЁЖНЫЙ АВТОМАТИЧЕСКИЙ СБРОС НАСТРОЕК В СКРИПТАХ
# -------------------------------------------------------------------------------
# Полный алгоритм программного отката на оригинальный закомментированный файл:
#
# sudo systemctl disable --now tlp.service tlp-pd.service NetworkManager-dispatcher.service
# sudo rm -f /etc/tlp.conf
# sudo pacman -S --noconfirm tlp tlp-rdw
# sudo systemctl enable tlp.service
# sudo systemctl enable --now tlp-pd.service NetworkManager-dispatcher.service
# sudo tlp start



# ===============================================================================
# ПОЛНАЯ НАСТРОЙКА ЗАВЕРШЕНА. СИСТЕМА ARCH LINUX ОПТИМИЗИРОВАНА ДЛЯ ВСЕХ РЕЖИМОВ!
# ===============================================================================
