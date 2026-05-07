#!/bin/bash

# =================================================================
# eaSway - Orquestador de Instalación
# Basado en la estructura de archivos: raíz/scripts/
# Desarrollado por: dozelix
# =================================================================

# 1. Configuración de Rutas
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_ROOT=$(cd "$BASE_DIR/../.." && pwd)
SCRIPTS_DIR="$REPO_ROOT/scripts"

# Colores para la interfaz Post-Punk
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Iniciando eaSway - Entorno Post-Punk para Debian${NC}"

# 2. Función de ejecución modular (Refactorizada para SC2181)
run_step() {
    local script_file="$1"
    local description="$2"
    local full_path="$SCRIPTS_DIR/$script_file"

    echo -e "\n[i] Pasos de: $description..."

    if [ -f "$full_path" ]; then
        # Corregido: Evaluamos el éxito del script directamente en el if
        # Esto elimina la necesidad de $? y evita el error de la línea 37
        if bash "$full_path"; then
            echo -e "${GREEN}✔ $description finalizado.${NC}"
        else
            echo -e "${RED}✘ Error durante $description.${NC}"
        fi
    else
        echo -e "${RED}[!] ERROR: No se encontró $script_file en $SCRIPTS_DIR${NC}"
        echo "Asegúrate de que el archivo existe en la carpeta 'scripts' de la raíz."
    fi
}

# 3. Ejecución de la secuencia
run_step "check_hardware.sh" "Detección de Hardware"
run_step "install_packages.sh" "Instalación de Binarios"
run_step "setup_config.sh" "Despliegue de Dotfiles"
run_step "post_install.sh" "Ajustes Finales de Sistema"

echo -e "\n${GREEN}Proceso de orquestación terminado.${NC}"