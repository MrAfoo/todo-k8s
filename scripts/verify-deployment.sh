#!/bin/bash
# Verification script for Kubernetes deployment

set -e

echo "🔍 Verifying Kubernetes Deployment Files..."
echo ""

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

ERRORS=0

# Check Dockerfiles
echo -e "${YELLOW}Checking Dockerfiles...${NC}"
for file in backend/Dockerfile frontend/Dockerfile backend/.dockerignore frontend/.dockerignore; do
    if [ -f "$file" ]; then
        echo -e "${GREEN}✓${NC} $file"
    else
        echo -e "${RED}✗${NC} $file missing"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# Check Kubernetes manifests
echo -e "${YELLOW}Checking Kubernetes manifests...${NC}"
K8S_FILES=(
    "namespace.yaml"
    "postgres-configmap.yaml"
    "postgres-secret.yaml"
    "postgres-pvc.yaml"
    "postgres-deployment.yaml"
    "postgres-service.yaml"
    "backend-configmap.yaml"
    "backend-secret.yaml"
    "backend-deployment.yaml"
    "backend-service.yaml"
    "frontend-deployment.yaml"
    "frontend-service.yaml"
)

for file in "${K8S_FILES[@]}"; do
    if [ -f "k8s/$file" ]; then
        echo -e "${GREEN}✓${NC} k8s/$file"
    else
        echo -e "${RED}✗${NC} k8s/$file missing"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# Check Helm chart
echo -e "${YELLOW}Checking Helm chart...${NC}"
HELM_FILES=(
    "Chart.yaml"
    "values.yaml"
    "values-staging.yaml"
    "values-production.yaml"
    "README.md"
)

for file in "${HELM_FILES[@]}"; do
    if [ -f "helm/todo-app/$file" ]; then
        echo -e "${GREEN}✓${NC} helm/todo-app/$file"
    else
        echo -e "${RED}✗${NC} helm/todo-app/$file missing"
        ERRORS=$((ERRORS + 1))
    fi
done

# Check templates
TEMPLATE_COUNT=$(find helm/todo-app/templates -name "*.yaml" -o -name "*.txt" | wc -l)
echo -e "${GREEN}✓${NC} helm/todo-app/templates ($TEMPLATE_COUNT files)"
echo ""

# Check scripts
echo -e "${YELLOW}Checking deployment scripts...${NC}"
SCRIPTS=(
    "minikube-setup.sh"
    "build-images.sh"
    "deploy-helm.sh"
    "deploy-k8s.sh"
    "cleanup.sh"
    "logs.sh"
)

for script in "${SCRIPTS[@]}"; do
    if [ -f "scripts/$script" ]; then
        if [ -x "scripts/$script" ]; then
            echo -e "${GREEN}✓${NC} scripts/$script (executable)"
        else
            echo -e "${YELLOW}⚠${NC} scripts/$script (not executable, run: chmod +x scripts/$script)"
        fi
    else
        echo -e "${RED}✗${NC} scripts/$script missing"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# Check documentation
echo -e "${YELLOW}Checking documentation...${NC}"
DOCS=(
    "KUBERNETES.md"
    "QUICK_START_K8S.md"
    "DEPLOYMENT_SUMMARY.md"
    "AGENTS.md"
    "helm/todo-app/README.md"
    "k8s/README.md"
    "scripts/README.md"
)

for doc in "${DOCS[@]}"; do
    if [ -f "$doc" ]; then
        echo -e "${GREEN}✓${NC} $doc"
    else
        echo -e "${RED}✗${NC} $doc missing"
        ERRORS=$((ERRORS + 1))
    fi
done
echo ""

# Check CI/CD
echo -e "${YELLOW}Checking CI/CD...${NC}"
if [ -f ".github/workflows/build-and-deploy.yml" ]; then
    echo -e "${GREEN}✓${NC} .github/workflows/build-and-deploy.yml"
else
    echo -e "${RED}✗${NC} .github/workflows/build-and-deploy.yml missing"
    ERRORS=$((ERRORS + 1))
fi
echo ""

# Summary
echo "=========================================="
if [ $ERRORS -eq 0 ]; then
    echo -e "${GREEN}✅ All deployment files verified successfully!${NC}"
    echo ""
    echo "Next steps:"
    echo "  1. Make scripts executable: chmod +x scripts/*.sh"
    echo "  2. Start Minikube: ./scripts/minikube-setup.sh"
    echo "  3. Build images: ./scripts/build-images.sh"
    echo "  4. Deploy: ./scripts/deploy-helm.sh"
    exit 0
else
    echo -e "${RED}❌ Verification failed with $ERRORS error(s)${NC}"
    exit 1
fi
