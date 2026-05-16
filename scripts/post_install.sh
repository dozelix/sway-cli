#!/bin/bash
set -euo pipefail
# =================================================================
# Versión: 0.0.4
# eaSway - Módulo de Post-instalación y Permisos
# Finalidad: Configurar el sistema de forma dinámica y genérica.
# Fix v0.0.4:
#   - Eliminado read -n 1 bloqueante (rompe ejecución no interactiva).
#   - Ruta de wallpaper actualizada a .webp
#   - REPO_ROOT corregido para scripts/ dentro de la raíz del repo.
# Fix v0.0.4:
#   - BUG-7: Agregado fallback .svg para easway_wallpaper_geometric.svg,
#     el único asset real del repo. Evita que swaybg arranque con path nulo.
# =================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)" || { echo -e "${RED}[ERROR] No se pudo determinar REPO_ROOT.${NC}"; exit 1; }

# Importar IN_VM si está disponible
export IN_VM=${IN_VM:-false}

echo -e "${YELLOW}>> Iniciando ajustes finales de sistema...${NC}"

# 1. Configuración de Grupos
TARGET_USER="${SUDO_USER:-${USER:-$(whoami)}}"
# Validar que el usuario existe
if ! id "$TARGET_USER" &>/dev/null; then
    echo -e "${YELLOW}[!] Usuario '$TARGET_USER' no encontrado.${NC}"
    TARGET_USER=$(getent passwd 1000 | cut -d: -f1) || TARGET_USER="root"
fi

echo -e "   - Configurando acceso a hardware para: '${TARGET_USER}'..."

if id "$TARGET_USER" &>/dev/null; then
    if sudo usermod -aG video,input,seat "$TARGET_USER" 2>/dev/null; then
        echo -e "${GREEN}   [OK] Usuario '${TARGET_USER}' añadido a grupos video e input.${NC}"
    else
        echo -e "${YELLOW}   [!] No se pudo agregar a grupos video/input/seat (podría requerir permisos).${NC}"
    fi
else
    echo -e "${RED}   [!] No se pudo determinar usuario válido. Saltando configuración.${NC}"
fi

# 2. Permisos para el control de brillo
if [ "$IN_VM" = false ] && command -v light > /dev/null; then
    echo -e "   - Ajustando permisos para control de brillo..."
    if sudo chmod +s "$(command -v light)" 2>/dev/null; then
        echo -e "${GREEN}   [OK] Permisos de brillo configurados.${NC}"
    else
        echo -e "${YELLOW}   [!] No se pudo configurar SUID para 'light' (esperado en algunos entornos).${NC}"
    fi
elif [ "$IN_VM" = true ]; then
    echo -e "${YELLOW}   [i] Virtualización detectada. Saltando SUID para 'light'.${NC}"
fi

# 3. Activación de Servicios Esenciales
if pidof systemd > /dev/null 2>&1 || [ -d /run/systemd/system ]; then
    echo -e "   - systemd detectado. Activando servicios de red..."
    
    # 1. Intentar activar NetworkManager
    if sudo systemctl enable --now NetworkManager 2>/dev/null; then
        echo -e "${GREEN}   [OK] NetworkManager activado.${NC}"
    else
        echo -e "${YELLOW}   [!] No se pudo activar NetworkManager (esperado en algunas VMs).${NC}"
    fi

    # 2. Intentar activar seatd (ya sabemos que systemd existe, no hace falta repetir el if)
    sudo systemctl enable --now seatd 2>/dev/null || true

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
elif [ -f "$REPO_ROOT/assets/wallpapers/easway_wallpaper_geometric.svg" ]; then
    # BUG-7 FIX: el único asset presente en el repo es .svg; sin este fallback
    # swaybg arrancaría con un path inexistente y el fondo quedaría negro.
    WALLPAPER_SRC="$REPO_ROOT/assets/wallpapers/easway_wallpaper_geometric.svg"
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