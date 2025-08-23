#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
STACK_NAME="aws-projects-stack"
REGION="us-east-1"
KEY_PAIR_NAME="aws-projects-key"  # AWS Key Pair name

echo -e "${BLUE}🚀 Starting AWS Multi-Project Infrastructure Deployment${NC}"

# Check if AWS CLI is installed
if ! command -v aws &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if user is authenticated
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

echo -e "${YELLOW}📋 Deploying CloudFormation stack...${NC}"

# Deploy CloudFormation stack
aws cloudformation deploy \
    --template-file cloudformation-template.yaml \
    --stack-name $STACK_NAME \
    --parameter-overrides KeyPairName=$KEY_PAIR_NAME \
    --capabilities CAPABILITY_NAMED_IAM \
    --region $REGION

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ CloudFormation stack deployed successfully!${NC}"
    
    # Get the public IP
    PUBLIC_IP=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' \
        --output text)
    
    # Get the Instance ID
    INSTANCE_ID=$(aws cloudformation describe-stacks \
        --stack-name $STACK_NAME \
        --region $REGION \
        --query 'Stacks[0].Outputs[?OutputKey==`InstanceId`].OutputValue' \
        --output text)
    
    echo -e "${GREEN}🌐 Public IP: $PUBLIC_IP${NC}"
    echo -e "${GREEN}🔧 Instance ID: $INSTANCE_ID${NC}"
    echo -e "${YELLOW}⏳ Waiting for instance to be ready...${NC}"
    
    # Wait for instance to be ready
    echo -e "${BLUE}🔍 Checking instance status...${NC}"
    MAX_ATTEMPTS=30
    ATTEMPT=0
    
    while [ $ATTEMPT -lt $MAX_ATTEMPTS ]; do
        ATTEMPT=$((ATTEMPT + 1))
        echo -e "${YELLOW}⏳ Attempt $ATTEMPT/$MAX_ATTEMPTS - Waiting for instance...${NC}"
        
        # Check if instance is running
        INSTANCE_STATE=$(aws ec2 describe-instances \
            --instance-ids $INSTANCE_ID \
            --region $REGION \
            --query 'Reservations[0].Instances[0].State.Name' \
            --output text 2>/dev/null)
        
        if [ "$INSTANCE_STATE" = "running" ]; then
            echo -e "${GREEN}✅ Instance is running: $INSTANCE_ID${NC}"
            break
        fi
        
        sleep 30
    done
    
    if [ "$INSTANCE_STATE" != "running" ]; then
        echo -e "${RED}❌ Instance is not running after $MAX_ATTEMPTS attempts${NC}"
        exit 1
    fi
    
    # Wait additional time for instance to be fully ready
    echo -e "${YELLOW}⏳ Waiting for instance to be fully ready...${NC}"
    sleep 60
    
    echo -e "${BLUE}📦 Copying application files to server...${NC}"
    
    # Create a temporary deployment package
    tar -czf deployment.tar.gz \
        --exclude='.git' \
        --exclude='node_modules' \
        --exclude='__pycache__' \
        --exclude='*.pyc' \
        --exclude='venv' \
        ../HelloProject ../docker-compose.yml ../nginx ../scripts
    
    # Copy files to server
    echo -e "${BLUE}📦 Copying application files to instance...${NC}"
    scp -i ~/.ssh/$KEY_PAIR_NAME.pem -o StrictHostKeyChecking=no deployment.tar.gz ec2-user@$PUBLIC_IP:/opt/applications/
    
    # Execute deployment commands on server
    echo -e "${BLUE}🚀 Deploying applications on instance...${NC}"
    ssh -i ~/.ssh/$KEY_PAIR_NAME.pem -o StrictHostKeyChecking=no ec2-user@$PUBLIC_IP << 'EOF'
        cd /opt/applications
        tar -xzf deployment.tar.gz
        rm deployment.tar.gz
        
        # Stop any existing containers
        docker-compose down 2>/dev/null || true
        
        # Deploy all projects with the main docker-compose
        docker-compose up -d --build
        
        # Wait for containers to be ready
        sleep 30
        
        # Check container status
        docker-compose ps
        
        echo "Deployment completed!"
        echo "Checking nginx configuration..."
        docker logs main-nginx
EOF
    
    echo -e "${GREEN}🎉 Deployment completed successfully!${NC}"
    echo -e "${BLUE}📱 Your applications are now available at:${NC}"
    echo -e "${GREEN}   • HelloProject: http://$PUBLIC_IP (maialejandra.com)${NC}"
    
else
    echo -e "${RED}❌ CloudFormation deployment failed!${NC}"
    exit 1
fi
