### Changelog eaSway

Todos los cambios notables en este proyecto serán documentados en este archivo. El formato se basa en [Keep a Changelog](https://keepachangelog.com/) y este proyecto adhiere a [Semantic Versioning](https://semver.org/).

---

#### [0.0.3-alpha] - 2026-05-10

**🚀 Infraestructura de Testeo y CI/CD**
- **Sincronización de Usuario (ID #01):** Implementación de `ARG USER` en `Dockerfile.test` para replicar el UID/GID del host y evitar conflictos de permisos.  
- **Orquestador de Pruebas:** Creación de `test_eaSway.sh` para automatizar el ciclo de construcción y ejecución del sandbox.  
- **Hardware-Passthrough:** Habilitado el acceso a `/dev/dri` y `/dev/input` en el contenedor para validación de drivers.

**🛠️ Módulo de Instalación (`main.sh`)**
- **Abstracción de OS (ID #02):** Detección dinámica de `/etc/os-release`.  
- **Lógica Adaptativa:** Solución al fallo de dependencias en Debian 13 / Ubuntu 24.04 mediante el mapeo de `libegl1` vs `libegl1-mesa`.  
- **Arrays Dinámicos:** Uso de `+=` para la inyección limpia de paquetes según la versión del sistema.

**🧹 Módulo de Desinstalación (`uninstall.sh`)**
- **Seguridad Crítica (SC2115):** Protección ante variables vacías con `${VAR:?}` para evitar borrados accidentales en `/`.  
- **Gestión de Backups (SC2012):** Uso de `find` y `sort` para restaurar siempre la configuración más reciente.  
- **Validación de Purga:** Verificación de longitud del array `PKGS` antes de ejecutar `apt`.

---

#### [0.0.2-alpha] - 2026-05-08

- **Robustez:** Implementada detección de `/.dockerenv` para omitir pasos de `systemd` incompatibles.  
- **Hardware:** Exportación de `GPU_VENDOR` para visibilidad global en los scripts.  
- **Sway Config:** Estabilización de `$XDG_RUNTIME_DIR` al inicio.

---

#### [0.0.1-alpha] - 2026-05-06

- Versión inicial del orquestador y estructura modular.

---

### Notas adicionales
- El changelog sigue el esquema **Unreleased / Added / Changed / Fixed / Removed** cuando aplique.  
- Para contribuciones relacionadas con cambios en CI/CD o scripts críticos, favor de abrir PRs con referencias a los **IDs** de detección o seguridad cuando existan (por ejemplo, `ID #01`, `ID #02`).  

--- 

**Desarrollado con ❤️ por dozelix**