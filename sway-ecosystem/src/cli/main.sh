#!/bin/bash

# Colores para la interfaz inicial
BLUE='\033[0;34m'
NC='\033[0m'

clear
echo -e "${BLUE} Welcome to SwayCLI / Bienvenido a SwayCLI${NC}"
echo "------------------------------------------"
echo "Select your language / Selecciona tu idioma:"
echo "1) English"
echo "2) Español"
read -p "Option/Opción [1-2]: " LANG_OPT

# Definir la ruta de los scripts de idioma
# Obtiene la ruta real de donde está guardado este script
SCRIPT_DIR=$(dirname "$(readlink -f "$0")")

# Define la ruta de idiomas basada en la ubicación del script
LANG_DIR="$SCRIPT_DIR/lang"

case $LANG_OPT in
    1)
        bash "$LANG_DIR/en_install.sh"
        ;;
    2)
        bash "$LANG_DIR/es_install.sh"
        ;;
    *) # Cualquier otra opción que no sea 1 o 2
            echo -e "\n\033[0;31mError: Opción inválida '$LANG_OPT'.\033[0m"
            echo "Cerrando el instalador... / Closing installer..."
            sleep 2 # Pausa de 2 segundos para que el usuario pueda leer el mensaje
            exit 1[cite: 2]
            ;;
esac
