FROM debian:latest

# 2. Re-declarar el ARG para que esté disponible en esta etapa
ARG USER
ENV USER=${USER}
ENV HOME=/home/${USER}

# Evitar diálogos interactivos durante la instalación
ENV DEBIAN_FRONTEND=noninteractive

# Instalación de dependencias mínimas para la infraestructura (Sprint 1)
RUN apt-get update && apt-get install -y \
    sudo \
    bash \
    coreutils \
    util-linux \
    && rm -rf /var/lib/apt/lists/*

# Crear el usuario dinámico y darle permisos de sudo
RUN useradd -m -s /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Configuración de espacio de trabajo
WORKDIR ${HOME}/eaSway

# Asegurar que los archivos pertenezcan al usuario sincronizado
COPY --chown=${USER}:${USER} . .

USER ${USER}
