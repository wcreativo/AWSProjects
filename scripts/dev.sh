#!/bin/bash

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo -e "${BLUE}🚀 Starting Development Environment${NC}"

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Build and start all services
echo -e "${YELLOW}📦 Building and starting all services...${NC}"
docker-compose up --build -d

# Wait for services to be ready
echo -e "${YELLOW}⏳ Waiting for services to be ready...${NC}"
sleep 30

# Check service status
echo -e "${BLUE}📊 Service Status:${NC}"
docker-compose ps

echo -e "${GREEN}✅ Development environment is ready!${NC}"
echo -e "${BLUE}📱 Your applications are available at:${NC}"
echo -e "${GREEN}   • HelloProject: http://localhost${NC}"
echo -e "${GREEN}   • WorldProyect: http://localhost:8001${NC}"
echo -e "${BLUE}🔧 To view logs: docker-compose logs -f${NC}"
echo -e "${BLUE}🛑 To stop: docker-compose down${NC}"
