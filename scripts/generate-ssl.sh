#!/bin/bash

# Script para generar certificados SSL con Certbot
# Automáticamente detecta y maneja el modo SSL
# Uso: ./scripts/generate-ssl.sh <dominio> <email>

if [ $# -ne 2 ]; then
    echo "Uso: $0 <dominio> <email>"
    echo "Ejemplo: $0 maialejandra.com admin@maialejandra.com"
    exit 1
fi

DOMAIN=$1
EMAIL=$2
SSL_WAS_ACTIVE=false

echo "🚀 Generando certificado SSL para: $DOMAIN"
echo "📧 Email de contacto: $EMAIL"

# Función para detectar si SSL está activo
detect_ssl_status() {
    if grep -q "listen 443 ssl" nginx/conf.d/default.conf; then
        return 0  # SSL activo
    else
        return 1  # SSL no activo
    fi
}

# Función para desactivar SSL temporalmente
disable_ssl() {
    echo "🔄 Desactivando SSL temporalmente para certbot..."
    cp nginx/conf.d/default.conf nginx/conf.d/default.conf.backup
    cp nginx/conf.d/default-certbot.template nginx/conf.d/default.conf
    
    echo "🔄 Reiniciando nginx en modo HTTP..."
    docker restart main-nginx
    
    if [ $? -eq 0 ]; then
        echo "✅ SSL desactivado temporalmente"
        return 0
    else
        echo "❌ Error desactivando SSL"
        return 1
    fi
}

# Función para reactivar SSL
enable_ssl() {
    echo "🔄 Reactivando SSL..."
    
    # Si había backup, restaurarlo; si no, usar template SSL
    if [ -f nginx/conf.d/default.conf.backup ]; then
        cp nginx/conf.d/default.conf.backup nginx/conf.d/default.conf
        rm nginx/conf.d/default.conf.backup
    else
        cp nginx/conf.d/default-ssl.template nginx/conf.d/default.conf
    fi
    
    echo "🔄 Reiniciando nginx con SSL..."
    docker restart main-nginx
    
    if [ $? -eq 0 ]; then
        echo "✅ SSL reactivado exitosamente"
        return 0
    else
        echo "❌ Error reactivando SSL"
        return 1
    fi
}

# Detectar estado actual de SSL
if detect_ssl_status; then
    echo "🔍 SSL detectado como ACTIVO - desactivando temporalmente..."
    SSL_WAS_ACTIVE=true
    
    if ! disable_ssl; then
        echo "❌ No se pudo desactivar SSL. Abortando."
        exit 1
    fi
    
    # Esperar un momento para que nginx se reinicie completamente
    sleep 3
else
    echo "🔍 SSL detectado como INACTIVO - procediendo con certbot..."
fi

# Generar certificado usando Docker directo
echo "🔐 Ejecutando certbot..."
docker run --rm \
    --network applications_main-network \
    -v applications_certbot_conf:/etc/letsencrypt \
    -v $(pwd)/certbot/www:/var/www/certbot \
    certbot/certbot certonly \
    --webroot \
    -w /var/www/certbot \
    --email $EMAIL \
    -d $DOMAIN \
    --agree-tos \
    --no-eff-email

CERTBOT_EXIT_CODE=$?

# Manejar resultado de certbot
if [ $CERTBOT_EXIT_CODE -eq 0 ]; then
    echo "✅ Certificado generado exitosamente para $DOMAIN"
    
    # Si SSL estaba activo o es primera vez, activar SSL
    if [ "$SSL_WAS_ACTIVE" = true ]; then
        echo "🔄 Restaurando configuración SSL..."
        enable_ssl
    else
        echo "🔄 Activando SSL por primera vez..."
        enable_ssl
    fi
    
    if [ $? -eq 0 ]; then
        echo "🎉 ¡Proceso completado exitosamente!"
        echo "🌐 Tu sitio está disponible en: https://$DOMAIN"
        echo "🔒 Certificado SSL activo y funcionando"
    else
        echo "⚠️  Certificado generado pero hubo problemas reactivando SSL"
        echo "🔧 Revisa la configuración manualmente"
    fi
else
    echo "❌ Error generando certificado para $DOMAIN"
    echo "🔍 Verifica que:"
    echo "   - El dominio apunte a esta IP"
    echo "   - El puerto 80 esté accesible"
    echo "   - No hayas excedido los rate limits de Let's Encrypt"
    
    # Si SSL estaba activo, intentar restaurarlo
    if [ "$SSL_WAS_ACTIVE" = true ]; then
        echo "🔄 Restaurando configuración SSL original..."
        enable_ssl
    fi
fi