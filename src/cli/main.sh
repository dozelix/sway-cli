#!/bin/bash

# =================================================================
# eaSway - Instalador Modular para SwayOS (Debian/LMDE)
# Finalidad: Orquestador principal del proceso de instalación.
# =================================================================

# 1. Definición de Rutas Críticas
# Obtenemos la ruta absoluta de este script
SCRIPT_PATH=$(readlink -f "$0")
# Subimos 2 niveles para llegar a la raíz del proyecto (desde src/cli/)
REPO_ROOT=$(dirname $(dirname "$SCRIPT_PATH"))

# Importar variables de color y estilo (opcional, para el diseño post-punk)
GREEN='\033[0;32m'
RED='\033[0;31m'
NC='\033[0m' # No Color

echo -e "${GREEN}Iniciando eaSway - Entorno Post-Punk para Debian${NC}"

# 2. Verificación de Seguridad
if [ "$EUID" -eq 0 ]; then 
    echo -e "${RED}Error: Por favor, no ejecutes este script como root (sudo).${NC}"
    echo "El script te pedirá contraseña cuando sea necesario."
    exit 1
fi

# 3. Función para ejecutar módulos de forma segura
run_module() {
    local module_path="$1"
    local module_name="$2"
    
    echo -e "\n[i] Ejecutando: $module_name..."
    if [ -f "$module_path" ]; then
        bash "$module_path"
        if [ $? -eq 0 ]; then
            echo -e "${GREEN}✔ $module_name completado con éxito.${NC}"
        else
            echo -e "${RED}✘ Error en $module_name. Revisa los logs.${NC}"
            # Aquí podríamos decidir si salir o continuar
        fi
    else
        echo -e "${RED}Error: No se encontró el módulo en $module_path${NC}"
    fi
}

# 4. Secuencia de Instalación Fragmentada
# Cada paso es un archivo independiente en la carpeta scripts/
run_module "$REPO_ROOT/scripts/check_hardware.sh" "Detección de Hardware"
run_module "$REPO_ROOT/scripts/install_packages.sh" "Instalación de Binarios"
run_module "$REPO_ROOT/scripts/setup_configs.sh" "Despliegue de Dotfiles"
run_module "$REPO_ROOT/scripts/post_install.sh" "Ajustes Finales de Sistema"

echo -e "\n${GREEN}Proceso finalizado. Reinicia para entrar en eaSway.${NC}"