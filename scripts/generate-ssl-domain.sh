#!/bin/bash

# Script para generar certificado SSL para un dominio específico
# Ejecutar SOLO en la instancia de AWS después del deploy
# Uso: sudo ./scripts/generate-ssl-domain.sh <dominio> [email]
# Ejemplos:
#   sudo ./scripts/generate-ssl-domain.sh maialejandra.com
#   sudo ./scripts/generate-ssl-domain.sh embyter.com user@example.com

set -e

# Colores para output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Función para mostrar ayuda
show_help() {
    echo "🔐 Generador de certificados SSL por dominio"
    echo ""
    echo "Uso: sudo $0 <dominio> [email]"
    echo ""
    echo "Parámetros:"
    echo "  dominio    Dominio para el cual generar el certificado (requerido)"
    echo "  email      Email para Let's Encrypt (opcional, se solicitará si no se proporciona)"
    echo ""
    echo "Ejemplos:"
    echo "  sudo $0 maialejandra.com"
    echo "  sudo $0 embyter.com user@example.com"
    echo "  sudo $0 nuevodominio.com"
    echo ""
    echo "Dominios soportados actualmente:"
    echo "  - maialejandra.com (HelloProject)"
    echo "  - embyter.com (WorldProyect)"
    echo "  - Cualquier dominio nuevo que agregues"
}

# Verificar parámetros
if [ $# -lt 1 ]; then
    echo -e "${RED}❌ Error: Dominio es requerido${NC}"
    echo ""
    show_help
    exit 1
fi

DOMAIN=$1
EMAIL=$2

echo "🔐 Generando certificado SSL para: $DOMAIN"

# Verificar que estamos ejecutando como root
if [ "$EUID" -ne 0 ]; then
    echo -e "${RED}❌ Error: Este script debe ejecutarse como root (usa sudo)${NC}"
    exit 1
fi

# Verificar que estamos en el directorio correcto
if [ ! -f "docker-compose.yml" ]; then
    echo -e "${RED}❌ Error: Ejecuta este script desde el directorio raíz del proyecto${NC}"
    exit 1
fi

# Validar formato de dominio básico
if [[ ! "$DOMAIN" =~ ^[a-zA-Z0-9][a-zA-Z0-9-]{1,61}[a-zA-Z0-9]\.[a-zA-Z]{2,}$ ]]; then
    echo -e "${RED}❌ Error: Formato de dominio inválido: $DOMAIN${NC}"
    exit 1
fi

# Instalar certbot si no está instalado
if ! command -v certbot &> /dev/null; then
    echo -e "${BLUE}📦 Instalando certbot...${NC}"
    
    # Detectar distribución
    if [ -f /etc/debian_version ]; then
        # Ubuntu/Debian
        apt update
        apt install -y certbot
    elif [ -f /etc/redhat-release ]; then
        # Amazon Linux/CentOS/RHEL
        yum update -y
        yum install -y certbot
    else
        echo -e "${RED}❌ Distribución no soportada. Instala certbot manualmente${NC}"
        exit 1
    fi
fi

# Solicitar email si no se proporcionó
if [ -z "$EMAIL" ]; then
    echo -e "${YELLOW}📧 Ingresa tu email para Let's Encrypt:${NC}"
    read -p "Email: " EMAIL
    
    if [ -z "$EMAIL" ]; then
        echo -e "${RED}❌ Error: Email es requerido${NC}"
        exit 1
    fi
fi

# Validar email básico
if [[ ! "$EMAIL" =~ ^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$ ]]; then
    echo -e "${RED}❌ Error: Formato de email inválido: $EMAIL${NC}"
    exit 1
fi

# Crear directorio para el dominio
echo -e "${BLUE}📁 Preparando directorio para $DOMAIN...${NC}"
mkdir -p "nginx/ssl/$DOMAIN"

# Verificar si ya existe un certificado válido
check_existing_certificate() {
    local cert_file="nginx/ssl/$DOMAIN/fullchain.pem"
    
    if [ -f "$cert_file" ]; then
        echo -e "${YELLOW}🔍 Verificando certificado existente...${NC}"
        
        # Verificar fecha de expiración
        local expiry_date=$(openssl x509 -enddate -noout -in "$cert_file" 2>/dev/null | cut -d= -f2)
        if [ -n "$expiry_date" ]; then
            local expiry_epoch=$(date -d "$expiry_date" +%s 2>/dev/null || date -j -f "%b %d %H:%M:%S %Y %Z" "$expiry_date" +%s 2>/dev/null)
            local current_epoch=$(date +%s)
            local days_until_expiry=$(( (expiry_epoch - current_epoch) / 86400 ))
            
            if [ $days_until_expiry -gt 30 ]; then
                echo -e "${GREEN}✅ Certificado válido por $days_until_expiry días${NC}"
                echo -e "${YELLOW}¿Deseas renovarlo de todas formas? (y/N):${NC}"
                read -p "" confirm
                if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
                    echo -e "${BLUE}ℹ️  Manteniendo certificado existente${NC}"
                    exit 0
                fi
            else
                echo -e "${YELLOW}⚠️  Certificado expira en $days_until_expiry días, renovando...${NC}"
            fi
        fi
    fi
}

# Verificar certificado existente
check_existing_certificate

# Función para obtener certificado
get_certificate() {
    echo -e "${BLUE}🔄 Obteniendo certificado para $DOMAIN...${NC}"
    
    # Verificar si nginx está corriendo
    local nginx_running=false
    if docker-compose ps main-nginx | grep -q "Up"; then
        nginx_running=true
        echo "🛑 Parando nginx temporalmente..."
        docker-compose stop main-nginx
    fi
    
    # Obtener certificado usando standalone
    if certbot certonly \
        --standalone \
        --email "$EMAIL" \
        --agree-tos \
        --no-eff-email \
        --domains "$DOMAIN,www.$DOMAIN" \
        --non-interactive; then
        
        # Copiar certificados a la ubicación de nginx
        if [ -d "/etc/letsencrypt/live/$DOMAIN" ]; then
            cp "/etc/letsencrypt/live/$DOMAIN/fullchain.pem" "nginx/ssl/$DOMAIN/"
            cp "/etc/letsencrypt/live/$DOMAIN/privkey.pem" "nginx/ssl/$DOMAIN/"
            
            # Configurar permisos
            chown root:root "nginx/ssl/$DOMAIN/"*.pem
            chmod 644 "nginx/ssl/$DOMAIN/fullchain.pem"
            chmod 600 "nginx/ssl/$DOMAIN/privkey.pem"
            
            echo -e "${GREEN}✅ Certificado para $DOMAIN configurado exitosamente${NC}"
        else
            echo -e "${RED}❌ Error: No se pudo obtener certificado para $DOMAIN${NC}"
            return 1
        fi
    else
        echo -e "${RED}❌ Error: Falló la obtención del certificado${NC}"
        return 1
    fi
    
    # Reiniciar nginx si estaba corriendo
    if [ "$nginx_running" = true ]; then
        echo "🔄 Reiniciando nginx..."
        docker-compose start main-nginx
        
        # Verificar que nginx inició correctamente
        sleep 5
        if docker-compose ps main-nginx | grep -q "Up"; then
            echo -e "${GREEN}✅ Nginx reiniciado correctamente${NC}"
        else
            echo -e "${RED}❌ Error: Nginx no pudo reiniciar${NC}"
            return 1
        fi
    fi
}

# Obtener el certificado
if get_certificate; then
    echo ""
    echo -e "${GREEN}🎉 ¡Certificado SSL para $DOMAIN configurado exitosamente!${NC}"
    echo ""
    echo "📋 Detalles del certificado:"
    
    # Mostrar información del certificado
    if [ -f "nginx/ssl/$DOMAIN/fullchain.pem" ]; then
        echo "  📄 Archivo: nginx/ssl/$DOMAIN/fullchain.pem"
        echo "  🔑 Clave: nginx/ssl/$DOMAIN/privkey.pem"
        
        # Mostrar fecha de expiración
        local expiry=$(openssl x509 -enddate -noout -in "nginx/ssl/$DOMAIN/fullchain.pem" | cut -d= -f2)
        echo "  📅 Expira: $expiry"
    fi
    
    echo ""
    echo "🌐 URLs disponibles:"
    echo "  https://$DOMAIN"
    echo "  https://www.$DOMAIN"
    echo ""
    echo "🔍 Para verificar:"
    echo "  curl -I https://$DOMAIN"
    echo "  curl -I https://www.$DOMAIN"
    echo ""
    echo "📝 Notas:"
    echo "  - El certificado se renovará automáticamente"
    echo "  - Para renovar manualmente: sudo $0 $DOMAIN $EMAIL"
    echo "  - Para otros dominios: sudo $0 <otro-dominio>"
else
    echo ""
    echo -e "${RED}❌ Error: No se pudo configurar el certificado SSL${NC}"
    echo ""
    echo "🔧 Posibles soluciones:"
    echo "  1. Verifica que el dominio apunte a esta IP"
    echo "  2. Verifica que el puerto 80 esté abierto"
    echo "  3. Revisa los logs de certbot arriba"
    echo "  4. Intenta nuevamente en unos minutos"
    exit 1
fi