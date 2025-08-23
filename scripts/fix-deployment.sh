#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🔧 Fix Deployment Script${NC}"
echo -e "${BLUE}========================${NC}"

# Configuration
STACK_NAME="aws-projects-stack"
REGION="us-east-1"
KEY_PAIR_NAME="aws-projects-key"

# Get instance information
PUBLIC_IP=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' \
    --output text 2>/dev/null)

if [ -z "$PUBLIC_IP" ]; then
    echo -e "${RED}❌ Could not get instance information${NC}"
    exit 1
fi

echo -e "${GREEN}🌐 Connecting to: $PUBLIC_IP${NC}"

# Create updated deployment package
echo -e "${YELLOW}📦 Creating updated deployment package...${NC}"
tar -czf deployment-fix.tar.gz \
    --exclude='.git' \
    --exclude='node_modules' \
    --exclude='__pycache__' \
    --exclude='*.pyc' \
    HelloProject WorldProyect docker-compose.yml nginx

# Copy files to server
echo -e "${BLUE}📦 Copying updated files...${NC}"
scp -i ~/.ssh/$KEY_PAIR_NAME.pem -o StrictHostKeyChecking=no deployment-fix.tar.gz ec2-user@$PUBLIC_IP:/opt/applications/

# Execute fix commands on server
echo -e "${BLUE}🔧 Applying fixes on server...${NC}"
ssh -i ~/.ssh/$KEY_PAIR_NAME.pem -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP << 'EOF'
    cd /opt/applications
    
    echo "Stopping all containers..."
    docker-compose down
    
    echo "Removing old files..."
    rm -rf HelloProject WorldProyect docker-compose.yml nginx
    
    echo "Extracting updated files..."
    tar -xzf deployment-fix.tar.gz
    rm deployment-fix.tar.gz
    
    echo "Rebuilding and starting containers..."
    docker-compose up -d --build
    
    echo "Waiting for services to start..."
    sleep 30
    
    echo "Checking container status..."
    docker-compose ps
    
    echo "Testing nginx configuration..."
    docker exec main-nginx nginx -t
    
    echo "Checking main nginx logs..."
    docker logs main-nginx --tail 10
    
    echo "Fix completed!"
EOF

echo -e "\n${GREEN}🎉 Fix deployment completed!${NC}"
echo -e "${BLUE}📱 Testing applications:${NC}"
echo -e "${GREEN}   • HelloProject: http://$PUBLIC_IP${NC}"
echo -e "${GREEN}   • WorldProject: http://$PUBLIC_IP:8001${NC}"

# Clean up local file
rm -f deployment-fix.tar.gz

echo -e "\n${YELLOW}📝 Run './scripts/diagnose.sh' to verify the fix${NC}"