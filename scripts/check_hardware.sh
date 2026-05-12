#!/bin/bash

# =================================================================
# Versión: 0.0.2
# eaSway - Módulo de Detección de Hardware
# Finalidad: Verificar el entorno antes de la instalación para
#evitar errores de configuración en VM y Docker.
# Cambios v0.0.2:
#   - Detección granular de GPU: Intel, AMD, NVIDIA (SW-08)
#   - Advertencia accionable si se detecta NVIDIA (Wayland quirks)
#   - Detección de entorno gráfico previo (X11 vs Wayland)
#   - Verificación de dependencias mínimas del sistema
#   - Salida estructurada compatible con el orquestador main.sh
# Fixes ShellCheck: 
#   - SC2034: Exportación de GPU_VENDOR para uso externo.
#   - SC2001: Uso de expansión de parámetros en lugar de sed.
# v0.0.3_alpha:
# implementacion de deteccion de bateria para laptop y export var
# para añadir pkgs a install
# =================================================================

# --- Colores ---
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

# --- Contadores de advertencias ---
WARNINGS=0

echo -e "${BLUE}>> Iniciando verificación de hardware...${NC}"
echo -e "   ----------------------------------------"

# =================================================================
# 1. DETECCIÓN DE ENTORNO CONTENEDOR / VIRTUAL
# =================================================================
if [ -f /.dockerenv ]; then
    echo -e "${YELLOW}[!] Entorno Docker detectado. Saltando pruebas físicas.${NC}"
    return 0
fi

if command -v systemd-detect-virt &>/dev/null; then
    VIRT_ENV=$(systemd-detect-virt 2>/dev/null)
    if [ "$VIRT_ENV" != "none" ]; then
        echo -e "${YELLOW}   [!] Entorno virtualizado detectado: $VIRT_ENV${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
fi

# =================================================================
# 2. ARQUITECTURA DEL SISTEMA
# =================================================================
ARCH=$(uname -m)
echo -e "   - Arquitectura del sistema: ${ARCH}"

if [ "$ARCH" != "x86_64" ]; then
    echo -e "${RED}   [!] ADVERTENCIA: eaSway está optimizado para x86_64.${NC}"
    WARNINGS=$((WARNINGS + 1))
fi

# --- Detección de Tipo de Chasis (Laptop vs Desktop) ---
IS_LAPTOP=false

# 1. Comprobar chasis mediante DMI
if [ -f /sys/class/dmi/id/chassis_type ]; then
    CHASSIS_ID=$(cat /sys/class/dmi/id/chassis_type)
    # Tipos 8, 9, 10, 11, 12 y 14 suelen ser portátiles
    case "$CHASSIS_ID" in
        8|9|10|11|12|14) IS_LAPTOP=true ;;
    esac
fi

# 2. Doble comprobación: ¿Existe una batería?
if [ -d /sys/class/power_supply/BAT0 ] || [ -d /sys/class/power_supply/BAT1 ]; then
    IS_LAPTOP=true
fi

if [ "$IS_LAPTOP" = true ]; then
    export DEVICE_TYPE="laptop"
    echo -e "${GREEN}   [OK] Dispositivo detectado como Laptop.${NC}"
else
    export DEVICE_TYPE="desktop"
    echo -e "   - Dispositivo detectado como Desktop."
fi

# =================================================================
# 3. DETECCIÓN DE GPU (CRÍTICO PARA WAYLAND)
# =================================================================

classify_gpu() {
    local raw="$1"
    if echo "$raw" | grep -qi "nvidia"; then
        echo "NVIDIA"
    elif echo "$raw" | grep -qi "amd\|radeon\|advanced micro"; then
        echo "AMD"
    elif echo "$raw" | grep -qi "intel"; then
        echo "Intel"
    else
        echo "Desconocido"
    fi
}

if ! command -v lspci &>/dev/null; then
    echo -e "${YELLOW}   [!] 'lspci' no encontrado. No se puede detectar la GPU.${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    GPU_RAW=$(lspci | grep -iE 'vga|display|3d controller' | head -n 1)
    GPU_NAME="${GPU_RAW#*: }"
    export GPU_VENDOR
    GPU_VENDOR=$(classify_gpu "$GPU_RAW")

    echo -e "   - GPU detectada: ${GPU_NAME:-Desconocida}"

    case "$GPU_VENDOR" in
        "NVIDIA")
            echo -e "${YELLOW}   [!] GPU NVIDIA detectada. Requiere drivers propietarios.${NC}"
            WARNINGS=$((WARNINGS + 1))
            ;;
        "AMD")
            echo -e "${GREEN}   [OK] GPU AMD detectada.${NC}"
            ;;
        "Intel")
            echo -e "${GREEN}   [OK] GPU Intel detectada.${NC}"
            ;;
        *)
            echo -e "${YELLOW}   [?] Fabricante de GPU no identificado.${NC}"
            WARNINGS=$((WARNINGS + 1))
            ;;
    esac
fi


# =================================================================
# 4. DEPENDENCIAS MÍNIMAS
# =================================================================
REQUIRED_CMDS=("bash" "apt" "sudo" "cp" "mkdir" "find")
for cmd in "${REQUIRED_CMDS[@]}"; do
    if ! command -v "$cmd" &>/dev/null; then
        echo -e "${RED}   [ERROR] Dependencia crítica no encontrada: '$cmd'${NC}"
    fi
done

# =================================================================
# 5. RESUMEN FINAL
# =================================================================
echo -e "   ----------------------------------------"
if [ "$WARNINGS" -gt 0 ]; then
    echo -e "${YELLOW}>> Verificación completada con $WARNINGS advertencia(s).${NC}"
else
    echo -e "${GREEN}>> Verificación de hardware completada sin problemas.${NC}"
fi

exit 0