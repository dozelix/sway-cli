#!/bin/bash
# =================================================================
# Versión: 0.5
# eaSway - Módulo de Post-instalación y Permisos
# Finalidad: Configurar el sistema de forma dinámica y genérica.
# Fix v0.5:
#   - Eliminado read -n 1 bloqueante (rompe ejecución no interactiva).
#   - Ruta de wallpaper actualizada a .webp
#   - REPO_ROOT corregido para scripts/ dentro de la raíz del repo.
# =================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REPO_ROOT=$(readlink -f "$(dirname "$0")/..")

echo -e "${YELLOW}>> Iniciando ajustes finales de sistema...${NC}"

# 1. Configuración de Grupos
TARGET_USER="${SUDO_USER:-${USER:-$(whoami)}}"
echo -e "   - Configurando acceso a hardware para: '${TARGET_USER}'..."

if id "$TARGET_USER" &>/dev/null; then
    if sudo usermod -aG video,input "$TARGET_USER"; then
        echo -e "${GREEN}   [OK] Usuario '${TARGET_USER}' añadido a grupos video e input.${NC}"
    else
        echo -e "${RED}   [ERROR] Falló usermod para '${TARGET_USER}'.${NC}"
    fi
else
    echo -e "${RED}   [!] No se pudo determinar el usuario actual. Saltando configuración.${NC}"
fi

# 2. Permisos para el control de brillo
if command -v light > /dev/null; then
    echo -e "   - Ajustando permisos para control de brillo..."
    sudo chmod +s "$(command -v light)"
    echo -e "${GREEN}   [OK] Permisos de brillo configurados.${NC}"
else
    echo -e "${YELLOW}   [!] 'light' no instalado. Saltando ajuste de brillo.${NC}"
fi

# 3. Activación de Servicios Esenciales
if pidof systemd > /dev/null 2>&1 || [ -d /run/systemd/system ]; then
    echo -e "   - systemd detectado. Activando servicios de red..."
    if sudo systemctl enable --now NetworkManager; then
        echo -e "${GREEN}   [OK] NetworkManager activado.${NC}"
    else
        echo -e "${RED}   [ERROR] Falló la activación de NetworkManager.${NC}"
    fi
else
    echo -e "${YELLOW}   [!] systemd NO disponible. Saltando activación de servicios.${NC}"
fi

# 4. Directorios de usuario y wallpaper
echo -e "   - Creando directorios de usuario..."
mkdir -p "$HOME/wallpapers"
mkdir -p "$HOME/capturas"

WALLPAPER_SRC=""
if [ -f "$REPO_ROOT/assets/wallpapers/easway_wallpaper.webp" ]; then
    WALLPAPER_SRC="$REPO_ROOT/assets/wallpapers/easway_wallpaper.webp"
elif [ -f "$REPO_ROOT/assets/wallpapers/easway_wallpaper.png" ]; then
    WALLPAPER_SRC="$REPO_ROOT/assets/wallpapers/easway_wallpaper.png"
fi

if [ -n "$WALLPAPER_SRC" ]; then
    cp "$WALLPAPER_SRC" "$HOME/wallpapers/"
    echo -e "${GREEN}   [OK] Wallpaper instalado: $(basename "$WALLPAPER_SRC")${NC}"
else
    echo -e "${YELLOW}   [!] Wallpaper no encontrado en assets/. Saltando.${NC}"
fi

echo -e "${GREEN}   [OK] Directorios creados.${NC}"
echo -e "${GREEN}>> Ajustes de sistema completados con éxito.${NC}"

exit 0