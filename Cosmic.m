# Устанавливаем COSMIC Store, подсистему Flatpak, утилиту AppStream и базу метаданных приложений Arch Linux
sudo pacman -S cosmic-store flatpak appstream archlinux-appstream-data

# Добавляем официальный репозиторий Flathub (основной источник графических приложений)
flatpak remote-add --if-not-exists flathub https://dl.flathub.org/repo/flathub.flatpakrepo

# Принудительно обновляем кэш метаданных, чтобы магазин корректно "увидел" доступные приложения
sudo appstreamcli refresh --force