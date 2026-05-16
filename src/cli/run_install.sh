#!/bin/bash
set -euo pipefail

# Wrapper para cachear credenciales sudo y ejecutar el instalador principal
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
INSTALL_SCRIPT="$BASE_DIR/install.sh"

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m'

ensure_sudo_cached() {
    if sudo -n true 2>/dev/null; then
        echo -e "${GREEN}[OK] Credenciales sudo en caché.${NC}"
        return 0
    fi

    echo -e "${YELLOW}[i] Se requiere permiso de administrador. Solicitando credenciales sudo...${NC}"
    if sudo -v; then
        echo -e "${GREEN}[OK] Credenciales sudo obtenidas.${NC}"
    else
        echo -e "${RED}[ERROR] No se pudo obtener credenciales sudo. Ejecuta el instalador con un usuario con privilegios o configura sudo.${NC}"
        exit 1
    fi
}

ensure_sudo_cached

if [ ! -f "$INSTALL_SCRIPT" ]; then
    echo -e "${RED}[ERROR] Instalador no encontrado en: $INSTALL_SCRIPT${NC}"
    exit 1
fi

exec bash "$INSTALL_SCRIPT" "$@"
