#################################################################
# 🐧 МАКЕТ БЛОЧНОЙ УСТАНОВКИ ARCH LINUX (BTRFS)
#################################################################
# ℹ️ Назначение: Пошаговая установка Arch Linux с BTRFS.
# 💡 Метод: Копируйте и вставляйте блоки команд по одному.
# ❗ Важно: Не запускайте как скрипт! Выполняйте вручную.
# 🌐 Требуется: Интернет, загрузочная среда Arch Linux (свежий ISO).
# 💡 Примечание: Данная установка предназначена для компьютеров
# с прошивкой BIOS (Legacy Boot), но с использованием таблицы разделов GPT.
# Требуется специальный BIOS Boot Partition (тип EF02).
#################################################################
# 📖 ДЛЯ НОВИЧКОВ — ЧТО НУЖНО ЗНАТЬ ПЕРЕД НАЧАЛОМ:
# ┌─────────────────────────────────────────────────────────────────┐
# │ ⏱️ ВРЕМЯ УСТАНОВКИ:                                             │
# │    ├─ Первая установка: 2-4 часа (с чтением документации)       │
# │    ├─ Повторная установка: 30-60 минут                          │
# │    └─ Не спешите! Ошибки могут привести к потере данных         │
# │                                                                 │
# │ 📋 ЧТО НУЖНО ПОДГОТОВИТЬ:                                       │
# │    ├─ ✓ Загрузочная флешка с Arch Linux (последний ISO)         │
# │    ├─ ✓ Резервная копия ВСЕХ важных данных                      │
# │    ├─ ✓ Стабильное подключение к интернету                      │
# │    ├─ ✓ Заряженное устройство (ноутбук к сети!)                 │
# │    └─ ✓ Блокнот для записи паролей и настроек                   │
# │                                                                 │
# │ 🔑 ТЕРМИНЫ КОТОРЫЕ ВСТРЕТЯТСЯ:                                  │
# │    ├─ BIOS — старый стандарт прошивки (Legacy Boot)             │
# │    ├─ UEFI — современный стандарт прошивки (вместо BIOS)        │
# │    ├─ BTRFS — файловая система с поддержкой снапшотов           │
# │    ├─ GPT — современная таблица разделов                        │
# │    ├─ BIOS Boot — специальный раздел для GRUB в BIOS+GPT        │
# │    ├─ chroot — переход в установленную систему из Live-среды    │
# │    ├─ pacman — менеджер пакетов Arch Linux                      │
# │    └─ AUR — репозиторий пользовательских пакетов                │
# │                                                                 │
# │ ⚠️ КРИТИЧЕСКИ ВАЖНО:                                            │
# │    ├─ Все данные на диске будут УДАЛЕНЫ!                        │
# │    ├─ Замените 'sdx' на имя ВАШЕГО диска (sda, nvme0n1, etc.)   │
# │    └─ Запомните пароли root и пользователя!                     │
# └─────────────────────────────────────────────────────────────────┘
#################################################################
# Структура установки:
# 1.  Настройка локации зеркал (Блок 0)
# 2.  Подготовка Live-среды (Блок 1)
# 3.  Диагностика оборудования (Блок 2)
# 4.  Настройка переменных (Блок 3) — ОБЯЗАТЕЛЬНО!
# 5.  Разметка диска GPT + BIOS Boot (Блок 4)
# 6.  Форматирование и монтирование (Блок 5)
# 7.  Установка базовых пакетов (Блок 6)
# 8.  Настройки внутри системы chroot (Блок 7)
# 9.  Hostname и пароль root (Блок 8)
# 10. Пользователь и sudo (Блок 9)
# 11. Установка ядра, GRUB, mkinitcpio (Блок 10)
# 12. Системные утилиты и настройки (Блок 11)
# 13. Установка видеодрайвера (Блок 12)
# 14. Установка в VirtualBox (Блок 13) — опционально
# 15. Установка графической среды DE/WM (Блок 14)
# 16. Завершение процесса (Блок 15)
# 17. Рекомендации после установки (Блок 16)
#################################################################











#################################################################
# 🔍  БЛОК 0: НАСТРОЙКА ЛОКАЦИИ ЗЕРКАЛ (Mirrors)
#################################################################
# ℹ️ Зачем: Для быстрой и качественной установки необходимы правильно
# подобранные зеркала mirrorlist. А для их настройки необходим reflector.
# ❗ Важно: Не выполнять в Live среде. Выполняется отдельно на компьютере
# с установленной системой.
# 💡 Показывает: Список 10 стран, которые ближе всего от местоположения
# пользователя.
#################################################################
clear
sudo pacman -Syy
# 📦 Установка необходимых зависимостей Python
# python — язык программирования для запуска скрипта
# python-requests — библиотека для HTTP запросов к API
# python-geopandas — работа с географическими данными карты
# python-shapely — геометрические операции для расчёта расстояний
sudo pacman -Sy --needed --noconfirm python python-requests python-geopandas python-shapely
# 🔍 СОЗДАНИЕ СКРИПТА
# Создание файла скрипта nearest_countries.py для определения местоположения
cat > nearest_countries.py << 'EOF'
import requests
import geopandas as gpd
from shapely.geometry import Point
import sys

# Функция получения координат по IP
def get_ip_location():
    try:
        # Используем бесплатный API без ключа
        response = requests.get('http://ip-api.com/json/')
        data = response.json()
        if data['status'] == 'fail':
            raise Exception("Не удалось определить местоположение по IP")
        return float(data['lat']), float(data['lon']), data.get('countryCode', 'Unknown')
    except Exception as e:
        print(f"Ошибка геолокации IP: {e}")
        sys.exit(1)

# Функция загрузки границ стран
def get_world_data():
    url = "https://raw.githubusercontent.com/johan/world.geo.json/master/countries.geo.json"
    try:
        gdf = gpd.read_file(url)
        return gdf
    except Exception as e:
        print(f"Ошибка загрузки данных карты: {e}")
        sys.exit(1)

# Основная функция
def main():
    print("1. Определение местоположения по IP...")
    lat, lon, user_country_code = get_ip_location()
    print(f"   Ваше местоположение (IP): {lat}, {lon} (Страна: {user_country_code})")
    print("2. Загрузка данных о границах стран...")
    world = get_world_data()
    print(f"   Загружено границ: {len(world)}")
    
    # Создаем гео-объект пользователя
    user_point = Point(lon, lat)
    user_geo = gpd.GeoDataFrame([{'geometry': user_point}], crs="EPSG:4326")
    
    # Проецируем в метры (Mercator) для точного расчета расстояния
    world_proj = world.to_crs(epsg=3395)
    user_proj = user_geo.to_crs(epsg=3395)
    user_point_proj = user_proj.geometry[0]
    
    print("3. Расчет расстояний до границ стран...")
    # Считаем минимальное расстояние до полигона каждой страны
    world_proj['distance'] = world_proj.geometry.distance(user_point_proj)
    nearest = world_proj.sort_values(by='distance')
    
    print("\n--- 10 ближайших стран (географически) ---")
    print(f"{'#': <3} {'Страна': <20} {'Расстояние (км)': <15} {'Код'}")
    print("-" * 50)
    
    count = 0
    for index, row in nearest.iterrows():
        name = row.get('name', 'Unknown')
        dist_km = row['distance'] / 1000
        print(f"{count + 1: <3} {name: <20} {dist_km: <15.2f} {row.get('id', 'N/A')}")
        count += 1
        if count >= 10:
            break

if __name__ == "__main__":
    main()
EOF
# 🚀 ЗАПУСК И ВЕРИФИКАЦИЯ
# ⚡ 3.1 Запуск скрипта для определения ближайших стран
clear
python ~/nearest_countries.py
# Удаление скрипта nearest_countries.py после использования
rm -r ~/nearest_countries.py
echo " "
echo "#################################################################"
echo "## 🧭 10 БЛИЖАЙШИХ СТРАН ОПРЕДЕЛЕНЫ                             ##"
echo "#################################################################"
echo "# "
echo " ✅ ВСЕ ДЕЙСТВИЯ ВЫПОЛНЕНЫ."
echo " ⚠️ Составьте по порядку список стран, через запятую, которые ближе всего."
echo " 📌 Замените переменную Russia на результат из скрипта."
echo " ⚙️ ПРИМЕР: Russia > Russia,Estonia,Latvia,Finland,Belarus,Lithuania"
echo "# ➡️ ПРОДОЛЖИТЕ УСТАНОВКУ:"
echo " "
#######################################################
# ПРИ НЕОБХОДИМОСТИ ЗАМЕНИТЕ СТРАНУ ЛОКАЦИИ ЗЕРКАЛ
# COUNTRY: Russia
#######################################################











#################################################################
# ⚙️ [LIVE] БЛОК 1: ПОДГОТОВКА LIVE-СРЕДЫ
#################################################################
# ℹ️ Зачем: Настройка системных часов, обновление зеркал, установка
# вспомогательных утилит.
# ℹ️ Важно: Выполняется в загрузочной среде (до chroot).
# 💡 Включает: haveged, inxi, lshw.
#################################################################
clear
# 🎹 Установка русской раскладки клавиатуры
loadkeys ru
# 🔤 Установка русского шрифта для консоли
setfont cyr-sun16
# ⏰ Синхронизация системного времени через NTP
timedatectl set-ntp true
# 🌐 Включение русской и английской локали в locale.gen
sed -i "s/#ru_RU/ru_RU/" /etc/locale.gen
sed -i "s/#en_US/en_US/" /etc/locale.gen
# locale-gen — генерация выбранных локалей
locale-gen
# export LANG — установка основной локали системы
export LANG=ru_RU.UTF-8
# ⚙️ Настройка pacman: параллельная загрузка 15 пакетов
sed -i s/'ParallelDownloads = 5'/'ParallelDownloads = 15'/g /etc/pacman.conf
# Включение цветного вывода pacman
sed -i s/'#Color'/'Color'/g /etc/pacman.conf
# Включение подробного списка пакетов при обновлении
sed -i '/^Color$/a VerbosePkgLists' /etc/pacman.conf
# Отключение таймаута загрузки пакетов
sed -i '/^Color$/a DisableDownloadTimeout' /etc/pacman.conf
# Включение индикатора прогресса "ILoveCandy"
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf
# Повторная синхронизация времени
timedatectl set-ntp true
# 🌐 Настройка reflector для выбора быстрых зеркал
echo "--country Russia" > /etc/xdg/reflector/reflector.conf
echo "--protocol https" >> /etc/xdg/reflector/reflector.conf
echo "--age 24" >> /etc/xdg/reflector/reflector.conf
echo "--sort rate" >> /etc/xdg/reflector/reflector.conf
echo "--latest 20" >> /etc/xdg/reflector/reflector.conf
echo "--connection-timeout 10" >> /etc/xdg/reflector/reflector.conf
echo "--download-timeout 10" >> /etc/xdg/reflector/reflector.conf
echo "--save /etc/pacman.d/mirrorlist" >> /etc/xdg/reflector/reflector.conf
# Перезапуск службы reflector для применения настроек
systemctl restart reflector
clear
echo " "
# 🔄 Принудительное обновление базы данных пакетов
pacman -Syy
# 📦 haveged — генератор энтропии для ускорения шифрования (~0.1 МБ)
# 📦 inxi — утилита для получения информации о системе (~0.5 МБ)
# 📦 util-linux — базовые утилиты Linux (lsblk, mount, fdisk) (~5 МБ)
pacman -Sy --needed --noconfirm haveged inxi util-linux
# 📦 lshw — подробная информация об оборудовании (~0.3 МБ)
pacman -Sy --needed --noconfirm lshw
# Включение и запуск службы haveged
systemctl enable haveged.service --now
clear
echo " "
echo "#####################################################"
echo "## ✅ ПОДГОТОВКА LIVE-СРЕДЫ ЗАВЕРШЕНА              ##"
echo "#####################################################"
echo " "











#################################################################
# 🔍  [LIVE] БЛОК 2: ДИАГНОСТИКА ОБОРУДОВАНИЯ
#################################################################
# ℹ️ Зачем: Вывод информации об оборудовании для настройки переменных.
# ❗ Важно: Сравните вывод с переменными в БЛОКЕ 3.
# 💡 Показывает: CPU, MB, диски, рекомендации по монтированию FSTAB.
#################################################################
clear
echo " "
echo "=== ДИАГНОСТИКА ОБОРУДОВАНИЯ ==="
echo " "
# 💾 Определение имени диска для замены переменной sdx
# lsblk — показывает все диски и разделы
# ⚠️ Запомните имя вашего диска (sda, sdb, nvme0n1, etc.)
echo "Замените переменную sdx на ваш жесткий диск для разметки диска"
echo "Пример: если ваш диск /dev/sda, замените ВСЕ 'sdx' на 'sda' в макете."
echo " "
lsblk
echo " "
echo " "
# 🔍 Определение производителя процессора
# lshw -C cpu — информация о процессоре
# ⚠️ Для Intel замените 'amd-ucode' на 'intel-ucode' в Блоке 6
echo "Замените или оставьте переменную amd-ucode в зависимости от типа вашего процессора"
echo "Для Intel: замените 'amd-ucode' на 'intel-ucode'"
echo " "
echo "Производитель процессора:"
lshw -C cpu 2>/dev/null | grep 'vendor:' | uniq
echo " "
echo " "
# 🖥️ Определение модели материнской платы
# inxi -M — информация о материнской плате
# ⚠️ Замените 'Sony' на желаемое имя компьютера
echo "Замените переменную Sony на имя вашего компьютера"
echo " "
echo "Материнская плата:"
inxi -M
echo " "
echo " "
# 💾 Рекомендации по размеру SWAP
# inxi -I — общая информация о системе (включая RAM)
# ⚠️ Для 8GB RAM замените '4G' на '8G' в Блоке 4
echo "Замените переменную 4G на необходимый размер SWAP"
echo "Пример: для 8GB swap, замените '4G' на '8G'"
echo " "
echo "Общая информация о системе:"
inxi -I
echo " "
echo " "
# 📊 Определение типа дисков (HDD/SSD) для параметров монтирования
# Это нужно для правильных параметров монтирования BTRFS
echo "=== РЕКОМЕНДУЕМЫЕ ПАРАМЕТРЫ МОНТИРОВАНИЯ FSTAB ==="
echo "Определение типа дисков (HDD/SSD) для параметров монтирования:"
{  
echo;  
for DEVICE in $(lsblk -dno NAME 2>/dev/null | grep -v -e '^loop' -e '^sr'); do  
DEVICE_PATH="/dev/$DEVICE";  
[[ ! -b "$DEVICE_PATH" ]] && continue;  
ROTA=$(lsblk -d -o ROTA --noheadings "$DEVICE_PATH" 2>/dev/null | awk '{print $1}');  
if [[ "$ROTA" == "1" ]]; then  
DISK_TYPE="HDD (Замените 'defaults' в БЛОКЕ 3 на):";  
MOUNT_OPTIONS="noatime,space_cache=v2,compress=zstd:3,autodefrag";  
else  
DISK_TYPE="SSD (Замените 'defaults' в БЛОКЕ 3 на):";  
MOUNT_OPTIONS="ssd,noatime,space_cache=v2,compress=zstd:3,discard=async";  
fi;  
echo "╔════════════════════════════════════════════════════════════════╗";  
printf "║  Диск: %-50s\n" "/dev/$DEVICE";  
echo "╠════════════════════════════════════════════════════════════════╣";  
printf "║  Тип: %-50s\n" "$DISK_TYPE";  
printf "║  Параметры: %-50s\n" "$MOUNT_OPTIONS";  
echo "╚════════════════════════════════════════════════════════════════╝";  
echo;  
done;  
}
echo " "
echo "#####################################################"
echo "## ✅ ДИАГНОСТИКА ОБОРУДОВАНИЯ ЗАВЕРШЕНА           ##"
echo "#####################################################"
echo " "











#################################################################
# 🔧  [EDIT] БЛОК 3: НАСТРОЙКА ПЕРЕМЕННЫХ (ОБЯЗАТЕЛЬНО!)
#################################################################
# ℹ️ Зачем: Настроить макет под ваше оборудование.
# ❗ ВАЖНО: Замена переменных происходит в ДВА ЭТАПА!
# 💡 ИНСТРУКЦИЯ:
#    ЭТАП 1 (СЕЙЧАС, до Блока 4): Замените sdx, Sony, forename, 4G
#    ЭТАП 2 (ПОСЛЕ Блока 4): Замените sda1, sda2, sda3 на реальные разделы
#################################################################################
# Назначение                 # Значение (шаблон)      # Когда менять?
#################################################################################
# Имя диска                  # sdx                    # ЭТАП 1 (сейчас)
# BIOS Boot Partition (GPT)  # sda1                   # ЭТАП 2 (после Блока 4)
# Root раздел                # sda2                   # ЭТАП 2 (после Блока 4)
# Swap раздел                # sda3                   # ЭТАП 2 (после Блока 4)
# Размер SWAP                # 4G                     # ЭТАП 1 (сейчас)
# Имя компьютера (HOSTNAME)  # Sony                   # ЭТАП 1 (сейчас)
# Имя пользователя           # forename               # ЭТАП 1 (сейчас)
# Полное имя пользователя    # User Name              # ЭТАП 1 (сейчас)
# Microcode                  # amd-ucode              # ЭТАП 1 (сейчас)
# Ядро                       # linux-lts              # ЭТАП 1 (сейчас)
# Параметры монтирования     # defaults               # ЭТАП 1 (сейчас)
#################################################################################
# 💡 СОВЕТ: После ЭТАПА 1 проверьте, что в файле больше нет строки "sdx".
# После ЭТАПА 2 — проверьте, что разделы соответствуют вашему диску.
#
# 📌 ВАЖНО: В режиме BIOS+GPT раздел sda1 — это НЕ /boot!
# Он не форматируется и не монтируется (BIOS Boot Partition).
#####################################################
# ✅ ПЕРЕМЕННЫЕ НАСТРОЕНЫ. ПЕРЕХОДИТЕ К БЛОКУ 4
#####################################################











#################################################################
# 💾  [LIVE] БЛОК 4: РАЗМЕТКА ДИСКА (GPT + BIOS Boot)
#################################################################
# ℹ️ Зачем: Создание разделов: BIOS Boot (EF02), root, swap.
# ❗ ВАЖНО: Все данные на /dev/sdx будут УДАЛЕНЫ!
# 💡 Используется: sgdisk для создания таблицы разделов GPT.
# ℹ️ ПЕРЕД ВЫПОЛНЕНИЕМ: Убедитесь, что 'sdx' заменён на ваш диск!
#################################################################
clear
# 🧹 Полная очистка диска от старых разделов и подписей
# wipefs --all --force — удаление всех подписей разделов
# sgdisk -Z — удаление таблицы разделов
wipefs --all --force /dev/sdx
sgdisk -Z /dev/sdx
# 📐 Создание новой таблицы разделов GPT с выравниванием 2048 секторов
# sgdisk -a 2048 — выравнивание разделов (оптимально для SSD)
# sgdisk -o — создание новой GPT таблицы
sgdisk -a 2048 -o /dev/sdx
# 📦 РАЗДЕЛ 1: BIOS Boot Partition — 4 МБ, тип ef02
# Назначение: Загрузчик GRUB для BIOS+GPT
# ⚠️ Этот раздел НЕ форматируется и НЕ монтируется!
sgdisk -n 1:0:+4M --typecode=1:ef02 --change-name=1:'BIOS Boot' /dev/sdx
# 📦 РАЗДЕЛ 2: ROOT — всё место минус 4ГБ для swap, тип 8300
# Назначение: Основная файловая система BTRFS
sgdisk -n 2:0:-4G --typecode=2:8300 --change-name=2:'Root Arch Linux' /dev/sdx
# 📦 РАЗДЕЛ 3: SWAP — оставшееся место, тип 8200
# Назначение: Виртуальная память + гибернация
sgdisk -n 3:0:0 --typecode=3:8200 --change-name=3:'Swap Arch Linux' /dev/sdx
clear
echo " "
# 🔍 Проверка созданной разметки
# fdisk -l — подробная информация о разделах
fdisk -l /dev/sdx
echo " "
# lsblk -a — дерево устройств со всеми разделами
lsblk -a /dev/sdx
echo " "
echo "#####################################################"
echo "## ✅ РАЗМЕТКА ДИСКА (GPT + BIOS) ЗАВЕРШЕНА        ##"
echo "#####################################################"
echo " "
echo " "
#################################################################
# 💡 ОБЯЗАТЕЛЬНО:
# После разметки проверьте имена разделов через lsblk!
# Замените sda1, sda2, sda3 на реальные имена в следующих блоках!
#################################################################











#################################################################
# 💾  [LIVE] БЛОК 5: ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ
#################################################################
# ℹ️ Зачем: Форматирование, создание подтомов Btrfs, монтирование.
# 💡 Подтомы: @, @home, @log, @pkg (для снапшотов).
# ❗ ПЕРЕД ВЫПОЛНЕНИЕМ: Проверьте имена разделов (sda1, sda2, sda3)!
#################################################################
clear
# 📦 Создание и активация swap раздела
# mkswap — инициализация swap раздела
# swapon — активация swap
mkswap /dev/sda3
swapon /dev/sda3
# 📦 Форматирование root раздела в BTRFS
# mkfs.btrfs -f — создание BTRFS (-f = принудительно)
mkfs.btrfs -f /dev/sda2
# 📦 Монтирование root раздела временно для создания подтомов
mount /dev/sda2 /mnt
# 📦 Создание подтомов BTRFS для снапшотов
# @ — корневая система
# @home — домашние каталоги пользователей
# @log — системные логи
# @pkg — кэш пакетов pacman
btrfs subvolume create /mnt/@
btrfs subvolume create /mnt/@home
btrfs subvolume create /mnt/@log
btrfs subvolume create /mnt/@pkg
# Отмонтирование для правильного монтирования подтомов
umount /mnt
# 📦 Монтирование подтома @ как корень системы
# subvol=@ — монтировать подтом @ как корень
mount -o defaults,subvol=@ /dev/sda2 /mnt
# Создание необходимых директорий
mkdir -p /mnt/{home,var/log,var/cache/pacman/pkg,var/lib/machines,var/lib/portables}
# 📦 Монтирование остальных подтомов
mount -o defaults,subvol=@home /dev/sda2 /mnt/home
mount -o defaults,subvol=@log /dev/sda2 /mnt/var/log
mount -o defaults,subvol=@pkg /dev/sda2 /mnt/var/cache/pacman/pkg
# ⚠️ ВНИМАНИЕ: В BIOS версии НЕТ монтирования EFI раздела!
# Раздел sda1 (BIOS Boot) не форматируется и не монтируется
clear
echo " "
# 🔍 Проверка структуры разделов
lsblk -o PATH,PTTYPE,PARTTYPE,FSTYPE,PARTTYPENAME /dev/sdx
echo " "
lsblk /dev/sdx
echo " "
# Список всех подтомов BTRFS
btrfs subvolume list /mnt
echo " "
echo "#####################################################"
echo "## ✅ ФОРМАТИРОВАНИЕ И МОНТИРОВАНИЕ ЗАВЕРШЕНО      ##"
echo "#####################################################"
echo " "











#################################################################
# 🧱  [LIVE] БЛОК 6: УСТАНОВКА БАЗОВЫХ ПАКЕТОВ
#################################################################
# ℹ️ Зачем: Установка минимальной системы и переход в chroot.
# 💡 Включает: base, btrfs, nano, pacman-contrib.
#################################################################
clear
# 📦 base — минимальный набор пакетов Arch Linux (~150 МБ)
# 📦 base-devel — инструменты разработки для компиляции (~200 МБ)
pacstrap /mnt base base-devel
# 📦 btrfs-progs — утилиты для работы с BTRFS (~5 МБ)
pacstrap /mnt btrfs-progs
# 📦 amd-ucode — микрокод для процессоров AMD (~3 МБ)
# 📦 iucode-tool — утилита для управления микрокодом Intel
# ⚠️ Для Intel замените amd-ucode на intel-ucode iucode-tool
pacstrap /mnt amd-ucode
# 📦 memtest86+ — тест оперативной памяти для BIOS (~2 МБ)
# ⚠️ В BIOS версии используется memtest86+ (без -efi)
pacstrap /mnt memtest86+
# 📦 nano — простой текстовый редактор для новичков (~0.3 МБ)
pacstrap /mnt nano
# 📦 pacman-contrib — дополнительные утилиты для pacman (~0.5 МБ)
# 📦 curl — загрузка файлов через HTTP/HTTPS (~0.7 МБ)
# 📦 reflector — автоматический выбор ближайших зеркал (~0.3 МБ)
pacstrap /mnt pacman-contrib curl reflector
# 📋 Генерация fstab — таблица монтирования разделов
# genfstab -pU — использовать UUID (надёжнее чем имена устройств)
genfstab -pU /mnt >> /mnt/etc/fstab
clear
echo " "
echo "#####################################################"
echo "## ✅ УСТАНОВКА БАЗОВЫХ ПАКЕТОВ ЗАВЕРШЕНА          ##"
echo "#####################################################"
echo " "
# 🚪 Вход в chroot — переход в установленную систему
# arch-chroot /mnt /bin/bash — запускаем оболочку bash в новой системе
arch-chroot /mnt /bin/bash
echo " "











#################################################################
# 🛠️  [CHROOT] БЛОК 7: НАСТРОЙКИ ВНУТРИ СИСТЕМЫ
#################################################################
# ℹ️ Зачем: Настройка системы: локали, fstab, время, зеркала.
#################################################################
clear
# 🔧 Исправление fstab для BTRFS подтомов
sed -i 's/\S subvol=(\S)/subvol=\1,defaults/g' /etc/fstab
# 📦 Включение репозитория multilib для 32-битных приложений
sed -i "/\[multilib\]/,/Include/"'s/^#//' /etc/pacman.conf
# ⚙️ Настройка pacman (как в Блоке 1)
sed -i s/'ParallelDownloads = 5'/'ParallelDownloads = 15'/g /etc/pacman.conf
sed -i s/'#Color'/'Color'/g /etc/pacman.conf
sed -i '/^Color$/a VerbosePkgLists' /etc/pacman.conf
sed -i '/^Color$/a DisableDownloadTimeout' /etc/pacman.conf
sed -i '/^Color$/a ILoveCandy' /etc/pacman.conf
# ⌨️ Настройка консоли (русский язык)
echo "KEYMAP=ru" > /etc/vconsole.conf
echo "FONT=cyr-sun16" >> /etc/vconsole.conf
# 🌐 Настройка локали
echo "LANG=ru_RU.UTF-8" > /etc/locale.conf
sed -i "s/#ru_RU/ru_RU/" /etc/locale.gen
sed -i "s/#en_US/en_US/" /etc/locale.gen
locale-gen
export LANG=ru_RU.UTF-8
# ⏰ Настройка временной зоны по IP
time_zone=$(curl -s https://ipinfo.io/timezone)
ln -sf /usr/share/zoneinfo/$time_zone /etc/localtime
hwclock --systohc
# 🌐 Настройка reflector
echo "--country Russia" > /etc/xdg/reflector/reflector.conf
echo "--protocol https" >> /etc/xdg/reflector/reflector.conf
echo "--age 24" >> /etc/xdg/reflector/reflector.conf
echo "--sort rate" >> /etc/xdg/reflector/reflector.conf
echo "--latest 20" >> /etc/xdg/reflector/reflector.conf
echo "--connection-timeout 10" >> /etc/xdg/reflector/reflector.conf
echo "--download-timeout 10" >> /etc/xdg/reflector/reflector.conf
echo "--save /etc/pacman.d/mirrorlist" >> /etc/xdg/reflector/reflector.conf
systemctl enable reflector.timer
clear
clear
echo " "
timedatectl status
echo " "
date
echo " "
echo "#####################################################"
echo "## ✅ БАЗОВАЯ КОНФИГУРАЦИЯ ЗАВЕРШЕНА               ##"
echo "#####################################################"
echo " "











#################################################################
# 🔐  [CHROOT] БЛОК 8: НАСТРОЙКА HOST И ROOT
#################################################################
# ℹ️ Зачем: Настройка имени системы и пароля root.
#################################################################
clear
# 🖥️ Настройка имени компьютера (замените Sony на своё)
echo "Sony" > /etc/hostname
# 📋 Настройка файла hosts
echo "127.0.0.1   localhost" > /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   Sony.localdomain   Sony" >> /etc/hosts
clear
echo " "
echo "###################################"
echo "## 🔑 СОЗДАЙТЕ ПАРОЛЬ ДЛЯ ROOT   ##"
echo "###################################"
echo " "
# 🔑 Установка пароля root
# ⚠️ Запомните этот пароль! Он нужен для администрирования
passwd
clear
echo " "
echo "#####################################################"
echo "## ✅ НАСТРОЙКА ROOT И HOST ЗАВЕРШЕНА              ##"
echo "#####################################################"
echo " "











#################################################################
# 👤  [CHROOT] БЛОК 9: ПОЛЬЗОВАТЕЛЬ И SUDO
#################################################################
# ℹ️ Зачем: Создание пользователя и настройка sudo.
#################################################################
clear
# 👤 Создание пользователя (замените forename и User Name)
# useradd forename — создать пользователя 'forename'
# -m — создать домашний каталог
# -c "User Name" — полное имя пользователя
# -s /bin/bash — оболочка по умолчанию
useradd forename -m -c "User Name" -s /bin/bash
# 📦 Добавление пользователя в группы wheel (sudo) и users
usermod -aG wheel,users forename
# 🔓 Включение sudo для группы wheel
sed -i s/'# %wheel ALL=(ALL:ALL) ALL'/'%wheel ALL=(ALL:ALL) ALL'/g /etc/sudoers
clear
echo " "
echo "###########################################"
echo "## 👤 СОЗДАЙТЕ ПАРОЛЬ ДЛЯ ПОЛЬЗОВАТЕЛЯ   ##"
echo "###########################################"
echo " "
# 🔑 Установка пароля пользователя
# ⚠️ Запомните этот пароль! Он для повседневного входа
passwd forename
clear
echo " "
echo "#####################################################"
echo "## ✅ НАСТРОЙКА ПОЛЬЗОВАТЕЛЯ И SUDO ЗАВЕРШЕНА      ##"
echo "#####################################################"
echo " "











#################################################################
# 🔧  [CHROOT] БЛОК 10: УСТАНОВКА ЯДРА, GRUB, MKINITCPIO
#################################################################
# ℹ️ Зачем: Настройка загрузчика и initramfs для BIOS+GPT.
# 💡 Включает: GRUB, grub-btrfs, plymouth, resume из swap.
#################################################################
clear
pacman -Syy
# 📦 linux-lts — ядро с долгосрочной поддержкой (~100 МБ)
# 📦 linux-lts-headers — заголовки ядра для драйверов (~15 МБ)
# 📦 linux-firmware — прошивки для оборудования (~200 МБ)
pacman -Sy --needed --noconfirm linux-lts linux-lts-headers linux-firmware
# 📦 grub — загрузчик системы для BIOS (~5 МБ)
# 📦 grub-btrfs — интеграция снапшотов BTRFS в GRUB (~0.2 МБ)
# ⚠️ В BIOS версии НЕ нужен efibootmgr!
pacman -Sy --needed --noconfirm grub grub-btrfs
# 📦 networkmanager — управление сетевыми подключениями (~2 МБ)
# 📦 wpa_supplicant — поддержка WPA/WPA2 для WiFi (~0.8 МБ)
# 📦 wireless_tools — утилиты для беспроводных сетей (~0.2 МБ)
pacman -Sy --needed --noconfirm networkmanager wpa_supplicant wireless_tools
# 📦 openssh — сервер и клиент SSH для удалённого доступа (~2 МБ)
pacman -Sy --needed --noconfirm openssh
# 📦 plymouth — экран загрузки с анимацией (~3 МБ)
pacman -Sy --needed --noconfirm plymouth
# 🔧 Включение служб
# NetworkManager — управление сетью
# grub-btrfsd — демон для обновления меню GRUB
# sshd — SSH сервер
systemctl enable NetworkManager.service grub-btrfsd.service sshd.service
# 📋 Установка GRUB для BIOS
# --target=i386-pc — для BIOS систем (не UEFI!)
# --recheck — перепроверить устройство
# /dev/sdx — весь диск, а не раздел!
grub-install --target=i386-pc --recheck /dev/sdx
# 📋 Настройка HOOKS mkinitcpio — ПОРЯДОК КРИТИЧЕН!
# keyboard, keymap — чтобы работала клавиатура для ввода пароля
# resume — восстановить из гибернации (swap)
# filesystems — смонтировать корневую ФС
# fsck — проверить файловую систему
sed -i '/^HOOKS=/{s/\bblock\b/block resume/; t; s/\budev\b/udev resume/}' /etc/mkinitcpio.conf
# 📋 Добавление модулей ядра в initramfs
# btrfs — поддержка файловой системы BTRFS
sed -i "s/MODULES=()/MODULES=(btrfs)/" /etc/mkinitcpio.conf
# 📋 Получение UUID swap раздела для resume
SWAP_UUID=$(blkid -s UUID -o value /dev/sda3)
# 📋 Настройка GRUB — включение splash экрана и resume из swap
sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash rd.shell=0 rd.emergency=halt"|' /etc/default/grub
# 📋 Параметры ядра для BTRFS
# rootflags — subvol BTRFS
# resume — swap для гибернации
sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"rootflags=subvol=@ resume=UUID='${SWAP_UUID}'\"|" /etc/default/grub
sed -i 's|^GRUB_PRELOAD_MODULES=.*|GRUB_PRELOAD_MODULES="part_gpt part_msdos"|' /etc/default/grub
# 📋 Настройка grub-btrfs для отображения снапшотов
sed -i 's/#GRUB_BTRFS_SUBMENUNAME=.*/GRUB_BTRFS_SUBMENUNAME="Arch Linux snapshots"/' /etc/default/grub-btrfs/config
sed -i 's/#GRUB_BTRFS_TITLE_FORMAT=.*/GRUB_BTRFS_TITLE_FORMAT=("description"  "date")/' /etc/default/grub-btrfs/config
# 📋 Генерация конфигурации GRUB
grub-mkconfig -o /boot/grub/grub.cfg
# 📋 Пересборка initramfs
mkinitcpio -P
clear
echo " "
echo "#####################################################"
echo "## ✅ ЗАГРУЗЧИК И ЯДРО УСТАНОВЛЕНЫ (BIOS+GPT)      ##"
echo "#####################################################"
echo " "











#################################################################
# 🛠️  [CHROOT] БЛОК 11: СИСТЕМНЫЕ УТИЛИТЫ И НАСТРОЙКИ
#################################################################
# ℹ️ Зачем: Установка системных утилит, PipeWire, шрифтов.
# 💡 Включает: Bluetooth, CUPS, xdg, PipeWire.
# 💡 Расширено: Добавлены утилиты для администрирования, просмотра
# файлов, сжатия, мониторинга и обслуживания.
#################################################################
# 🧹 Очистка экрана терминала
clear
# 🔄 Обновление базы данных пакетов
pacman -Syy
# 📦 haveged — генератор энтропии
pacman -Sy --needed --noconfirm haveged
systemctl enable haveged.service
# 📦 wget — загрузка файлов через HTTP/HTTPS
# 📦 usbutils — утилиты для USB (lsusb)
# 📦 lsof — список открытых файлов
# 📦 dmidecode — информация о железе (DMI/SMBIOS)
# 📦 dialog — текстовые диалоговые окна
# 📦 zip/unzip/unrar/p7zip/lzop/lrzip — архиваторы
# 📦 sudo — выполнение команд от root
# 📦 mlocate — быстрый поиск файлов
# 📦 less — постраничный просмотр текста
# 📦 bash-completion — автодополнение команд в bash
pacman -Sy --needed --noconfirm wget usbutils lsof dmidecode dialog zip unzip unrar p7zip lzop lrzip sudo mlocate less bash-completion
# 📦 neovim — продвинутый текстовый редактор
# 📦 ripgrep — быстрый поиск по тексту
# 📦 bat — улучшенная версия cat с подсветкой
# 📦 zstd/lz4 — алгоритмы сжатия
# 📦 btop — монитор системы (красивый top)
# 📦 smartmontools — мониторинг S.M.A.R.T. дисков
# 📦 lm_sensors — мониторинг температур
# 📦 rsync — синхронизация файлов
# 📦 git — система контроля версий
# 📦 fwupd — обновление прошивок оборудования
pacman -Sy --needed --noconfirm neovim ripgrep bat zstd lz4 btop smartmontools lm_sensors rsync git fwupd
systemctl enable fwupd.service
# 📦 dosfstools — утилиты для FAT32
# 📦 ntfs-3g — поддержка NTFS (Windows разделы)
# 📦 exfatprogs — поддержка exFAT (флешки)
# 📦 gptfdisk — работа с GPT разделами
# 📦 fuse2/fuse3/fuseiso — пользовательские ФС
# 📦 nfs-utils/cifs-utils — сетевые ФС
pacman -Sy --needed --noconfirm dosfstools ntfs-3g exfatprogs gptfdisk fuse2 fuse3 fuseiso nfs-utils cifs-utils
# 📦 dbus-broker — шина D-BUS (межпроцессное взаимодействие)
pacman -Sy --needed --noconfirm dbus-broker
systemctl enable dbus-broker.service
# 📦 cronie — планировщик задач (cron)
pacman -Sy --needed --noconfirm cronie
systemctl enable cronie.service systemd-timesyncd.service
# 📋 Настройка swappiness (частота использования swap)
# 10 = минимальное использование swap (рекомендуется для SSD)
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
# 📦 bluez/bluez-utils — Bluetooth стек
pacman -Sy --needed --noconfirm bluez bluez-utils
systemctl enable bluetooth.service
sed -i 's/#AutoEnable=true/AutoEnable=true/g' /etc/bluetooth/main.conf
# 📦 cups/cups-pdf — принтеры и сканирование
# 📦 ghostscript/gsfonts — обработка PDF/PostScript
# 📦 avahi — служба обнаружения в сети
# 📦 system-config-printer — GUI для настройки принтеров
# 📦 simple-scan — программа для сканирования
pacman -Sy --needed --noconfirm cups cups-pdf ghostscript gsfonts avahi system-config-printer simple-scan
systemctl enable cups.service avahi-daemon.service
# 📦 xdg-utils/xdg-user-dirs — стандарты freedesktop.org
pacman -Sy --needed --noconfirm xdg-utils xdg-user-dirs
xdg-user-dirs-update
# 📦 udisks2/udiskie/polkit — автоматическое монтирование
pacman -Sy --needed --noconfirm udisks2 udiskie polkit
# 📦 pipewire-* — аудио/видео сервер (современный)
# 📦 alsa-utils — утилиты ALSA (alsamixer)
# 📦 sof-firmware — исходный код прошивки для DSP-чипов, для обработки звука
pacman -Sy --needed --noconfirm pipewire-alsa pipewire-pulse pipewire-jack pipewire-v4l2 pipewire-zeroconf alsa-utils sof-firmware
# 📦 wireplumber — менеджер сессий PipeWire
pacman -Sy --needed --noconfirm wireplumber
systemctl --global enable pipewire pipewire-pulse wireplumber
# 📦 gstreamer + кодеки — воспроизведение медиа
# 📦 ffmpeg — конвертация видео/аудио
# 📦 libdvdcss — воспроизведение DVD
pacman -Sy --needed --noconfirm gstreamer gst-plugins-{base,good,bad,ugly} gst-libav ffmpeg a52dec faac faad2 flac lame libdca libdv libmad libmpeg2 libtheora libvorbis wavpack x264 x265 xvidcore libdvdcss taglib
# 📦 man-db/man-pages/man-pages-ru — документация
pacman -Sy --needed --noconfirm man-db man-pages man-pages-ru
# 📦 iproute2/inetutils/dnsutils — сетевые утилиты
pacman -Sy --needed --noconfirm iproute2 inetutils dnsutils
pacman -Syy --noconfirm
# 📦 Шрифты: Noto, DejaVu, Liberation, Terminus
pacman -Sy --needed --noconfirm noto-fonts noto-fonts-emoji ttf-dejavu ttf-liberation terminus-font
pacman -Sy --needed --noconfirm wqy-zenhei wqy-bitmapfont
pacman -Sy --needed --noconfirm fontconfig freetype2 harfbuzz libxft
# 📋 Обновление кэша шрифтов
fc-cache -fv
# 🧹 Очистка экрана терминала
clear
echo " "
echo "######################################"
echo "## ✅ СИСТЕМНЫЕ УТИЛИТЫ НАСТРОЕНЫ   ##"
echo "######################################"
echo " "
echo "##############################################"
echo "## 🎮 ОПРЕДЕЛЕНИЕ ВИДЕОКАРТЫ ДЛЯ ДРАЙВЕРОВ  ##"
echo "##############################################"
echo " "
# Проверка видеокарты
lspci -nn | grep -E 'VGA|3D|Display'
# Проверка загруженных драйверов
lsmod | grep -E 'nvidia|amdgpu|i915|nouveau'












#################################################################
# 🎨 [CHROOT] БЛОК 12: УСТАНОВКА ВИДЕОДРАЙВЕРОВ И НАСТРОЙКА WAYLAND
#################################################################
# ℹ️ Зачем: Установка драйверов для Intel/AMD/NVIDIA, настройка
#           ядерных модулей для Wayland и энергосбережения.
# ⚠️ ВАЖНО: Если установка в VirtualBox — пропустите этот блок!
#################################################################
# 🧹 Очистка экрана терминала
clear
# ------------------------------------------------------------------------------
# ШАГ 1: БАЗОВЫЕ УТИЛИТЫ И ПАКЕТЫ ДЛЯ ТЕСТИРОВАНИЯ (ОБЯЗАТЕЛЬНО ДЛЯ ВСЕХ)
# ------------------------------------------------------------------------------
# mesa/lib32-mesa : Основа графического стека (OpenGL, Vulkan, OpenCL).
# vulkan-tools    : Утилита vulkaninfo для диагностики.
# libva-utils     : Утилита vainfo для проверки видео-ускорения.
# mesa-utils      : Утилита glxinfo для проверки OpenGL.
# mesa-demos      : Демонстрационные программы OpenGL.
# glmark2         : Бенчмарк производительности графики.
# ------------------------------------------------------------------------------
pacman -Sy --needed --noconfirm mesa lib32-mesa vulkan-tools libva-utils mesa-utils mesa-demos glmark2
# ------------------------------------------------------------------------------
# ШАГ 2: ВЫБОР СЦЕНАРИЯ ВИДЕО (ВЫПОЛНИТЬ ТОЛЬКО ОДИН БЛОК)
# ------------------------------------------------------------------------------
# >>> [СЦЕНАРИЙ А] INTEL (Встроенная графика) <<<
#intel-media-driver : VA-API для аппаратного декодирования видео.
#vulkan-intel       : Только для CPU старше 11 поколения (опционально).
#ПРИМЕЧАНИЕ: lib32-intel-media-driver доступен ТОЛЬКО в AUR!
pacman -Sy --needed --noconfirm intel-media-driver
pacman -Sy --needed --noconfirm vulkan-intel
# >>> [СЦЕНАРИЙ Б] AMD (Radeon / APU) <<<
#libva-mesa-driver       : VA-API драйвер для AMD.
#lib32-libva-mesa-driver : 32-битная версия (официальный multilib).
pacman -Sy --needed --noconfirm libva-mesa-driver lib32-libva-mesa-driver
# >>> [СЦЕНАРИЙ В] NVIDIA (Дискретная или Гибридная) <<<
#nvidia-open-dkms        : Драйвер с открытыми модулями ядра (RTX 20xx+).
#                          Автоматически собирает модули для ЛЮБОГО ядра.
#nvidia-utils            : Утилиты и библиотеки (включая VA-API).
#lib32-nvidia-utils      : 32-битные библиотеки для игр (Steam/Proton).
#nvidia-settings         : Панель управления настройками GPU.
pacman -Sy --needed --noconfirm nvidia-open-dkms nvidia-utils lib32-nvidia-utils nvidia-settings
# --- ДОПОЛНИТЕЛЬНО ДЛЯ ГИБРИДНЫХ НОУТБУКОВ (NVIDIA + Intel/AMD) ---
#Выберите ОДИН метод управления:
#Метод 1: Prime (универсальный, команда 'prime-run' в терминале)
pacman -Sy --needed --noconfirm nvidia-prime
#Метод 2: Switcheroo (интеграция в GUI GNOME/KDE/Wayland)
pacman -Sy --needed --noconfirm switcheroo-control
systemctl enable switcheroo-control.service
# ------------------------------------------------------------------------------
# ШАГ 3: НАСТРОЙКА ЯДРА И МОДУЛЕЙ (ОБЯЗАТЕЛЬНО ДЛЯ СЦЕНАРИЕВ А, Б, В)
# ------------------------------------------------------------------------------
#Для Intel/AMD: Применяются общие настройки KMS.
#Для NVIDIA: КРИТИЧЕСКИ ВАЖНО для работы Wayland и энергосбережения!
#1. Добавить модули NVIDIA в mkinitcpio.conf (для ранней загрузки)
sed -i 's/^MODULES=(\(.*\))/MODULES=(\1 nvidia nvidia_modeset nvidia_uvm nvidia_drm)/' /etc/mkinitcpio.conf
#2. Добавить параметр ядра nvidia-drm.modeset=1 (включает поддержку Wayland)
sed -i 's/GRUB_CMDLINE_LINUX_DEFAULT="\(.*\)"/GRUB_CMDLINE_LINUX_DEFAULT="\1 nvidia-drm.modeset=1"/' /etc/default/grub
#3. Конфигурация модулей (modprobe) — ТОЛЬКО ДЛЯ NVIDIA
#Создаем файл настроек для активации modeset и управления питанием
echo 'options nvidia-drm modeset=1' > /etc/modprobe.d/nvidia.conf
#Включаем режим энергосбережения (Runtime PM) — полезно для ноутбуков
echo 'options nvidia NVreg_DynamicPowerManagement=0x02' >> /etc/modprobe.d/nvidia.conf
#Принудительная загрузка модуля nvidia-drm
echo 'nvidia-drm' > /etc/modules-load.d/nvidia-drm.conf
#4. Пересобрать initramfs
#Применяет все изменения: новые модули, хуки и подхватывает конфиги modprobe.
#Для NVIDIA (DKMS) это также запустит компиляцию драйвера под все ядра.
mkinitcpio -P
# 🧹 Очистка экрана терминала
clear
echo ""
echo "#################################################################"
echo "## 🧭 ЗАВЕРШЕНИЕ БЛОКА 12                                      ##"
echo "#################################################################"
echo "# "
echo " ✅ ВСЕ ДЕЙСТВИЯ ВЫПОЛНЕНЫ."
echo " ⚠️ НЕ ВЫХОДИТЕ из chroot!"
echo " 📌 Убедитесь, что все команды из выбранных шагов выполнены."
echo " ➡️ ПРОДОЛЖИТЕ УСТАНОВКУ:"
echo " "











#################################################################
# 🖥️  [CHROOT] БЛОК 13: УСТАНОВКА В VIRTUALBOX
#################################################################
# ℹ️ Зачем: Настройка интеграции с VirtualBox (гостевые дополнения).
# ❗ Важно: Только если установка в VirtualBox.
#################################################################
# 🧹 Очистка экрана терминала
clear
# Установка гостевых утилит и видеодрайвера
pacman -Sy --needed --noconfirm virtualbox-guest-utils
# Загрузка модулей ядра
modprobe -a vboxguest vboxsf vboxvideo
# Включение службы автозапуска
systemctl enable vboxservice.service
# Создание файла конфигурации модулей
echo "vboxguest vboxsf vboxvideo" > /etc/modules-load.d/virtualbox.conf
# Добавление пользователя в группу vboxsf (для общих папок)
# ЗАМЕНИТЕ 'forename' НА ВАШЕ ИМЯ ПОЛЬЗОВАТЕЛЯ (например, rublev)!
usermod -aG vboxsf forename
# 🧹 Очистка экрана терминала
clear
echo ""
echo "#####################################################"
echo "## ✅ НАСТРОЙКА VIRTUALBOX ЗАВЕРШЕНА               ##"
echo "#####################################################"
echo ""












#################################################################
# 🖥️  [CHROOT] БЛОК 14: УСТАНОВКА ГРАФИЧЕСКОЙ СРЕДЫ (DE/WM)
#################################################################
# ℹ️ Зачем: Установка выбранного окружения рабочего стола.
# 💡 Включает: KDE Plasma, GNOME, XFCE4, MATE, Cinnamon, LXQT, LXDE.
# ❗ Важно: Убедитесь, что видеодрайверы установлены (БЛОК 12).
#################################################################

#################################################################
# 🌐 УСТАНОВКА KDE PLASMA
#################################################################
# 🧹 Очистка экрана терминала
clear
pacman -Syy
pacman -Sy --needed --noconfirm plasma kde-system-meta dolphin-plugins kate konsole skanpage skanlite gwenview elisa okular ark
pacman -Sy --needed --noconfirm ffmpegthumbs poppler-glib
pacman -Sy --needed --noconfirm packagekit packagekit-qt6
pacman -Sy --needed --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --needed --noconfirm sddm
systemctl enable sddm.service
mkinitcpio -P
# 🧹 Очистка экрана терминала
clear
echo ""
echo "#####################################################"
echo "## ✅ KDE PLASMA УСТАНОВЛЕНА УСПЕШНО               ##"
echo "#####################################################"
echo ""
# Выход из chroot
exit

#################################################################
# 🌐 УСТАНОВКА GNOME
#################################################################
clear
pacman -Syy
pacman -Sy --needed --noconfirm gnome
pacman -Sy --needed --noconfirm dconf-editor
pacman -Sy --needed --noconfirm file-roller
pacman -Sy --needed --noconfirm gnome-tweaks
pacman -Sy --needed --noconfirm gnome-themes-extra
pacman -Sy --needed --noconfirm gnome-browser-connector
pacman -Sy --needed --noconfirm packagekit packagekit-qt6 gnome-packagekit
pacman -Sy --needed --noconfirm gnome-shell-extensions
pacman -Sy --needed --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --needed --noconfirm ffmpegthumbnailer poppler-glib
systemctl enable gdm
echo "[User]" > /var/lib/AccountsService/users/root
echo "SystemAccount=true" >> /var/lib/AccountsService/users/root
mkinitcpio -P
# 🧹 Очистка экрана терминала
clear
echo " "
echo "#####################################################"
echo "## ✅ GNOME УСТАНОВЛЕНА УСПЕШНО                    ##"
echo "#####################################################"
echo " "
# Выход из chroot
exit

#################################################################
# 🪟 УСТАНОВКА XFCE4
#################################################################
# 🧹 Очистка экрана терминала
clear
pacman -Syy
pacman -Sy --needed --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -Sy --needed --noconfirm network-manager-applet blueman
pacman -Sy --needed --noconfirm mugshot pavucontrol xdg-user-dirs xdg-desktop-portal-gtk ristretto thunar-archive-plugin ffmpegthumbnailer
pacman -Sy --needed --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --needed --noconfirm ffmpegthumbnailer poppler-glib
systemctl enable lightdm.service
mkinitcpio -P
# 🧹 Очистка экрана терминала
clear
echo ""
echo "#####################################################"
echo "## ✅ XFCE4 УСТАНОВЛЕНА УСПЕШНО                    ##"
echo "#####################################################"
echo ""
# Выход из chroot
exit

#################################################################
# 🍃 УСТАНОВКА MATE
#################################################################
# 🧹 Очистка экрана терминала
clear
pacman -Syy
pacman -Sy --needed --noconfirm mate mate-extra lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -Sy --needed --noconfirm network-manager-applet blueman
pacman -Sy --needed --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --needed --noconfirm ffmpegthumbnailer poppler-glib
systemctl enable lightdm.service
# 🧹 Очистка экрана терминала
clear
echo ""
echo "#####################################################"
echo "## ✅ MATE УСТАНОВЛЕНА УСПЕШНО                     ##"
echo "#####################################################"
echo ""
# Выход из chroot
exit

#################################################################
# 🕯️ УСТАНОВКА CINNAMON
#################################################################
# 🧹 Очистка экрана терминала
clear
pacman -Syy
pacman -Sy --needed --noconfirm cinnamon cinnamon-translations blueman lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings gnome-terminal evince
pacman -Sy --needed --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --needed --noconfirm ffmpegthumbnailer poppler-glib
systemctl enable lightdm.service
mkinitcpio -P
# 🧹 Очистка экрана терминала
clear
echo ""
echo "#####################################################"
echo "## ✅ CINNAMON УСТАНОВЛЕНА УСПЕШНО                 ##"
echo "#####################################################"
echo ""
# Выход из chroot
exit

#################################################################
# 🧩 УСТАНОВКА LXQT
#################################################################
# 🧹 Очистка экрана терминала
clear
pacman -Syy
pacman -Sy --needed --noconfirm lxqt sddm breeze breeze-icons blueman featherpad libstatgrab libsysstat
pacman -Sy --needed --noconfirm network-manager-applet blueman
pacman -Sy --needed --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --needed --noconfirm ffmpegthumbnailer poppler-glib
systemctl enable sddm.service
mkinitcpio -P
# 🧹 Очистка экрана терминала
clear
echo ""
echo "#####################################################"
echo "## ✅ LXQT УСТАНОВЛЕНА УСПЕШНО                     ##"
echo "#####################################################"
echo ""
# Выход из chroot
exit

#################################################################
# 🖼️ УСТАНОВКА LXDE
#################################################################
# 🧹 Очистка экрана терминала
clear
pacman -Syy
pacman -Sy --needed --noconfirm lxde openbox mousepad lightdm lightdm-slick-greeter blueman thunar-archive-plugin ffmpegthumbnailer udiskie xfce4-notifyd dunst picom
pacman -Sy --needed --noconfirm network-manager-applet blueman
pacman -Sy --needed --noconfirm ffmpegthumbnailer poppler-glib gnome-themes-extra
sed -i 's/#greeter-session=example-gtk-gnome/greeter-session=lightdm-slick-greeter/' /etc/lightdm/lightdm.conf
systemctl enable lightdm.service
mkinitcpio -P
# 🧹 Очистка экрана терминала
clear
echo ""
echo "#####################################################"
echo "## ✅ LXDE УСТАНОВЛЕНА УСПЕШНО                     ##"
echo "#####################################################"
echo ""
# Выход из chroot
exit











#################################################################
# 🧹  [LIVE] БЛОК 15: ЗАВЕРШЕНИЕ УСТАНОВКИ
#################################################################
umount -R /mnt
swapoff -a
poweroff

#################################################################
# 🧹 Очистка конфигурации ssh соединения (При необходимости)
#################################################################
rm -r .ssh/











#################################################################
# 📋  [USER] БЛОК 16: РЕКОМЕНДАЦИИ ПОСЛЕ УСТАНОВКИ И ТЕСТЫ
#################################################################
# 🎯 Зачем: Установка утилит (Yay, Btrfs) и проверка видео.
# ⚠️ Важно: Выполняется ПОСЛЕ первой загрузки в установленную систему.
# 👤 Выполняется: От имени обычного пользователя с sudo правами.
# 💡 Примечание: Для визуальных тестов должна быть запущена графическая сессия!
#################################################################

################# ШАГ 1: УСТАНОВКА YAY (AUR HELPER) ############
# Клонируем репозиторий yay, собираем и устанавливаем пакет.
# После установки удаляем исходники для чистоты системы.

git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
rm -rf yay

################# ШАГ 2: НАСТРОЙКА BTRFS И SNAPPER ############
# Установка официальных пакетов для работы с Btrfs и снапшотами.
sudo pacman -Syy
sudo pacman -Sy --needed --noconfirm snapper snap-pac btrfsmaintenance btrfs-assistant

# Установка дополнительных утилит из AUR (требуется yay).
yay -Syy
yay -Sy --noconfirm snapper-support snapper-tools

# Включение таймера автоматического создания снапшотов.
sudo systemctl enable --now snapper-timeline.timer

# 📌 ДЕЙСТВИЯ ПОЛЬЗОВАТЕЛЯ:
# 1. Запустите 'Btrfs Assistant' из меню приложений.
# 2. Настройте расписание снапшотов (Timeline).
# 3. При обновлении системы снапшоты будут создаваться автоматически.
# 4. В меню GRUB появятся пункты для отката (rollback).

################# ШАГ 3: ДИАГНОСТИКА (ТЕКСТОВАЯ) ##############
# Выполните эти команды по очереди в терминале для проверки статуса драйверов.

# 1. Проверка статуса драйвера NVIDIA (только для NVIDIA)
# Ожидаемый результат: Таблица с информацией о карте и температуре.
nvidia-smi

# 2. Проверка поддержки Vulkan (все карты)
# Ожидаемый результат: Название вашей видеокарты (deviceName).
vulkaninfo --summary | grep "deviceName"

# 3. Проверка аппаратного декодирования видео (VA-API)
# Ожидаемый результат: Список поддерживаемых профилей (H264, HEVC и т.д.).
vainfo

# 4. Проверка активного OpenGL рендерера
# Ожидаемый результат: Строка "OpenGL renderer: ..." с названием GPU.
glxinfo | grep "OpenGL renderer"

################# ШАГ 4: ВИЗУАЛЬНЫЕ ТЕСТЫ (GUI) ###############
# ⚠️ ВАЖНО: Эти команды открывают графические окна.
# Выполняйте их по одной. Закройте окно теста перед запуском следующей.
# Если окно не открывается или черный экран — проверьте настройки драйверов.

# --- Тест 1: Базовая анимация OpenGL (Шестеренки) ---
# Проверка работы базового OpenGL контекста.
glxgears

# --- Тест 2: Vulkan-куб (Интегрированная карта) ---
# Проверка работы Vulkan на основной графике. Куб должен вращаться плавно.
vkcube

# --- Тест 3: Полный бенчмарк производительности ---
# Серия тестов графики с выводом итогового счета (FPS).
glmark2

# --- Тест 4: ЭКСПРЕСС-ПРОВЕРКА ДИСКРЕТНОЙ КАРТЫ (Гибриды) ---
# Запускает вращающийся куб принудительно на GPU #1 (обычно NVIDIA).
# Если окно открылось и куб вращается — переключение работает идеально!
switcherooctl launch --gpu 1 vkcube

# --- Тест 5: Бенчмарк на дискретной карте (Нагрузочный тест) ---
# Запуск полного бенчмарка glmark2 на дискретной видеокарте.
switcherooctl launch --gpu 1 glmark2

# --- Тест 6: Панель управления NVIDIA на дискретной карте ---
# Проверка запуска GUI утилит на конкретной GPU.
switcherooctl launch --gpu 1 nvidia-settings

#################################################################
# 🏁 ЗАВЕРШЕНИЕ УСТАНОВКИ
#################################################################
# ✅ Если все команды выше выполнились без ошибок и окна открылись:
#    - Система полностью настроена.
#    - Драйверы работают корректно.
#    - Резервное копирование (Snapper) активно.
#
# 🎉 Добро пожаловать в мир Arch Linux!
#
# 💡 РЕКОМЕНДАЦИИ:
#    - Регулярное обновление: sudo pacman -Syu
#    - Мониторинг снапшотов: через Btrfs Assistant.
#    - При проблемах с Wayland: проверьте параметр modeset=1 в cmdline.
#################################################################
