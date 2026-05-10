#!/bin/bash
# =================================================================
# Versión: 0.0.2-alpha
# eaSway - Módulo de Instalación con Control de Errores
# Finalidad: Garantizar que el entorno base esté presente.
# Cambios v0.0.3-alpha:
#implementacion de OS_ID y OS_VER para manejar casos específicos de paquetes
 #(ej. libegl1-mesa en Debian 12)
# =================================================================

# --- Colores para la salida en terminal ---
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =================================================================
# 0. DETECCIÓN DE ENTORNO
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
# =================================================================

# Extraer ID y VERSION_ID manualmente para evitar errores de 'source'
OS_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
OS_VER=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')

# Definir la base del array
WAYLAND_CORE=("wayland-protocols" "libwayland-egl1" "mesa-utils" "xwayland")

# Lógica condicional de inyección
if [ "$OS_ID" = "debian" ] && [ "$OS_VER" = "12" ]; then
    # Caso Debian 12 (Bookworm)
    WAYLAND_CORE+=("libegl1-mesa")
else
    # Caso Debian 13+, Ubuntu 24.04/26.04 y Docker (Trixie)
    WAYLAND_CORE+=("libegl1" "libgl1-mesa-dri")
fi

echo "[i] OS detectado: $OS_ID $OS_VER"
echo "[i] Paquetes a instalar: ${WAYLAND_CORE[*]}"

# Componentes críticos de easway (compositor, barra, launcher y notificador)
CRITICAL_PKGS=(
    "sway"
    "waybar"
    "wofi"
    "mako-notifier")
# Utilidades y aplicaciones de usuario
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
    "foot")

# =================================================================
# 2. ACTUALIZACIÓN INTELIGENTE DE REPOSITORIOS
# =================================================================
echo -e "${YELLOW}>> Verificando estado de repositorios...${NC}"

# Si no existe el archivo de stamp, forzamos actualización
if [ ! -f /var/lib/apt/periodic/update-success-stamp ]; then
    last_update=0
else
    last_update=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp 2>/dev/null || echo 0)
fi

now=$(date +%s)

if [ $((now - last_update)) -gt 86400 ]; then
    echo -e "   [i] Repositorios con más de 24h. Actualizando..."
    if ! sudo apt update; then
        echo -e "${RED}   [ERROR] Falló apt update. Verifica tu conexión.${NC}"
        exit 1
    fi
else
    echo -e "${GREEN}   [OK] Repositorios actualizados recientemente.${NC}"
fi

# =================================================================
# 3. INSTALACIÓN DE COMPONENTES CORE (ORDENADA)
# =================================================================

# Primero: Protocolos y Drivers
echo -e "${YELLOW}>> Instalando protocolos y drivers de Wayland...${NC}"
if sudo apt install -y "${WAYLAND_CORE[@]}"; then
    echo -e "${GREEN}   [OK] Librerías base instaladas.${NC}"
else
    echo -e "${RED}   [ERROR] Fallo crítico en librerías Wayland. Abortando.${NC}"
    exit 1
fi

# Segundo: Compositor y Entorno
echo -e "${YELLOW}>> Instalando componentes críticos de Sway...${NC}"
if sudo apt install -y "${CRITICAL_PKGS[@]}"; then
    echo -e "${GREEN}   [OK] Sway y componentes core instalados.${NC}"
else
    echo -e "${RED}   [ERROR] Fallo crítico al instalar Sway. Abortando.${NC}"
    exit 1
fi

# =================================================================
# 4. INSTALACIÓN DE UTILIDADES
# =================================================================
echo -e "${YELLOW}>> Instalando utilidades y extras...${NC}"
if sudo apt install -y "${UTILITY_PKGS[@]}"; then
    echo -e "${GREEN}   [OK] Utilidades instaladas correctamente.${NC}"
else
    echo -e "${YELLOW}   [!] Algunos paquetes opcionales fallaron. Revisa los logs.${NC}"
fi

# =================================================================
# 5. CONFIGURACIÓN DE USUARIO Y GRUPOS (SW-05)
# =================================================================
echo -e "${YELLOW}>> Configurando permisos de usuario...${NC}"

TARGET_USER="${SUDO_USER:-${USER:-dozelix}}"
echo -e "   [i] Usuario objetivo: '${TARGET_USER}'"

if id "$TARGET_USER" &>/dev/null; then
    if sudo usermod -aG video,input "$TARGET_USER"; then
        echo -e "${GREEN}   [OK] '${TARGET_USER}' añadido a grupos video e input.${NC}"
    else
        echo -e "${RED}   [ERROR] Falló usermod para '${TARGET_USER}'.${NC}"
    fi
else
    echo -e "${YELLOW}   [!] Usuario '${TARGET_USER}' no encontrado.${NC}"
fi

# =================================================================
# 6. PERMISOS PARA CONTROL DE BRILLO
# =================================================================
if [ "$IN_DOCKER" = false ] && command -v light > /dev/null; then
    echo -e "   [i] Configurando SUID para 'light'..."
    sudo chmod +s "$(command -v light)"
    echo -e "${GREEN}   [OK] Permisos de brillo configurados.${NC}"
fi

# =================================================================
# 7. ACTIVACIÓN DE SERVICIOS (SW-03)
# =================================================================
echo -e "${YELLOW}>> Verificando gestor de servicios...${NC}"

if pidof systemd > /dev/null 2>&1 || [ -d /run/systemd/system ]; then
    echo -e "   [i] systemd detectado. Activando NetworkManager..."
    sudo systemctl enable --now NetworkManager 2>/dev/null || echo -e "${RED}   [!] No se pudo activar NetworkManager.${NC}"
else
    echo -e "${YELLOW}   [!] systemd no disponible. Saltando servicios.${NC}"
fi

# =================================================================
# 8. LIMPIEZA FINAL
# =================================================================
echo -e "${YELLOW}>> Limpiando caché de apt...${NC}"
sudo apt autoremove -y && sudo apt autoclean

echo -e "${GREEN}>> Instalación de paquetes v0.0.2-alpha completada.${NC}"