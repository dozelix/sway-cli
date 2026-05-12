### eaSway

Un instalador integral de instalación y personalización para elevar la experiencia de **Sway WM** al siguiente nivel. **SwayCLI** nace con el objetivo de eliminar la fricción inicial al configurar un gestor de ventanas tipo tiling. Ofrecemos una **herramienta CLI potente**, una **interfaz gráfica intuitiva** y una **experiencia de escritorio pulida** desde el primer segundo.

nuestro tipo de usuario es el que tiene conocimientos basicos de terminal en base debian que quiera implementar tillig en wayland sin muchas complicaciones.


---

### Estado del Proyecto

**v0.0.4-alpha**  
**en desarrollo**

- Actualmente hemos finalizado la **Fase de Infraestructura**. El instalador ya es capaz de detectar la versión de tu OS y ajustar las dependencias de **Wayland** automáticamente.
- hemos agregado un fix para que puedas testear el repo en VMs

---

### Arquitectura del Proyecto

```text
eaSway/
├── src/
│   ├── cli/             # Lógica de instalación por terminal
│   └── gui/             # Aplicación GTK4/Libadwaita (aun sin desarrollar)
├── dotfiles/            # Plantillas de configuración (.conf)
├── scripts/             # Utilidades de detección de hardware,OS y herramientas del instalador cli
└── assets/              # Recursos visuales y logos
```

---

### Entorno de Pruebas Sandbox

Para el desarrollo seguro, incluimos un entorno basado en **Docker** que permite validar la lógica de los scripts sin riesgo para el host.
(aun falta implementarlo dentro de github, actualmente dentro del repositorio)

**Cómo lanzar los tests:**  
```bash
chmod +x test_eaSway.sh
./test_eaSway.sh
```

**Nota sobre el entorno Docker:**  
El entorno Docker actual se utiliza para validación de sintaxis, dependencias y lógica de instalación. Para pruebas de renderizado gráfico de **Sway (Wayland)**, se recomienda el uso de una **Máquina Virtual VM** debido a las limitaciones de systemd y seatd dentro de contenedores.

---

### Roadmap

- [x] **Soporte dinámico para Debian 12 Bookworm y Debian 13 Trixie**
- [x] **Soporte dinamico para las ultimas 2 versiones Ubuntu LTS**
- [x] **Scripts de desinstalación con protección de backups**
- [ ] **Implementación de sway-gui alpha**
- [ ] **Soporte oficial para distribuciones basadas en Arch Linux**

---

### Contribuir

¡Las contribuciones son lo que hacen a la comunidad open source un lugar increíble!

1. Haz un **Fork** del proyecto.  
2. Crea tu rama de función.  
   ```bash
   git checkout -b feature/AmazingFeature
   ```
3. Haz **commit** de tus cambios.  
4. Abre un **Pull Request**.

---

**Desarrollado con ❤️ por dozelix**