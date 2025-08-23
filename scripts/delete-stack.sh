#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${RED}🗑️  DELETE AWS STACK${NC}"
echo -e "${RED}===================${NC}"

# Configuration
STACK_NAME="aws-projects-stack"
REGION="us-east-1"

# Check if AWS CLI is configured
if ! aws sts get-caller-identity &> /dev/null; then
    echo -e "${RED}❌ AWS CLI is not configured. Please run 'aws configure' first.${NC}"
    exit 1
fi

# Check if stack exists
echo -e "${YELLOW}🔍 Checking if stack exists...${NC}"
STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text 2>/dev/null)

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Stack '$STACK_NAME' does not exist${NC}"
    exit 0
fi

echo -e "${GREEN}✅ Found stack: $STACK_NAME${NC}"
echo -e "${BLUE}📊 Current status: $STACK_STATUS${NC}"

# Get Elastic IP before deletion
ELASTIC_IP=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`PublicIP`].OutputValue' \
    --output text 2>/dev/null)

if [ ! -z "$ELASTIC_IP" ]; then
    echo -e "${YELLOW}📍 Current Elastic IP: $ELASTIC_IP${NC}"
fi

# Show resources that will be deleted
echo -e "\n${YELLOW}📋 Resources that will be PERMANENTLY DELETED:${NC}"
aws cloudformation describe-stack-resources \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'StackResources[].{Type:ResourceType,ID:PhysicalResourceId,Status:ResourceStatus}' \
    --output table

# Final confirmation
echo -e "\n${RED}⚠️  DANGER ZONE ⚠️${NC}"
echo -e "${RED}This will PERMANENTLY DELETE:${NC}"
echo -e "${RED}  • EC2 Instance${NC}"
echo -e "${RED}  • Elastic IP${NC}"
echo -e "${RED}  • Security Groups${NC}"
echo -e "${RED}  • VPC and networking${NC}"
echo -e "${RED}  • All data and configurations${NC}"
echo -e "\n${YELLOW}💡 Your applications will be COMPLETELY REMOVED${NC}"

echo -e "\n${RED}Type 'DELETE' to confirm (case sensitive):${NC}"
read -p "> " confirmation

if [ "$confirmation" != "DELETE" ]; then
    echo -e "${GREEN}✅ Deletion cancelled - Stack preserved${NC}"
    exit 0
fi

# Delete the stack
echo -e "\n${RED}🗑️  DELETING CloudFormation stack...${NC}"
aws cloudformation delete-stack \
    --stack-name $STACK_NAME \
    --region $REGION

if [ $? -eq 0 ]; then
    echo -e "${YELLOW}⏳ Stack deletion initiated...${NC}"
    
    # Show deletion progress
    echo -e "${BLUE}💭 Monitoring deletion progress...${NC}"
    
    # Wait for deletion with progress updates
    while true; do
        CURRENT_STATUS=$(aws cloudformation describe-stacks \
            --stack-name $STACK_NAME \
            --region $REGION \
            --query 'Stacks[0].StackStatus' \
            --output text 2>/dev/null)
        
        if [ $? -ne 0 ]; then
            echo -e "\n${GREEN}🎉 Stack successfully deleted!${NC}"
            break
        fi
        
        echo -e "${YELLOW}⏳ Status: $CURRENT_STATUS${NC}"
        
        if [[ "$CURRENT_STATUS" == *"FAILED"* ]]; then
            echo -e "\n${RED}❌ Stack deletion failed!${NC}"
            echo -e "${YELLOW}📋 Check AWS Console for details${NC}"
            break
        fi
        
        sleep 15
    done
    
    echo -e "\n${GREEN}✅ CLEANUP COMPLETED${NC}"
    echo -e "${BLUE}📝 All AWS resources have been removed${NC}"
    
    if [ ! -z "$ELASTIC_IP" ]; then
        echo -e "${YELLOW}💡 The Elastic IP ($ELASTIC_IP) has been released${NC}"
        echo -e "${YELLOW}💡 Update your DNS records if needed${NC}"
    fi
    
else
    echo -e "${RED}❌ Failed to initiate stack deletion${NC}"
    echo -e "${YELLOW}📋 Check your AWS permissions and try again${NC}"
    exit 1
fi