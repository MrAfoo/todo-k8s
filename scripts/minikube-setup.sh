#!/bin/bash
# Minikube setup script for local Kubernetes development

set -e

echo "🚀 Starting Minikube setup for Todo App..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if minikube is installed
if ! command -v minikube &> /dev/null; then
    echo -e "${RED}❌ Minikube is not installed. Please install it first.${NC}"
    echo "Visit: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
fi

# Check if kubectl is installed
if ! command -v kubectl &> /dev/null; then
    echo -e "${RED}❌ kubectl is not installed. Please install it first.${NC}"
    exit 1
fi

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo -e "${YELLOW}⚠️  Helm is not installed. Installing Helm...${NC}"
    curl https://raw.githubusercontent.com/helm/helm/main/scripts/get-helm-3 | bash
fi

# Start Minikube with recommended settings
echo -e "${GREEN}📦 Starting Minikube cluster...${NC}"
minikube start \
    --cpus=4 \
    --memory=8192 \
    --disk-size=20g \
    --driver=docker \
    --kubernetes-version=v1.28.0

# Enable required addons
echo -e "${GREEN}🔌 Enabling Minikube addons...${NC}"
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable storage-provisioner

# Configure kubectl context
echo -e "${GREEN}⚙️  Configuring kubectl context...${NC}"
kubectl config use-context minikube

# Configure Docker environment to use Minikube's Docker daemon
echo -e "${GREEN}🐳 Configuring Docker environment...${NC}"
eval $(minikube docker-env)

echo -e "${GREEN}✅ Minikube setup complete!${NC}"
echo ""
echo -e "${YELLOW}📝 Next steps:${NC}"
echo "  1. Build Docker images:"
echo "     ./scripts/build-images.sh"
echo ""
echo "  2. Deploy using Helm:"
echo "     ./scripts/deploy-helm.sh"
echo ""
echo "  3. Or deploy using kubectl:"
echo "     ./scripts/deploy-k8s.sh"
echo ""
echo -e "${YELLOW}🔍 Useful commands:${NC}"
echo "  - View cluster status: minikube status"
echo "  - Access dashboard: minikube dashboard"
echo "  - Get service URL: minikube service frontend -n todo-app"
echo "  - Stop cluster: minikube stop"
echo "  - Delete cluster: minikube delete"
