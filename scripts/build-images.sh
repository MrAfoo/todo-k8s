#!/bin/bash
# Build Docker images for Minikube

set -e

echo "🔨 Building Docker images..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Use Minikube's Docker daemon
echo -e "${YELLOW}🐳 Configuring Docker to use Minikube's daemon...${NC}"
eval $(minikube docker-env)

# Build backend image
echo -e "${GREEN}📦 Building backend image...${NC}"
docker build -t todo-backend:latest ./backend

# Build frontend image
echo -e "${GREEN}📦 Building frontend image...${NC}"
docker build -t todo-frontend:latest \
    --build-arg NEXT_PUBLIC_API_URL=http://backend:8000 \
    ./frontend

echo -e "${GREEN}✅ Docker images built successfully!${NC}"
echo ""
echo "📋 Images created:"
docker images | grep -E "todo-backend|todo-frontend"
echo ""
echo -e "${YELLOW}📝 Next step:${NC}"
echo "  Deploy to Minikube: ./scripts/deploy-helm.sh or ./scripts/deploy-k8s.sh"
