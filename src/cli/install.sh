#!/bin/bash

# =================================================================
# version: 0.0.4
# eaSway - Orquestador de Instalación
# Finalidad: Punto de entrada genérico para el despliegue del entorno.
# Fix v0.0.4:
#   - REPO_ROOT corregido: install.sh vive en la raíz del repo,
#     no en src/cli/, por lo que ya no hay que subir dos niveles.
# =================================================================

BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT="$BASE_DIR"
SCRIPTS_DIR="$REPO_ROOT/scripts"

GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Iniciando eaSway para Debian${NC}"
echo -e "Usuario detectado: ${USER:-$(whoami)}\n"

# =================================================================
# Ejecución de pasos que no exportan variables al orquestador
# =================================================================
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

# =================================================================
# Ejecución de pasos que exportan variables al orquestador
# (source para que GPU_VENDOR y DEVICE_TYPE sean visibles aquí)
# =================================================================
run_step_source() {
    local script_file="$1"
    local description="$2"
    local full_path="$SCRIPTS_DIR/$script_file"

    echo -e "[i] Ejecutando: $description..."

    if [ -f "$full_path" ]; then
        # shellcheck source=/dev/null
        if source "$full_path"; then
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

# =================================================================
# Secuencia de instalación
# =================================================================

# Paso 1: source — necesita exportar GPU_VENDOR y DEVICE_TYPE
run_step_source "check_hardware.sh" "Detección de Hardware"

# Pasos 2-4: bash normal
run_step "install_packages.sh"  "Instalación de Paquetes"
run_step "setup_config.sh"      "Despliegue de Configuraciones"
run_step "post_install.sh"      "Ajustes de Sistema y Permisos"

# Paso 5: bash normal — GPU_VENDOR ya está en el entorno via export
run_step "gpu_environment.sh"   "Configuración de Entorno Gráfico"

echo -e "${GREEN}Proceso de orquestación finalizado correctamente.${NC}"