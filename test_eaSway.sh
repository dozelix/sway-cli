#!/bin/bash

# =================================================================
#version 0.1
# eaSway - Automatización de Pruebas en Contenedor
# Finalidad: Limpiar, construir y lanzar el entorno de testeo.
# =================================================================

IMAGE_NAME="easway-test"
CONTAINER_NAME="easway-container"
# Usuario dinámico para que coincida con el host
HOST_USER="${USER:-$(whoami)}"
RUNTIME_DIR="/tmp/runtime-$HOST_USER"

echo ">> Limpiando entornos previos..."
docker rm -f "$CONTAINER_NAME" 2>/dev/null

echo ">> Construyendo imagen de prueba..."
if [ -f "Dockerfile.test" ]; then
    docker build -t "$IMAGE_NAME" -f Dockerfile.test .
else
    echo "ERROR: Dockerfile.test no encontrado en el directorio actual."
    exit 1
fi

echo ">> Preparando entorno y lanzando contenedor..."
echo "-----------------------------------------------------------"
echo " Usuario:          $HOST_USER (con sudo NOPASSWD)"
echo " XDG_RUNTIME_DIR:  $RUNTIME_DIR"
echo " Mapeo de código:  $(pwd) -> /home/$HOST_USER/eaSway"
echo "-----------------------------------------------------------"

docker run -it \
    --privileged \
    --name "$CONTAINER_NAME" \
    -v "$(pwd):/home/$HOST_USER/eaSway" \
    -e XDG_RUNTIME_DIR="$RUNTIME_DIR" \
    -u root \
    "$IMAGE_NAME" /bin/bash -c "
        # 1. Crear directorio de runtime para el usuario con permisos correctos
        mkdir -p $RUNTIME_DIR
        chown $HOST_USER:$HOST_USER $RUNTIME_DIR
        chmod 700 $RUNTIME_DIR
        echo '[OK] XDG_RUNTIME_DIR configurado en $RUNTIME_DIR'

        # 2. Iniciar sesión como el usuario y entrar al proyecto
        su - $HOST_USER -c 'export XDG_RUNTIME_DIR=$RUNTIME_DIR && cd ~/eaSway && /bin/bash'
    "