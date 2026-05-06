#!/bin/bash
GREEN='\033[0;32m'
NC='\033[0m'

echo -e "${GREEN}Starting installation in English...${NC}"
# Aquí la misma lógica pero con mensajes en inglés.
# --hardware-detection.sh--
echo -e "\n${YELLOW}${MSG_DETECT_GPU}${NC}"
GPU_TYPE=$(lspci | grep -iE 'vga|3d' | tr '[:upper:]' '[:lower:]')

if echo "$GPU_TYPE" | grep -q "nvidia"; then
    VENDOR="NVIDIA"
elif echo "$GPU_TYPE" | grep -q "intel"; then
    VENDOR="INTEL"
elif echo "$GPU_TYPE" | grep -q "amd"; then
    VENDOR="AMD"
else
    VENDOR="GENERIC"
fi

if [[ "$VENDOR" == "GENERIC" ]]; then
    echo -e "${YELLOW}${MSG_GPU_UNKNOWN}${NC}"
else
    echo -e "${GREEN}${MSG_GPU_FOUND} ${VENDOR}.${NC}"
fi

echo -e "\n${YELLOW}press Enter for exit...${NC}"
read