#!/bin/bash

# =================================================================
# Versión: 0.1
# eaSway - Módulo de Post-instalación y Permisos
# Finalidad: Configurar el sistema de forma dinámica y genérica.
# =================================================================

#colores
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

#output al usuario
echo -e "${YELLOW}>> Iniciando ajustes finales de sistema...${NC}"

# 1. Configuración de Grupos (Dinámica)
# Obtenemos el usuario actual de forma genérica
TARGET_USER="${USER:-$(whoami)}"

echo -e "   - Configurando acceso a hardware para el usuario: '${TARGET_USER}'..."

if id "$TARGET_USER" &>/dev/null; then
    # Evaluación directa para cumplir con ShellCheck
    if sudo usermod -aG video,input "$TARGET_USER"; then
        echo -e "${GREEN}   [OK] Usuario '${TARGET_USER}' añadido a grupos video e input.${NC}"
    else
        echo -e "${RED}   [ERROR] Falló usermod para '${TARGET_USER}'.${NC}"
    fi
else
    echo -e "${RED}   [!] No se pudo determinar el usuario actual. Saltando configuración.${NC}"
fi

# 2. Permisos para el control de brillo (herramienta 'light')
if command -v light > /dev/null; then
    echo -e "   - Ajustando permisos para control de brillo..."
    sudo chmod +s "$(command -v light)"
    echo -e "${GREEN}   [OK] Permisos de brillo configurados.${NC}"
else
    echo -e "${YELLOW}   [!] 'light' no instalado. Saltando ajuste de brillo.${NC}"
fi

# 3. Activación de Servicios Esenciales (Guard para systemd)
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

echo -e "${GREEN}>> Ajustes de sistema completados con éxito.${NC}"

read -n 1 -s -r -p "Presiona cualquier tecla para continuar..."
echo
exit 0