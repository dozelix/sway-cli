#!/bin/bash
# =================================================================
# eaSway - Automatización de Pruebas en Contenedor
# Finalidad: Limpiar, construir y lanzar el entorno de testeo.
#  version anterior  0.1 
# Cambios v0.0.2:
# ninguno
# Cambios v0.0.3:
#   - Integración de construcción y ejecución en un solo script.
#   - Validación de construcción con manejo de errores (SC2181).
#   - Salida estructurada para facilitar la depuración.
# Fixes ShellCheck:
#   - SC2181: Uso de manejo de errores directo en lugar de if.
# =================================================================

IMAGE_NAME="easway-test"
CONTAINER_NAME="easway-container"
HOST_USER=$(whoami)
RUNTIME_DIR="/tmp/runtime-$HOST_USER"

echo ">> Limpiando entornos previos..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null

echo ">> Construyendo imagen de prueba para usuario: $HOST_USER..."

# PASO CLAVE: Construcción y validación en un solo bloque (SC2181 corregido)
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

# Ejecución final ajustada al hardware Intel
docker run -it \
    --privileged \
    --name "$CONTAINER_NAME" \
    --device /dev/dri:/dev/dri \
    -e XDG_RUNTIME_DIR="$RUNTIME_DIR" \
    -v "$(pwd):/home/$HOST_USER/eaSway" \
    "$IMAGE_NAME" /bin/bash