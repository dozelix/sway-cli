# Changelog eaSway

Todos los cambios notables en este proyecto serán documentados en este archivo. El formato se basa en [Keep a Changelog](https://keepachangelog.com/en/1.0.0/) y este proyecto adhiere a [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

---

## [0.0.2-alpha] - 2026-05-08

### 🛠️ Módulo de Instalación (`install_packages.sh`)
- **SW-03 (Crítico):** Se añadió un guard de `systemd` antes de llamar a `systemctl enable NetworkManager`. Detecta disponibilidad mediante `pidof systemd` o existencia de `/run/systemd/system`. En Docker omite el paso con aviso amarillo en lugar de abortar.
- **SW-05 (Crítico):** Corrección en `usermod` mediante la variable dinámica `TARGET_USER="${SUDO_USER:-${USER:-dozelix}}"`. Cubre escenarios de usuario real con sudo, sesión normal y fallback a contenedor.
- **Mejora de Robustez:** Implementación de detección de `/.dockerenv` definiendo `IN_DOCKER=true` para omitir pasos incompatibles (brillo, servicios).
- **Validación de Arquitectura:** Verificación de `uname -m` con advertencia si el sistema no es `x86_64`.
- **Dependencias:** Inclusión de `kitty` y `foot` en la lista `UTILITY_PKGS`.
- **Orden de Instalación:** Priorización de librerías base (Wayland Core) antes del compositor (Sway) para evitar errores de renderizado EGL.

### 🔍 Módulo de Hardware (`check_hardware.sh`)
- **SW-08:** Implementación de detección granular de GPU (Intel, AMD, NVIDIA).
- **Corrección ShellCheck SC2034:** Se añadió la exportación (`export`) de la variable `GPU_VENDOR` para asegurar su visibilidad en el orquestador `main.sh`.
- **Corrección ShellCheck SC2001:** Sustitución de tuberías de `sed` por expansión de parámetros nativa de Bash `${variable#*: }` para mejorar el rendimiento.
- **Diagnóstico:** Detección de entorno gráfico previo y validación de dependencias mínimas.

### 🖥️ Configuración de Sway (`dotfiles/sway/config`)
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