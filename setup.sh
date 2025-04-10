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
    echo "Este script precisa ser executado como root. Solicitando sudo..."
    exec sudo "$0" "$@"
    exit
  fi
}

pause() {
  read -rp "Pressione Enter para continuar..."
}

check_grub_backup() {
  if ! grep -q "$TAG" "$GRUB_CFG"; then
    echo "Fazendo backup de $GRUB_CFG em $BACKUP_FILE..."
    cp "$GRUB_CFG" "$BACKUP_FILE"
  fi
}

install_theme() {
  echo "Instalando o tema $THEME_NAME..."

  mkdir -p "$THEMES_DIR"
  mkdir -p "$THEME_DEST"

  echo "Copiando arquivos do tema para $THEME_DEST..."
  cp -r ./* "$THEME_DEST"

  check_grub_backup

  echo "Aplicando configurações no GRUB..."
  sed -i "/^GRUB_THEME=/d" "$GRUB_CFG"
  sed -i "/^GRUB_GFXMODE=/d" "$GRUB_CFG"

  {
    echo ""
    echo "GRUB_GFXMODE=1920x1080"
    echo "GRUB_THEME=\"$THEME_DEST/theme.txt\" $TAG"
  } >> "$GRUB_CFG"

  echo "Atualizando configuração do GRUB..."
  grub-mkconfig -o "$GRUB_DIR/grub.cfg"

  echo -e "\nTema $THEME_NAME instalado com sucesso!"
  read -rp "Deseja reiniciar agora para ver o novo tema? [s/N]: " resp
  [[ "$resp" =~ ^[Ss]$ ]] && reboot
}

remove_theme() {
  if [ ! -f "$BACKUP_FILE" ]; then
    echo "Backup não encontrado. Cancelando remoção."
    return
  fi

  echo "Removendo o tema $THEME_NAME e restaurando backup..."

  echo "Restaurando $GRUB_CFG a partir de $BACKUP_FILE..."
  cp "$BACKUP_FILE" "$GRUB_CFG"

  echo "Removendo tema de $THEME_DEST..."
  rm -rf "$THEME_DEST"

  echo "Atualizando configuração do GRUB..."
  grub-mkconfig -o "$GRUB_DIR/grub.cfg"

  echo "Tema removido e configuração restaurada com sucesso!"
  pause
}

menu() {
  clear
  echo "===== Tema GRUB CachyOS - Instalador ====="
  echo "1) Instalar o tema $THEME_NAME"
  echo "2) Remover o tema e restaurar backup do GRUB"
  echo "3) Cancelar"
  echo "=========================================="
  read -rp "Escolha uma opção: " opt

  case "$opt" in
    1) install_theme ;;
    2) remove_theme ;;
    *) echo "Cancelado." ;;
  esac
}

# Execução principal
require_sudo "$@"
menu
