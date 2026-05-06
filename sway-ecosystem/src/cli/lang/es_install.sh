#!/bin/bash

# Mensajes en Español
MSG_START=" Iniciando eaSway Installer (Base Debian/LMDE)..."
MSG_CHECKING=" Verificando instalaciones previas..."
MSG_INSTALL_BASE=" Instalando paquetes base para Sway..."
MSG_CONFIG_ENV=" Configurando entorno para"
MSG_FINISH=" Instalación completada con éxito."
MSG_DOTS=" Aplicando configuraciones de eaSway..."

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# Definición de rutas críticas[cite: 1]
# SCRIPT_DIR es heredada desde main.sh; REPO_ROOT sube dos niveles hasta la raíz de eaSway
REPO_ROOT=$(dirname $(dirname "$SCRIPT_DIR"))
CONF_DIR="$HOME/.config"

clear
echo -e "${BLUE}${MSG_START}${NC}"

# --- 1. Verificación de Sway ---
echo -e "\n${YELLOW}${MSG_CHECKING}${NC}"

if command -v sway >/dev/null 2>&1; then
    echo -e "${GREEN}✔ Sway ya está instalado. Saltando instalación base...${NC}"
else
    echo -e "${BLUE}${MSG_INSTALL_BASE}${NC}"
    # Lista de paquetes optimizada incluyendo wofi
    sudo apt update
    sudo apt install -y sway waybar mako-notifier foot wofi wlogout grim slurp wl-clipboard
fi

# --- 2. Lógica de Detección de Hardware ---
echo -e "\n${YELLOW}🔍 Detectando hardware de video...${NC}"
GPU_TYPE=$(lspci | grep -iE 'vga|3d' | tr '[:upper:]' '[:lower:]')

if echo "$GPU_TYPE" | grep -q "nvidia"; then
    VENDOR="NVIDIA"
elif echo "$GPU_TYPE" | grep -q "intel"; then
    VENDOR="INTEL"
elif echo "$GPU_TYPE" | grep -q "amd"; then
    VENDOR="AMD"
else
    VENDOR="GENERIC"
fi

echo -e "${GREEN}✔ Detectada GPU: ${VENDOR}.${NC}"

# --- 3. Detección de Laptop vs Desktop ---
CHASSIS=$(cat /sys/class/dmi/id/chassis_type)
if [[ "$CHASSIS" == "9" || "$CHASSIS" == "10" || "$CHASSIS" == "11" ]]; then
    echo -e "${GREEN}✔ Dispositivo identificado como Laptop.${NC}"
else
    echo -e "${GREEN}✔ Dispositivo identificado como Desktop.${NC}"
fi

# --- 4. Despliegue de Dotfiles (Ajustado para eaSway) ---
echo -e "\n${BLUE}${MSG_DOTS}${NC}"

# Lista de aplicaciones basada en imagen_2.png más wofi
APPS=("kitty" "mako" "sway" "waybar" "wofi")

for APP in "${APPS[@]}"; do
    # Gestión de Backups: Renombra carpetas existentes para evitar pérdida de datos
    if [ -d "$CONF_DIR/$APP" ]; then
        echo -e "${YELLOW}Aviso: Creando backup de la config antigua de $APP...${NC}"
        mv "$CONF_DIR/$APP" "$CONF_DIR/${APP}_backup_$(date +%Y%m%d_%H%M%S)"
    fi

    # Verificación de origen antes de copiar para evitar errores de 'stat'
    if [ -d "$REPO_ROOT/dotfiles/$APP" ]; then
        mkdir -p "$CONF_DIR/$APP"
        cp -r "$REPO_ROOT/dotfiles/$APP/"* "$CONF_DIR/$APP/"
        echo -e "${GREEN}✔ $APP configurado.${NC}"
    else
        echo -e "${RED}✘ Error: No se encontró la carpeta dotfiles/$APP en el repositorio.${NC}"
    fi
done

echo -e "\n${GREEN}${MSG_FINISH}${NC}"

echo -e "\n${YELLOW}Presiona Enter para salir...${NC}"
read