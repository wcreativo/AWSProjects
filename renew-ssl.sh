#!/bin/bash

# Script para renovar certificados SSL
echo "Renovando certificados SSL..."

# Renovar certificados
docker run --rm \
  -v $(pwd)/certbot/conf:/etc/letsencrypt \
  -v $(pwd)/certbot/www:/var/www/certbot \
  certbot/certbot renew \
  --webroot \
  --webroot-path=/var/www/certbot

# Reiniciar nginx si la renovación fue exitosa
if [ $? -eq 0 ]; then
    echo "Certificados renovados exitosamente. Reiniciando nginx..."
    docker-compose restart main-nginx
    echo "Nginx reiniciado."
else
    echo "Error al renovar certificados."
fi