#!/bin/bash

# Script para generar certificados SSL con Certbot
# Uso: ./scripts/generate-ssl.sh <dominio> <email>

if [ $# -ne 2 ]; then
    echo "Uso: $0 <dominio> <email>"
    echo "Ejemplo: $0 maialejandra.com admin@maialejandra.com"
    exit 1
fi

DOMAIN=$1
EMAIL=$2

echo "Generando certificado SSL para: $DOMAIN"
echo "Email de contacto: $EMAIL"

# Generar certificado usando Docker directo
docker run --rm \
    --network applications_main-network \
    -v awsprojects_certbot_conf:/etc/letsencrypt \
    -v awsprojects_certbot_www:/var/www/certbot \
    certbot/certbot certonly \
    --webroot \
    -w /var/www/certbot \
    --email $EMAIL \
    -d $DOMAIN \
    --agree-tos \
    --no-eff-email

if [ $? -eq 0 ]; then
    echo "✅ Certificado generado exitosamente para $DOMAIN"
    
    # Cambiar automáticamente a configuración SSL
    echo "🔄 Activando configuración HTTPS..."
    cp nginx/conf.d/default-ssl.template nginx/conf.d/default.conf
    
    # Reiniciar nginx con SSL usando Docker directo
    echo "🔄 Reiniciando nginx con SSL..."
    docker restart main-nginx
    
    if [ $? -eq 0 ]; then
        echo "✅ ¡SSL activado exitosamente!"
        echo "🌐 Tu sitio está disponible en: https://$DOMAIN"
    else
        echo "❌ Error reiniciando nginx. Revisa la configuración SSL."
    fi
else
    echo "❌ Error generando certificado para $DOMAIN"
    echo "🔍 Verifica que:"
    echo "   - El dominio apunte a esta IP"
    echo "   - El puerto 80 esté accesible"
    echo "   - No hayas excedido los rate limits de Let's Encrypt"
fi