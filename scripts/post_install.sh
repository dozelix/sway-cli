#!/bin/bash

# =================================================================
# eaSway - Módulo de Post-instalación y Permisos
# Finalidad: Configurar el sistema para que "simplemente funcione".
# =================================================================

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo -e "${YELLOW}>> Iniciando ajustes finales de sistema...${NC}"

# 1. Configuración de Grupos (Vital para laptops y periféricos)
# Explicación: Añadimos al usuario actual ($USER) a grupos críticos.
echo -e "   - Configurando acceso a hardware (video e input)..."
sudo usermod -aG video $USER
sudo usermod -aG input $USER

# 2. Permisos para el control de brillo (herramienta 'light')
# Explicación: 'light' necesita permisos especiales en /sys/class/backlight
if command -v light > /dev/null; then
    echo -e "   - Ajustando permisos para control de brillo..."
    sudo chmod +s $(which light)
fi

# 3. Activación de Servicios Esenciales
# Explicación: Habilitamos NetworkManager para que el internet funcione tras reiniciar.
echo -e "   - Activando servicios de red..."
sudo systemctl enable --now NetworkManager

echo -e "${GREEN}>> Ajustes de sistema completados con éxito.${NC}"