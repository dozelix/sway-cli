#!/bin/bash
# =================================================================
# eaSway - Automatización de Pruebas en Contenedor
# Finalidad: Limpiar, construir y lanzar el entorno de testeo.
# Cambios v0.0.3:
#   - Fix SC2155: Declaración y asignación separadas.
#   - Validación de construcción con manejo de errores (SC2181).
# =================================================================

IMAGE_NAME="easway-test"
CONTAINER_NAME="easway-container"
HOST_USER=$(whoami)
export HOST_USER

RUNTIME_DIR="/tmp/runtime-$HOST_USER"
export RUNTIME_DIR

echo ">> Limpiando entornos previos..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null

# =================================================================
# FASE 0: VALIDACIÓN ESTÁTICA (host — antes de construir)
# =================================================================
echo ">> [QA] Verificando dependencias de validación..."

if ! command -v shellcheck &>/dev/null; then
    echo "-----------------------------------------------------------"
    echo " [!] shellcheck no encontrado en el host."
    echo " Instala con: sudo apt install shellcheck"
    echo "-----------------------------------------------------------"
    exit 1
fi

echo ">> [QA] Ejecutando bash -n (validación de sintaxis)..."
SYNTAX_ERRORS=0
while IFS= read -r -d '' script; do
    if ! bash -n "$script" 2>/dev/null; then
        echo "   [ERROR] Sintaxis inválida: $script"
        SYNTAX_ERRORS=$((SYNTAX_ERRORS + 1))
    fi
done < <(find . -name "*.sh" -not -path "./.git/*" -print0)

if [ "$SYNTAX_ERRORS" -gt 0 ]; then
    echo "-----------------------------------------------------------"
    echo " FALLO: $SYNTAX_ERRORS script(s) con errores de sintaxis."
    echo "-----------------------------------------------------------"
    exit 1
fi
echo "   [OK] Sintaxis bash válida."

echo ">> [QA] Ejecutando ShellCheck..."
SHELLCHECK_ERRORS=0
while IFS= read -r -d '' script; do
    if ! shellcheck "$script"; then
        SHELLCHECK_ERRORS=$((SHELLCHECK_ERRORS + 1))
    fi
done < <(find . -name "*.sh" -not -path "./.git/*" -print0)

if [ "$SHELLCHECK_ERRORS" -gt 0 ]; then
    echo "-----------------------------------------------------------"
    echo " FALLO: ShellCheck encontró errores en $SHELLCHECK_ERRORS archivo(s)."
    echo "-----------------------------------------------------------"
    exit 1
fi
echo "   [OK] ShellCheck pasó sin errores."

echo ">> [QA] Validando JSON de Waybar..."
WAYBAR_JSON="./dotfiles/waybar/config"
if [ -f "$WAYBAR_JSON" ]; then
    if python3 -m json.tool "$WAYBAR_JSON" > /dev/null 2>&1; then
        echo "   [OK] dotfiles/waybar/config es JSON válido."
    else
        echo "   [ERROR] dotfiles/waybar/config tiene JSON inválido."
        exit 1
    fi
fi
echo "-----------------------------------------------------------"

echo ">> Construyendo imagen de prueba para usuario: $HOST_USER..."

# PASO CLAVE: Manejo de errores directo (SC2181 corregido)
if ! docker build --build-arg USER="$HOST_USER" -t "$IMAGE_NAME" -f Dockerfile .; then
    echo "-----------------------------------------------------------"
    echo " FALLO CRÍTICO: No se pudo construir la imagen de Docker.  "
    echo " Revisa el Dockerfile.test y los logs de arriba.           "
    echo "-----------------------------------------------------------"
    exit 1
fi

echo ">> Imagen construida con éxito. Lanzando contenedor..."
echo "-----------------------------------------------------------"
echo " Usuario:          $HOST_USER"
echo " XDG_RUNTIME_DIR:  $RUNTIME_DIR"
echo "-----------------------------------------------------------"

# Ejecución ajustada al hardware Intel y sincronización de volumen (Tarea #01)

docker run -it --privileged \
    --name "$CONTAINER_NAME" \
    --user 1000:1000 \
    --env="WAYLAND_DISPLAY=$WAYLAND_DISPLAY" \
    --env="XDG_RUNTIME_DIR=/run/user/1000" \
    --volume="/run/user/1000:/run/user/1000" \
    --device /dev/dri:/dev/dri \
    --device /dev/input:/dev/input \
    -v "$(pwd):/home/dozelix/eaSway" \
    "$IMAGE_NAME" /bin/bash