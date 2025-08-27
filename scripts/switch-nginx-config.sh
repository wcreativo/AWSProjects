#!/bin/bash

# Script para cambiar la configuración de nginx entre SSL y no-SSL
# Uso: ./switch-nginx-config.sh [ssl|certbot]

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
show_help() {
    echo "Uso: $0 [ssl|certbot]"
    echo ""
    echo "Opciones:"
    echo "  ssl     - Activa configuración SSL con HTTPS y redirección"
    echo "  certbot - Activa configuración temporal para generación de certificados"
    echo ""
    echo "Ejemplos:"
    echo "  $0 ssl     # Cambiar a configuración SSL"
    echo "  $0 certbot # Cambiar a configuración para certbot"
}

# Función para validar que nginx esté corriendo en Docker
check_nginx_container() {
    if ! docker ps | grep -q nginx; then
        echo -e "${YELLOW}Advertencia: No se detectó contenedor nginx corriendo${NC}"
        echo "Asegúrate de reiniciar nginx después del cambio de configuración"
        return 1
    fi
    return 0
}

# Función para recargar nginx
reload_nginx() {
    if check_nginx_container; then
        echo -e "${YELLOW}Recargando configuración de nginx...${NC}"
        if docker exec nginx nginx -t; then
            docker exec nginx nginx -s reload
            echo -e "${GREEN}✓ Nginx recargado exitosamente${NC}"
        else
            echo -e "${RED}✗ Error en la configuración de nginx${NC}"
            return 1
        fi
    fi
}

# Verificar parámetros
if [ $# -eq 0 ] || [ "$1" = "-h" ] || [ "$1" = "--help" ]; then
    show_help
    exit 0
fi

CONFIG_TYPE="$1"
NGINX_DIR="nginx/conf.d"
TARGET_CONFIG="$NGINX_DIR/default.conf"

# Verificar que estamos en el directorio correcto
if [ ! -d "$NGINX_DIR" ]; then
    echo -e "${RED}Error: No se encontró el directorio $NGINX_DIR${NC}"
    echo "Asegúrate de ejecutar este script desde la raíz del proyecto"
    exit 1
fi

case "$CONFIG_TYPE" in
    "ssl")
        TEMPLATE_FILE="$NGINX_DIR/default-ssl.template"
        CONFIG_NAME="SSL con HTTPS"
        ;;
    "certbot")
        TEMPLATE_FILE="$NGINX_DIR/default-certbot.template"
        CONFIG_NAME="Certbot (HTTP temporal)"
        ;;
    *)
        echo -e "${RED}Error: Opción no válida '$CONFIG_TYPE'${NC}"
        echo ""
        show_help
        exit 1
        ;;
esac

# Verificar que existe la plantilla
if [ ! -f "$TEMPLATE_FILE" ]; then
    echo -e "${RED}Error: No se encontró la plantilla $TEMPLATE_FILE${NC}"
    exit 1
fi

# Crear backup de la configuración actual
BACKUP_FILE="$TARGET_CONFIG.backup.$(date +%Y%m%d_%H%M%S)"
if [ -f "$TARGET_CONFIG" ]; then
    echo -e "${YELLOW}Creando backup: $BACKUP_FILE${NC}"
    cp "$TARGET_CONFIG" "$BACKUP_FILE"
fi

# Aplicar nueva configuración
echo -e "${YELLOW}Aplicando configuración: $CONFIG_NAME${NC}"
cp "$TEMPLATE_FILE" "$TARGET_CONFIG"

echo -e "${GREEN}✓ Configuración cambiada exitosamente${NC}"
echo "  Configuración activa: $CONFIG_NAME"
echo "  Archivo: $TARGET_CONFIG"
echo "  Backup guardado en: $BACKUP_FILE"

# Intentar recargar nginx si está corriendo
echo ""
reload_nginx

echo ""
echo -e "${GREEN}¡Configuración aplicada!${NC}"

case "$CONFIG_TYPE" in
    "ssl")
        echo -e "${YELLOW}Nota:${NC} Asegúrate de que los certificados SSL estén disponibles en:"
        echo "  /etc/letsencrypt/live/maialejandra.com/"
        ;;
    "certbot")
        echo -e "${YELLOW}Nota:${NC} Esta configuración es temporal para generar certificados."
        echo "Ejecuta el proceso de certbot y luego cambia a configuración SSL."
        ;;
esac