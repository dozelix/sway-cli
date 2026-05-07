#!/bin/bash

# =================================================================
# eaSway - Módulo de Post-instalación y Permisos
# Finalidad: Configurar el sistema para que "simplemente funcione".
# Versión: 0.3 - 07-05-2026
# =================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${YELLOW}>> Iniciando ajustes finales de sistema...${NC}"

# 1. Configuración de Grupos
TARGET_USER="dozelix"

echo -e "   - Configurando acceso a hardware para '${TARGET_USER}'..."

if id "$TARGET_USER" &>/dev/null; then
    # SC2181 corregido: Evaluación directa de usermod
    if sudo usermod -aG video,input "$TARGET_USER"; then
        echo -e "${GREEN}   [OK] Usuario '${TARGET_USER}' añadido a grupos video e input.${NC}"
    else
        echo -e "${RED}   [ERROR] Falló usermod para '${TARGET_USER}'.${NC}"
    fi
else
    echo -e "${RED}   [!] Usuario '${TARGET_USER}' no encontrado. Saltando configuración.${NC}"
fi

# 2. Permisos para el control de brillo (herramienta 'light')
# SC2046 corregido: Se añaden comillas a la sustitución de comando
if command -v light > /dev/null; then
    echo -e "   - Ajustando permisos para control de brillo..."
    sudo chmod +s "$(command -v light)"
    echo -e "${GREEN}   [OK] Permisos de brillo configurados.${NC}"
else
    echo -e "${YELLOW}   [!] 'light' no instalado. Saltando ajuste de brillo.${NC}"
fi

# 3. Activación de Servicios Esenciales
echo -e "   - Verificando disponibilidad de systemd..."

if pidof systemd > /dev/null 2>&1 || [ -d /run/systemd/system ]; then
    echo -e "   - systemd detectado. Activando servicios de red..."
    # SC2181 corregido: Evaluación directa de systemctl
    if sudo systemctl enable --now NetworkManager; then
        echo -e "${GREEN}   [OK] NetworkManager activado.${NC}"
    else
        echo -e "${RED}   [ERROR] Falló la activación de NetworkManager.${NC}"
    fi
else
    echo -e "${YELLOW}   [!] systemd NO disponible. Saltando activación.${NC}"
fi

echo -e "${GREEN}>> Ajustes de sistema completados con éxito.${NC}"

# Pausa para lectura en entorno GUI
read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
echo
exit 0