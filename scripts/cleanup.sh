#!/bin/bash
# Cleanup Kubernetes resources

set -e

echo "🧹 Cleaning up Todo App resources..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

# Check if using Helm or kubectl
if helm list -n todo-app | grep -q todo-app; then
    echo -e "${YELLOW}🗑️  Uninstalling Helm release...${NC}"
    helm uninstall todo-app -n todo-app
else
    echo -e "${YELLOW}🗑️  Deleting Kubernetes resources...${NC}"
    kubectl delete -f k8s/ --ignore-not-found=true
fi

echo -e "${YELLOW}🗑️  Deleting namespace...${NC}"
kubectl delete namespace todo-app --ignore-not-found=true

echo -e "${GREEN}✅ Cleanup complete!${NC}"

echo ""
read -p "Do you want to stop Minikube? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${YELLOW}⏹️  Stopping Minikube...${NC}"
    minikube stop
    echo -e "${GREEN}✅ Minikube stopped!${NC}"
fi

echo ""
read -p "Do you want to DELETE Minikube cluster? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo -e "${RED}🗑️  Deleting Minikube cluster...${NC}"
    minikube delete
    echo -e "${GREEN}✅ Minikube cluster deleted!${NC}"
fi
