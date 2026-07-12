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
# [ ] ЭТАП 1: УСТАНОВКА ВИДЕО-ДРАЙВЕРОВ
#------------------------------------------------------------------------------
# 🎯 Зачем: Установка видео-драйверов на чистую систему с базовыми драйверами.
# ⚠️ Важно: Выполняется ПОСЛЕ первой загрузки в установленную систему.
# 1.1 chwd-arch-git — Утилита сканирует компоненты вашего компьютера и определяет правильные драйверы.
yay -S --noconfirm chwd-arch-git
# 1.2 Установка видео-драйверов
sudo chwd -a
reboot

# 1.3 Настройка после установки видео-драйверов
# ⚠️ ИНСТРУКЦИЯ:
# ❗ Правильный выбор вариантов зависит от конфигурации компьютера
# ✅ Вариант А - Компьютеры с единственной видеокартой (NVIDIA dGPU)
# ✅ Вариант Б - Компьютеры с двумя видеокартами (Intel/AMD iGPU + NVIDIA dGPU)
# • Удалите символ # только перед командами, которые нужно выполнить
# • Удалите не нужный вариант, что-бы не было путаницы и ошибок
# ⚠️ Важно: Выполняется с правами администратора
sudo su

# >>> [ВАРИАНТ А] NVIDIA (ОДИНОЧНАЯ, ДЕСКТОП / ПК) <<<

# --- Настройки ядра и модулей (ТОЛЬКО ДЛЯ ОДИНОЧНОЙ NVIDIA) ---
# 📋 1. Добавить параметр ядра nvidia-drm.modeset=1 в GRUB
# ✅ Включает DRM KMS, что обязательно для Wayland и корректного пробуждения.
# sed -i -E 's/^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"/\1 nvidia-drm.modeset=1"/' /etc/default/grub

# 📋 2. Конфигурация модулей (modprobe) — ТОЛЬКО ДЛЯ ОДИНОЧНОЙ NVIDIA (ПК)
# ✅ Создаёт файл с параметрами для сохранения VRAM при сне/гибернации.
# echo "options nvidia-drm modeset=1" > /etc/modprobe.d/nvidia.conf
# echo "options nvidia NVreg_PreserveVideoMemoryAllocations=1" >> /etc/modprobe.d/nvidia.conf
# echo "options nvidia NVreg_TemporaryFilePath=/var/tmp" >> /etc/modprobe.d/nvidia.conf

# 📋 3. Включение системных служб управления сном/гибернацией
# ✅ КРИТИЧЕСКИ ВАЖНО ДЛЯ ПК С ОДНОЙ NVIDIA:
#    Службы сохраняют VRAM в RAM перед сном. Без них будет чёрный экран при пробуждении.
# systemctl enable nvidia-suspend.service nvidia-hibernate.service nvidia-resume.service

# 📋 4. Пересобрать initramfs и обновить GRUB
# mkinitcpio -P
# grub-mkconfig -o /boot/grub/grub.cfg

# >>> [ВАРИАНТ Б] ГИБРИДНАЯ ГРАФИКА (Intel/AMD iGPU + NVIDIA dGPU) <<<

# 📋 1. Настройка параметров ядра (GRUB) – ОБЯЗАТЕЛЬНО ДЛЯ ГИБРИДА!
# Добавляем:
#   - nvidia-drm.modeset=1 (для Wayland и корректного пробуждения)
#   - nvidia.NVreg_PreserveVideoMemoryAllocations=0 (освобождает видеопамять)
#   - resume_offset=0 (помогает ядру найти образ гибернации)
# sed -i -E 's/^(GRUB_CMDLINE_LINUX_DEFAULT="[^"]*)"/\1 nvidia-drm.modeset=1 nvidia.NVreg_PreserveVideoMemoryAllocations=0 resume_offset=0"/' /etc/default/grub

# 📋 2. Создание скрипта для выгрузки модулей NVIDIA перед гибернацией.
# ✅ Гарантирует, что дискретная карта не помешает сохранению образа гибернации.
# ❗ БЕЗ ЭТОГО СКРИПТА ГИБЕРНАЦИЯ НА ГИБРИДНЫХ НОУТБУКАХ НЕ РАБОТАЕТ!
# echo '#!/bin/sh' > /usr/lib/systemd/system-sleep/nvidia.sh
# echo "case \$1 in" >> /usr/lib/systemd/system-sleep/nvidia.sh
# echo "    pre)" >> /usr/lib/systemd/system-sleep/nvidia.sh
# echo "        rmmod nvidia_drm nvidia_uvm nvidia_modeset nvidia 2>/dev/null" >> /usr/lib/systemd/system-sleep/nvidia.sh
# echo "        sleep 1" >> /usr/lib/systemd/system-sleep/nvidia.sh
# echo "        ;;" >> /usr/lib/systemd/system-sleep/nvidia.sh
# echo "    post)" >> /usr/lib/systemd/system-sleep/nvidia.sh
# echo "        ;;" >> /usr/lib/systemd/system-sleep/nvidia.sh
# echo "esac" >> /usr/lib/systemd/system-sleep/nvidia.sh
# chmod +x /usr/lib/systemd/system-sleep/nvidia.sh

# ⛔ КАТЕГОРИЧЕСКИ НЕЛЬЗЯ ДЛЯ ГИБРИДНОГО НОУТБУКА:
# • Включать службы: nvidia-suspend.service, nvidia-hibernate.service, nvidia-resume.service
#   (systemctl enable nvidia-suspend.service и т.п.) – приведёт к kernel panic!
# • Создавать /etc/modprobe.d/nvidia.conf с опцией NVreg_PreserveVideoMemoryAllocations=1
#   (она предназначена только для ПК с одной NVIDIA, на ноутбуке вызовет конфликты с Runtime PM).

# 📋 3. Добавление модуля nvme в initramfs (КРИТИЧНО ДЛЯ ГИБЕРНАЦИИ НА NVME)
# ✅ Добавляет nvme к уже существующим модулям (btrfs из Блока 12).
# sed -i "s/^MODULES=(\(.*\))/MODULES=(\1 nvme)/" /etc/mkinitcpio.conf

# 📋 5. Пересборка initramfs и обновление GRUB
mkinitcpio -P
grub-mkconfig -o /boot/grub/grub.cfg
reboot






#------------------------------------------------------------------------------
# [ ] ЭТАП 2: ДИАГНОСТИКА ВИДЕОКАРТ И ДРАЙВЕРОВ
#------------------------------------------------------------------------------
# Приоритет: [ОБЯЗАТЕЛЬНО]
# ⚠️ Важно: Выполняется ПОСЛЕ первой загрузки в установленную систему.
# 👤 Выполняется: От имени обычного пользователя с sudo правами.
# 💡 Примечание: Для визуальных тестов должна быть запущена графическая сессия!

# 2.1 ДИАГНОСТИКА (ТЕКСТОВАЯ)
# Проверка статуса драйвера NVIDIA (только для NVIDIA). Ожидаемый результат: Таблица с информацией о карте и температуре.
nvidia-smi
# Проверка поддержки Vulkan (все карты). Ожидаемый результат: Название вашей видеокарты (deviceName).
vulkaninfo --summary | grep "deviceName"
# Проверка аппаратного декодирования видео (VA-API). Ожидаемый результат: Список поддерживаемых профилей.
vainfo
# Проверка активного OpenGL рендерера. Ожидаемый результат: Строка "OpenGL renderer: ..." с названием GPU.
glxinfo | grep "OpenGL renderer"

# 2.2 ВИЗУАЛЬНЫЕ ТЕСТЫ (GUI)
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







#------------------------------------------------------------------------------
# [ ] ЭТАП 3: НАСТРОЙКА БРАНДМАУЭРА UFW
#------------------------------------------------------------------------------
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

#------------------------------------------------------------------------------
# [ ] ЭТАП 4: НАСТРОЙКА UFW ДЛЯ СЕТЕВЫХ УСТРОЙСТВ
#------------------------------------------------------------------------------
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








#------------------------------------------------------------------------------
# [ ] ЭТАП 5: БАЗОВОЕ УПРОЧНЕНИЕ БЕЗОПАСНОСТИ
#------------------------------------------------------------------------------
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








#------------------------------------------------------------------------------
# [ ] ЭТАП 6: НАСТРОЙКА ЗВУКА (ПОЛНАЯ: ALSAMIXER + AMIXER + PIPEWIRE)
#------------------------------------------------------------------------------
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








#------------------------------------------------------------------------------
# [ ] ЭТАП 7: УСТАНОВКА ПРИЛОЖЕНИЙ
#------------------------------------------------------------------------------
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
yay -S --noconfirm grub-customizer grub2-theme-arch-leap update-grub
reboot






#------------------------------------------------------------------------------
# [ ] ЭТАП 8: НАСТРОЙКА РЕДАКТОРА NANO
#------------------------------------------------------------------------------
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








#------------------------------------------------------------------------------
# [ ] ЭТАП 9: НАСТРОЙКА ZSH И OH MY ZSH
#------------------------------------------------------------------------------
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

# !!! ВАЖНО: Если вы используете Wayland (например, KDE Plasma под Wayland),
# уведомления VirtualBox могут быть неинтерактивны (нельзя закрыть кликом).
# Чтобы отключить эти уведомления, выполните следующие команды после установки
# и перезапустите VirtualBox:
# Отключить мини-тулбар
VBoxManage setextradata global GUI/ShowMiniToolBar 0
# Отключить уведомления о пользовательском вводе
VBoxManage setextradata global GUI/NotifyAboutUserInput 0
VBoxManage setextradata global GUI/NotifyAbout3DUserInput 0
# Отключить значки и общие уведомления (если опция существует)
VBoxManage setextradata global GUI/ShowNotificationIcons 0
VBoxManage setextradata global GUI/ShowNotifications 0








#------------------------------------------------------------------------------
# [ ] ЭТАП 11: НАСТРОЙКА ДЛЯ ИГР (LUX-WINE)
#------------------------------------------------------------------------------
# Приоритет: [ОПЦИОНАЛЬНО]

# 11.1 Предварительные требования: проверка Vulkan

vulkaninfo --summary 2>/dev/null | grep "deviceName"


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
lwrun -update all      # Обновить префиксы lux-wine и их содержимое
lwrun --uninstall      # Полное удаление

# 11.10 Настройка

# Для того чтобы большинство Windows-игр запускались через Lux Wine без проблем, вам необходимо установить базовый набор библиотек, шрифтов и компонентов DirectX через встроенный Winetricks.

# Вот пошаговый алгоритм настройки.

## 1. Подготовка чистого префикса

# Перед установкой компонентов убедитесь, что вы работаете с нужным префиксом (желательно 64-битным для современных игр).

# * Откройте Lux Wine.
# * Выберите ваш игровой префикс (или создайте новый).
# * Откройте Winetricks через меню управления этим префиксом.

## 2. Установка шрифтов (Fonts)

# Многие игры и их лаунчеры вылетают, если в системе отсутствуют стандартные шрифты Windows.

# * В Winetricks выберите Select the default wineprefix -> Install a font.
# * Отметьте галочкой и установите:

* corefonts (базовые шрифты Microsoft: Arial, Times New Roman и др.)
* tahoma (часто используется в интерфейсах старых игр)

## 3. Установка библиотек и рантаймов (Windows DLLs)
# Это самый важный этап. Играм необходимы библиотеки среды выполнения.

# * Вернитесь назад и выберите Install a Windows DLL or component.
# * Отметьте галочками и установите следующий универсальный набор:

* d3dx9, d3dx10, d3dx11 (компоненты DirectX для старых и средних игр)
* dxvk (транслятор DirectX 9/10/11 в Vulkan — критически важен для производительности)
* vkd3d (транслятор DirectX 12 в Vulkan для современных игр)
* vcrun2005, vcrun2008, vcrun2010, vcrun2012, vcrun2013, vcrun2015 (наборы библиотек Visual C++ разных лет)
* dotnet40 или dotnet48 (платформа .NET Framework, необходимая для лаунчеров и модификаций)
* physx (если планируете играть в игры с поддержкой физики Nvidia PhysX)

## 4. Настройка звука и видео

# * В том же списке DLL найдите и установите:

* faudio (для корректной работы звука в современных играх)
* xact (аудио-движок для старых игр)

## 5. Смена версии Windows

# * Выйдите в главное меню Winetricks для этого префикса.
# * Выберите Run winecfg.
# * На вкладке «Приложения» (Applications) снизу установите Версию Windows: Windows 10 (для старых игр начала 2000-х можно временно менять на Windows XP/7).

------------------------------








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
