#!/bin/bash

# =================================================================
# version: 0.1
# eaSway - Orquestador de Instalación
# Finalidad: Punto de entrada genérico para el despliegue del entorno.
# =================================================================

# 1. Configuración de Rutas
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$BASE_DIR/../.." && pwd)
SCRIPTS_DIR="$REPO_ROOT/scripts"

# Colores para la interfaz
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Iniciando eaSway para Debian${NC}"
echo -e "Usuario detectado: ${USER:-$(whoami)}\n"

# 2. Función de ejecución modular
run_step() {
    local script_file="$1"
    local description="$2"
    local full_path="$SCRIPTS_DIR/$script_file"

    echo -e "[i] Ejecutando: $description..."

    if [ -f "$full_path" ]; then
        if bash "$full_path"; then
            echo -e "${GREEN}✔ $description completado con éxito.${NC}\n"
        else
            echo -e "${RED}✘ Error durante $description. Abortando instalación.${NC}\n"
            exit 1
        fi
    else
        echo -e "${RED}[!] ERROR: No se encontró el archivo $script_file en $SCRIPTS_DIR${NC}\n"
        exit 1
    fi

}

# 3. Ejecución de la secuencia de instalación
run_step "check_hardware.sh" "Detección de Hardware"
run_step "install_packages.sh" "Instalación de Paquetes"
run_step "setup_config.sh" "Despliegue de Configuraciones"
run_step "post_install.sh" "Ajustes de Sistema y Permisos"

echo -e "${GREEN}Proceso de orquestación finalizado correctamente.${NC}"