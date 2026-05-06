#!/bin/bash

# =================================================================
# eaSway - Orquestador de Instalación
# Basado en la estructura de archivos: raíz/scripts/
# =================================================================

# 1. Configuración de Rutas (Navegación por el árbol de directorios)
# Obtenemos la ruta absoluta de la carpeta donde está este script (eaSway/src/cli)
BASE_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

# Subimos dos niveles para llegar a la raíz que vemos en tu imagen
# Nivel 1: eaSway/src/ | Nivel 2: eaSway/ (RAÍZ)
REPO_ROOT=$(cd "$BASE_DIR/../.." && pwd)

# Definimos la ruta a la carpeta de scripts que está en la raíz
SCRIPTS_DIR="$REPO_ROOT/scripts"

# Colores para la interfaz Post-Punk
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m'

echo -e "${GREEN}Iniciando eaSway - Entorno Post-Punk para Debian${NC}"

# 2. Función de ejecución modular
run_step() {
    local script_file="$1"
    local description="$2"
    local full_path="$SCRIPTS_DIR/$script_file"

    echo -e "\n[i] Pasos de: $description..."

    if [ -f "$full_path" ]; then
        # Ejecutamos el script usando 'bash' para asegurar compatibilidad
        bash "$full_path"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✔ $description finalizado.${NC}"
        else
            echo -e "${RED}✘ Error durante $description.${NC}"
        fi
    else
        echo -e "${RED}[!] ERROR: No se encontró $script_file en $SCRIPTS_DIR${NC}"
        echo "Asegúrate de que el archivo existe en la carpeta 'scripts' de la raíz."
    fi
}

# 3. Ejecución de la secuencia según la arquitectura del proyecto
run_step "check_hardware.sh" "Detección de Hardware"
run_step "install_packages.sh" "Instalación de Binarios"
run_step "setup_config.sh" "Despliegue de Dotfiles"
run_step "post_install.sh" "Ajustes Finales de Sistema"

echo -e "\n${GREEN}Proceso de orquestación terminado.${NC}"