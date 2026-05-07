#!/bin/bash

# =================================================================
# eaSway - Módulo de Desinstalación y Limpieza
# Finalidad: Revertir los cambios para permitir pruebas repetitivas.
# =================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}>> Iniciando desinstalación de eaSway...${NC}"

# 1. Lista de paquetes a remover (basada en install_packages.sh)
PKGS="sway waybar wofi mako-notifier xwayland swaybg swayidle swaylock grim slurp light pavucontrol"

echo " - Eliminando paquetes..."
sudo apt purge -y $PKGS
sudo apt autoremove -y

# 2. Restauración de archivos de configuración
echo " - Restaurando backups de .config..."
CONFIG_DIR="$HOME/.config"
APPS=("sway" "waybar" "mako" "kitty" "wofi")

for APP in "${APPS[@]}"; do
    # Eliminar la carpeta instalada por eaSway
    rm -rf "$CONFIG_DIR/$APP"
    
    # Buscar el backup más reciente
    LATEST_BAK=$(ls -d ${CONFIG_DIR}/${APP}_bak_* 2>/dev/null | sort -r | head -n 1)
    
    if [ -n "$LATEST_BAK" ]; then
        mv "$LATEST_BAK" "$CONFIG_DIR/$APP"
        echo "   [OK] Restaurado backup para $APP"
    fi
done

echo -e "${GREEN}>> Limpieza completada. El sistema está listo para un nuevo test.${NC}"