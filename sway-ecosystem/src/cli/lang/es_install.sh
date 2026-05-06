#!/bin/bash

# Mensajes en Español
MSG_START="🌌 Iniciando SwayOS CLI Installer (Base Debian/LMDE)..."
MSG_CHECKING="🔍 Verificando instalaciones previas..."
MSG_INSTALL_BASE="📦 Instalando paquetes base para Sway..."
MSG_CONFIG_ENV="⚙ Configurando entorno para"
MSG_FINISH="✨ Instalación completada con éxito."

# Colores[cite: 3]
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

clear
echo -e "${BLUE}${MSG_START}${NC}"

# --- 1. Verificación de Sway ---
echo -e "\n${YELLOW}${MSG_CHECKING}${NC}"

# Comprobamos si el binario de sway ya existe en el sistema
if command -v sway >/dev/null 2>&1; then
    echo -e "${GREEN}✔ Sway ya está instalado. Saltando instalación base...${NC}"
else
    echo -e "${BLUE}${MSG_INSTALL_BASE}${NC}"
    # Lista de paquetes optimizada para Debian 12 / LMDE
    sudo apt update
    sudo apt install -y sway waybar mako-notifier foot wofi wlogout grim slurp wl-clipboard
fi

# --- 2. Lógica de Detección de Hardware[cite: 3] ---
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

# Notificación de GPU encontrada[cite: 3]
echo -e "${GREEN}✔ Detectada GPU: ${VENDOR}.${NC}"

# --- 3. Detección de Laptop vs Desktop[cite: 3] ---
CHASSIS=$(cat /sys/class/dmi/id/chassis_type)
if [[ "$CHASSIS" == "9" || "$CHASSIS" == "10" || "$CHASSIS" == "11" ]]; then
    echo -e "${GREEN}✔ Dispositivo identificado como Laptop.${NC}"
else
    echo -e "${GREEN}✔ Dispositivo identificado como Desktop.${NC}"
fi

echo -e "\n${GREEN}${MSG_FINISH}${NC}"


echo -e "\n${YELLOW}Presiona Enter para salir...${NC}"
read