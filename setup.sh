#!/bin/bash

THEME_NAME="cachyos"
GRUB_DIR="/boot/grub"
THEMES_DIR="$GRUB_DIR/themes"
THEME_DEST="$THEMES_DIR/$THEME_NAME"
GRUB_CFG="/etc/default/grub"
BACKUP_FILE="/etc/default/grub.backup.$THEME_NAME"
TAG="# [cachyos-theme-applied]"

require_sudo() {
  if [ "$EUID" -ne 0 ]; then
    echo "This script needs to be run as root. Requesting sudo..."
    exec sudo "$0" "$@"
    exit
  fi
}

pause() {
  read -rp "Press Enter to continue..."
}

check_grub_backup() {
  if ! grep -q "$TAG" "$GRUB_CFG"; then
    echo "Backing up $GRUB_CFG in $BACKUP_FILE..."
    cp "$GRUB_CFG" "$BACKUP_FILE"
  fi
}

install_theme() {
  echo "Installing the $THEME_NAME theme..."

  mkdir -p "$THEMES_DIR"
  mkdir -p "$THEME_DEST"

  echo "Copying theme files to $THEME_DEST..."
  cp -r ./* "$THEME_DEST"

  check_grub_backup

  echo "Applying GRUB settings..."
  sed -i "/^GRUB_THEME=/d" "$GRUB_CFG"
  sed -i "/^GRUB_GFXMODE=/d" "$GRUB_CFG"

  {
    echo ""
    echo "GRUB_GFXMODE=1920x1080"
    echo "GRUB_THEME=\"$THEME_DEST/theme.txt\" $TAG"
  } >> "$GRUB_CFG"

  echo "Updating GRUB configuration..."
  grub-mkconfig -o "$GRUB_DIR/grub.cfg"

  echo -e "\nTheme $THEME_NAME successfully installed!"
  read -rp "Would you like to restart now to see the new theme? [y/N]: " resp
  [[ "$resp" =~ ^[Yy]$ ]] && reboot
}

remove_theme() {
  if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup not found. Cancelling removal."
    return
  fi

  echo "Removing the $THEME_NAME theme and restoring the backup..."

  echo "Restoring $GRUB_CFG from $BACKUP_FILE..."
  cp "$BACKUP_FILE" "$GRUB_CFG"

  echo "Removing theme from $THEME_DEST..."
  rm -rf "$THEME_DEST"

  echo "Updating GRUB configuration..."
  grub-mkconfig -o "$GRUB_DIR/grub.cfg"

  echo "Theme removed and configuration successfully restored!"
  pause
}

menu() {
  clear
  echo "===== CachyOS GRUB Theme - Installer ====="
  echo "1) Install the $THEME_NAME theme"
  echo "2) Remove theme and restore GRUB backup"
  echo "3) Cancel"
  echo "=========================================="
  read -rp "Choose an option: " opt

  case "$opt" in
    1) install_theme ;;
    2) remove_theme ;;
    *) echo "Cancelled." ;;
  esac
}

# Main execution
require_sudo "$@"
menu
