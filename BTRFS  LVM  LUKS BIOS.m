#################################################################
# 🐧 МАКЕТ БЛОЧНОЙ УСТАНОВКИ ARCH LINUX (BIOS + GPT + BTRFS + LVM + LUKS)
#################################################################
# ℹ️ Назначение: Пошаговая установка Arch Linux с BTRFS, LVM и LUKS.
# 💡 Метод: Копируйте и вставляйте блоки команд по одному.
# ❗ Важно: Не запускайте как скрипт! Выполняйте вручную.
# 🌐 Требуется: Интернет, загрузочная среда Arch Linux (свежий ISO).
# 💡 Примечание: Данная установка предназначена для компьютеров
# с прошивкой BIOS (Legacy Boot), но с использованием таблицы разделов GPT.
# Требуется специальный BIOS Boot Partition (тип EF02).
# Шифрование LUKS охватывает корневой и домашний разделы.
# LVM используется поверх LUKS для гибкого управления разделами.
# Btrfs используется как файловая система на логических томах LVM.
# Создаётся ОТДЕЛЬНЫЙ НЕЗАШИФРОВАННЫЙ раздел /boot (ext4, 1 ГБ).
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
# │    ├─ LUKS — шифрование диска (Linux Unified Key Setup)         │
# │    ├─ LVM — менеджер логических томов                           │
# │    ├─ chroot — переход в установленную систему из Live-среды    │
# │    ├─ pacman — менеджер пакетов Arch Linux                      │
# │    └─ AUR — репозиторий пользовательских пакетов                │
# │                                                                 │
# │ ⚠️ КРИТИЧЕСКИ ВАЖНО:                                            │
# │    ├─ Все данные на диске будут УДАЛЕНЫ!                        │
# │    ├─ Замените 'sdx' на имя ВАШЕГО диска (sda, nvme0n1, etc.)   │
# │    ├─ Запомните пароль LUKS! Без него данные НЕ ВОССТАНОВИТЬ!   │
# │    └─ Запомните пароли root и пользователя!                     │
# └─────────────────────────────────────────────────────────────────┘
#################################################################
# Структура:
# 1. Настройка локации зеркал
# 2. Подготовка Live-среды
# 3. Диагностика оборудования
# 4. Настройка переменных (обязательно!)
# 5. Разметка диска (GPT + BIOS Boot) + LUKS + LVM
# 6. Форматирование, LUKS, LVM, Btrfs, монтирование
# 7. Установка базовых пакетов
# 8. Настройки внутри системы (chroot)
# 9. Hostname и пароль root (chroot)
# 10. Пользователь и sudo (chroot)
# 11. Установка ядра, GRUB, mkinitcpio (chroot)
# 12. Системные утилиты и настройки (chroot)
# 13. Установка видеодрайвера (chroot)
# 14. Установка в VirtualBox (chroot) (опционально)
# 15. Установка графической среды (DE/WM) (chroot)
# 16. Завершение процесса
# 17. Рекомендации после установки
#################################################################











#################################################################
# 🔍  БЛОК 0: НАСТРОЙКА ЛОКАЦИИ ЗЕРКАЛ (Mirrors)
#################################################################
# ℹ️ Зачем: Для быстрой и качественной установки необходимы правильно
# подобранные зеркала mirrorlist. А для их настройки необходим
# reflector.
# ❗ Важно: Не выполнять в Live среде. Выполняется отдельно на компьютере
# с установленной системой.
# 💡 Показывает: Список 10 стран, которые ближе всего от местоположения
# пользователя.
# ℹ️ Зачем: Для настройки конфигурации в файле reflector.conf
# списков стран c близким местоположением.
#################################################################
# 🧹 Очистка экрана терминала
clear
# 🔄 Обновление базы данных пакетов
sudo pacman -Syy
# 📦 Установка необходимых зависимостей Python
# python — язык программирования для запуска скрипта
# python-requests — библиотека для HTTP запросов к API
# python-geopandas — работа с географическими данными карты
# python-shapely — геометрические операции для расчёта расстояний
sudo pacman -S --noconfirm python python-requests python-geopandas python-shapely
# 🔍 СОЗДАНИЕ СКРИПТА
# Создание файла скрипта nearest_countries.py
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
# ⚡ 3.1 Запуск скрипта
# 🧹 Очистка экрана терминала
clear
# Запуск скрипта для определения ближайших стран
python ~/nearest_countries.py
# Удаление скрипта nearest_countries.py
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
# 💡 Включает: reflector, haveged, inxi, lshw, lvm2, cryptsetup.
#################################################################
# 🧹 Очистка экрана терминала
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
# 🧹 Очистка экрана терминала
clear
echo " "
# 🔄 Принудительное обновление базы данных пакетов
pacman -Syy
# 📦 pacman-contrib — дополнительные утилиты для pacman
# 📦 curl — загрузка файлов через HTTP/HTTPS
pacman -Sy --noconfirm pacman-contrib curl
# 📦 haveged — генератор энтропии для ускорения шифрования (~0.1 МБ)
# 📦 inxi — утилита для получения информации о системе (~0.5 МБ)
# 📦 util-linux — базовые утилиты Linux (lsblk, mount, fdisk) (~5 МБ)
# 📦 lshw — подробная информация об оборудовании (~0.3 МБ)
# 📦 lvm2 — менеджер логических томов для LVM (~5 МБ)
# 📦 cryptsetup — утилита для шифрования LUKS (~1 МБ)
pacman -Sy --noconfirm haveged inxi util-linux lshw lvm2 cryptsetup
# Включение и запуск службы haveged
systemctl enable haveged.service --now
# 🧹 Очистка экрана терминала
clear
echo " "
echo "#####################################################"
echo "## ✅ ПОДГОТОВКА LIVE-СРЕДЫ ЗАВЕРШЕНА              ##"
echo "#####################################################"
echo " "











#################################################################
# 🔍  [LIVE] БЛОК 2: ДИАГНОСТИКА ОБОРУДОВАНИЯ
#################################################################
# ℹ️ Зачем: Вывод информации об оборудовании (процессор, материнская
# плата, диски) для корректной настройки переменных.
# ❗ Важно: Сравните вывод с переменными в БЛОКЕ 3.
# 💡 Показывает: Производителя CPU, модель MB, список дисков/разделов,
# рекомендованные параметры монтирования FSTAB.
#################################################################
# 🧹 Очистка экрана терминала
clear
echo " "
echo "=== ДИАГНОСТИКА ОБОРУДОВАНИЯ ==="
echo " "
# 💾 Определение имени диска для замены переменной sdx
echo "Замените переменную sdx на ваш жесткий диск для разметки диска"
echo "Пример: если ваш диск /dev/sda, замените ВСЕ 'sdx' на 'sda' в макете."
echo " "
# lsblk — показывает все диски и разделы
lsblk
echo " "
echo " "
# 🔍 Определение производителя процессора
echo "Замените или оставьте переменную amd-ucode в зависимости от типа вашего процессора"
echo "Для Intel: замените 'amd-ucode' на 'intel-ucode'"
echo " "
echo "Производитель процессора:"
lshw -C cpu 2>/dev/null | grep 'vendor:' | uniq
echo " "
echo " "
# 🖥️ Определение модели материнской платы
echo "Замените переменную Sony на имя вашего компьютера"
echo " "
echo "Материнская плата:"
inxi -M
echo " "
echo " "
# 💾 Рекомендации по размеру SWAP
echo "Замените переменную 4G на необходимый размер SWAP"
echo "Пример: для 8GB swap, замените '4G' на '8G'"
echo " "
echo "Общая информация о системе:"
inxi -I
echo " "
echo " "
# 📊 Определение типа дисков (HDD/SSD) для параметров монтирования
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
# ❗ ВАЖНО: Замена переменных происходит в ДВА ЭТАПА (см. таблицу ниже)!
# 💡 ИНСТРУКЦИЯ:
#    ЭТАП 1 (СЕЙЧАС, до Блока 4):
#    • Замените переменные, отмеченные как "ЭТАП 1".
#    • Это необходимо для корректной разметки диска.
#
#    ЭТАП 2 (ПОСЛЕ Блока 4 — разметки диска):
#    • После создания разделов замените переменные "ЭТАП 2"
#    (sda1, sda2, sda3) на реальные имена разделов.
#    • Используйте вывод lsblk из Блока 4 для определения имён.
#    • Имя зашифрованного LUKS-устройства будет cryptlvm (если не измените вручную).
#    • Имя группы томов LVM будет vg_main (если не измените вручную).
#    • Имена логических томов будут lv_root, lv_home, lv_swap.
#
# 📌 Примечание: Порядок замены критичен! Не меняйте sda1/sda2/sda3 до
# завершения Блока 4 — иначе установка завершится ошибкой.
#################################################################################
# Назначение                 # Значение (шаблон)      # Когда менять?
#################################################################################
# Имя диска                  # sdx                    # ЭТАП 1 (сейчас)
# BIOS Boot Partition        # sda1                   # ЭТАП 2 (после Блока 4)
# /boot раздел (ext4)        # sda2                   # ЭТАП 2 (после Блока 4)
# LUKS/LVM раздел            # sda3                   # ЭТАП 2 (после Блока 4)
# Размер SWAP                # 4G                     # ЭТАП 1 (сейчас)
# Имя компьютера (HOSTNAME)  # Sony                   # ЭТАП 1 (сейчас)
# Имя пользователя           # forename               # ЭТАП 1 (сейчас)
# Полное имя пользователя    # User Name              # ЭТАП 1 (сейчас)
# Microcode                  # amd-ucode              # ЭТАП 1 (сейчас)
# Ядро                       # linux-lts              # ЭТАП 1 (сейчас)
# Параметры монтирования     # defaults               # ЭТАП 1 (сейчас)
#################################################################################
# 💡 СОВЕТ: После ЭТАПА 1 проверьте, что в файле больше нет строки "sdx".
# После ЭТАПА 2 — проверьте, что разделы "sda1", "sda2", "sda3"
# Соответствуют имени своего диска "sdx".
#
# 📌 ВАЖНО: В режиме BIOS+GPT раздел sda1 — это BIOS Boot Partition!
# Он не форматируется и не монтируется.
# 📌 ВАЖНО: Раздел sda2 — это /boot (ext4, НЕ шифруется)!
# 📌 ВАЖНО: Раздел sda3 — это LUKS контейнер (шифруется)!
######################################################
# ✅ ПЕРЕМЕННЫЕ НАСТРОЕНЫ. ПЕРЕХОДИТЕ К БЛОКУ 4
######################################################











#################################################################
# 💾  [LIVE] БЛОК 4: РАЗМЕТКА ДИСКА (GPT + BIOS Boot) + LUKS + LVM
#################################################################
# ℹ️ Зачем: Создание разделов: BIOS Boot, /boot, зашифрованный раздел для LVM.
# ❗ ВАЖНО: Все данные на /dev/sdx будут УДАЛЕНЫ!
# 💡 Используется: sgdisk для GPT, cryptsetup для LUKS, pvcreate/vgcreate/lvcreate для LVM.
# 💡 Файловая система Btrfs будет на логических томах (LV) LVM.
# ℹ️ ПЕРЕД ВЫПОЛНЕНИЕМ: Убедитесь, что 'sdx' заменен на ваш диск!
#################################################################
# 🧹 Очистка экрана терминала
clear
# 🧹 Полная очистка диска от старых разделов и подписей
wipefs --all --force /dev/sdx
sgdisk -Z /dev/sdx
# 📐 Создание новой таблицы разделов GPT с выравниванием 2048 секторов
sgdisk -a 2048 -o /dev/sdx
# 📦 РАЗДЕЛ 1: BIOS Boot Partition — 4 МБ, тип ef02
# Назначение: Загрузчик GRUB для BIOS+GPT
sgdisk -n 1:0:+4M --typecode=1:ef02 --change-name=1:'BIOS Boot' /dev/sdx
# 📦 РАЗДЕЛ 2: /boot — 1 ГБ, тип 8300
# Назначение: Ядро и загрузчик (НЕ шифруется!)
sgdisk -n 2:0:+1G --typecode=2:8300 --change-name=2:'Boot' /dev/sdx
# 📦 РАЗДЕЛ 3: LUKS Crypt — остальное место, тип 8309
# Назначение: LUKS шифрование + LVM + BTRFS
sgdisk -n 3:0:0 --typecode=3:8309 --change-name=3:'LUKS Crypt' /dev/sdx
# 🧹 Очистка экрана терминала
clear
echo " "
# 🔍 Проверка созданной разметки
fdisk -l /dev/sdx
echo " "
lsblk -a /dev/sdx
echo " "
echo "#####################################################"
echo "## ✅ РАЗМЕТКА ДИСКА ЗАВЕРШЕНА                     ##"
echo "#####################################################"
echo " "
echo " "
# 💡 ОБЯЗАТЕЛЬНО:
# После разметки проверьте, что разделы "sda1", "sda2", "sda3"
# Соответствуют имени своего диска "sdx".











#################################################################
# 💾  [LIVE] БЛОК 5: ФОРМАТИРОВАНИЕ, LUKS, LVM, МОНТИРОВАНИЕ
#################################################################
# ℹ️ Зачем: Форматирование /boot (НЕ шифруем!), создание LUKS-контейнера,
# настройка LVM, создание подтомов Btrfs, монтирование.
# ℹ️ Важно: Выполняется до chroot.
# 💡 Подтомы: @, @home, @log, @pkg, @snapshots.
# ❗ ПЕРЕД ВЫПОЛНЕНИЕМ: Убедитесь, что 'sda1', 'sda2', 'sda3' заменены на правильные разделы!
# ❗ ВАЖНО: Запомните пароль, который вы введете для LUKS!
#################################################################
# 🧹 Очистка экрана терминала
clear
# 📦 Форматирование /boot раздела в ext4 (НЕ шифруется!)
mkfs.ext4 -L BOOT /dev/sda2
# 🧹 Очистка экрана терминала
clear
echo " "
echo "###################################"
echo "## 🔑 СОЗДАЙТЕ ПАРОЛЬ ДЛЯ        ##"
echo "##   ДЛЯ ЗАЩИТЫ ДИСКА КОМПЬЮТЕРА ##"
echo "###################################"
echo " "
# 🔐 Создание LUKS-контейнера на разделе sda3
# ⚠️ ВНИМАНИЕ: Все данные на разделе будут уничтожены!
# ⚠️ Запомните пароль! Без него доступ к данным невозможен!
cryptsetup luksFormat /dev/sda3
# 🔓 Открытие LUKS-контейнера с именем cryptlvm
# Введите пароль, который вы задали выше
cryptsetup open /dev/sda3 cryptlvm
# 📦 Создание физического тома LVM на зашифрованном устройстве
pvcreate /dev/mapper/cryptlvm
# 📦 Создание группы томов LVM с именем vg_main
vgcreate vg_main /dev/mapper/cryptlvm
# 📦 Создание логического тома для swap (4ГБ)
lvcreate -L 4G vg_main -n lv_swap
# 📦 Создание логического тома для root (остальное место)
lvcreate -l 100%FREE vg_main -n lv_root
# 📦 Форматирование root тома в BTRFS
mkfs.btrfs -f /dev/vg_main/lv_root
# 📦 Монтирование root тома временно для создания подтомов
mount /dev/vg_main/lv_root /mnt
# 📦 Создание подтомов BTRFS для снапшотов
# @ — корневая система
# @home — домашние каталоги пользователей
# @log — системные логи
# @pkg — кэш пакетов pacman
btrfs su cr /mnt/@
btrfs su cr /mnt/@home
btrfs su cr /mnt/@log
btrfs su cr /mnt/@pkg
# Отмонтирование для правильного монтирования подтомов
umount /mnt
# 📦 Монтирование подтома @ как корень системы
mount -o defaults,subvol=@ /dev/vg_main/lv_root /mnt
# Создание необходимых директорий
mkdir -p /mnt/{boot,home,var/log,var/cache/pacman/pkg,var/lib/machines,var/lib/portables}
# 📦 Монтирование остальных подтомов
mount -o defaults,subvol=@home /dev/vg_main/lv_root /mnt/home
mount -o defaults,subvol=@log /dev/vg_main/lv_root /mnt/var/log
mount -o defaults,subvol=@pkg /dev/vg_main/lv_root /mnt/var/cache/pacman/pkg
# 📦 Монтирование /boot раздела
mount /dev/sda2 /mnt/boot
# 📦 Создание и активация swap раздела
mkswap /dev/vg_main/lv_swap
swapon /dev/vg_main/lv_swap
# 🧹 Очистка экрана терминала
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
echo "################################################################"
echo "## ✅ ФОРМАТИРОВАНИЕ, LUKS, LVM И МОНТИРОВАНИЕ ЗАВЕРШЕНО      ##"
echo "################################################################"
echo " "











#################################################################
# 🧱  [LIVE] БЛОК 6: УСТАНОВКА БАЗОВЫХ ПАКЕТОВ
#################################################################
# ℹ️ Зачем: Установка минимальной системы и переход в chroot.
# ℹ️ Важно: После этого — вход в chroot.
# 💡 Включает: base, btrfs, lvm2, nano, reflector, pacman-contrib.
# 💡 Правильный fstab критически важен для загрузки.
#################################################################
# 🧹 Очистка экрана терминала
clear
# 📦 base — минимальный набор пакетов Arch Linux (~150 МБ)
# 📦 base-devel — инструменты разработки для компиляции (~200 МБ)
pacstrap /mnt base base-devel
# 📦 btrfs-progs — утилиты для работы с BTRFS (~5 МБ)
pacstrap /mnt btrfs-progs
# 📦 lvm2 — менеджер логических томов для LVM (~5 МБ)
# 📦 cryptsetup — утилита для шифрования LUKS (~1 МБ)
pacstrap /mnt lvm2 cryptsetup
# 📦 amd-ucode — микрокод для процессоров AMD (~3 МБ)
# 📦 iucode-tool — утилита для управления микрокодом Intel
# ⚠️ Для Intel замените amd-ucode на intel-ucode iucode-tool
pacstrap /mnt amd-ucode
# 📦 memtest86+ — тест оперативной памяти для BIOS (~2 МБ)
pacstrap /mnt memtest86+
# 📦 nano — простой текстовый редактор для новичков (~0.3 МБ)
# 📦 reflector — автоматический выбор ближайших зеркал (~0.3 МБ)
pacstrap /mnt nano reflector
# 📦 pacman-contrib — дополнительные утилиты для pacman
# 📦 curl — загрузка файлов через HTTP/HTTPS
pacstrap /mnt reflector pacman-contrib curl
# 📋 Генерация fstab — таблица монтирования разделов
# -U = использовать UUID (надёжнее чем имена устройств)
genfstab -U /mnt >> /mnt/etc/fstab
# 🧹 Очистка экрана терминала
clear
echo " "
echo "#####################################################"
echo "## ✅ УСТАНОВКА БАЗОВЫХ ПАКЕТОВ ЗАВЕРШЕНА          ##"
echo "#####################################################"
echo " "
# 🚪 Вход в chroot — переход в установленную систему
arch-chroot /mnt /bin/bash
echo " "











#################################################################
# 🛠️  [CHROOT] БЛОК 7: НАСТРОЙКИ ВНУТРИ СИСТЕМЫ
#################################################################
# ℹ️ Зачем: Настройка системы: локали, fstab, время, зеркала.
# ℹ️ Важно: Выполняется внутри chroot.
# 💡 Автоматизация: Временная зона по IP, зеркала по стране.
# 💡 Шрифты: Установлены (Noto, DejaVu, Liberation, Terminus).
#################################################################
# 🧹 Очистка экрана терминала
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
# 🧹 Очистка экрана терминала
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
# 🧹 Очистка экрана терминала
clear
# 🖥️ Настройка имени компьютера (замените Sony на своё)
echo "Sony" > /etc/hostname
# 📋 Настройка файла hosts
echo "127.0.0.1   localhost" > /etc/hosts
echo "::1         localhost" >> /etc/hosts
echo "127.0.1.1   Sony.localdomain   Sony" >> /etc/hosts
# 🧹 Очистка экрана терминала
clear
echo " "
echo "###################################"
echo "## 🔑 СОЗДАЙТЕ ПАРОЛЬ ДЛЯ ROOT   ##"
echo "###################################"
echo " "
# 🔑 Установка пароля root
# ⚠️ Запомните этот пароль! Он нужен для администрирования
passwd
# 🧹 Очистка экрана терминала
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
# 🧹 Очистка экрана терминала
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
# 🧹 Очистка экрана терминала
clear
echo " "
echo "###########################################"
echo "## 👤 СОЗДАЙТЕ ПАРОЛЬ ДЛЯ ПОЛЬЗОВАТЕЛЯ   ##"
echo "###########################################"
echo " "
# 🔑 Установка пароля пользователя
# ⚠️ Запомните этот пароль! Он для повседневного входа
passwd forename
# 🧹 Очистка экрана терминала
clear
echo " "
echo "#####################################################"
echo "## ✅ НАСТРОЙКА ПОЛЬЗОВАТЕЛЯ И SUDO ЗАВЕРШЕНА      ##"
echo "#####################################################"
echo " "











#################################################################
# 🔧  [CHROOT] БЛОК 10: УСТАНОВКА ЯДРА, GRUB, MKINITCPIO
#################################################################
# ℹ️ Зачем: Настройка загрузчика и initramfs для LUKS+LVM+Btrfs.
# 💡 Включает: GRUB, grub-btrfs, plymouth, поддержку шифрования и LVM.
# ❗ КРИТИЧЕСКИ ВАЖНО: Без этих настроек система НЕ ЗАГРУЗИТСЯ.
#################################################################
# 🧹 Очистка экрана терминала
clear
# 🔄 Обновление базы данных пакетов
pacman -Syy
# 📦 linux-lts — ядро с долгосрочной поддержкой (~100 МБ)
# 📦 linux-lts-headers — заголовки ядра для драйверов (~15 МБ)
# 📦 linux-firmware — прошивки для оборудования (~200 МБ)
pacman -Sy --noconfirm linux-lts linux-lts-headers linux-firmware
# 📦 grub — загрузчик системы (~5 МБ)
# 📦 grub-btrfs — интеграция снапшотов BTRFS в GRUB (~0.2 МБ)
# 📦 os-prober — обнаружение других ОС на диске (~0.1 МБ)
pacman -Sy --noconfirm grub grub-btrfs os-prober
# 📦 networkmanager — управление сетевыми подключениями (~2 МБ)
# 📦 openssh — сервер и клиент SSH для удалённого доступа (~2 МБ)
# 📦 plymouth — экран загрузки с анимацией (~3 МБ)
pacman -Sy --noconfirm networkmanager openssh plymouth
# 📋 Настройка HOOKS mkinitcpio — ПОРЯДОК КРИТИЧЕН!
# keyboard, keymap — чтобы работала клавиатура для ввода пароля
# encrypt — расшифровать LUKS контейнер
# lvm2 — активировать LVM тома после расшифровки
# resume — восстановить из гибернации (swap)
# filesystems — смонтировать корневую ФС
# fsck — проверить файловую систему
sed -i 's/HOOKS=(.*)/HOOKS=(base udev autodetect modconf block keyboard keymap encrypt lvm2 resume filesystems fsck)/' /etc/mkinitcpio.conf
# 📋 Добавление модулей ядра в initramfs
# btrfs — поддержка файловой системы BTRFS
# dm_mod — Device Mapper (нужен для LVM)
# dm_crypt — Device Mapper Crypt (нужен для LUKS)
echo 'MODULES=(btrfs dm_mod dm_crypt)' >> /etc/mkinitcpio.conf
# 📋 Установка GRUB для BIOS
# --target=i386-pc — для BIOS систем (не UEFI!)
# --recheck — перепроверить устройство
# /dev/sdx — весь диск, а не раздел!
grub-install --target=i386-pc --recheck /dev/sdx
# 🔍 Получение UUID LUKS контейнера для параметров ядра
CRYPT_UUID=$(blkid -s UUID -o value /dev/sda3)
# 🔍 Получение UUID swap раздела для параметров ядра
SWAP_UUID=$(blkid -s UUID -o value /dev/vg_main/lv_swap)
# 📋 Настройка GRUB
sed -i 's|^GRUB_DEFAULT=.*|GRUB_DEFAULT=0|' /etc/default/grub
sed -i 's|^GRUB_TIMEOUT=.*|GRUB_TIMEOUT=5|' /etc/default/grub
sed -i 's|^GRUB_DISTRIBUTOR=.*|GRUB_DISTRIBUTOR="Arch"|' /etc/default/grub
sed -i 's|^GRUB_TIMEOUT_STYLE=.*|GRUB_TIMEOUT_STYLE=menu|' /etc/default/grub
sed -i 's|^GRUB_CMDLINE_LINUX_DEFAULT=.*|GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash rd.shell=0 rd.emergency=halt"|' /etc/default/grub
# 📋 Параметры ядра для LUKS + LVM + BTRFS
# cryptdevice — расшифровать LUKS контейнер
# root — корневой раздел в LVM
# rootflags — subvol BTRFS
# resume — swap для гибернации
sed -i "s|^GRUB_CMDLINE_LINUX=.*|GRUB_CMDLINE_LINUX=\"cryptdevice=UUID=${CRYPT_UUID}:cryptlvm root=/dev/vg_main/lv_root rootflags=subvol=@ resume=UUID=${SWAP_UUID}\"|" /etc/default/grub
sed -i 's|^GRUB_PRELOAD_MODULES=.*|GRUB_PRELOAD_MODULES="part_gpt part_msdos"|' /etc/default/grub
# 📋 GRUB_ENABLE_CRYPTODISK — ОТКЛЮЧЕН для BIOS+LUKS с отдельным /boot
sed -i 's|^GRUB_ENABLE_CRYPTODISK=.*|#GRUB_ENABLE_CRYPTODISK=y|' /etc/default/grub
sed -i 's|^# GRUB_DISABLE_RECOVERY=.*|GRUB_DISABLE_RECOVERY=true|' /etc/default/grub
# 📋 Настройка grub-btrfs для отображения снапшотов
sed -i 's/#GRUB_BTRFS_SUBMENUNAME=.*/GRUB_BTRFS_SUBMENUNAME="Arch Linux snapshots"/' /etc/default/grub-btrfs/config
sed -i 's/#GRUB_BTRFS_TITLE_FORMAT=.*/GRUB_BTRFS_TITLE_FORMAT=("description",  "date")/' /etc/default/grub-btrfs/config
# 📋 Генерация конфигурации GRUB
grub-mkconfig -o /boot/grub/grub.cfg
# 📋 Пересборка initramfs
# Включает все модули для загрузки с LUKS+LVM
mkinitcpio -P
# 🔧 Включение служб
systemctl enable NetworkManager grub-btrfsd sshd plymouth-quit
# 🧹 Очистка экрана терминала
clear
echo " "
echo "#####################################################"
echo "## ✅ GRUB НАСТРОЕН КОРРЕКТНО (BIOS + LUKS)        ##"
echo "##   Система загрузится и запросит пароль ОДИН раз ##"
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
pacman -Sy --noconfirm haveged
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
pacman -Sy --noconfirm wget usbutils lsof dmidecode dialog zip unzip unrar p7zip lzop lrzip sudo mlocate less bash-completion
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
pacman -Sy --noconfirm neovim ripgrep bat zstd lz4 btop smartmontools lm_sensors rsync git fwupd
systemctl enable fwupd.service
# 📦 dosfstools — утилиты для FAT32
# 📦 ntfs-3g — поддержка NTFS (Windows разделы)
# 📦 exfatprogs — поддержка exFAT (флешки)
# 📦 gptfdisk — работа с GPT разделами
# 📦 fuse2/fuse3/fuseiso — пользовательские ФС
# 📦 nfs-utils/cifs-utils — сетевые ФС
pacman -Sy --noconfirm dosfstools ntfs-3g exfatprogs gptfdisk fuse2 fuse3 fuseiso nfs-utils cifs-utils
# 📦 dbus-broker — шина D-BUS (межпроцессное взаимодействие)
pacman -Sy --noconfirm dbus-broker
systemctl enable dbus-broker.service
# 📦 cronie — планировщик задач (cron)
pacman -Sy --noconfirm cronie
systemctl enable cronie.service systemd-timesyncd.service
# 📋 Настройка swappiness (частота использования swap)
# 10 = минимальное использование swap (рекомендуется для SSD)
echo 'vm.swappiness=10' > /etc/sysctl.d/99-swappiness.conf
# 📦 bluez/bluez-utils — Bluetooth стек
pacman -Sy --noconfirm bluez bluez-utils
systemctl enable bluetooth.service
sed -i 's/#AutoEnable=true/AutoEnable=true/g' /etc/bluetooth/main.conf
# 📦 cups/cups-pdf — принтеры и сканирование
# 📦 ghostscript/gsfonts — обработка PDF/PostScript
# 📦 avahi — служба обнаружения в сети
# 📦 system-config-printer — GUI для настройки принтеров
# 📦 simple-scan — программа для сканирования
pacman -Sy --noconfirm cups cups-pdf ghostscript gsfonts avahi system-config-printer simple-scan
systemctl enable cups.service avahi-daemon.service
# 📦 xdg-utils/xdg-user-dirs — стандарты freedesktop.org
pacman -Sy --noconfirm xdg-utils xdg-user-dirs
xdg-user-dirs-update
# 📦 udisks2/udiskie/polkit — автоматическое монтирование
pacman -Sy --noconfirm udisks2 udiskie polkit
# 📦 pipewire-* — аудио/видео сервер (современный)
# 📦 alsa-utils — утилиты ALSA (alsamixer)
pacman -Sy --noconfirm pipewire-alsa pipewire-pulse pipewire-jack pipewire-v4l2 pipewire-zeroconf alsa-utils
# 📦 wireplumber — менеджер сессий PipeWire
pacman -Sy --noconfirm wireplumber
systemctl --global enable pipewire pipewire-pulse wireplumber
# 📦 gstreamer + кодеки — воспроизведение медиа
# 📦 ffmpeg — конвертация видео/аудио
# 📦 libdvdcss — воспроизведение DVD
pacman -Sy --noconfirm gstreamer gst-plugins-{base,good,bad,ugly} gst-libav ffmpeg a52dec faac faad2 flac lame libdca libdv libmad libmpeg2 libtheora libvorbis wavpack x264 x265 xvidcore libdvdcss taglib
# 📦 man-db/man-pages/man-pages-ru — документация
pacman -Sy --noconfirm man-db man-pages man-pages-ru
# 📦 iproute2/inetutils/dnsutils — сетевые утилиты
pacman -Sy --noconfirm iproute2 inetutils dnsutils
pacman -Syy --noconfirm
# 📦 Шрифты: Noto, DejaVu, Liberation, Terminus
pacman -Sy --noconfirm noto-fonts noto-fonts-emoji ttf-dejavu ttf-liberation terminus-font
pacman -Sy --noconfirm wqy-zenhei wqy-bitmapfont
pacman -Sy --noconfirm fontconfig freetype2 harfbuzz libxft
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
# 🖥️  [CHROOT] БЛОК 12: УСТАНОВКА ГРАФИЧЕСКИХ ДРАЙВЕРОВ
#################################################################
# 💡 Цель: Установить драйверы для Intel, AMD, NVIDIA.
# ⚠️  ВАЖНО: Если установка в VirtualBox — пропустите этот блок!
#################################################################
clear
#### === Intel Integrated Graphics ===
# pacman -Sy --noconfirm mesa vulkan-intel lib32-mesa lib32-vulkan-intel
#### === AMD Radeon Graphics или Open-Source NVIDIA (nouveau) ===
# pacman -Sy --noconfirm mesa vulkan-radeon lib32-mesa lib32-vulkan-radeon
#### === NVIDIA (Проприетарные драйверы) ===
# 📌 ВАЖНО: Этот раздел делится на два подраздела: современные и устаревшие драйверы.
# Определите архитектуру вашей карты (например, GM204 = Maxwell, TU104 = Turing) через lspci.
# --- C1. Современные GPU (Pascal, Turing, Ampere, Ada Lovelace и новее): ---
# 💡 ОФИЦИАЛЬНАЯ РЕКОМЕНДАЦИЯ NVIDIA:
# «Многие дистрибутивы Linux предоставляют собственные пакеты драйвера NVIDIA...»
# 📌 ВЕТКИ ДРАЙВЕРОВ:
# 1. **Production Branch (рекомендовано для большинства):**
# A. Для стандартного ядра (linux):
# pacman -Sy --noconfirm nvidia-open nvidia-utils lib32-nvidia-utils
# B. Для LTS-ядра (linux-lts):
# pacman -Sy --noconfirm nvidia-open-lts nvidia-utils lib32-nvidia-utils
# C. Универсальный DKMS-драйвер (для кастомных ядер):
# pacman -Sy --noconfirm nvidia-open-dkms nvidia-utils lib32-nvidia-utils
# 📌 ГИБРИДНАЯ ГРАФИКА (Intel/AMD + NVIDIA):
# pacman -Sy --noconfirm switcheroo-control
# systemctl enable switcheroo-control.service
# 📌 ТОЛЬКО ДЛЯ СИСТЕМ С ОДНОЙ СОВРЕМЕННОЙ NVIDIA-КАРТОЙ:
# pacman -Sy --noconfirm libva-nvidia-driver
####################################################
## 🧰 ШАГ 2: УСТАНОВКА ДОПОЛНИТЕЛЬНЫХ БИБЛИОТЕК   ##
####################################################
# ℹ️ Зачем: Обеспечить совместимость с Vulkan и VA-API.
# 💡 Обязательно для всех типов GPU.
# pacman -Sy --noconfirm vulkan-icd-loader lib32-vulkan-icd-loader
#########################################################
## 🔧 ШАГ 3: КОНФИГУРАЦИЯ МОДУЛЕЙ И INITRAMFS          ##
#########################################################
# ℹ️ Зачем: Включить режим модсета для NVIDIA (требуется для Wayland).
# ❗ ВАЖНО: Выполняется ТОЛЬКО при установке NVIDIA драйверов (любой ветки, включая устаревшие).
# 💡 Этот шаг применяется ТОЛЬКО если вы выбрали ВАРИАНТ C (NVIDIA Proprietary).
# === ТОЛЬКО ДЛЯ NVIDIA (ПРОПРИЕТАРНЫЕ): Настройка модулей и initramfs ===
# 📌 РАСКОММЕНТИРУЙТЕ СЛЕДУЮЩИЕ СТРОКИ, ЕСЛИ ВЫ УСТАНАВЛИВАЕТЕ NVIDIA-ДРАЙВЕР:
# echo 'options nvidia-drm modeset=1' > /etc/modprobe.d/nvidia.conf
# Для ноутбуков (опционально)
# echo 'options nvidia NVreg_DynamicPowerManagement=0x02' >> /etc/modprobe.d/nvidia.conf
# echo 'nvidia-drm' > /etc/modules-load.d/nvidia-drm.conf
# 🔄 Пересобираем initramfs — ОБЯЗАТЕЛЬНО!
# mkinitcpio -P
clear
echo " "
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
# ℹ️ Зачем: Настройка интеграции с VirtualBox.
# ❗ Важно: Только если установка в VirtualBox.
#################################################################
# 🧹 Очистка экрана терминала
clear
pacman -Sy --needed --noconfirm virtualbox-guest-utils
modprobe -a vboxguest vboxsf vboxvideo
systemctl enable vboxservice.service
echo "vboxguest vboxsf vboxvideo" > /etc/modules-load.d/virtualbox.conf
usermod -aG vboxsf forename
# 🧹 Очистка экрана терминала
clear
echo ""
echo "#####################################################"
echo "## ✅ НАСТРОЙКА VIRTUALBOX ЗАВЕРШЕНА               ##"
echo "#####################################################"
echo ""
# ➡️ ПРОДОЛЖИТЕ: перейдите к БЛОКУ 14 или завершите установку без DE











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
pacman -Sy --noconfirm plasma kde-system-meta dolphin-plugins kate konsole skanpage skanlite gwenview elisa okular ark
pacman -Sy --noconfirm ffmpegthumbs poppler-glib
pacman -Sy --noconfirm packagekit packagekit-qt6
pacman -Sy --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --noconfirm sddm
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
pacman -Sy --noconfirm gnome
pacman -Sy --noconfirm dconf-editor
pacman -Sy --noconfirm file-roller
pacman -Sy --noconfirm gnome-tweaks
pacman -Sy --noconfirm gnome-themes-extra
pacman -Sy --noconfirm gnome-browser-connector
pacman -Sy --noconfirm packagekit packagekit-qt6 gnome-packagekit
pacman -Sy --noconfirm gnome-shell-extensions
pacman -Sy --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --noconfirm ffmpegthumbnailer poppler-glib
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
pacman -Sy --noconfirm xfce4 xfce4-goodies lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -Sy --noconfirm network-manager-applet blueman
pacman -Sy --noconfirm mugshot pavucontrol xdg-user-dirs xdg-desktop-portal-gtk ristretto thunar-archive-plugin ffmpegthumbnailer
pacman -Sy --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --noconfirm ffmpegthumbnailer poppler-glib
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
pacman -Sy --noconfirm mate mate-extra lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings
pacman -Sy --noconfirm network-manager-applet blueman
pacman -Sy --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --noconfirm ffmpegthumbnailer poppler-glib
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
pacman -Sy --noconfirm cinnamon cinnamon-translations blueman lightdm lightdm-gtk-greeter lightdm-gtk-greeter-settings gnome-terminal evince
pacman -Sy --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --noconfirm ffmpegthumbnailer poppler-glib
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
pacman -Sy --noconfirm lxqt sddm breeze breeze-icons blueman featherpad libstatgrab libsysstat
pacman -Sy --noconfirm network-manager-applet blueman
pacman -Sy --noconfirm gvfs gvfs-afc gvfs-dnssd gvfs-goa gvfs-google gvfs-gphoto2 gvfs-mtp gvfs-nfs gvfs-onedrive gvfs-smb gvfs-wsdd
pacman -Sy --noconfirm ffmpegthumbnailer poppler-glib
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
pacman -Sy --noconfirm lxde openbox mousepad lightdm lightdm-slick-greeter blueman thunar-archive-plugin ffmpegthumbnailer udiskie xfce4-notifyd dunst picom
pacman -Sy --noconfirm network-manager-applet blueman
pacman -Sy --noconfirm ffmpegthumbnailer poppler-glib gnome-themes-extra
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
# 📋  [USER] БЛОК 16: РЕКОМЕНДАЦИИ ПОСЛЕ УСТАНОВКИ
#################################################################
# 🎯 Зачем: Завершение настройки системы после первой загрузки.
# ⚠️ Важно: Выполняется ПОСЛЕ первой загрузки в установленную систему.
# 👤 Выполняется: От имени обычного пользователя с sudo правами.
#################################################################

################# YAY ###########################################
# 🧹 Очистка экрана терминала
clear
git clone https://aur.archlinux.org/yay.git
cd yay
makepkg -si --noconfirm
cd ..
rm -rf yay

################## BTRFS ASSISTANT #############################
# 🧹 Очистка экрана терминала
clear
sudo pacman -Syy
sudo pacman -Sy --noconfirm snapper snap-pac btrfsmaintenance btrfs-assistant
yay -Syy
yay -Sy --noconfirm snapper-support snapper-tools
# 🧹 Очистка экрана терминала
clear
sudo systemctl enable snapper-timeline.timer

#################################################################
# 3. Настройка Btrfs Assistant:
# - Запустите Btrfs Assistant из меню приложений.
# - Он может запросить права администратора для выполнения действий.
# - Используйте его для управления снапшотами, балансировки и т.д.
#
# 4. Проверка работы grub-btrfs и snapper-tools:
# - После перезагрузки и создания снапшота, в меню GRUB
# должны появиться пункты для старых снапшотов.
# - При выборе снапшота в GRUB может быть предложено
# восстановить систему до этого снапшота (функция rollback).
#################################################################
