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

echo ">> Construyendo imagen de prueba para usuario: $HOST_USER..."

# PASO CLAVE: Manejo de errores directo (SC2181 corregido)
if ! docker build --build-arg USER="$HOST_USER" -t "$IMAGE_NAME" -f Dockerfile.test .; then
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
docker run -it \
    --privileged \
    --name "$CONTAINER_NAME" \
    --device /dev/dri:/dev/dri \
    -e XDG_RUNTIME_DIR="$RUNTIME_DIR" \
    -v "$(pwd):/home/$HOST_USER/eaSway" \
    "$IMAGE_NAME" /bin/bash