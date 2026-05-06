#!/bin/bash

# Mensajes en Español
MSG_START=" Iniciando eaSway Installer (Base Debian/LMDE)..."
MSG_CHECKING=" Verificando instalaciones previas..."
MSG_INSTALL_BASE=" Instalando paquetes base para Sway..."
MSG_FINISH=" Instalación completada con éxito."
MSG_DOTS=" Aplicando configuraciones de eaSway..."

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- Definición de rutas críticas con rutas absolutas reales ---
SCRIPT_PATH=$(readlink -f "${BASH_SOURCE[0]}")
SCRIPT_DIR_ABS=$(dirname "$SCRIPT_PATH")
REPO_ROOT=$(dirname $(dirname $(dirname "$SCRIPT_DIR_ABS")))
CONF_DIR="$HOME/.config"

clear
echo -e "${BLUE}${MSG_START}${NC}"

# --- 1. Verificación de Sway ---
echo -e "\n${YELLOW}${MSG_CHECKING}${NC}"

if command -v sway >/dev/null 2>&1; then
    echo -e "${GREEN}✔ Sway ya está instalado. Saltando instalación base...${NC}"[cite: 3]
else
    echo -e "${BLUE}${MSG_INSTALL_BASE}${NC}"[cite: 3]
    sudo apt update[cite: 3]
    sudo apt install -y sway waybar mako-notifier foot wofi wlogout grim slurp wl-clipboard[cite: 3]
fi

# --- 2. Lógica de Detección de Hardware ---
echo -e "\n${YELLOW}🔍 Detectando hardware de video...${NC}"[cite: 3]
GPU_TYPE=$(lspci | grep -iE 'vga|3d' | tr '[:upper:]' '[:lower:]')[cite: 3]

if echo "$GPU_TYPE" | grep -q "nvidia"; then
    VENDOR="NVIDIA"[cite: 3]
elif echo "$GPU_TYPE" | grep -q "intel"; then
    VENDOR="INTEL"[cite: 3]
elif echo "$GPU_TYPE" | grep -q "amd"; then
    VENDOR="AMD"[cite: 3]
else
    VENDOR="GENERIC"[cite: 3]
fi
echo -e "${GREEN}✔ Detectada GPU: ${VENDOR}.${NC}"[cite: 3]

# --- 3. Detección de Laptop vs Desktop ---
CHASSIS=$(cat /sys/class/dmi/id/chassis_type)[cite: 3]
if [[ "$CHASSIS" == "9" || "$CHASSIS" == "10" || "$CHASSIS" == "11" ]]; then
    echo -e "${GREEN}✔ Dispositivo identificado como Laptop.${NC}"[cite: 3]
else
    echo -e "${GREEN}✔ Dispositivo identificado como Desktop.${NC}"[cite: 3]
fi

# --- 4. Despliegue de Dotfiles ---
echo -e "\n${BLUE}${MSG_DOTS}${NC}"[cite: 3]

APPS=("kitty" "mako" "sway" "waybar" "wofi")[cite: 3]

for APP in "${APPS[@]}"; do
    SOURCE_DIR="$REPO_ROOT/dotfiles/$APP"[cite: 3]

    if [ -d "$SOURCE_DIR" ]; then
        # Verificar si la carpeta de origen tiene archivos
        if [ "$(ls -A "$SOURCE_DIR")" ]; then[cite: 3]
            # Gestión de Backups
            if [ -d "$CONF_DIR/$APP" ]; then
                echo -e "${YELLOW}Aviso: Creando backup de la config antigua de $APP...${NC}"[cite: 3]
                mv "$CONF_DIR/$APP" "$CONF_DIR/${APP}_backup_$(date +%Y%m%d_%H%M%S)"[cite: 3]
            fi

            mkdir -p "$CONF_DIR/$APP"[cite: 3]
            cp -r "$SOURCE_DIR/." "$CONF_DIR/$APP/"[cite: 3]
            echo -e "${GREEN}✔ $APP configurado.${NC}"[cite: 3]
        else
            echo -e "${YELLOW}⚠ Omisión: La carpeta $APP en el repositorio está vacía.${NC}"[cite: 3]
        fi
    else
        echo -e "${RED}✘ Error: No se encontró la carpeta dotfiles/$APP en $REPO_ROOT${NC}"[cite: 3]
    fi
done

echo -e "\n${GREEN}${MSG_FINISH}${NC}"[cite: 3]
echo -e "\n${YELLOW}Presiona Enter para salir...${NC}"[cite: 3]
read