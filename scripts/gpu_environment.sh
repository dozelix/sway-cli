#!/bin/bash

# =================================================================
# eaSway - Módulo de Variables de Entorno Gráfico
# Finalidad: Generar configuración de Wayland según GPU detectada.
# Fix v0.0.4:
#   - GPU_VENDOR="Desconocido" ya no causa exit 1.
#     Escribe variables genéricas de Wayland y advierte al usuario.
# =================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

setup_video_env() {
    local ENV_FILE="/etc/profile.d/easway_env.sh"

    # Si GPU_VENDOR no está definido, asignar valor por defecto
    if [ -z "$GPU_VENDOR" ]; then
        echo -e "${YELLOW}   [!] GPU_VENDOR no definido. Usando configuración genérica.${NC}"
        GPU_VENDOR="Desconocido"
    fi

    echo -e "   [i] Configurando variables de entorno para: $GPU_VENDOR..."

    local GPU_VARS
    case "$GPU_VENDOR" in
        "NVIDIA")
            GPU_VARS="# Fixes para NVIDIA Propietario
export WLR_NO_HARDWARE_CURSORS=1
export LIBVA_DRIVER_NAME=nvidia
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export GBM_BACKEND=nvidia-drm"
            ;;
        "Intel")
            GPU_VARS="# Optimización para Intel
export LIBVA_DRIVER_NAME=iHD
export WLR_RENDERER=vulkan
export WLR_NO_HARDWARE_CURSORS=0"
            ;;
        "AMD")
            GPU_VARS="# Optimización para AMD
export LIBVA_DRIVER_NAME=radeonsi"
            ;;
        *)
            echo -e "${YELLOW}   [!] GPU no reconocida o entorno virtual. Aplicando config genérica.${NC}"
            GPU_VARS="# GPU no reconocida / VM — renderer software habilitado
export WLR_NO_HARDWARE_CURSORS=1
export WLR_RENDERER=auto
export WLR_RENDERER_ALLOW_SOFTWARE=1"
            ;;
    esac

    sudo tee "$ENV_FILE" > /dev/null <<EOF
# =================================================================
# eaSway - Graphic Environment Variables
# Generado automáticamente por gpu_environment.sh
# GPU detectada: $GPU_VENDOR
# =================================================================

# Forzar Wayland en aplicaciones comunes
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export CLUTTER_BACKEND=wayland
export SDL_VIDEODRIVER=wayland

# Configuración específica por Hardware
$GPU_VARS
EOF

    sudo chmod +x "$ENV_FILE"
    echo -e "${GREEN}   [OK] Variables de entorno generadas en $ENV_FILE${NC}"
}

setup_video_env