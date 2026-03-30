# ##########################################################################
# 📘           ПОСТУСТАНОВОЧНАЯ НАСТРОЙКА Arch Linux
# ##########################################################################
# ################################################################
# 🔍 ЧАСТЬ 1: ПРЕДВАРИТЕЛЬНЫЕ ПРОВЕРКИ И ИНФОРМАЦИЯ
# ################################################################

# 1.1 Информация о дисках и разделах
# 💾 Полезно перед настройкой файловых систем (например, Btrfs) и Snapper.
#    Показывает путь к устройству, тип таблицы разделов, тип файловой системы и т.д.

lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME,SIZE,MOUNTPOINTS

# 1.2 Список явно установленных пакетов (без зависимостей)
# 📦 Показывает пакеты, которые вы установили вручную (не как зависимости).

pacman -Qqet

# 1.3 (Опционально) Проверка "висячих" зависимостей
# 🧹 Найдите пакеты, которые больше не требуются.

pacman -Qtd






#################################################################
# 🎧 ЧАСТЬ 2:    НАСТРОЙКА ЗВУКА ПОСЛЕ УСТАНОВКИ (PIPEWIRE)
#################################################################
# ⚠️ КОНТЕКСТ: Выполняется ПОСЛЕ первой загрузки в систему!
# 👤 ОТ ИМЕНИ: Обычного пользователя (НЕ root).
# 📦 ТРЕБУЕТСЯ: Пакеты из Блока 11 уже установлены.
# 📚 ИСТОЧНИКИ: Arch Wiki, comss.ru/page.php?id=19755
#################################################################

################# ШАГ 0: ПРОВЕРКА УСТАНОВЛЕННЫХ ПАКЕТОВ #######
# Убедитесь, что все необходимые пакеты установлены.

# Проверка установленных пакетов
pacman -Q pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber
pacman -Q sof-firmware alsa-ucm-conf alsa-utils

# Если чего-то нет — установите:
sudo pacman -S --needed --noconfirm pipewire pipewire-alsa pipewire-pulse pipewire-jack wireplumber sof-firmware alsa-ucm-conf alsa-utils

################# ШАГ 1: ВКЛЮЧЕНИЕ СЕРВИСОВ ###################
# PipeWire работает как user service (не системный!).

# Включить и запустить сервисы PipeWire
systemctl --user enable --now pipewire pipewire-pulse wireplumber

# Проверить статус (должно быть "active (running)")
systemctl --user status pipewire
systemctl --user status wireplumber

# Проверка, что PipeWire заменил PulseAudio
pactl info | grep "Server Name"
# Должно быть: PipeWire PulseAudio

################# ШАГ 2: ПРОВЕРКА ГРОМКОСТИ ###################
# ⚠️ После установки звук часто заглушен (Muted) по умолчанию!

# Запустить терминальный микшер
alsamixer

# 📌 ИНСТРУКЦИЯ:
# 1. Нажмите F6 → Выберите вашу звуковую карту (не PCH!)
# 2. Найдите каналы с пометкой "MM" (Muted)
# 3. Нажмите M для разблокировки (должно стать "00")
# 4. Стрелками ↑↓ настройте громкость:
#    - Master      : Общая громкость
#    - PCM         : Громкость воспроизведения
#    - Speaker     : Динамики
#    - Headphone   : Наушники
# 5. Нажмите Esc для выхода

# Если звук заглушен — разблокировать:
amixer set Master unmute
amixer set Master 80%

################# ШАГ 3: НАСТРОЙКА ВЫВОДА (Pavucontrol) ########
# Pavucontrol — удобный GUI для управления PipeWire.
# ⚠️ ОПЦИОНАЛЬНО: Не обязателен для всех систем!

# 📌 КОГДА PAVUCONTROL НУЖЕН:
# ┌─────────────────────────────────────────────────────────────┐
# │ Сценарий                    │  Pavucontrol  │  Почему      │
# ├─────────────────────────────────────────────────────────────┤
# │ Минималистичные WM (i3,     │  ✅ НУЖЕН     │  Нет GUI    │
# │ sway, hyprland, dwm)        │               │  настроек   │
# ├─────────────────────────────────────────────────────────────┤
# │ Продвинутая настройка       │  ✅ НУЖЕН     │  Пер-прило- │
# │ (громкость по приложениям)  │               │  жение, порты│
# ├─────────────────────────────────────────────────────────────┤
# │ Проблемы со звуком          │  ✅ НУЖЕН     │  Диагностика│
# │ (нет вывода, не тот порт)   │               │             │
# ├─────────────────────────────────────────────────────────────┤
# │ GNOME / KDE / XFCE          │  ❌ НЕ НУЖЕН  │  Встроено   │
# │ (полноценные DE)            │               │  в панель   │
# ├─────────────────────────────────────────────────────────────┤
# │ Обычное использование       │  ❌ НЕ НУЖЕН  │  Хватает    │
# │ (только громкость)          │               │  системного │
# └─────────────────────────────────────────────────────────────┘

# Если решили установить:
sudo pacman -S --needed --noconfirm pavucontrol

# Запустить
pavucontrol

# 📌 ВКЛАДКИ:
# 1. "Устройства вывода" → Выберите правильные динамики/наушники
# 2. "Воспроизведение" → Громкость по отдельным приложениям
# 3. "Запись" → Настройка микрофона
# 4. "Конфигурация" → Выберите профиль устройства

################# ШАГ 4: УЛУЧШЕНИЕ ЗВУКА (EasyEffects) #########
# EasyEffects — эквалайзер, шумоподавление, бас-буст и др.
# 📚 Рекомендации: comss.ru/page.php?id=19755

# ------------------------------------------------------------------------------
# 4.1. УСТАНОВКА EASYEFFECTS И ВСЕХ ПЛАГИНОВ
# ------------------------------------------------------------------------------
# Полная установка со всеми доступными плагинами для максимальных возможностей

sudo pacman -S --needed --noconfirm easyeffects calf lsp-plugins-lv2 zam-plugins-lv2 mda.lv2 yelp

# 📌 ЧТО УСТАНАВЛИВАЕТСЯ:
# ┌─────────────────────────────────────────────────────────────┐
# │ Пакет              │  Что даёт                              │
# ├─────────────────────────────────────────────────────────────┤
# │ easyeffects        │  Основная программа                    │
# ├─────────────────────────────────────────────────────────────┤
# │ calf               │  Компрессор, лимитер, эквалайзер,      │
# │                    │  реверберация, бас-энхансер            │
# ├─────────────────────────────────────────────────────────────┤
# │ lsp-plugins-lv2    │  Студийные плагины (параметрический    │
# │                    │  EQ, компрессор, дээссер, анализатор)  │
# ├─────────────────────────────────────────────────────────────┤
# │ zam-plugins-lv2    │  Дополнительные эффекты (гитара, бас)  │
# ├─────────────────────────────────────────────────────────────┤
# │ mda.lv2            │  Классические эффекты (пиано, органы)  │
# ├─────────────────────────────────────────────────────────────┤
# │ yelp               │  Справка по плагинам (документация)    │
# └─────────────────────────────────────────────────────────────┘

# ------------------------------------------------------------------------------
# 4.2. ЗАПУСК И НАСТРОЙКА
# ------------------------------------------------------------------------------
# Запуск EasyEffects
easyeffects

# 📌 ВКЛЮЧЕНИЕ АВТОЗАПУСКА:
# 1. Откройте EasyEffects → Настройки (⚙️)
# 2. Включите "Launch Service at System Startup"
# 3. Закройте настройки

# ------------------------------------------------------------------------------
# 4.3. ГОТОВЫЕ ПРЕСЕТЫ (АВТОМАТИЧЕСКАЯ И РУЧНАЯ УСТАНОВКА)
# ------------------------------------------------------------------------------
# ⚠️ ВАЖНО: Пресеты с comss.ru могут не работать из-за устаревшего формата!
#          Используйте актуальные пресеты с GitHub.

# 📌 ПРАВИЛЬНЫЙ ПУТЬ ДЛЯ ПРЕСЕТОВ:
# ~/.local/share/easyeffects/output/  ← Для вывода (динамики/наушники)
# ~/.local/share/easyeffects/input/   ← Для входа (микрофон)

# ═════════════════════════════════════════════════════════════
# 🚀 ПРЕСЕТЫ ОТ JackHack96/EasyEffects-Presets
# ═════════════════════════════════════════════════════════════
# Одна команда установит все пресеты в правильную папку!

# JackHack96 Presets (Автоматическая установка)
bash -c "$(curl -fsSL https://raw.githubusercontent.com/JackHack96/EasyEffects-Presets/master/install.sh)"

# 📌 После установки:
# 1. Откройте EasyEffects
# 2. Перейдите во вкладку "Предустановки" (📋)
# 3. В разделе "Локальные" найдите скачанный пресет
# 4. Нажмите на него для применения

# 📌 ПРОВЕРКА УСТАНОВЛЕННЫХ ПРЕСЕТОВ:
# Показать все локальные пресеты
ls -la ~/.local/share/easyeffects/output/
ls -la ~/.local/share/easyeffects/input/

# ------------------------------------------------------------------------------
# 4.4. РУЧНАЯ НАСТРОЙКА (ЕСЛИ ПРЕСЕТЫ НЕ ПОДОШЛИ)
# ------------------------------------------------------------------------------
# 1. Откройте вкладку "Эффекты" (🎛️)
# 2. Нажмите "Добавить эффект" (+)
# 3. Добавляйте плагины в порядке ниже:

# ┌─────────────────────────────────────────────────────────────────────────────┐
# │ № │  Плагин         │  Где найти          │  Настройки                     │
# ├───┼─────────────────┼─────────────────────┼────────────────────────────────┤
# │ 1 │  Filter         │  Фильтры            │  Type: High-pass               │
# │   │                 │                     │  Frequency: 90 Hz              │
# ├───┼─────────────────┼─────────────────────┼────────────────────────────────┤
# │ 2 │  Bass Enhancer  │  Бас                │  Amount: 5.0                   │
# │   │                 │                     │  Harmonics: 5.5                │
# │   │                 │                     │  Blend: -2.0                   │
# ├───┼─────────────────┼─────────────────────┼────────────────────────────────┤
# │ 3 │  Exciter        │  Эффекты            │  Amount: 3.0                   │
# │   │                 │                     │  Harmonics: 4.5                │
# ├───┼─────────────────┼─────────────────────┼────────────────────────────────┤
# │ 4 │  Stereo Tools   │  Стерео             │  Stereo Base: 0.45             │
# ├───┼─────────────────┼─────────────────────┼────────────────────────────────┤
# │ 5 │  Equalizer      │  Фильтры            │  Режим: 4 полосы               │
# │   │                 │                     │  Полоса 1: 250 Hz,  -2.5 dB    │
# │   │                 │                     │  Полоса 2: 1200 Hz, +1.5 dB    │
# │   │                 │                     │  Полоса 3: 4000 Hz, +2.0 dB    │
# │   │                 │                     │  Полоса 4: 10000 Hz, +1.0 dB   │
# ├───┼─────────────────┼─────────────────────┼────────────────────────────────┤
# │ 6 │  Compressor     │  Динамика           │  Attack: 15 ms                 │
# │   │                 │                     │  Release: 100 ms               │
# │   │                 │                     │  Ratio: 3.0                    │
# │   │                 │                     │  Threshold: -18 dB             │
# │   │                 │                     │  Makeup: 4.5 dB                │
# ├───┼─────────────────┼─────────────────────┼────────────────────────────────┤
# │ 7 │  Limiter        │  Динамика           │  Limit: -0.5 dB                │
# │   │                 │                     │  ⚠️ Всегда последним в цепи!   │
# └───┴─────────────────┴─────────────────────┴────────────────────────────────┘

# 📌 СОХРАНЕНИЕ СВОЕГО ПРЕСЕТА:
# 1. Настройте все плагины во вкладке "Эффекты"
# 2. Перейдите во вкладку "Предустановки"
# 3. Нажмите "Сохранить" (💾)
# 4. Дайте имя (например: "Laptop Speakers", "Music", "Gaming")
# 5. Включите "Auto Load" для автоматического применения

################# ШАГ 5: НАСТРОЙКА BLUETOOTH АУДИО ############
# Для беспроводных наушников и колонок.

# Включить службу Bluetooth
sudo systemctl enable --now bluetooth

# Проверить статус
systemctl status bluetooth

# 📌 В Pavucontrol:
# 1. Подключите Bluetooth-устройство
# 2. Перейдите во вкладку "Конфигурация"
# 3. Выберите профиль:
# ┌─────────────────────────────────────────────────────────────┐
# │ Профиль                          │  Качество  │  Использование │
# ├─────────────────────────────────────────────────────────────┤
# │ High Fidelity Playback (A2DP)    │  ✅ ВЫСОКОЕ │  Музыка, видео │
# │ Hands-Free (HSP/HFP)             │  ❌ НИЗКОЕ  │  Только звонки │
# └─────────────────────────────────────────────────────────────┘
#
# ⚠️ ВАЖНО: Нельзя использовать A2DP и микрофон одновременно!

################# ШАГ 6: ОПТИМИЗАЦИЯ ДЛЯ ИГР (НИЗКАЯ ЗАДЕРЖКА) #
# Уменьшение аудио-задержки для игр и записи.

# Создать конфиг PipeWire для низкой задержки
mkdir -p ~/.config/pipewire/pipewire.conf.d

echo "
context.properties = {
    default.clock.quantum = 512
    default.clock.min-quantum = 256
}
" > ~/.config/pipewire/pipewire.conf.d/99-low-latency.conf

# Перезапустить PipeWire для применения настроек
systemctl --user restart pipewire

# 📌 ПАРАМЕТРЫ:
# ┌─────────────────────────────────────────────────────────────┐
# │ Quantum  │  Задержка  │  Стабильность  │  Рекомендация    │
# ├─────────────────────────────────────────────────────────────┤
# │ 256      │  ~5 ms     │  ⚠️ Может трещать │  Профи         │
# │ 512      │  ~10 ms    │  ✅ Баланс       │  Игры            │
# │ 1024     │  ~20 ms    │  ✅✅ Максимум   │  Музыка/Видео    │
# └─────────────────────────────────────────────────────────────┘

################# ШАГ 7: ПРОВЕРКА РАБОТЫ ######################
# Тестовые команды для диагностики.

# 1. Тест звука (должны быть слышны гудки)
speaker-test -c 2 -t wav

# 2. Проверка активного вывода
pactl list short sinks

# 3. Проверка работы EasyEffects
pactl list modules | grep easyeffects

# 4. Проверка состояния PipeWire
pw-stat

# 5. Проверка микрофона
arecord -f cd -d 5 test.wav && aplay test.wav && rm test.wav

################# ШАГ 8: ДИАГНОСТИКА ПРОБЛЕМ ##################

# ❌ НЕТ ЗВУКА ВООБЩЕ:
# 1. Проверьте alsamixer — не стоит ли Mute (M)
#    Решение: Нажмите M для разблокировки
#
# 2. Проверьте pavucontrol — выбрано ли правильное устройство
#    Решение: Выберите активное устройство во вкладке "Вывод"
#
# 3. Проверьте статус сервисов:
#    systemctl --user status pipewire
#    Решение: systemctl --user restart pipewire
#
# 4. Для ноутбуков Intel — проверьте sof-firmware:
#    pacman -Q sof-firmware
#    Решение: sudo pacman -S sof-firmware

# ❌ ЗВУК ТИХИЙ:
# 1. Проверьте все уровни в alsamixer (Master, PCM, Speaker)
#    Решение: amixer set Master 100%
#
# 2. В EasyEffects добавьте Maximizer
#    Threshold: -6 dB, Ceiling: -1 dB

# ❌ МИКРОФОН НЕ РАБОТАЕТ:
# 1. В pavucontrol → "Запись" → выберите правильный микрофон
#
# 2. Добавьте Noise Reduction в EasyEffects
#
# 3. Проверьте разрешения (для Wayland):
#    Настройки → Конфиденциальность → Микрофон

# ❌ BLUETOOTH ПОДКЛЮЧАЕТСЯ, НО НЕТ ЗВУКА:
# 1. В pavucontrol выберите профиль A2DP (не HSP!)
#
# 2. Перезапустите Bluetooth:
#    sudo systemctl restart bluetooth

# ❌ ТРЕЩИТ ИЛИ ПРЕРЫВАЕТСЯ ЗВУК:
# 1. Увеличьте квант PipeWire (см. Шаг 6)
#    quantum = 1024 вместо 512
#
# 2. Отключите тяжёлые плагины в EasyEffects
#
# 3. Проверьте нагрузку на CPU:
#    htop

#################################################################
# 📚 ПОЛЕЗНЫЕ РЕСУРСЫ
#################################################################
# - Arch Wiki (PipeWire): https://wiki.archlinux.org/title/PipeWire
# - Arch Wiki (EasyEffects): https://wiki.archlinux.org/title/EasyEffects
# - Официальный GitHub: https://github.com/wwmm/easyeffects
# - Пресеты Digitalone1: https://github.com/Digitalone1/EasyEffects-Presets
# - Пресеты JackHack96: https://github.com/JackHack96/EasyEffects-Presets
# - Авто-установка пресетов: https://github.com/JackHack96/EasyEffects-Presets
#################################################################

#################################################################
# 🎉 УДАЧНОЙ НАСТРОЙКИ!
#################################################################
# ✅ Если все тесты прошли успешно — звук настроен идеально!
# 🎵 Наслаждайтесь качественным аудио в Arch Linux!
#################################################################






# ################################################################
# 📦 ЧАСТЬ 3: УСТАНОВКА ПРИЛОЖЕНИЙ
# ################################################################




clear
sudo pacman -Syy
sudo pacman -S --noconfirm \
doublecmd-qt6 vlc vlc-plugins-all \
fastfetch hyfetch inxi \
htop cpu-x gparted qbittorrent \
libreoffice-still-ru \
hardinfo2
sudo systemctl enable --now hardinfo2.service
sudo modprobe -a at24 ee1004 spd5118
sudo usermod -aG hardinfo2 $USER
yay -S --noconfirm \
pamac-aur ventoy-bin grub-customizer \
grub2-theme-arch-leap update-grub stacer-bin system-monitoring-center
clear
# ###




# ################################################################
# 🐚 ЧАСТЬ 4: НАСТРОЙКА Zsh И Oh My Zsh
# ################################################################




clear
sudo pacman -Sy
sudo pacman -S --noconfirm zsh
export CHSH=no
export RUNZSH=no
export KEEP_ZSHRC=yes
sh -c "$(curl -fsSL https://raw.githubusercontent.com/ohmyzsh/ohmyzsh/master/tools/install.sh)" "" --unattended
git clone --depth=1 https://github.com/zsh-users/zsh-syntax-highlighting.git ~/.oh-my-zsh/custom/plugins/zsh-syntax-highlighting
git clone --depth=1 https://github.com/zsh-users/zsh-autosuggestions.git ~/.oh-my-zsh/custom/plugins/zsh-autosuggestions
sed -i 's/^ZSH_THEME=.*/ZSH_THEME="agnoster"/' ~/.zshrc
sed -i 's/^plugins=(.*)/plugins=(git archlinux extract zsh-syntax-highlighting zsh-autosuggestions)/' ~/.zshrc
echo 'ZSH_AUTOSUGGEST_HIGHLIGHT_STYLE="fg=8"' >> ~/.zshrc
echo 'ZSH_AUTOSUGGEST_BUFFER_MAX_SIZE=20' >> ~/.zshrc
source ~/.zshrc
chsh -s $(which zsh)
grep -q "hyfetch" ~/.zshrc || echo "hyfetch" >> ~/.zshrc
clear





# ##############################################
# ## 🖋️  ЧАСТЬ 5: НАСТРОЙКА NANO
# ##############################################
#
# Зачем: Глубокая настройка редактора nano.
# Включает: Цвета, подсветку, автоотступы, табы, softwrap, поддержку мыши.

clear

# Объединяем все изменения sed в одну команду для эффективности
sudo sed -i '
s/# set autoindent/set autoindent/g;
s/# set constantshow/set constantshow/g;
s/# set indicator/set indicator/g;
s/# set linenumbers/set linenumbers/g;
s/# set multibuffer/set multibuffer/g;
s/# set quickblank/set quickblank/g;
s/# set smarthome/set smarthome/g;
s/# set softwrap/set softwrap/g;
s/# set tabsize 8/set tabsize 4/g;
s/# set tabstospaces/set tabstospaces/g;
s/# set trimblanks/set trimblanks/g;
s/# set unix/set unix/g;
s/# set wordbounds/set wordbounds/g;
s/# set titlecolor bold,white,magenta/set titlecolor bold,white,magenta/g;
s/# set promptcolor black,yellow/set promptcolor black,yellow/g;
s/# set statuscolor bold,white,magenta/set statuscolor bold,white,magenta/g;
s/# set errorcolor bold,white,red/set errorcolor bold,white,red/g;
s/# set spotlightcolor black,orange/set spotlightcolor black,orange/g;
s/# set selectedcolor lightwhite,cyan/set selectedcolor lightwhite,cyan/g;
s/# set stripecolor ,yellow/set stripecolor ,yellow/g;
s/# set scrollercolor magenta/set scrollercolor magenta/g;
s/# set numbercolor magenta/set numbercolor magenta/g;
s/# set keycolor lightmagenta/set keycolor lightmagenta/g;
s/# set functioncolor magenta/set functioncolor magenta/g;
s/# include \/usr\/share\/nano\/\*\.nanorc/include \/usr\/share\/nano\/\*\.nanorc/g;
#s/# set mouse/set mouse/g; # Включаем поддержку мыши
# Добавим строку для отключения строки справки, если это нужно пользователю
# s/# set nohelp/set nohelp/g;
' /etc/nanorc





# ################################################################
# 🖼️ ЧАСТЬ 6: СОЗДАНИЕ ISO ОБРАЗА С Archiso
# ################################################################

# 6.1 Установка archiso
clear
# 📦 Устанавливаем утилиту для создания ISO-образов.
sudo pacman -S archiso
clear


# 6.2 Создание образа
# 📁 Создаем рабочую директорию.
mkdir -p ~/ArchIso/ && cd ~/ArchIso/
# 🏗️ Запускаем mkarchiso с официальным профилем releng.
sudo mkarchiso -v /usr/share/archiso/configs/releng/
# 📁 Результат появится в ~/out/ (по умолчанию).
# 🧹 Удаляем временную директорию.
sudo rm -r ~/ArchIso/





clear
# ################################################################
# 🖥️ ЧАСТЬ 7: УСТАНОВКА VirtualBox
# ################################################################

# 7.1 Установка основного пакета
# 📦 Устанавливаем VirtualBox.
sudo pacman -S virtualbox

# 💡 Во время установки вам будет предложено выбрать версию драйвера ядра
#    (например, `virtualbox-host-modules-arch`, `virtualbox-host-modules-lts` или `virtualbox-host-dkms`).
#    Выберите подходящую версию для вашего ядра (например, `virtualbox-host-modules-lts` для linux-lts).

# 7.2 Установка дополнительных пакетов
# 💾 Устанавливаем образ гостевых дополнений.
sudo pacman -S virtualbox-guest-iso

# 7.3 Добавление пользователя в группу
# 🔐 Добавляем пользователя в группу vboxusers для доступа к VirtualBox.
sudo gpasswd -a $USER vboxusers
clear
# 🔁 Выйдите из системы и снова войдите, чтобы изменения вступили в силу.
# reboot # Раскомментируйте, если хотите перезагрузить сразу.

# ⚠️ ВАЖНО: Если вы используете Wayland (например, KDE Plasma под Wayland),
# уведомления VirtualBox могут быть неинтерактивны (нельзя закрыть кликом).
# Чтобы отключить эти уведомления, выполните следующие команды после установки
# и перезапустите VirtualBox:

# VBoxManage setextradata global GUI/ShowMiniToolBar 0
# VBoxManage setextradata global GUI/NotifyAboutUserInput 0
# VBoxManage setextradata global GUI/NotifyAbout3DUserInput 0
# VBoxManage setextradata global GUI/ShowNotificationIcons 0
# VBoxManage setextradata global GUI/ShowNotifications 0

# ################################################################
# 📌 ЧАСТЬ 8: ПОЛЕЗНЫЕ КОМАНДЫ И НАСТРОЙКИ
# ################################################################

# 8.1 Установка темы KDE Plasma
# 🎨 Установка темы оформления из архива.
# kpackagetool6 --type Plasma/LookAndFeel --install архив_с_темой.tar.xz

# 8.2 Обновление системы
# 🔄 Обновление всех пакетов и очистка кэша.
# yay -Syu
# yay -Sc






# ################################################################
# ✅ ЗАКЛЮЧЕНИЕ
# ################################################################
# ✅ <<< ПОСТУСТАНОВОЧНАЯ НАСТРОЙКА Arch Linux ЗАВЕРШЕНА >>> ✅
# 💡 Теперь ваша система готова к использованию.
#    Не забывайте регулярно обновлять пакеты и следить за безопасностью.
