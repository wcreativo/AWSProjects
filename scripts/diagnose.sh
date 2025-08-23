#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔍 Diagnostic Script for AWS Projects${NC}"
echo -e "${BLUE}======================================${NC}"

# Configuration
STACK_NAME="aws-projects-stack"
REGION="us-east-1"
KEY_PAIR_NAME="aws-projects-key"

# Get instance information
echo -e "${YELLOW}📋 Getting instance information...${NC}"
PUBLIC_IP=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' \
    --output text 2>/dev/null)

INSTANCE_ID=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
    --output text 2>/dev/null)

if [ -z "$PUBLIC_IP" ] || [ -z "$INSTANCE_ID" ]; then
    echo -e "${RED}❌ Could not get instance information. Stack might not exist.${NC}"
    exit 1
fi

echo -e "${GREEN}🌐 Public IP: $PUBLIC_IP${NC}"
echo -e "${GREEN}🔧 Instance ID: $INSTANCE_ID${NC}"

# Test connectivity
echo -e "\n${YELLOW}🔗 Testing connectivity...${NC}"
if ping -c 1 $PUBLIC_IP &> /dev/null; then
    echo -e "${GREEN}✅ Instance is reachable${NC}"
else
    echo -e "${RED}❌ Instance is not reachable${NC}"
fi

# Test HTTP ports
echo -e "\n${YELLOW}🌐 Testing HTTP ports...${NC}"
for port in 80 8001; do
    if curl -s --connect-timeout 5 http://$PUBLIC_IP:$port > /dev/null; then
        echo -e "${GREEN}✅ Port $port is accessible${NC}"
    else
        echo -e "${RED}❌ Port $port is not accessible${NC}"
    fi
done

# SSH and check services
echo -e "\n${YELLOW}🔍 Checking services on instance...${NC}"
ssh -i ~/.ssh/$KEY_PAIR_NAME.pem -o StrictHostKeyChecking=no -o ConnectTimeout=10 ec2-user@$PUBLIC_IP << 'EOF'
    echo "=== Docker Status ==="
    sudo systemctl status docker --no-pager -l
    
    echo -e "\n=== Docker Compose Services ==="
    cd /opt/applications
    docker-compose ps
    
    echo -e "\n=== Container Logs (last 20 lines) ==="
    echo "--- Main Nginx ---"
    docker logs --tail 20 main-nginx 2>/dev/null || echo "Container not found"
    
    echo -e "\n--- HelloProject Nginx ---"
    docker logs --tail 20 helloproject-nginx 2>/dev/null || echo "Container not found"
    
    echo -e "\n--- WorldProject Nginx ---"
    docker logs --tail 20 worldproyect-nginx 2>/dev/null || echo "Container not found"
    
    echo -e "\n=== Network Status ==="
    docker network ls
    
    echo -e "\n=== Port Usage ==="
    sudo netstat -tlnp | grep -E ':(80|8001|3000|8000)'
    
    echo -e "\n=== Nginx Configuration Test ==="
    docker exec main-nginx nginx -t 2>/dev/null || echo "Could not test nginx config"
    
    echo -e "\n=== System Resources ==="
    free -h
    df -h
EOF

echo -e "\n${YELLOW}🌐 Testing domain resolution...${NC}"
echo -e "${BLUE}Testing maialejandra.com (HelloProject):${NC}"
curl -s -H "Host: maialejandra.com" http://$PUBLIC_IP | head -n 5 || echo "Failed to connect"

echo -e "\n${BLUE}Testing embyter.com (WorldProject):${NC}"
curl -s -H "Host: embyter.com" http://$PUBLIC_IP | head -n 5 || echo "Failed to connect"

echo -e "\n${BLUE}Testing WorldProject on port 8001:${NC}"
curl -s http://$PUBLIC_IP:8001 | head -n 5 || echo "Failed to connect"

echo -e "\n${GREEN}🎉 Diagnostic completed!${NC}"
echo -e "${YELLOW}📝 If you see issues, check the logs above for more details.${NC}"