# 🔍 AUDIT REPORT - eaSway Bash Scripts
**Fecha:** 2026-05-16  
**Protocolo:** RPROTOCOLO_AUDITORIA_BASH_DEBIAN_V1.0  
**Severidad:** 5 Críticos | 3 Warnings | 2 Refactorización

---

## 🔴 BUGS CRÍTICOS

### **[T01-CRITICAL] Missing `set -euo pipefail` in core scripts**
- **ARCHIVOS:** `install_packages.sh`, `uninstall.sh`, `gpu_environment.sh`, `post_install.sh`, `setup_config.sh`, `check_hardware.sh`
- **LÍNEA:** Top of each script
- **ERROR:** Sin flags de robustez. Script continúa con errores silenciosos.
- **RATIONALE:** Debian Policy requiere `-e` (abort on error), `-u` (unset vars error), `-o pipefail` (pipe integrity)
- **REFACTOR:**
```bash
#!/bin/bash
set -euo pipefail
```

---

### **[T02-CRITICAL] Unsafe variable quoting in `install_packages.sh`**
- **LÍNEA:** 45-46
- **ERROR:** Variables sin comillas al parsear `/etc/os-release`
```bash
# ❌ MALO - expandido sin protección
OS_ID=$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
OS_VER=$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')
```
- **REFACTOR:**
```bash
# ✅ CORRECTO - quoted
OS_ID="$(grep '^ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')"
OS_VER="$(grep '^VERSION_ID=' /etc/os-release | cut -d'=' -f2 | tr -d '"')"
```

---

### **[T03-CRITICAL] Unsafe array syntax in `test_vm_local.sh`**
- **LÍNEA:** 104
- **ERROR:** `source` dentro de función sin validación de estatus
```bash
source "$script" > "$tmp_out" 2>&1
local exit_code=$?
```
- **RATIONALE:** `source` en subshell pierde contexto; exit_code capturado correctamente pero `set -e` no propaga
- **REFACTOR:**
```bash
#!/bin/bash
set -euo pipefail  # Agregar al top del script

# Luego en función:
{
    source "$script"
} > "$tmp_out" 2>&1
local exit_code=$?
```

---

### **[T04-CRITICAL] Missing DEBIAN_FRONTEND in apt operations**
- **ARCHIVOS:** `install_packages.sh` líneas 146, 158, 166, 177
- **ERROR:** `apt` sin `DEBIAN_FRONTEND=noninteractive` - puede ser interactivo en ciertos contextos
- **REFACTOR:**
```bash
# ❌ MALO
sudo apt update
sudo apt install -y "${WAYLAND_CORE[@]}"

# ✅ CORRECTO
DEBIAN_FRONTEND=noninteractive sudo apt update
DEBIAN_FRONTEND=noninteractive sudo apt install -yq "${WAYLAND_CORE[@]}"
```

---

### **[T05-CRITICAL] Temporary file without trap cleanup**
- **ARCHIVOS:** `test_vm_local.sh` línea 99
- **ERROR:** `mktemp` sin `trap` cleanup; falla si script interrumpido
- **REFACTOR:**
```bash
test_step_source() {
    local script="$1"
    local desc="$2"
    local tmp_out
    tmp_out=$(mktemp) || { echo "mktemp failed"; return 1; }
    
    # 🔧 AGREGAR AL INICIO DE LA FUNCIÓN:
    trap "rm -f '$tmp_out'" RETURN INT TERM
    
    # ... resto del código ...
}
```

---

## 🟡 WARNINGS

### **[W01] Unquoted variable in conditional**
- **ARCHIVO:** `check_hardware.sh`, línea 85
- **LÍNEA:** `CHASSIS_ID=$(cat /sys/class/dmi/id/chassis_type 2>/dev/null)`
- **ISSUE:** Si archivo vacío, `$CHASSIS_ID` se expande a nada
- **REFACTOR:**
```bash
case "$CHASSIS_ID" in  # Ya está quoted aquí, bien
```

### **[W02] Silent failure in gpu_environment.sh**
- **LÍNEA:** 55
- **ERROR:** `sudo tee` puede fallar silenciosamente
```bash
# ❌ MALO - falla oculta
sudo tee "$ENV_FILE" > /dev/null <<'EOF'

# ✅ CORRECTO
sudo tee "$ENV_FILE" > /dev/null <<'EOF' || { echo "tee failed"; exit 1; }
```

### **[W03] Missing validation in setup_config.sh**
- **LÍNEA:** 44
- **ERROR:** `mv "$DEST" "$BACKUP_PATH"` sin validar éxito
```bash
# ❌ MALO
mv "$DEST" "$BACKUP_PATH"

# ✅ CORRECTO
mv "$DEST" "$BACKUP_PATH" || { echo "Backup failed for $APP"; exit 1; }
```

---

## 🔧 REFACTORIZACIÓN

### **[R01] DRY - Reducir repetición en apt calls**
- **ARCHIVOS:** `install_packages.sh` (líneas 158, 166, 177)
- **ISSUE:** Mismo pattern `sudo apt install -y` repetido 3 veces
- **REFACTOR:**
```bash
install_apt_packages() {
    local -n pkg_array=$1
    local desc=$2
    
    echo -e "${YELLOW}>> $desc${NC}"
    DEBIAN_FRONTEND=noninteractive sudo apt install -yq "${pkg_array[@]}" || {
        echo -e "${RED}   [ERROR] Instalación falló.${NC}"
        return 1
    }
    echo -e "${GREEN}   [OK] $desc completado.${NC}"
}

# Uso:
install_apt_packages WAYLAND_CORE "Instalando protocolos y drivers de Wayland"
install_apt_packages CRITICAL_PKGS "Instalando componentes críticos de Sway"
install_apt_packages UTILITY_PKGS "Instalando utilidades y extras"
```

### **[R02] Extract GPU detection logic**
- **ARCHIVO:** `check_hardware.sh`
- **ISSUE:** Lógica GPU detection puede reutilizarse
- **REFACTOR:** Crear `lib/gpu_detection.sh` con `classify_gpu()` 

---

## ✅ POSITIVOS DETECTADOS

- ✔️ `uninstall.sh:51` - Excelente uso de `${VAR:?}` para protección
- ✔️ `uninstall.sh:54` - Correcto uso de `find` en lugar de `ls`
- ✔️ `test_vm_local.sh:31` - Variables correctamente quoted en `rm -rf`
- ✔️ General: Buenas prácticas en validación con `command -v` antes de usar

---

## 📊 RESUMEN DE ACCIÓN

| Prioridad | Acción | Archivo | Línea |
|-----------|--------|---------|-------|
| 🔴 AHORA  | Agregar `set -euo pipefail` | ALL | 1 |
| 🔴 AHORA  | Quote variables en OS_ID/OS_VER | install_packages.sh | 45-46 |
| 🔴 AHORA  | Agregar DEBIAN_FRONTEND | install_packages.sh | 146, 158, 166, 177 |
| 🔴 AHORA  | Trap cleanup para mktemp | test_vm_local.sh | 99 |
| 🟡 SOON   | Validar mov result | setup_config.sh | 44 |
| 🟡 SOON   | Validar tee result | gpu_environment.sh | 55 |
| 🟢 OPTIONAL | Extract install_apt_packages() | install_packages.sh | 158-188 |

---

## 🔗 Referencias
- POSIX Shell Guidelines: https://pubs.opengroup.org/onlinepubs/9699919799/
- Debian Policy: https://www.debian.org/doc/debian-policy/
- ShellCheck: SC2115, SC2181, SC2086
