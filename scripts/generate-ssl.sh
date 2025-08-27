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

# Generar certificado
docker-compose run --rm certbot certonly \
    --webroot \
    -w /var/www/certbot \
    --email $EMAIL \
    -d $DOMAIN \
    --agree-tos \
    --no-eff-email

if [ $? -eq 0 ]; then
    echo "✅ Certificado generado exitosamente para $DOMAIN"
    echo "📝 Recuerda actualizar tu configuración nginx para usar HTTPS"
    echo "🔄 Reinicia nginx: docker-compose restart main-nginx"
else
    echo "❌ Error generando certificado para $DOMAIN"
    echo "🔍 Verifica que:"
    echo "   - El dominio apunte a esta IP"
    echo "   - El puerto 80 esté accesible"
    echo "   - No hayas excedido los rate limits de Let's Encrypt"
fi