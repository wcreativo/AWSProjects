#!/bin/bash

# Script para renovar certificados SSL
# Los certificados de Let's Encrypt duran 90 días

echo "🔄 Renovando certificados SSL..."

# Renovar todos los certificados que estén próximos a vencer usando Docker directo
docker run --rm \
    --network applications_main-network \
    -v applications_certbot_conf:/etc/letsencrypt \
    -v $(pwd)/certbot/www:/var/www/certbot \
    certbot/certbot renew

if [ $? -eq 0 ]; then
    echo "✅ Certificados renovados exitosamente"
    echo "🔄 Reiniciando nginx para aplicar cambios..."
    docker restart main-nginx
    echo "✅ Nginx reiniciado"
else
    echo "❌ Error renovando certificados"
    echo "🔍 Revisa los logs para más detalles"
fi