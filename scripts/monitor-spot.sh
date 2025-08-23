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

echo -e "${BLUE}🔍 Spot Instance Monitor${NC}"

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

# Get Spot Instance Request ID
SPOT_REQUEST_ID=$(aws cloudformation describe-stacks \
    --stack-name $STACK_NAME \
    --region $REGION \
    --query 'Stacks[0].Outputs[?OutputKey==`SpotInstanceRequestId`].OutputValue' \
    --output text 2>/dev/null)

if [ -z "$SPOT_REQUEST_ID" ]; then
    echo -e "${RED}❌ Could not find Spot Instance Request ID. Is the stack deployed?${NC}"
    exit 1
fi

echo -e "${GREEN}📋 Spot Instance Request ID: $SPOT_REQUEST_ID${NC}"

# Get Spot Instance Request status
echo -e "${BLUE}📊 Spot Instance Request Status:${NC}"
aws ec2 describe-spot-instance-requests \
    --spot-instance-request-ids $SPOT_REQUEST_ID \
    --region $REGION \
    --query 'SpotInstanceRequests[0].[State,InstanceId,SpotPrice]' \
    --output table

# Get instance details
echo -e "${BLUE}🖥️ Instance Details:${NC}"
INSTANCE_ID=$(aws ec2 describe-spot-instance-requests \
    --spot-instance-request-ids $SPOT_REQUEST_ID \
    --region $REGION \
    --query 'SpotInstanceRequests[0].InstanceId' \
    --output text 2>/dev/null)

if [ "$INSTANCE_ID" = "None" ] || [ -z "$INSTANCE_ID" ]; then
    echo -e "${YELLOW}⚠️ No active instance found${NC}"
else
    echo -e "${GREEN}✅ Instance ID: $INSTANCE_ID${NC}"
    
    # Get instance state
    INSTANCE_STATE=$(aws ec2 describe-instances \
        --instance-ids $INSTANCE_ID \
        --region $REGION \
        --query 'Reservations[0].Instances[0].State.Name' \
        --output text 2>/dev/null)
    
    echo -e "${GREEN}📊 Instance State: $INSTANCE_STATE${NC}"
fi

# Get Spot price history
echo -e "${BLUE}💰 Spot Price History (Last 24 hours):${NC}"
aws ec2 describe-spot-price-history \
    --instance-types t3.medium \
    --product-description "Linux/UNIX" \
    --start-time $(date -u -d '24 hours ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --region $REGION \
    --query 'SpotPriceHistory[0:5].[Timestamp,SpotPrice,AvailabilityZone]' \
    --output table

# Get CloudWatch metrics
echo -e "${BLUE}📈 CloudWatch Metrics (Last 1 hour):${NC}"
echo -e "${YELLOW}Note: Metrics may take a few minutes to appear${NC}"

# Get CPU utilization
CPU_UTILIZATION=$(aws cloudwatch get-metric-statistics \
    --namespace AWS/EC2 \
    --metric-name CPUUtilization \
    --dimensions Name=AutoScalingGroupName,Value=$STACK_NAME \
    --start-time $(date -u -d '1 hour ago' +%Y-%m-%dT%H:%M:%S) \
    --end-time $(date -u +%Y-%m-%dT%H:%M:%S) \
    --period 300 \
    --statistics Average \
    --region $REGION \
    --query 'Datapoints[0].Average' \
    --output text 2>/dev/null)

if [ "$CPU_UTILIZATION" != "None" ] && [ -n "$CPU_UTILIZATION" ]; then
    echo -e "${GREEN}CPU Utilization: ${CPU_UTILIZATION}%${NC}"
else
    echo -e "${YELLOW}CPU Utilization: No data available${NC}"
fi

# Cost estimation
echo -e "${BLUE}💵 Cost Estimation:${NC}"
echo -e "${GREEN}Spot Instance (t3.medium): ~$0.0416/hour${NC}"
echo -e "${GREEN}Estimated monthly cost: ~$30-35${NC}"
echo -e "${YELLOW}On-Demand equivalent: ~$0.0416/hour (~$30/month)${NC}"
echo -e "${GREEN}Potential savings: Up to 90% during low-demand periods${NC}"

echo -e "${BLUE}🔗 Useful Commands:${NC}"
echo -e "${YELLOW}View CloudWatch logs: aws logs describe-log-groups${NC}"
echo -e "${YELLOW}Check Spot price: aws ec2 describe-spot-price-history --instance-types t3.medium${NC}"
echo -e "${YELLOW}Monitor costs: aws ce get-cost-and-usage --time-period Start=2024-01-01,End=2024-01-31${NC}"
