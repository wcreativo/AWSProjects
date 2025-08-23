#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Production Deployment${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Stop existing containers
echo -e "${YELLOW}🛑 Stopping existing containers...${NC}"
docker-compose down

# Remove old images
echo -e "${YELLOW}🧹 Cleaning up old images...${NC}"
docker system prune -f

# Build and start all services
echo -e "${YELLOW}📦 Building and starting all services...${NC}"
docker-compose up --build -d

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 60

# Check service status
echo -e "${BLUE}📊 Service Status:${NC}"
docker-compose ps

# Health checks
echo -e "${YELLOW}🏥 Running health checks...${NC}"

# Check HelloProject
if curl -f http://localhost/api/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ HelloProject API is healthy${NC}"
else
    echo -e "${RED}❌ HelloProject API is not responding${NC}"
fi

# Check WorldProyect
if curl -f http://localhost:8001/api/ > /dev/null 2>&1; then
    echo -e "${GREEN}✅ WorldProyect API is healthy${NC}"
else
    echo -e "${RED}❌ WorldProyect API is not responding${NC}"
fi

echo -e "${GREEN}✅ Production deployment completed!${NC}"
echo -e "${BLUE}📱 Your applications are available at:${NC}"
echo -e "${GREEN}   • HelloProject: http://localhost${NC}"
echo -e "${GREEN}   • WorldProyect: http://localhost:8001${NC}"
echo -e "${BLUE}🔧 To view logs: docker-compose logs -f${NC}"
echo -e "${BLUE}🛑 To stop: docker-compose down${NC}"
