#!/bin/bash
# Módulo: Configuración de Entorno (Dotfiles)

# Hereda REPO_ROOT del script principal[cite: 1]
CONF_DIR="$HOME/.config"
APPS=("kitty" "mako" "sway" "waybar")

echo -e "\nCopiando configuraciones desde: $REPO_ROOT/dotfiles"

for APP in "${APPS[@]}"; do
    SOURCE="$REPO_ROOT/dotfiles/$APP"
    
    if [ -d "$SOURCE" ]; then
        # Solo procedemos si la carpeta no está vacía
        if [ "$(ls -A "$SOURCE" 2>/dev/null)" ]; then
            # Backup si ya existe una configuración previa
            if [ -d "$CONF_DIR/$APP" ]; then
                mv "$CONF_DIR/$APP" "$CONF_DIR/${APP}_bak_$(date +%Y%m%d_%H%M%S)"
            fi
            
            mkdir -p "$CONF_DIR/$APP"
            cp -r "$SOURCE/." "$CONF_DIR/$APP/"[cite: 3]
            echo -e "\033[0;32m✔ $APP configurado.\033[0m"
        else
            echo -e "\033[1;33m⚠ $APP saltado (carpeta vacía).\033[0m"[cite: 3]
        fi
    fi
done