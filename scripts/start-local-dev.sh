#!/bin/bash

# WhatsApp Clone Local Development Environment Startup Script
set -e

echo "🚀 Starting WhatsApp Clone Local Development Environment"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo -e "${RED}❌ Docker is not running. Please start Docker first.${NC}"
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo -e "${RED}❌ docker-compose is not installed. Please install docker-compose first.${NC}"
    exit 1
fi

# Create necessary directories
echo -e "${BLUE}📁 Creating necessary directories...${NC}"
mkdir -p volumes/{db/data,storage,functions,logs}

# Copy environment file and export variables
if [ ! -f .env ]; then
    echo -e "${YELLOW}📝 Copying .env.local to .env...${NC}"
    cp .env.local .env
else
    echo -e "${GREEN}✅ .env file already exists${NC}"
fi

# Export environment variables
echo -e "${BLUE}📋 Loading environment variables...${NC}"
set -a  # automatically export all variables
source .env.local
set +a  # disable automatic export

# Start Supabase services
echo -e "${BLUE}🐳 Starting Supabase services...${NC}"
docker-compose -f docker-compose.local.yml up -d

# Wait for services to be ready
echo -e "${BLUE}⏳ Waiting for services to start...${NC}"
sleep 10

# Check service health
echo -e "${BLUE}🔍 Checking service health...${NC}"

# Check if Kong (API Gateway) is responding
if curl -f http://localhost:8000/health > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Kong API Gateway is ready${NC}"
else
    echo -e "${YELLOW}⚠️  Kong API Gateway is still starting...${NC}"
fi

# Check if Studio is responding
if curl -f http://localhost:3000 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Supabase Studio is ready${NC}"
else
    echo -e "${YELLOW}⚠️  Supabase Studio is still starting...${NC}"
fi

# Check if LiveKit is responding
if curl -f http://localhost:7880 > /dev/null 2>&1; then
    echo -e "${GREEN}✅ LiveKit Server is ready${NC}"
else
    echo -e "${YELLOW}⚠️  LiveKit Server is still starting...${NC}"
fi

# Display service URLs
echo -e "\n${GREEN}🎉 Local Development Environment Started!${NC}\n"
echo -e "${BLUE}Service URLs:${NC}"
echo -e "  📊 Supabase Studio:  http://localhost:3000"
echo -e "  🌐 API Gateway:      http://localhost:8000"
echo -e "  🗄️  Database:         postgresql://postgres:your-super-secret-and-long-postgres-password@localhost:54322/postgres"
echo -e "  📡 Realtime:         ws://localhost:8000/realtime/v1"
echo -e "  📦 Storage:          http://localhost:8000/storage/v1"
echo -e "  🎥 LiveKit Server:   ws://localhost:7880"
echo -e "  🎬 LiveKit Web UI:   http://localhost:7880"

echo -e "\n${BLUE}Environment Variables for Flutter:${NC}"
echo -e "  SUPABASE_URL=http://localhost:8000"
echo -e "  SUPABASE_ANON_KEY=eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZS1kZW1vIiwicm9sZSI6ImFub24iLCJleHAiOjE5ODM4MTI5OTZ9.CRXP1A7WOeoJeXxjNni43kdQwgnWNReilDMblYTn_I0"
echo -e "  LIVEKIT_URL=ws://localhost:7880"
echo -e "  LIVEKIT_API_KEY=devkey"
echo -e "  LIVEKIT_API_SECRET=secret"

echo -e "\n${BLUE}Next Steps:${NC}"
echo -e "  1. 📱 Start Flutter app: ${GREEN}flutter run -d chrome -t lib/main_local.dart${NC}"
echo -e "  2. 🎛️  Open Supabase Studio: ${GREEN}http://localhost:3000${NC}"
echo -e "  3. 🛠️  Configure your database schema in Studio"
echo -e "  4. 🧪 Test your app with local services"

echo -e "\n${BLUE}To stop services:${NC}"
echo -e "  ${GREEN}docker-compose -f docker-compose.local.yml down${NC}"

echo -e "\n${YELLOW}📝 Note: This is a local development environment with mock data.${NC}"
echo -e "${YELLOW}   All data will be lost when you stop the containers.${NC}"