#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Fresh Deployment Script${NC}"
echo -e "${BLUE}==========================${NC}"

# Configuration
STACK_NAME="aws-projects-stack"
REGION="us-east-1"

# Check if stack exists
echo -e "${YELLOW}🔍 Checking for existing stack...${NC}"
STACK_EXISTS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION 2>/dev/null)

if [ $? -eq 0 ]; then
    echo -e "${YELLOW}⚠️  Stack '$STACK_NAME' already exists${NC}"
    echo -e "${BLUE}💡 You need to delete it first using: ./scripts/cleanup-stack.sh${NC}"
    
    read -p "Do you want to delete the existing stack and continue? (yes/no): " delete_confirmation
    
    if [ "$delete_confirmation" = "yes" ]; then
        echo -e "${YELLOW}🗑️  Deleting existing stack...${NC}"
        ./scripts/cleanup-stack.sh
        
        if [ $? -ne 0 ]; then
            echo -e "${RED}❌ Failed to delete existing stack${NC}"
            exit 1
        fi
        
        echo -e "${YELLOW}⏳ Waiting a moment before creating new stack...${NC}"
        sleep 10
    else
        echo -e "${YELLOW}❌ Deployment cancelled${NC}"
        exit 0
    fi
fi

echo -e "\n${BLUE}🚀 Starting fresh deployment...${NC}"

# Run the deployment
cd infrastructure
./deploy.sh

if [ $? -eq 0 ]; then
    echo -e "\n${GREEN}🎉 Fresh deployment completed successfully!${NC}"
    
    # Get the new public IP
    PUBLIC_IP=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' \
        --output text 2>/dev/null)
    
    if [ ! -z "$PUBLIC_IP" ]; then
        echo -e "\n${BLUE}📱 Your applications are now available at:${NC}"
        echo -e "${GREEN}   • HelloProject (maialejandra.com): http://$PUBLIC_IP${NC}"
        echo -e "${GREEN}   • EscapeRooms (escaperooms21.com): http://$PUBLIC_IP${NC}"
        echo -e "\n${YELLOW}📝 DNS Configuration:${NC}"
        echo -e "${BLUE}   Point your domains to: $PUBLIC_IP${NC}"
        echo -e "${BLUE}   • maialejandra.com → $PUBLIC_IP${NC}"
        echo -e "${BLUE}   • escaperooms21.com → $PUBLIC_IP${NC}"
    fi
    
    echo -e "\n${YELLOW}🔍 Run './scripts/diagnose.sh' to verify everything is working${NC}"
else
    echo -e "${RED}❌ Fresh deployment failed${NC}"
    exit 1
fi