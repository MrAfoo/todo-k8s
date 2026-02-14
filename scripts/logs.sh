#!/bin/bash
# View logs from Kubernetes pods

set -e

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

NAMESPACE="todo-app"
COMPONENT=${1:-all}

echo -e "${GREEN}📋 Viewing logs for: ${COMPONENT}${NC}"
echo ""

case $COMPONENT in
    backend)
        kubectl logs -n $NAMESPACE -l app=backend --tail=100 -f
        ;;
    frontend)
        kubectl logs -n $NAMESPACE -l app=frontend --tail=100 -f
        ;;
    postgres)
        kubectl logs -n $NAMESPACE -l app=postgres --tail=100 -f
        ;;
    all)
        echo -e "${YELLOW}Available components: backend, frontend, postgres${NC}"
        echo "Usage: $0 [backend|frontend|postgres]"
        echo ""
        echo -e "${GREEN}Current pods:${NC}"
        kubectl get pods -n $NAMESPACE
        ;;
    *)
        echo -e "${YELLOW}Unknown component: $COMPONENT${NC}"
        echo "Available: backend, frontend, postgres"
        exit 1
        ;;
esac
