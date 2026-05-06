#!/bin/bash

# =================================================================
# eaSway - Módulo de Post-instalación y Permisos
# Finalidad: Configurar el sistema para que "simplemente funcione".
# Versión: 0.2 - 06-05-2026
# Correcciones: usermod con usuario explícito + guard para systemd
# =================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}>> Iniciando ajustes finales de sistema...${NC}"

# 1. Configuración de Grupos (Vital para laptops y periféricos)
# BUGFIX: Se usa 'dozelix' explícitamente. $USER puede estar vacío
# en entornos de contenedor o sesiones no-interactivas.
TARGET_USER="dozelix"

echo -e "   - Configurando acceso a hardware (video e input) para '${TARGET_USER}'..."

# Verificamos que el usuario existe antes de intentar modificarlo
if id "$TARGET_USER" &>/dev/null; then
    sudo usermod -aG video,input "$TARGET_USER"
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   [OK] Usuario '${TARGET_USER}' añadido a grupos video e input.${NC}"
    else
        echo -e "${RED}   [ERROR] Falló usermod para '${TARGET_USER}'.${NC}"
    fi
else
    echo -e "${RED}   [!] Usuario '${TARGET_USER}' no encontrado. Saltando configuración de grupos.${NC}"
fi

# 2. Permisos para el control de brillo (herramienta 'light')
if command -v light > /dev/null; then
    echo -e "   - Ajustando permisos para control de brillo..."
    sudo chmod +s $(which light)
    echo -e "${GREEN}   [OK] Permisos de brillo configurados.${NC}"
else
    echo -e "${YELLOW}   [!] 'light' no instalado. Saltando ajuste de brillo.${NC}"
fi

# 3. Activación de Servicios Esenciales
# BUGFIX: Guard para systemd. Docker y otros contenedores no usan
# systemd como PID 1, por lo que systemctl falla con error fatal.
# Detectamos si systemd está disponible antes de usarlo.
echo -e "   - Verificando disponibilidad de systemd..."

if pidof systemd > /dev/null 2>&1 || [ -d /run/systemd/system ]; then
    echo -e "   - systemd detectado. Activando servicios de red..."
    sudo systemctl enable --now NetworkManager
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}   [OK] NetworkManager activado.${NC}"
    else
        echo -e "${RED}   [ERROR] Falló la activación de NetworkManager.${NC}"
    fi
else
    echo -e "${YELLOW}   [!] systemd NO disponible (entorno de contenedor).${NC}"
    echo -e "${YELLOW}       NetworkManager NO se activará. Esto es esperado en Docker.${NC}"
    echo -e "${YELLOW}       En tu PC real, los servicios se activarán correctamente.${NC}"
fi

echo -e "${GREEN}>> Ajustes de sistema completados con éxito.${NC}"