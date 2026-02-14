#!/bin/bash
# Deploy to Kubernetes using Helm

set -e

echo "🚀 Deploying Todo App using Helm..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Check if helm is installed
if ! command -v helm &> /dev/null; then
    echo "❌ Helm is not installed. Please install it first."
    exit 1
fi

# Deploy using Helm
echo -e "${GREEN}📦 Installing/Upgrading Helm chart...${NC}"
helm upgrade --install todo-app ./helm/todo-app \
    --namespace todo-app \
    --create-namespace \
    --wait \
    --timeout 10m

echo ""
echo -e "${GREEN}✅ Deployment complete!${NC}"
echo ""
echo -e "${YELLOW}📊 Deployment status:${NC}"
kubectl get all -n todo-app

echo ""
echo -e "${YELLOW}🌐 Access the application:${NC}"
if command -v minikube &> /dev/null; then
    echo "  Run: minikube service frontend -n todo-app"
else
    echo "  Run: kubectl port-forward -n todo-app svc/frontend 3000:80"
    echo "  Then open: http://localhost:3000"
fi

echo ""
echo -e "${YELLOW}📝 Helm release info:${NC}"
helm list -n todo-app
