#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🗑️  AWS Stack Cleanup Script${NC}"
echo -e "${BLUE}=============================${NC}"

# Configuration
STACK_NAME="aws-projects-stack"
REGION="us-east-1"

# Check if stack exists
echo -e "${YELLOW}🔍 Checking if stack exists...${NC}"
STACK_STATUS=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].StackStatus' \
    --output text 2>/dev/null)

if [ $? -ne 0 ]; then
    echo -e "${YELLOW}⚠️  Stack '$STACK_NAME' does not exist or is already deleted${NC}"
    exit 0
fi

echo -e "${GREEN}✅ Found stack: $STACK_NAME (Status: $STACK_STATUS)${NC}"

# Get resources before deletion for confirmation
echo -e "\n${YELLOW}📋 Stack resources that will be deleted:${NC}"
aws cloudformation describe-stack-resources \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'StackResources[].{Type:ResourceType,ID:PhysicalResourceId}' \
    --output table

# Confirmation
echo -e "\n${RED}⚠️  WARNING: This will permanently delete all resources in the stack!${NC}"
read -p "Are you sure you want to delete the stack '$STACK_NAME'? (yes/no): " confirmation

if [ "$confirmation" != "yes" ]; then
    echo -e "${YELLOW}❌ Deletion cancelled${NC}"
    exit 0
fi

# Delete the stack
echo -e "\n${YELLOW}🗑️  Deleting CloudFormation stack...${NC}"
aws cloudformation delete-stack \
    --stack-name $STACK_NAME \
    --region $REGION

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✅ Stack deletion initiated${NC}"
    
    # Wait for deletion to complete
    echo -e "${YELLOW}⏳ Waiting for stack deletion to complete...${NC}"
    echo -e "${BLUE}💡 This may take several minutes...${NC}"
    
    aws cloudformation wait stack-delete-complete \
        --stack-name $STACK_NAME \
        --region $REGION
    
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}🎉 Stack deleted successfully!${NC}"
        echo -e "${GREEN}✅ All AWS resources have been cleaned up${NC}"
    else
        echo -e "${RED}❌ Stack deletion failed or timed out${NC}"
        echo -e "${YELLOW}📋 Check the CloudFormation console for details${NC}"
        
        # Show current stack status
        CURRENT_STATUS=$(aws cloudformation describe-stacks \
            --stack-name $STACK_NAME \
            --region $REGION \
            --query 'Stacks[0].StackStatus' \
            --output text 2>/dev/null)
        
        if [ $? -eq 0 ]; then
            echo -e "${YELLOW}Current status: $CURRENT_STATUS${NC}"
        fi
    fi
else
    echo -e "${RED}❌ Failed to initiate stack deletion${NC}"
    exit 1
fi