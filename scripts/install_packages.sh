#!/bin/bash

# =================================================================
# Versión: 0.0.1-alpha
# eaSway - Módulo de Instalación con Control de Errores
# Finalidad: Garantizar que el entorno base esté presente.
# Cambios v0.0.2-alpha:
#   - SW-03: Condicional systemd antes de activar NetworkManager
#   - SW-05: usermod corregido con variable TARGET_USER dinámica
#   - Mejora: Validación de arquitectura (x86_64) al inicio
#   - Mejora: Guard para entorno Docker (salta pasos incompatibles)
# =================================================================

# --- Colores para la salida en terminal ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =================================================================
# 0. DETECCIÓN DE ENTORNO
# Determina si estamos en Docker para omitir pasos incompatibles.
# =================================================================
IN_DOCKER=false
if [ -f /.dockerenv ]; then
    IN_DOCKER=true
    echo -e "${YELLOW}[!] Entorno Docker detectado. Algunos pasos serán omitidos.${NC}"
fi

# Validación de arquitectura
ARCH=$(uname -m)
if [ "$ARCH" != "x86_64" ]; then
    echo -e "${YELLOW}[!] Arquitectura detectada: $ARCH. eaSway está optimizado para x86_64.${NC}"
fi
echo -e "${BLUE}   - Arquitectura: $ARCH${NC}"

# =================================================================
# 1. DEFINICIÓN DE PAQUETES POR PRIORIDAD
# Uso de arrays (best practice SC2086): cada elemento se expande
# como argumento individual protegido con "${ARRAY[@]}"
# =================================================================
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
    "kitty"
)

# =================================================================
# 2. ACTUALIZACIÓN INTELIGENTE DE REPOSITORIOS
# Solo actualiza si los repos tienen más de 24 horas de antigüedad.
# =================================================================
echo -e "${YELLOW}>> Verificando estado de repositorios...${NC}"

last_update=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp 2>/dev/null || echo 0)
now=$(date +%s)

if [ $((now - last_update)) -gt 86400 ]; then
    echo -e "   [i] Repositorios con más de 24h. Actualizando..."
    if ! sudo apt update; then
        echo -e "${RED}   [ERROR] Falló apt update. Verifica tu conexión a internet.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}   [OK] Repositorios actualizados recientemente. Saltando update.${NC}"
fi

# =================================================================
# 3. INSTALACIÓN DE PAQUETES CRÍTICOS
# Evaluación directa del comando (cumple SC2181).
# Si falla algún paquete crítico, el script se detiene.
# =================================================================
echo -e "${YELLOW}>> Instalando componentes core de Sway...${NC}"

if sudo apt install -y "${CRITICAL_PKGS[@]}"; then
    echo -e "${GREEN}   [OK] Componentes Core instalados correctamente.${NC}"
else
    echo -e "${RED}   [ERROR] Fallo crítico al instalar componentes Core. Abortando.${NC}"
    exit 1
fi

# =================================================================
# 4. INSTALACIÓN DE UTILIDADES
# Un fallo aquí no es fatal: se avisa pero el script continúa.
# =================================================================
echo -e "${YELLOW}>> Instalando utilidades y extras...${NC}"

if sudo apt install -y "${UTILITY_PKGS[@]}"; then
    echo -e "${GREEN}   [OK] Utilidades instaladas correctamente.${NC}"
else
    echo -e "${YELLOW}   [!] Algunos paquetes opcionales no se instalaron. Revisa los logs.${NC}"
fi

# =================================================================
# 5. CONFIGURACIÓN DE USUARIO Y GRUPOS (SW-05)
# Corrección: TARGET_USER se obtiene dinámicamente.
# ${SUDO_USER} = usuario real cuando se usa 'sudo'
# ${USER}      = usuario actual en sesión normal
# 'dozelix'    = fallback para el contenedor Docker
# =================================================================
echo -e "${YELLOW}>> Configurando permisos de usuario...${NC}"

TARGET_USER="${SUDO_USER:-${USER:-dozelix}}"
echo -e "   [i] Usuario objetivo: '${TARGET_USER}'"

if id "$TARGET_USER" &>/dev/null; then
    # SC2181: Evaluación directa del comando (no se usa $?)
    if sudo usermod -aG video,input "$TARGET_USER"; then
        echo -e "${GREEN}   [OK] '${TARGET_USER}' añadido a grupos video e input.${NC}"
    else
        echo -e "${RED}   [ERROR] Falló usermod para '${TARGET_USER}'. Continúa manualmente.${NC}"
    fi
else
    echo -e "${YELLOW}   [!] Usuario '${TARGET_USER}' no encontrado. Saltando configuración de grupos.${NC}"
fi

# =================================================================
# 6. PERMISOS PARA CONTROL DE BRILLO ('light')
# Solo aplica en hardware real; se omite en Docker.
# =================================================================
if [ "$IN_DOCKER" = false ] && command -v light > /dev/null; then
    echo -e "   [i] Configurando permisos para control de brillo..."
    sudo chmod +s "$(command -v light)"
    echo -e "${GREEN}   [OK] Permisos de brillo configurados.${NC}"
elif [ "$IN_DOCKER" = true ]; then
    echo -e "${YELLOW}   [!] Entorno Docker: saltando configuración de brillo.${NC}"
else
    echo -e "${YELLOW}   [!] 'light' no instalado. Saltando ajuste de brillo.${NC}"
fi

# =================================================================
# 7. ACTIVACIÓN DE SERVICIOS ESENCIALES (SW-03)
# Guard para systemd: Docker no lo tiene como PID 1, así que
# systemctl fallará. Detectamos systemd antes de llamarlo.
# =================================================================
echo -e "${YELLOW}>> Verificando gestor de servicios...${NC}"

if pidof systemd > /dev/null 2>&1 || [ -d /run/systemd/system ]; then
    echo -e "   [i] systemd detectado. Activando NetworkManager..."
    if sudo systemctl enable --now NetworkManager; then
        echo -e "${GREEN}   [OK] NetworkManager activado y habilitado.${NC}"
    else
        echo -e "${RED}   [ERROR] Falló la activación de NetworkManager.${NC}"
    fi
else
    echo -e "${YELLOW}   [!] systemd NO disponible (entorno Docker o contenedor). Saltando activación de servicios.${NC}"
fi

# =================================================================
# 8. LIMPIEZA FINAL
# =================================================================
echo -e "${YELLOW}>> Finalizando y limpiando caché de apt...${NC}"
sudo apt autoremove -y && sudo apt autoclean

echo -e "${GREEN}>> Instalación de paquetes completada.${NC}"