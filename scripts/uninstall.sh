#!/bin/bash
set -euo pipefail

# =================================================================
# Versión: 0.2
# eaSway - Módulo de Desinstalación y Limpieza
# Finalidad: remover el entorno de forma segura para el usuario.
# Fix v0.2:
#   - BUG#7: Agregado "foot" al array APPS de restauración para
#     que coincida con lo que despliega setup_config.sh
# =================================================================

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${RED}>> Iniciando desinstalación de eaSway...${NC}"

# 1. Lista de paquetes a remover
PKGS=(
    "sway"
    "waybar"
    "wofi"
    "mako-notifier"
    "xwayland"
    "swaybg"
    "swayidle"
    "swaylock"
    "grim"
    "slurp"
    "light"
    "pavucontrol"
)

# Validar si el array tiene elementos antes de proceder
if [ ${#PKGS[@]} -gt 0 ]; then
    echo ">> Iniciando purga de paquetes..."
    sudo apt purge -y "${PKGS[@]}"
    sudo apt autoremove -y
fi

# 2. Restauración de archivos de configuración
echo " - Restaurando backups de .config..."
CONFIG_DIR="$HOME/.config"

# BUG#7 FIX: agregado "foot" para que coincida con setup_config.sh
# setup_config.sh despliega: sway, waybar, mako, wofi, foot
APPS=("sway" "waybar" "mako" "wofi" "foot")

for APP in "${APPS[@]}"; do
    # SC2115: Protección ante variables vacías para evitar borrar '/'
    rm -rf "${CONFIG_DIR:?}/${APP:?}"

    # SC2012: Uso de 'find' en lugar de 'ls' para manejar backups
    LATEST_BAK=$(find "$CONFIG_DIR" -maxdepth 1 -type d -name "${APP}_bak_*" 2>/dev/null | sort -r | head -n 1)

    if [ -n "$LATEST_BAK" ]; then
        mv "$LATEST_BAK" "$CONFIG_DIR/$APP"
        echo -e "   ${GREEN}[OK]${NC} Restaurado backup para $APP"
    else
        echo -e "   [i] No se encontró backup para $APP, omitiendo."
    fi
done

echo -e "${GREEN}>> Limpieza completada. El sistema está listo para un nuevo test.${NC}"