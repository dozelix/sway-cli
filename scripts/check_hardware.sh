#!/bin/bash

# =================================================================
# eaSway - Módulo de Detección de Hardware
# Desarrollado por: dozelix
# =================================================================

# Colores
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}>> Iniciando verificación de hardware...${NC}"

# 1. Detectar si estamos en un contenedor
if [ -f /.dockerenv ]; then
    echo -e "${YELLOW}[!] Entorno Docker detectado. Saltando pruebas físicas.${NC}"
    exit 0
fi

# 2. Verificar arquitectura (esperamos x86_64 para Debian/LMDE)
ARCH=$(uname -m)
echo "   - Arquitectura: $ARCH"

# 3. Verificar si hay batería (típico de laptops)
if [ -d /sys/class/power_supply/BAT0 ]; then
    echo "   - Dispositivo: Laptop detectada (Batería presente)."
else
    echo "   - Dispositivo: Desktop / VM detectada."
fi

# 4. Verificar GPU
GPU_TYPE=$(lspci | grep -iE 'vga|display' | cut -d: -f3)
echo "   - GPU detectada:$GPU_TYPE"

echo -e "${BLUE}>> Verificación terminada.${NC}"
exit 0