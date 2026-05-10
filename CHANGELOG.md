# Changelog eaSway

Todos los cambios notables en este proyecto serán documentados en este archivo. El formato se basa en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.0.3-alpha] - 2026-05-10

### Infraestructura de Testeo y CI/CD

* **Sincronización Dinámica (Tarea #01):** Implementación de `ARG USER` en `Dockerfile.test` para replicar el `UID/GID` del host dentro del contenedor, eliminando conflictos de permisos en volúmenes compartidos.
* **Orquestador `test_eaSway.sh`:** Creación de un script de automatización que gestiona el ciclo de vida completo (limpieza, construcción y ejecución) del entorno de pruebas.
* **Fix ShellCheck SC2181:** Optimización del manejo de errores mediante validación directa de comandos en bloques condicionales (`if ! docker build ...`).
* **Fix ShellCheck SC2155:** Corrección de enmascaramiento de valores de retorno mediante la separación de declaración y asignación en variables críticas (`HOST_USER`, `RUNTIME_DIR`).

### Módulo de Instalación (`main.sh` & `scripts`)

* **Abstracción de OS:** Implementación de detección dinámica mediante la lectura de `/etc/os-release` para identificar variantes de Debian y Ubuntu.
* **Lógica Adaptativa de Paquetes:** - Solución al fallo crítico de dependencias en **Debian 13 (Trixie)** y **Ubuntu 24.04+**.
* Mapeo dinámico del array `WAYLAND_CORE`: utiliza `libegl1-mesa` para Debian 12 (Legacy) y realiza el fallback a `libegl1` + `libgl1-mesa-dri` para versiones modernas.


* **Robustez de Arrays:** Uso del operador `+=` para la inyección limpia de dependencias según el entorno detectado, evitando variables vacías.

### Módulo de Desinstalación (`uninstall.sh`)

* **Implementacion de array** para un mejor manero de archivos PKGS  ahora es un array fragmentado
* **Seguridad Crítica (SC2115)** Implementación de protecciones contra variables vacías mediante `${VARIABLE:?}` en comandos `rm -rf`, previniendo el borrado accidental de la raíz o del directorio home.
* **Gestión de Backups (SC2012)** Sustitución de `ls` por `find` con `-maxdepth 1` para una localización de directorios de respaldo más segura y eficiente.
* **Restauración Automática** Mejora en el bucle de recuperación de configuraciones para restaurar siempre el backup más reciente (`sort -r | head -n 1`).
* **Validación de Purga** Añadida verificación de longitud de array (`${#PKGS[@]}`) antes de invocar a `apt purge` para evitar llamadas a comandos vacíos.

---

### Notas de Versión

> Esta versión cierra la **Fase de Cimentación e Infraestructura**. El proyecto ahora es totalmente consciente de su entorno (Docker vs Host) y posee una lógica de instalación resiliente a los cambios de nomenclatura en los repositorios de Debian.
---

## [0.0.2-alpha] - 2026-05-08

### Módulo de Instalación (`install_packages.sh`)
- **SW-03 (Crítico):** Se añadió un guard de `systemd` antes de llamar a `systemctl enable NetworkManager`. Detecta disponibilidad mediante `pidof systemd` o existencia de `/run/systemd/system`. En Docker omite el paso con aviso amarillo en lugar de abortar.
- **SW-05 (Crítico):** Corrección en `usermod` mediante la variable dinámica `TARGET_USER="${SUDO_USER:-${USER:-dozelix}}"`. Cubre escenarios de usuario real con sudo, sesión normal y fallback a contenedor.
- **Mejora de Robustez:** Implementación de detección de `/.dockerenv` definiendo `IN_DOCKER=true` para omitir pasos incompatibles (brillo, servicios).
- **Validación de Arquitectura:** Verificación de `uname -m` con advertencia si el sistema no es `x86_64`.
- **Dependencias:** Inclusión de `kitty` y `foot` en la lista `UTILITY_PKGS`.
- **Orden de Instalación:** Priorización de librerías base (Wayland Core) antes del compositor (Sway) para evitar errores de renderizado EGL.

### Módulo de Hardware (`check_hardware.sh`)
- **SW-08:** Implementación de detección granular de GPU (Intel, AMD, NVIDIA).
- **Corrección ShellCheck SC2034:** Se añadió la exportación (`export`) de la variable `GPU_VENDOR` para asegurar su visibilidad en el orquestador `main.sh`.
- **Corrección ShellCheck SC2001:** Sustitución de tuberías de `sed` por expansión de parámetros nativa de Bash `${variable#*: }` para mejorar el rendimiento.
- **Diagnóstico:** Detección de entorno gráfico previo y validación de dependencias mínimas.

### Configuración de Sway (`dotfiles/sway/config`)
- **SW-06:** Estabilización de inicio mediante `exec_always mkdir -p "$XDG_RUNTIME_DIR"` y `exec_always chmod 700 "$XDG_RUNTIME_DIR"`.
- **Espacios de Trabajo:** Ampliación de 4 a 6 workspaces con sus respectivos atajos de navegación.
- **Keybindings:** Añadidos atajos para movimiento de ventanas (`$mod+Shift+hjkl`), modo resize y layouts (stacking, tabbed, split, fullscreen, floating).
- **Multimedia:** Atajos para capturas de pantalla con `grim` y `slurp` (tecla `Print` y `$mod+Print`) con guardado automático en `~/capturas/`.
- **Reglas de Ventana:** Configuración de modo flotante para `pavucontrol`, `thunar` y `nm-connection-editor`.
- **Integración D-Bus:** Añadido `--systemd` a `dbus-update-activation-environment`.

---

## [0.0.1-alpha] - 2026-05-06
- Versión inicial del orquestador.
- Estructura modular básica (`main.sh`, `install_packages.sh`, `setup_config.sh`).
- Definición de estética neobrutalista/post-punk.
- Configuración inicial de Waybar y Kitty.