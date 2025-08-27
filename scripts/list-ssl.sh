#!/bin/bash

# Script para listar certificados SSL existentes

echo "📋 Certificados SSL instalados:"
echo "================================"

# Listar certificados usando Docker directo
docker run --rm \
    -v awsprojects_certbot_conf:/etc/letsencrypt \
    certbot/certbot certificates

echo ""
echo "💡 Comandos útiles:"
echo "   - Generar nuevo: ./scripts/generate-ssl.sh <dominio> <email>"
echo "   - Renovar todos: ./scripts/renew-ssl.sh"
echo "   - Ver este listado: ./scripts/list-ssl.sh"