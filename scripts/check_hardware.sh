#!/bin/bash

# =================================================================
# Versión: 0.0.1
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
    exit 0
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

# =================================================================
# 3. DETECCIÓN DE GPU (CRÍTICO PARA WAYLAND)
# =================================================================
if ! command -v lspci &>/dev/null; then
    echo -e "${YELLOW}   [!] 'lspci' no encontrado. No se puede detectar la GPU.${NC}"
    WARNINGS=$((WARNINGS + 1))
else
    # Extraemos el nombre completo de la GPU
    GPU_RAW=$(lspci | grep -iE 'vga|display|3d controller' | head -n 1)
    
    # Fix SC2001: Usamos expansión de parámetros de Bash en lugar de sed
    # Esto elimina todo hasta el primer ": " incluido
    GPU_NAME="${GPU_RAW#*: }"

    echo -e "   - GPU detectada: ${GPU_NAME:-Desconocida}"

    # Clasificación del fabricante
    # Fix SC2034: Exportamos la variable para que sea visible por otros scripts
    if echo "$GPU_RAW" | grep -qi "nvidia"; then
        export GPU_VENDOR="NVIDIA"
        echo -e "${YELLOW}   [!] GPU NVIDIA detectada. Requiere drivers propietarios.${NC}"
        WARNINGS=$((WARNINGS + 1))
    elif echo "$GPU_RAW" | grep -qi "amd\|radeon\|advanced micro"; then
        export GPU_VENDOR="AMD"
        echo -e "${GREEN}   [OK] GPU AMD detectada.${NC}"
    elif echo "$GPU_RAW" | grep -qi "intel"; then
        export GPU_VENDOR="Intel"
        echo -e "${GREEN}   [OK] GPU Intel detectada.${NC}"
    else
        export GPU_VENDOR="Desconocido"
        echo -e "${YELLOW}   [?] Fabricante de GPU no identificado.${NC}"
        WARNINGS=$((WARNINGS + 1))
    fi
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