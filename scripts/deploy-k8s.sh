#!/bin/bash
# Deploy to Kubernetes using kubectl

set -e

echo "🚀 Deploying Todo App to Kubernetes..."

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Apply Kubernetes manifests in order
echo -e "${GREEN}📝 Creating namespace...${NC}"
kubectl apply -f k8s/namespace.yaml

echo -e "${GREEN}📝 Creating ConfigMaps and Secrets...${NC}"
kubectl apply -f k8s/postgres-configmap.yaml
kubectl apply -f k8s/postgres-secret.yaml
kubectl apply -f k8s/backend-configmap.yaml
kubectl apply -f k8s/backend-secret.yaml
kubectl apply -f k8s/mcp-configmap.yaml

echo -e "${GREEN}📝 Creating PersistentVolumeClaims...${NC}"
kubectl apply -f k8s/postgres-pvc.yaml

echo -e "${GREEN}📝 Deploying PostgreSQL...${NC}"
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml

echo -e "${YELLOW}⏳ Waiting for PostgreSQL to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=postgres -n todo-app --timeout=300s

echo -e "${GREEN}📝 Deploying Backend API...${NC}"
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml

echo -e "${YELLOW}⏳ Waiting for Backend to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=backend -n todo-app --timeout=300s

echo -e "${GREEN}📝 Deploying MCP Server...${NC}"
kubectl apply -f k8s/mcp-deployment.yaml
kubectl apply -f k8s/mcp-service.yaml

echo -e "${YELLOW}⏳ Waiting for MCP Server to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=mcp -n todo-app --timeout=300s

echo -e "${GREEN}📝 Deploying Frontend...${NC}"
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml

echo -e "${YELLOW}⏳ Waiting for Frontend to be ready...${NC}"
kubectl wait --for=condition=ready pod -l app=frontend -n todo-app --timeout=300s

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
