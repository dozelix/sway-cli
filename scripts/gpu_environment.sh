#!/bin/bash

# Función para configurar el entorno gráfico según la GPU
setup_video_env() {
    local ENV_FILE="/etc/profile.d/easway_env.sh"
    
    echo "[i] Configurando variables de entorno para $GPU_VENDOR..."

    sudo bash -c "cat > $ENV_FILE" <<EOF
# --- eaSway Graphic Environment Variables ---

# Forzar Wayland en aplicaciones comunes
export MOZ_ENABLE_WAYLAND=1
export QT_QPA_PLATFORM=wayland
export CLUTTER_BACKEND=wayland
export SDL_VIDEODRIVER=wayland

# Configuración específica por Hardware
EOF

    case "$GPU_VENDOR" in
        "NVIDIA")
            sudo bash -c "cat >> $ENV_FILE" <<EOF
# Fixes para NVIDIA Propietario
export WLR_NO_HARDWARE_CURSORS=1
export LIBVA_DRIVER_NAME=nvidia
export __GLX_VENDOR_LIBRARY_NAME=nvidia
export GBM_BACKEND=nvidia-drm
EOF
            ;;
        "Intel")
            sudo bash -c "cat >> $ENV_FILE" <<EOF
# Optimización para Intel
export LIBVA_DRIVER_NAME=iHD
EOF
            ;;
        "AMD")
            sudo bash -c "cat >> $ENV_FILE" <<EOF
# Optimización para AMD
export LIBVA_DRIVER_NAME=radeonsi
EOF
            ;;
    esac

    sudo chmod +x "$ENV_FILE"
    echo -e "${GREEN}   [OK] Variables de entorno generadas en $ENV_FILE${NC}"
}

# Al final de scripts/gpu_environment.sh añade:
setup_video_env