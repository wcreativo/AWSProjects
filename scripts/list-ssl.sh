#!/bin/bash

# Script para listar certificados SSL existentes

echo "📋 Certificados SSL instalados:"
echo "================================"

docker-compose run --rm certbot certificates

echo ""
echo "💡 Comandos útiles:"
echo "   - Generar nuevo: ./scripts/generate-ssl.sh <dominio> <email>"
echo "   - Renovar todos: ./scripts/renew-ssl.sh"
echo "   - Ver este listado: ./scripts/list-ssl.sh"