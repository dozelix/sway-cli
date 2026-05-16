#!/bin/bash
set -euo pipefail
# =================================================================
# Versión: 0.0.4
# eaSway - Módulo de Instalación con Control de Errores
# Finalidad: Garantizar que el entorno base esté presente.
# Fix v0.0.4:
# issue: #22
#   - BUG#2: Eliminado echo de $ARCH que se imprimía vacío
#   - BUG#4: apt autoremove movido dentro del guard de apt
# =================================================================

#def colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# =================================================================
# 1. VALIDACIÓN DE VARIABLES CRÍTICAS
# =================================================================
if [ -z "$DEVICE_TYPE" ]; then
    echo -e "${YELLOW}[!] DEVICE_TYPE no definido. Usando 'desktop' por defecto.${NC}"
    export DEVICE_TYPE="desktop"
fi

if [ -z "$GPU_VENDOR" ]; then
    echo -e "${YELLOW}[!] GPU_VENDOR no definido. Usando 'Desconocido' por defecto.${NC}"
    export GPU_VENDOR="Desconocido"
fi

if [ -z "$IN_VM" ]; then
    export IN_VM=false
fi

echo -e "${BLUE}   - Dispositivo: $DEVICE_TYPE${NC}"
echo -e "${BLUE}   - GPU: $GPU_VENDOR${NC}"
echo -e "${BLUE}   - En VM: $IN_VM${NC}\n"

# =================================================================
# 2. DEFINICIÓN DE PAQUETES POR PRIORIDAD
# =================================================================

# Identificar el sistema
OS_ID="$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')"
OS_VER="$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')"

# Definir paquetes base
WAYLAND_CORE=("wayland-protocols" "libwayland-egl1" "mesa-utils" "xwayland")

get_extra_deps() {
    case "$1-$2" in
        "debian-12" | "ubuntu-22.04")
            printf "%s\n" "libegl1-mesa" "libgl1-mesa-dri"
            ;;
        "debian-13" | "ubuntu-24.04" | "ubuntu-26.04")
            printf "%s\n" "libegl1" "libgl1-mesa-dri"
            ;;
        *)
            printf "%s\n" "libegl1" "libgl1-mesa-dri"
            ;;
    esac
}

# Usar mapfile para llenar el array correctamente
mapfile -t EXTRA_DEPS_ARRAY < <(get_extra_deps "$OS_ID" "$OS_VER")
WAYLAND_CORE+=("${EXTRA_DEPS_ARRAY[@]}")
echo "[i] Instalando para $OS_ID ($OS_VER)"
echo "[i] Paquetes a instalar: ${WAYLAND_CORE[*]}"

# def compCritic easway
CRITICAL_PKGS=(
    "sway"
    "waybar"
    "wofi"
    "mako-notifier"
    "seatd"
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
    "foot"
)

if [ "$DEVICE_TYPE" = "laptop" ]; then
    UTILITY_PKGS+=("tlp" "brightnessctl" "libinput-tools")
fi

# =================================================================
# 3. PAQUETES CONDICIONALES POR GPU
# =================================================================

add_gpu_packages() {
    local vendor="$1"
    case "$vendor" in
        "Intel")
            UTILITY_PKGS+=("intel-media-va-driver")
            echo -e "${BLUE}   [i] GPU Intel: agregando intel-media-va-driver.${NC}"
            ;;
        "AMD")
            UTILITY_PKGS+=("mesa-va-drivers")
            echo -e "${BLUE}   [i] GPU AMD: agregando mesa-va-drivers.${NC}"
            ;;
        "NVIDIA")
            echo -e "${YELLOW}   [!] GPU NVIDIA: drivers propietarios requieren instalación manual.${NC}"
            ;;
        *)
            echo -e "${YELLOW}   [?] GPU desconocida. Saltando paquetes específicos de GPU.${NC}"
            ;;
    esac
}

if [ -n "$GPU_VENDOR" ]; then
    add_gpu_packages "$GPU_VENDOR"
else
    echo -e "${YELLOW}   [!] GPU_VENDOR no definido. Ejecuta check_hardware.sh primero.${NC}"
fi

# =================================================================
# 4. ACTUALIZACIÓN DE REPOSITORIOS
# =================================================================
echo -e "${YELLOW}>> Verificando estado de repositorios...${NC}"

if ! command -v apt &>/dev/null; then
    echo -e "${YELLOW}   [!] 'apt' no disponible. Saltando instalación de paquetes.${NC}"
    echo -e "${YELLOW}   [!] Esto es normal en entornos de testing/Docker con APT simulado.${NC}"
else
    if [ ! -f /var/lib/apt/periodic/update-success-stamp ]; then
        last_update=0
    else
        last_update=$(stat -c %Y /var/lib/apt/periodic/update-success-stamp 2>/dev/null) || last_update=0
    fi

    now=$(date +%s) || now=0

    if [ $((now - last_update)) -gt 86400 ]; then
        echo -e "   [i] Repositorios con más de 24h. Actualizando..."
        if ! DEBIAN_FRONTEND=noninteractive sudo apt update; then
            echo -e "${RED}   [ERROR] Falló apt update. Verifica tu conexión.${NC}"
            exit 1
        fi
    else
        echo -e "${GREEN}   [OK] Repositorios actualizados recientemente.${NC}"
    fi

    # =================================================================
    # 5. INSTALACIÓN DE COMPONENTES CORE (ORDENADA)
    # =================================================================
    echo -e "${YELLOW}>> Instalando protocolos y drivers de Wayland...${NC}"
    if DEBIAN_FRONTEND=noninteractive sudo apt install -yq "${WAYLAND_CORE[@]}"; then
        echo -e "${GREEN}   [OK] Librerías base instaladas.${NC}"
    else
        echo -e "${RED}   [ERROR] Fallo crítico en librerías Wayland. Abortando.${NC}"
        exit 1
    fi

    echo -e "${YELLOW}>> Instalando componentes críticos de Sway...${NC}"
    if DEBIAN_FRONTEND=noninteractive sudo apt install -yq "${CRITICAL_PKGS[@]}"; then
        echo -e "${GREEN}   [OK] Sway y componentes core instalados.${NC}"
    else
        echo -e "${RED}   [ERROR] Fallo crítico al instalar Sway. Abortando.${NC}"
        exit 1
    fi

    # =================================================================
    # 6. INSTALACIÓN DE UTILIDADES
    # =================================================================
    echo -e "${YELLOW}>> Instalando utilidades y extras...${NC}"
    if DEBIAN_FRONTEND=noninteractive sudo apt install -yq "${UTILITY_PKGS[@]}"; then
        echo -e "${GREEN}   [OK] Utilidades instaladas correctamente.${NC}"
    else
        echo -e "${YELLOW}   [!] Algunos paquetes opcionales fallaron. Revisa los logs.${NC}"
    fi

    # =================================================================
    # 7. LIMPIEZA FINAL
    # BUG#4 FIX: apt autoremove movido dentro del bloque "command -v apt"
    # =================================================================
    echo -e "${YELLOW}>> Limpiando caché de apt...${NC}"
    DEBIAN_FRONTEND=noninteractive sudo apt autoremove -yq && DEBIAN_FRONTEND=noninteractive sudo apt autoclean
fi

# =================================================================
# 8. CONFIGURACIÓN DE USUARIO Y GRUPOS
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
# 9. PERMISOS PARA CONTROL DE BRILLO
# =================================================================
if [ "$IN_VM" = false ] && command -v light > /dev/null; then
    echo -e "   [i] Configurando SUID para 'light'..."
    if sudo chmod +s "$(command -v light)" 2>/dev/null; then
        echo -e "${GREEN}   [OK] Permisos de brillo configurados.${NC}"
    else
        echo -e "${YELLOW}   [!] No se pudo configurar SUID para 'light' (esperado en algunos entornos).${NC}"
    fi
elif [ "$IN_VM" = true ]; then
    echo -e "${YELLOW}   [i] Virtualización detectada. Saltando SUID para 'light'.${NC}"
fi

# =================================================================
# 10. ACTIVACIÓN DE SERVICIOS
# =================================================================
echo -e "${YELLOW}>> Verificando gestor de servicios...${NC}"

if pidof systemd > /dev/null 2>&1 || [ -d /run/systemd/system ]; then
    echo -e "   [i] systemd detectado. Activando NetworkManager..."
    if sudo systemctl enable --now NetworkManager 2>/dev/null; then
        echo -e "${GREEN}   [OK] NetworkManager activado.${NC}"
    else
        echo -e "${YELLOW}   [!] No se pudo activar NetworkManager (esperado en algunas VMs).${NC}"
    fi
else
    echo -e "${YELLOW}   [!] systemd NO disponible. Saltando activación de servicios.${NC}"
fi

echo -e "${GREEN}>> Instalación de paquetes completada.${NC}"