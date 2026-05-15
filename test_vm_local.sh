#!/bin/bash

# =================================================================
# eaSway - Test Local VM Simulation
# Finalidad: Simular entorno VM sin necesitar VM real
# Permite testear la instalación en ambiente controlado local
# =================================================================

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TEST_ENV_DIR="${SCRIPT_DIR}/.test_vm_env"
LOG_FILE="${SCRIPT_DIR}/test_vm_local.log"

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

# =================================================================
# LIMPIEZA INICIAL
# =================================================================
echo -e "${BLUE}>> Limpiando entorno anterior...${NC}"
rm -rf "$TEST_ENV_DIR" "$LOG_FILE"
mkdir -p "$TEST_ENV_DIR"

# =================================================================
# CREAR ESTRUCTURA SIMULADA DE VM
# =================================================================
echo -e "${BLUE}>> Creando estructura simulada de VM...${NC}"

# Simulamos detección de VM con systemd-detect-virt
mkdir -p "$TEST_ENV_DIR/usr/bin"
cat > "$TEST_ENV_DIR/usr/bin/systemd-detect-virt" << 'EOF'
#!/bin/bash
echo "kvm"
exit 0
EOF
chmod +x "$TEST_ENV_DIR/usr/bin/systemd-detect-virt"

# Crear fake /sys para evitar que se lean valores reales
mkdir -p "$TEST_ENV_DIR/sys/class/dmi/id"
mkdir -p "$TEST_ENV_DIR/sys/class/power_supply"

# Crear fake /run/systemd para simular systemd disponible
mkdir -p "$TEST_ENV_DIR/run/systemd/system"

# Crear archivo /etc/os-release simulado
mkdir -p "$TEST_ENV_DIR/etc"
cat > "$TEST_ENV_DIR/etc/os-release" << 'EOF'
NAME="Debian GNU/Linux"
VERSION_ID="12"
ID="debian"
ID_LIKE="debian"
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
EOF

# Crear fake lspci que no encuentra GPU en VM
cat > "$TEST_ENV_DIR/usr/bin/lspci" << 'EOF'
#!/bin/bash
# Simular lspci sin GPU VGA
echo "00:00.0 Host bridge: Intel Corporation 440FX - 82441FX PMC [Natoma] (rev 02)"
exit 0
EOF
chmod +x "$TEST_ENV_DIR/usr/bin/lspci"

# Crear fake sudo que NO pide contraseña
cat > "$TEST_ENV_DIR/usr/bin/sudo" << 'EOF'
#!/bin/bash
# Simulación de sudo sin contraseña
# Solo ejecuta el comando, sin pedir contraseña
"$@"
EOF
chmod +x "$TEST_ENV_DIR/usr/bin/sudo"

echo -e "${GREEN}   [OK] Estructura simulada creada.${NC}\n"

# =================================================================
# CREAR WRAPPER PARA EJECUTAR EN AMBIENTE AISLADO
# =================================================================
echo -e "${BLUE}>> Preparando environment de prueba...${NC}"

# Crear PATH que prefiera nuestros fakes
FAKE_PATH="$TEST_ENV_DIR/usr/bin:/usr/local/bin:/usr/bin:/bin"

# Variables de entorno para la prueba
export PATH="$FAKE_PATH:$PATH"
export SCRIPT_DIR
export TEST_LOG="$LOG_FILE"

echo -e "${GREEN}   [OK] Environment preparado.${NC}\n"

# =================================================================
# EJECUTAR SCRIPTS EN ORDEN
# =================================================================
echo -e "${BLUE}>> Ejecutando pruebas simuladas...${NC}"
echo "================================================" >> "$LOG_FILE"
echo "eaSway VM Local Test - $(date)" >> "$LOG_FILE"
echo "================================================" >> "$LOG_FILE"

test_step() {
    local script="$1"
    local desc="$2"

    echo -e "${YELLOW}[TEST] $desc${NC}"
    echo "--- $desc ---" >> "$LOG_FILE"

    if bash "$script" >> "$LOG_FILE" 2>&1; then
        echo -e "${GREEN}   ✔ $desc exitoso${NC}"
        echo "SUCCESS" >> "$LOG_FILE"
    else
        local exit_code=$?
        echo -e "${RED}   ✗ $desc falló (exit code: $exit_code)${NC}"
        echo "FAILED (exit code: $exit_code)" >> "$LOG_FILE"
        return "$exit_code"
    fi
    echo "" >> "$LOG_FILE"
}

# Ejecutar scripts
test_step "${SCRIPT_DIR}/scripts/check_hardware.sh" "Detección de Hardware"
test_step "${SCRIPT_DIR}/scripts/install_packages.sh" "Instalación de Paquetes" || true
test_step "${SCRIPT_DIR}/scripts/gpu_environment.sh" "Configuración GPU"
test_step "${SCRIPT_DIR}/scripts/setup_config.sh" "Setup de Configuraciones" || true

# =================================================================
# VALIDACIÓN FINAL
# =================================================================
echo -e "\n${BLUE}>> Validando resultados...${NC}\n"

# Verificar que las variables estén definidas
if grep -q "Entorno virtualizado detectado" "$LOG_FILE"; then
    echo -e "${GREEN}   [OK] Virtualización correctamente detectada${NC}"
else
    echo -e "${YELLOW}   [!] Virtualización no se detectó como esperado${NC}"
fi

if grep -q "GPU_VENDOR.*Desconocido" "$LOG_FILE"; then
    echo -e "${GREEN}   [OK] GPU_VENDOR correctamente asignado como 'Desconocido'${NC}"
else
    echo -e "${YELLOW}   [!] GPU_VENDOR no es 'Desconocido' en VM${NC}"
fi

if grep -q "DEVICE_TYPE.*desktop" "$LOG_FILE"; then
    echo -e "${GREEN}   [OK] DEVICE_TYPE correctamente asignado como 'desktop'${NC}"
else
    echo -e "${YELLOW}   [!] DEVICE_TYPE no es 'desktop'${NC}"
fi

# Contar errores - grep -c devuelve 0 con exit 1 cuando no hay coincidencias
ERRORS=0
if grep -q "^FAILED" "$LOG_FILE" 2>/dev/null; then
    ERRORS=$(grep -c "^FAILED" "$LOG_FILE")
fi

if [ "$ERRORS" -eq 0 ]; then
    echo -e "\n${GREEN}>> Todas las pruebas completadas sin problemas.${NC}"
    FINAL_EXIT=0
else
    echo -e "\n${YELLOW}>> $ERRORS pasos tuvieron problemas.${NC}"
    FINAL_EXIT=1
fi

# =================================================================
# MOSTRAR LOG
# =================================================================
echo -e "\n${BLUE}>> Log completo:${NC}"
echo "================================================"
cat "$LOG_FILE"
echo "================================================"

echo -e "\n${BLUE}>> Log guardado en: $LOG_FILE${NC}\n"

if [ "$FINAL_EXIT" -eq 0 ]; then
    echo -e "${GREEN}✔ Test VM simulado exitoso${NC}"
    exit 0
else
    echo -e "${RED}✗ Test VM simulado con problemas${NC}"
    exit 1
fi
