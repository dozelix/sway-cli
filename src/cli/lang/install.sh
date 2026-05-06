#!/bin/bash

# =================================================================
# eaSway - Instalador Unificado (Versión de Desarrollo)
# =================================================================

# Colores para una interfaz limpia
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

# --- 1. Configuración de Rutas ---
# Al estar el script en la raíz, REPO_ROOT es simplemente el directorio actual
REPO_ROOT=$(pwd)
CONF_DIR="$HOME/.config"

clear
echo -e "${BLUE} Iniciando eaSway Installer (Base Debian/LMDE)...${NC}"

# --- 2. Verificación de Privilegios ---
if [[ $EUID -eq 0 ]]; then
   echo -e "${RED}Error: No ejecutes este script con sudo directamente.${NC}"
   echo -e "El script pedirá la contraseña cuando sea necesario para proteger tu \$HOME."
   exit 1
fi

# --- 3. Instalación de Paquetes ---
echo -e "\n${YELLOW} Verificando paquetes base...${NC}"
if ! command -v sway >/dev/null 2>&1; then
    echo -e "${BLUE} Instalando componentes de Sway...${NC}"
    sudo apt update && sudo apt install -y sway waybar mako-notifier foot wofi wlogout grim slurp wl-clipboard
else
    echo -e "${GREEN}✔ Sway y sus componentes ya están presentes.${NC}"
fi

# --- 4. Detección de Hardware ---
echo -e "\n${YELLOW}🔍 Detectando hardware...${NC}"
GPU_TYPE=$(lspci | grep -iE 'vga|3d' | tr '[:upper:]' '[:lower:]')
VENDOR="GENERIC"
[[ "$GPU_TYPE" == *"intel"* ]] && VENDOR="INTEL"
[[ "$GPU_TYPE" == *"nvidia"* ]] && VENDOR="NVIDIA"
[[ "$GPU_TYPE" == *"amd"* ]] && VENDOR="AMD"

CHASSIS=$(cat /sys/class/dmi/id/chassis_type)
TYPE="Desktop"
[[ "$CHASSIS" =~ ^(9|10|11)$ ]] && TYPE="Laptop"

echo -e "${GREEN}✔ Sistema: $TYPE | GPU: $VENDOR${NC}"

# --- 5. Despliegue de Dotfiles ---
echo -e "\n${BLUE} Aplicando configuraciones de eaSway...${NC}"

APPS=("kitty" "mako" "sway" "waybar" "wofi")

for APP in "${APPS[@]}"; do
    SOURCE_DIR="$REPO_ROOT/dotfiles/$APP"

    if [ -d "$SOURCE_DIR" ]; then
        # Verificar si hay archivos para copiar
        if [ "$(ls -A "$SOURCE_DIR" 2>/dev/null)" ]; then
            # Backup de seguridad
            if [ -d "$CONF_DIR/$APP" ]; then
                echo -e "${YELLOW}Aviso: Respaldando config antigua de $APP...${NC}"
                mv "$CONF_DIR/$APP" "$CONF_DIR/${APP}_bak_$(date +%Y%m%d_%H%M%S)"
            fi

            mkdir -p "$CONF_DIR/$APP"
            cp -r "$SOURCE_DIR/." "$CONF_DIR/$APP/"
            echo -e "${GREEN}✔ $APP configurado con éxito.${NC}"
        else
            echo -e "${YELLOW}⚠ Saltado: $APP no tiene archivos en dotfiles/.${NC}"
        fi
    else
        echo -e "${RED}✘ Error: No se encontró la carpeta dotfiles/$APP${NC}"
    fi
done

# --- 6. Finalización ---
echo -e "\n${GREEN} Instalación completada con éxito.${NC}"
echo -e "${YELLOW}Presiona Enter para finalizar...${NC}"
read