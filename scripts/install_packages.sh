#!/bin/bash

# =================================================================
# eaSway - Módulo de Instalación con Control de Errores
# Finalidad: Garantizar que el entorno base esté presente.
# =================================================================



GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

# 1. Definición de paquetes por prioridad
CRITICAL_PKGS="sway waybar wofi mako-notifier xwayland"
UTILITY_PKGS="swaybg swayidle swaylock grim slurp light pavucontrol network-manager-gnome thunar"

echo -e "${YELLOW}>> Iniciando instalación de paquetes críticos...${NC}"

# 2. Función de verificación
check_install() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN} [OK] $1 instalado correctamente.${NC}"
    else
        echo -e "${RED} [ERROR] Fallo crítico al instalar $1.${NC}"
        exit 1
    fi
}

# 3. Instalación de Críticos (Si uno falla, el script se detiene)
# Verifica si el archivo de marca de tiempo de apt es viejo (más de 86400 segundos / 24h)
last_update=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp 2>/dev/null || echo 0)
now=$(date +%s)

if [ $((now - last_update)) -gt 86400 ]; then
    echo "[i] Repositorios antiguos. Actualizando..."
    sudo apt update
else
    echo "[OK] Repositorios actualizados recientemente. Saltando update."
fi
sudo apt install -y "$CRITICAL_PKGS"
check_install "Componentes Core de Sway"

# 4. Instalación de Utilidades (Si fallan, solo avisamos)
echo -e "${YELLOW}>> Instalando utilidades y extras...${NC}"
sudo apt install -y "$UTILITY_PKGS"

if [ $? -ne 0 ]; then
    echo -e "${YELLOW} [!] Algunos paquetes menores no se instalaron, revisa los logs más tarde.${NC}"
else
    echo -e "${GREEN} [OK] Utilidades instaladas.${NC}"
fi

# 5. Limpieza final
sudo apt autoremove -y && sudo apt autoclean