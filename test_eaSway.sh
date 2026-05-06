#!/bin/bash

# =================================================================
# eaSway - Automatización de Pruebas en Contenedor (Versión Pro)
# Finalidad: Limpiar, construir y lanzar el entorno de testeo.
# =================================================================

IMAGE_NAME="easway-test"
CONTAINER_NAME="easway-container"

echo ">> Limpiando entornos previos..."
docker rm -f $CONTAINER_NAME 2>/dev/null

echo ">> Construyendo imagen de prueba..."
# Usamos -f para especificar tu archivo Dockerfile.test
docker build -t $IMAGE_NAME -f Dockerfile.test .

echo ">> Preparando entorno y lanzando contenedor..."
echo "-----------------------------------------------------------"
echo "Nota: Se ha configurado XDG_RUNTIME_DIR para permitir"
echo "la ejecución de Sway y herramientas de Wayland."
echo "-----------------------------------------------------------"

# Ejecución con correcciones para el entorno de usuario y Wayland
docker run -it \
    --privileged \
    --name $CONTAINER_NAME \
    -v "$(pwd):/home/tester/eaSway" \
    -e XDG_RUNTIME_DIR=/tmp/runtime-tester \
    -u root \
    $IMAGE_NAME /bin/bash -c "
        # Crear directorio de runtime para el usuario tester
        mkdir -p /tmp/runtime-tester
        chown tester:tester /tmp/runtime-tester
        chmod 700 /tmp/runtime-tester
        # Entrar como tester en la carpeta del proyecto
        su - tester -c 'cd ~/eaSway && /bin/bash'
    "