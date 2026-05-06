# SwayCLI Ecosystem

Un ecosistema integral de instalación y personalización para elevar la experiencia de Sway WM al siguiente nivel.

SwayCLI nace con el objetivo de eliminar la fricción inicial al configurar un gestor de ventanas tipo tiling. Ofrecemos una herramienta CLI potente, una interfaz gráfica intuitiva y una experiencia de escritorio pulida desde el primer segundo.

## Tabla de Contenidos 

Características Principales

Arquitectura del Proyecto

Instalación

Roadmap

Contribuciones

✨ Características Principales

1. Sway-CLI Installer

El núcleo del proyecto. Un instalador inteligente desarrollado para ser rápido y modular.

Hardware-Aware: Detección automática de GPU (Intel, AMD, NVIDIA) y aplicación de parches necesarios para Wayland.

Selección de Componentes: Tú eliges qué instalar: Waybar, Mako, Rofi-Wayland, Wlogout, etc.

Configuración de Laptops: Optimización de gestos táctiles y gestión de energía (TLP / Auto-cpufreq).

2. Sway-GUI (The "Easy" Way)

Una interfaz gráfica moderna construida en GTK4/Libadwaita para aquellos que prefieren una experiencia visual guiada. Ideal para usuarios que migran desde GNOME o KDE.

3. Desktop Experience

No es solo un script; es un entorno diseñado con coherencia:

Tematizado Unificado: Colores y fuentes consistentes entre Sway, aplicaciones GTK y terminal.

Flujo de Trabajo: Atajos de teclado lógicos y preconfigurados para máxima productividad.

Multimonitor: Gestión inteligente de pantallas vía wlr-randr.

🏗 Arquitectura del Proyecto

sway-ecosystem/
├── src/
│   ├── cli/             # Lógica de instalación por terminal
│   └── gui/             # Aplicación GTK4/Libadwaita
├── dotfiles/            # Plantillas de configuración (.conf)
├── scripts/             # Utilidades de detección de hardware
└── assets/              # Recursos visuales y logos


🛠 Instalación

Actualmente el proyecto se encuentra en fase Alpha. Puedes probar el instalador ejecutando:

# Clonar el repositorio
git clone [https://github.com/tu-usuario/sway-ecosystem.git](https://github.com/tu-usuario/sway-ecosystem.git)

# Entrar al directorio
cd sway-ecosystem

# Ejecutar el instalador CLI
chmod +x sway-cli
./sway-cli install


🗺 Roadmap

[ ] Soporte oficial para distribuciones basadas en Arch Linux.

[ ] Implementación de sway-gui (Beta).

[ ] Panel de control centralizado para configuraciones rápidas (Hot-swapping).

[ ] Soporte extendido para Fedora y Debian Sid.

[ ] Integración de SwayFX como opción de renderizado estética.

🤝 Contribuir

¡Las contribuciones son lo que hacen a la comunidad open source un lugar increíble!

Haz un Fork del proyecto.

Crea tu rama de función (git checkout -b feature/AmazingFeature).

Haz commit de tus cambios (git commit -m 'Add some AmazingFeature').

Haz Push a la rama (git push origin feature/AmazingFeature).

Abre un Pull Request.

Desarrollado con ❤️ por dozelix
