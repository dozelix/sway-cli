#!/bin/bash

# =================================================================
# eaSway - Módulo de Desinstalación y Limpieza (Versión Segura)
# Finalidad: Revertir los cambios para permitir pruebas repetitivas.
# =================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}>> Iniciando desinstalación de eaSway...${NC}"

# 1. Lista de paquetes a remover
# En uninstall.sh
PKGS=(sway waybar wofi mako-notifier xwayland swaybg swayidle swaylock grim slurp light pavucontrol)
sudo apt purge -y "${PKGS[@]}"
echo " - Eliminando paquetes..."
sudo apt autoremove -y

# 2. Restauración de archivos de configuración
echo " - Restaurando backups de .config..."
CONFIG_DIR="$HOME/.config"
APPS=("sway" "waybar" "mako" "kitty" "wofi")

for APP in "${APPS[@]}"; do
    # SC2115: Protección ante variables vacías para evitar borrar '/'
    # Si APP o CONFIG_DIR están vacíos, el script fallará aquí de forma segura.
    rm -rf "${CONFIG_DIR:?}/${APP:?}"
    
    # SC2012: Uso de 'find' en lugar de 'ls' para manejar backups
    # Buscamos directorios que coincidan con el patrón, ordenamos y tomamos el último
    LATEST_BAK=$(find "$CONFIG_DIR" -maxdepth 1 -type d -name "${APP}_bak_*" 2>/dev/null | sort -r | head -n 1)
    
    if [ -n "$LATEST_BAK" ]; then
        mv "$LATEST_BAK" "$CONFIG_DIR/$APP"
        echo -e "   ${GREEN}[OK]${NC} Restaurado backup para $APP"
    else
        echo -e "   [i] No se encontró backup para $APP, omitiendo."
    fi
done

echo -e "${GREEN}>> Limpieza completada. El sistema está listo para un nuevo test.${NC}"