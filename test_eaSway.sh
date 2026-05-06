#!/bin/bash

# =================================================================
# eaSway - Automatización de Pruebas en Contenedor (Versión 0.2)
# Finalidad: Limpiar, construir y lanzar el entorno de testeo.
# Correcciones: usuario dozelix, XDG_RUNTIME_DIR automático
# =================================================================

IMAGE_NAME="easway-test"
CONTAINER_NAME="easway-container"

echo ">> Limpiando entornos previos..."
docker rm -f $CONTAINER_NAME 2>/dev/null

echo ">> Construyendo imagen de prueba..."
docker build -t $IMAGE_NAME -f Dockerfile.test .

echo ">> Preparando entorno y lanzando contenedor..."
echo "-----------------------------------------------------------"
echo " Usuario:         dozelix (con sudo NOPASSWD)"
echo " Modo:            --privileged (acceso a hardware simulado)"
echo " XDG_RUNTIME_DIR: /tmp/runtime-dozelix (creado automático)"
echo " Mapeo de código: $(pwd) -> /home/dozelix/eaSway"
echo "-----------------------------------------------------------"

docker run -it \
    --privileged \
    --name $CONTAINER_NAME \
    -v "$(pwd):/home/dozelix/eaSway" \
    -e XDG_RUNTIME_DIR=/tmp/runtime-dozelix \
    -u root \
    $IMAGE_NAME /bin/bash -c "
        # Crear directorio de runtime para dozelix con permisos correctos
        mkdir -p /tmp/runtime-dozelix
        chown dozelix:dozelix /tmp/runtime-dozelix
        chmod 700 /tmp/runtime-dozelix
        echo '[OK] XDG_RUNTIME_DIR creado en /tmp/runtime-dozelix'

        # Entrar como dozelix en la carpeta del proyecto
        su - dozelix -c 'cd ~/eaSway && export XDG_RUNTIME_DIR=/tmp/runtime-dozelix && /bin/bash'
    "