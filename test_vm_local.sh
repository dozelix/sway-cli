#!/bin/bash

# =================================================================
# eaSway - Test Local VM Simulation
# Finalidad: Simular entorno VM sin necesitar VM real
# Permite testear la instalación en ambiente controlado local
# Fix:
#   - BUG#1: check_hardware.sh ahora se ejecuta con source para que
#     GPU_VENDOR, DEVICE_TYPE e IN_VM se propaguen a los pasos
#     siguientes (install_packages, gpu_environment).
#   - BUG#5: Corregidos los greps de validación final para que
#     coincidan con el output real de check_hardware.sh.
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

mkdir -p "$TEST_ENV_DIR/usr/bin"
cat > "$TEST_ENV_DIR/usr/bin/systemd-detect-virt" << 'EOF'
#!/bin/bash
echo "kvm"
exit 0
EOF
chmod +x "$TEST_ENV_DIR/usr/bin/systemd-detect-virt"

mkdir -p "$TEST_ENV_DIR/sys/class/dmi/id"
mkdir -p "$TEST_ENV_DIR/sys/class/power_supply"
mkdir -p "$TEST_ENV_DIR/run/systemd/system"

mkdir -p "$TEST_ENV_DIR/etc"
cat > "$TEST_ENV_DIR/etc/os-release" << 'EOF'
NAME="Debian GNU/Linux"
VERSION_ID="12"
ID="debian"
ID_LIKE="debian"
PRETTY_NAME="Debian GNU/Linux 12 (bookworm)"
EOF

cat > "$TEST_ENV_DIR/usr/bin/lspci" << 'EOF'
#!/bin/bash
echo "00:00.0 Host bridge: Intel Corporation 440FX - 82441FX PMC [Natoma] (rev 02)"
exit 0
EOF
chmod +x "$TEST_ENV_DIR/usr/bin/lspci"

cat > "$TEST_ENV_DIR/usr/bin/sudo" << 'EOF'
#!/bin/bash
"$@"
EOF
chmod +x "$TEST_ENV_DIR/usr/bin/sudo"

echo -e "${GREEN}   [OK] Estructura simulada creada.${NC}\n"

# =================================================================
# PREPARAR ENVIRONMENT
# =================================================================
echo -e "${BLUE}>> Preparando environment de prueba...${NC}"

FAKE_PATH="$TEST_ENV_DIR/usr/bin:/usr/local/bin:/usr/bin:/bin"
export PATH="$FAKE_PATH:$PATH"
export SCRIPT_DIR
export TEST_LOG="$LOG_FILE"

echo -e "${GREEN}   [OK] Environment preparado.${NC}\n"

# =================================================================
# FUNCIONES DE EJECUCIÓN
# =================================================================

# BUG-1 FIX: source dentro de un pipe fuerza subshell — las variables exportadas
# (GPU_VENDOR, DEVICE_TYPE, IN_VM) se perdían y PIPESTATUS[0] siempre devolvía 0.
# Solución: source en el proceso actual, salida capturada en fichero temporal;
# se vuelca a pantalla y al log sin ningún subshell de por medio.
test_step_source() {
    local script="$1"
    local desc="$2"
    local tmp_out
    tmp_out=$(mktemp)

    echo -e "${YELLOW}[TEST] $desc${NC}"
    echo "--- $desc ---" >> "$LOG_FILE"

    source "$script" > "$tmp_out" 2>&1
    local exit_code=$?

    cat "$tmp_out"
    cat "$tmp_out" >> "$LOG_FILE"
    rm -f "$tmp_out"

    if [ "$exit_code" -eq 0 ]; then
        echo -e "${GREEN}   ✔ $desc exitoso${NC}"
        echo "SUCCESS" >> "$LOG_FILE"
    else
        echo -e "${RED}   ✗ $desc falló (exit code: $exit_code)${NC}"
        echo "FAILED (exit code: $exit_code)" >> "$LOG_FILE"
        return "$exit_code"
    fi
    echo "" >> "$LOG_FILE"
}

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

# =================================================================
# EJECUTAR SCRIPTS EN ORDEN
# =================================================================
echo -e "${BLUE}>> Ejecutando pruebas simuladas...${NC}"
echo "================================================" >> "$LOG_FILE"
echo "eaSway VM Local Test - $(date)" >> "$LOG_FILE"
echo "================================================" >> "$LOG_FILE"

# BUG#1 FIX: check_hardware usa source para exportar variables al entorno actual
test_step_source "${SCRIPT_DIR}/scripts/check_hardware.sh" "Detección de Hardware"

# Verificar que las variables llegaron correctamente antes de continuar
echo -e "${BLUE}   Variables detectadas: GPU=${GPU_VENDOR:-VACÍO} | DEVICE=${DEVICE_TYPE:-VACÍO} | VM=${IN_VM:-VACÍO}${NC}"

test_step "${SCRIPT_DIR}/scripts/install_packages.sh" "Instalación de Paquetes" || true
test_step "${SCRIPT_DIR}/scripts/gpu_environment.sh" "Configuración GPU"
test_step "${SCRIPT_DIR}/scripts/setup_config.sh" "Setup de Configuraciones" || true

# =================================================================
# VALIDACIÓN FINAL
# BUG#5 FIX: los greps ahora coinciden con el output real de check_hardware.sh
# =================================================================
echo -e "\n${BLUE}>> Validando resultados...${NC}\n"

if grep -q "Entorno virtualizado detectado" "$LOG_FILE"; then
    echo -e "${GREEN}   [OK] Virtualización correctamente detectada${NC}"
else
    echo -e "${YELLOW}   [!] Virtualización no se detectó como esperado${NC}"
fi

# BUG#5 FIX: era "GPU_VENDOR.*Desconocido" — el log imprime "Fabricante de GPU: Desconocido"
if grep -q "Fabricante de GPU: Desconocido" "$LOG_FILE"; then
    echo -e "${GREEN}   [OK] GPU_VENDOR correctamente asignado como 'Desconocido'${NC}"
else
    echo -e "${YELLOW}   [!] GPU_VENDOR no es 'Desconocido' en VM${NC}"
fi

# BUG#5 FIX: era "DEVICE_TYPE.*desktop" — el log imprime "Tipo de dispositivo: desktop"
if grep -q "Tipo de dispositivo: desktop" "$LOG_FILE"; then
    echo -e "${GREEN}   [OK] DEVICE_TYPE correctamente asignado como 'desktop'${NC}"
else
    echo -e "${YELLOW}   [!] DEVICE_TYPE no es 'desktop'${NC}"
fi

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