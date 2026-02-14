#!/bin/bash
# Docker AI Agent (Gordon) compatible build script
# Can be invoked by Gordon or run manually as fallback

set -e

echo "🤖 Docker AI Agent (Gordon) - Image Build Script"
echo "=================================================="

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Configuration
BACKEND_IMAGE="${BACKEND_IMAGE:-todo-backend:latest}"
FRONTEND_IMAGE="${FRONTEND_IMAGE:-todo-frontend:latest}"
REGISTRY="${REGISTRY:-}"
BUILD_CONTEXT="${BUILD_CONTEXT:-minikube}"

# Functions
function check_docker() {
    if ! command -v docker &> /dev/null; then
        echo "❌ Docker is not installed. Please install Docker first."
        exit 1
    fi
    echo -e "${GREEN}✅ Docker is available${NC}"
}

function configure_minikube_docker() {
    if [ "$BUILD_CONTEXT" = "minikube" ]; then
        if command -v minikube &> /dev/null; then
            echo -e "${YELLOW}🐳 Configuring Docker to use Minikube's daemon...${NC}"
            eval $(minikube docker-env)
            echo -e "${GREEN}✅ Using Minikube Docker daemon${NC}"
        else
            echo -e "${YELLOW}⚠️  Minikube not found, using host Docker daemon${NC}"
        fi
    fi
}

function build_backend() {
    echo ""
    echo -e "${BLUE}📦 Building Backend Image...${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    docker build \
        --tag "$BACKEND_IMAGE" \
        --file ./backend/Dockerfile \
        --progress=plain \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        ./backend
    
    echo -e "${GREEN}✅ Backend image built: $BACKEND_IMAGE${NC}"
}

function build_frontend() {
    echo ""
    echo -e "${BLUE}📦 Building Frontend Image...${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Default API URL for Kubernetes
    API_URL="${NEXT_PUBLIC_API_URL:-http://backend:8000}"
    
    docker build \
        --tag "$FRONTEND_IMAGE" \
        --file ./frontend/Dockerfile \
        --build-arg NEXT_PUBLIC_API_URL="$API_URL" \
        --progress=plain \
        --build-arg BUILDKIT_INLINE_CACHE=1 \
        ./frontend
    
    echo -e "${GREEN}✅ Frontend image built: $FRONTEND_IMAGE${NC}"
}

function tag_and_push() {
    if [ -n "$REGISTRY" ]; then
        echo ""
        echo -e "${BLUE}🏷️  Tagging and pushing images to registry...${NC}"
        echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        
        # Tag images
        docker tag "$BACKEND_IMAGE" "$REGISTRY/$BACKEND_IMAGE"
        docker tag "$FRONTEND_IMAGE" "$REGISTRY/$FRONTEND_IMAGE"
        
        # Push images
        docker push "$REGISTRY/$BACKEND_IMAGE"
        docker push "$REGISTRY/$FRONTEND_IMAGE"
        
        echo -e "${GREEN}✅ Images pushed to $REGISTRY${NC}"
    fi
}

function show_summary() {
    echo ""
    echo -e "${GREEN}🎉 Build Complete!${NC}"
    echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    echo ""
    echo "📋 Images created:"
    docker images | grep -E "todo-backend|todo-frontend" | head -2
    echo ""
    
    # Image sizes
    BACKEND_SIZE=$(docker images --format "{{.Size}}" "$BACKEND_IMAGE" | head -1)
    FRONTEND_SIZE=$(docker images --format "{{.Size}}" "$FRONTEND_IMAGE" | head -1)
    
    echo "📊 Image Sizes:"
    echo "  Backend:  $BACKEND_SIZE"
    echo "  Frontend: $FRONTEND_SIZE"
    echo ""
    
    echo -e "${YELLOW}📝 Next Steps:${NC}"
    if [ "$BUILD_CONTEXT" = "minikube" ]; then
        echo "  1. Deploy to Minikube: ./scripts/deploy-helm.sh"
        echo "  2. Or use kubectl-ai: kubectl-ai deploy todo app using helm chart at ./helm/todo-app"
    else
        echo "  1. Deploy to cluster: helm upgrade --install todo-app ./helm/todo-app -n todo-app"
        echo "  2. Or push to registry: REGISTRY=ghcr.io/your-org ./scripts/gordon-build.sh"
    fi
    echo ""
}

# Main execution
echo ""
echo -e "${BLUE}Configuration:${NC}"
echo "  Backend Image:  $BACKEND_IMAGE"
echo "  Frontend Image: $FRONTEND_IMAGE"
echo "  Registry:       ${REGISTRY:-<none - local only>}"
echo "  Build Context:  $BUILD_CONTEXT"
echo ""

check_docker
configure_minikube_docker
build_backend
build_frontend
tag_and_push
show_summary

echo -e "${GREEN}✨ All done!${NC}"
