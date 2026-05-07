#!/bin/bash

# =================================================================
# eaSway - Módulo de Instalación con Control de Errores
# Finalidad: Garantizar que el entorno base esté presente.
# Versión: 1.0 - Limpio de errores ShellCheck
# =================================================================

# Colores para la salida en terminal
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Definición de paquetes por prioridad usando arreglos (Arrays)
# El uso de arreglos es la mejor práctica para evitar el error SC2086
CRITICAL_PKGS=(
    "sway"
    "waybar"
    "wofi"
    "mako-notifier"
    "xwayland"
)

UTILITY_PKGS=(
    "swaybg"
    "swayidle"
    "swaylock"
    "grim"
    "slurp"
    "light"
    "pavucontrol"
    "network-manager-gnome"
    "thunar"
)

echo -e "${YELLOW}>> Iniciando instalación de paquetes críticos...${NC}"

# 2. Actualización inteligente de repositorios
last_update=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp 2>/dev/null || echo 0)
now=$(date +%s)

if [ $((now - last_update)) -gt 86400 ]; then
    echo -e "[i] Repositorios antiguos. Actualizando..."
    sudo apt update
else
    echo -e "[OK] Repositorios actualizados recientemente. Saltando update."
fi

# 3. Instalación de Críticos (Evaluación directa para cumplir SC2181)
# El uso de "${ARRAY[@]}" expande cada elemento como un argumento individual protegido
if sudo apt install -y "${CRITICAL_PKGS[@]}"; then
    echo -e "${GREEN} [OK] Componentes Core de Sway instalados correctamente.${NC}"
else
    echo -e "${RED} [ERROR] Fallo crítico al instalar Componentes Core. El script se detendrá.${NC}"
    exit 1
fi

# 4. Instalación de Utilidades (Evaluación directa sin detención fatal)
echo -e "${YELLOW}>> Instalando utilidades y extras...${NC}"

if sudo apt install -y "${UTILITY_PKGS[@]}"; then
    echo -e "${GREEN} [OK] Utilidades instaladas.${NC}"
else
    echo -e "${YELLOW} [!] Algunos paquetes menores no se instalaron, revisa los logs más tarde.${NC}"
fi

# 5. Limpieza final
echo -e "${YELLOW}>> Finalizando limpieza de caché...${NC}"
sudo apt autoremove -y && sudo apt autoclean