# AI Agent Guidelines for Todo App Kubernetes Deployment

This file contains context and best practices for AI agents (kubectl-ai, Kagent, Gordon) working with this Kubernetes deployment.

## Project Overview

Full-stack Todo application with AI-powered features, deployed using cloud-native Kubernetes practices.

**Stack:**
- Frontend: Next.js 14 (TypeScript, Tailwind CSS)
- Backend: FastAPI (Python 3.13)
- Database: PostgreSQL 16
- AI: Groq API (Llama 3.3 70B)

## Deployment Architecture

### Components
1. **Frontend**: Stateless Next.js app (2+ replicas)
2. **Backend**: Stateless FastAPI app (2+ replicas)
3. **MCP Server**: Stateless MCP tool server (2+ replicas) - Provides AI task management tools
4. **PostgreSQL**: Stateful database (1 replica with PVC)

### Namespaces
- Local/Dev: `todo-app`
- Staging: `todo-app-staging`
- Production: `todo-app`

### Services
- `postgres` (ClusterIP:5432) - Database
- `backend` (ClusterIP:8000) - API
- `mcp-server` (ClusterIP:8001) - MCP Tools Server
- `frontend` (LoadBalancer:80) - Web UI

## Common AI Agent Commands

### Deployment

```bash
# Deploy everything (Helm - recommended)
kubectl-ai deploy todo app using helm chart at ./helm/todo-app

# Deploy with kubectl
kubectl-ai apply all manifests in k8s directory in correct order

# Check deployment status
kubectl-ai show status of all pods in todo-app namespace
```

### Scaling

```bash
# Scale backend
kubectl-ai scale backend deployment to 5 replicas in todo-app namespace

# Scale MCP server
kubectl-ai scale mcp deployment to 3 replicas in todo-app namespace

# Scale frontend
kubectl-ai scale frontend deployment to 5 replicas in todo-app namespace

# Enable autoscaling
kubectl-ai enable horizontal pod autoscaler for backend with min 3 max 10 replicas at 70% CPU
```

### Debugging

```bash
# Check pod issues
kubectl-ai show logs for backend pods in todo-app namespace
kubectl-ai show logs for mcp pods in todo-app namespace

# Describe problematic pod
kubectl-ai describe pod with issues in todo-app namespace

# Check events
kubectl-ai show recent events in todo-app namespace sorted by time
```

### Configuration Updates

```bash
# Update backend config
kubectl-ai update backend-config configmap with DEBUG=True in todo-app namespace

# Restart deployments after config change
kubectl-ai restart backend deployment in todo-app namespace
```

### Database Operations

```bash
# Connect to PostgreSQL
kubectl-ai exec into postgres pod and run psql as postgres user

# Backup database
kubectl-ai exec postgres pod and dump database todo_db to stdout

# Check database connection
kubectl-ai test connection from backend pod to postgres service
```

## File Locations

### Configuration
- **Helm values**: `helm/todo-app/values.yaml` (default), `values-staging.yaml`, `values-production.yaml`
- **K8s manifests**: `k8s/*.yaml`
- **Secrets**: `k8s/*-secret.yaml` (⚠️ contains defaults, must be updated for production)

### Deployment Scripts
- **Setup**: `scripts/minikube-setup.{sh,ps1}`
- **Build**: `scripts/build-images.{sh,ps1}`
- **Deploy**: `scripts/deploy-helm.{sh,ps1}` or `scripts/deploy-k8s.{sh,ps1}`
- **Logs**: `scripts/logs.{sh,ps1}`
- **Cleanup**: `scripts/cleanup.{sh,ps1}`

### Documentation
- **Quick Start**: `QUICK_START_K8S.md` (5-minute setup)
- **Complete Guide**: `KUBERNETES.md` (comprehensive)
- **Helm Chart**: `helm/todo-app/README.md`
- **Summary**: `DEPLOYMENT_SUMMARY.md`

## Environment Variables

### Backend
**From ConfigMap** (`backend-config`):
- `ALGORITHM=HS256`
- `ACCESS_TOKEN_EXPIRE_MINUTES=30`
- `DEBUG=False`
- `ALLOWED_ORIGINS=http://localhost:3000,http://frontend:3000`

**From Secrets** (`backend-secret`):
- `BETTER_AUTH_SECRET` - JWT signing key (⚠️ change in production)
- `SECRET_KEY` - Application secret (⚠️ change in production)
- `GROQ_API_KEY` - Groq API key for AI features

**Constructed**:
- `DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/todo_db`

### MCP Server
**From ConfigMap** (`mcp-config`):
- `LOG_LEVEL=INFO`
- `SERVICE_NAME=mcp-server`

**Constructed**:
- `DATABASE_URL=postgresql://postgres:${POSTGRES_PASSWORD}@postgres:5432/todo_db`

### Frontend
- `NEXT_PUBLIC_API_URL=http://backend:8000`
- `NODE_ENV=production`

### PostgreSQL
**From ConfigMap** (`postgres-config`):
- `POSTGRES_DB=todo_db`
- `POSTGRES_USER=postgres`

**From Secret** (`postgres-secret`):
- `POSTGRES_PASSWORD` (⚠️ change in production)

## Resource Limits

Default resource specifications:

```yaml
resources:
  requests:
    memory: 256Mi
    cpu: 250m
  limits:
    memory: 512Mi
    cpu: 500m
```

Production recommendations:
- Backend: 512Mi-1Gi RAM, 500m-1000m CPU
- MCP Server: 256Mi-512Mi RAM, 250m-500m CPU
- Frontend: 512Mi-1Gi RAM, 500m-1000m CPU
- PostgreSQL: 2Gi-4Gi RAM, 1000m-2000m CPU

## Health Checks

All services have liveness and readiness probes:

**Backend**:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8000
readinessProbe:
  httpGet:
    path: /health
    port: 8000
```

**MCP Server**:
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8001
readinessProbe:
  httpGet:
    path: /health
    port: 8001
```

**Frontend**:
```yaml
livenessProbe:
  httpGet:
    path: /
    port: 3000
readinessProbe:
  httpGet:
    path: /
    port: 3000
```

**PostgreSQL**:
```yaml
livenessProbe:
  exec:
    command: [pg_isready, -U, postgres]
readinessProbe:
  exec:
    command: [pg_isready, -U, postgres]
```

## Security Considerations

1. **Non-root containers**: All services run as non-root users
2. **Secrets management**: Use external secret managers in production
3. **Network policies**: Consider implementing for production
4. **RBAC**: Apply principle of least privilege
5. **Image scanning**: Scan for vulnerabilities before deployment

## Troubleshooting Patterns

### Pod Won't Start
```bash
kubectl-ai describe pod <failing-pod> in todo-app namespace
kubectl-ai show logs for <failing-pod> in todo-app namespace
kubectl-ai get events in todo-app namespace showing errors
```

### Database Connection Issues
```bash
# Check PostgreSQL is ready
kubectl-ai check if postgres pod is running in todo-app namespace

# Test connection from backend
kubectl-ai exec into backend pod and test connection to postgres:5432

# Check service endpoints
kubectl-ai show endpoints for postgres service in todo-app namespace
```

### Image Pull Errors
```bash
# For Minikube
kubectl-ai show docker images in minikube docker environment

# Verify image exists
kubectl-ai describe pod <pod-name> and show image pull status
```

### Service Not Accessible
```bash
# Check service
kubectl-ai describe frontend service in todo-app namespace

# Get LoadBalancer IP
kubectl-ai get external IP for frontend service in todo-app namespace

# Port forward for testing
kubectl-ai port-forward frontend service to local port 3000 in todo-app namespace
```

## Helm Operations

### Install/Upgrade
```bash
helm upgrade --install todo-app ./helm/todo-app \
  --namespace todo-app \
  --create-namespace \
  --values ./helm/todo-app/values-production.yaml
```

### Rollback
```bash
helm rollback todo-app -n todo-app
```

### View Values
```bash
helm get values todo-app -n todo-app
```

## CI/CD Integration

GitHub Actions workflow at `.github/workflows/build-and-deploy.yml`:
- Builds Docker images on push
- Pushes to GitHub Container Registry
- Deploys to staging (develop branch)
- Deploys to production (main branch)

Required secrets:
- `KUBE_CONFIG` - Base64 encoded kubeconfig for staging
- `KUBE_CONFIG_PROD` - Base64 encoded kubeconfig for production

## Best Practices for AI Agents

1. **Always check namespace**: Commands should specify `-n todo-app`
2. **Verify before scaling**: Check current replica count first
3. **Use Helm when possible**: Easier to manage than raw manifests
4. **Check events on failures**: `kubectl get events -n todo-app --sort-by='.lastTimestamp'`
5. **Follow deployment order**: PostgreSQL → Backend → MCP Server → Frontend
6. **Wait for readiness**: Use `kubectl wait --for=condition=ready pod -l app=<component>`
7. **Update secrets safely**: Never log secret values
8. **Check resource usage**: Monitor CPU/memory before scaling

## Quick Reference

| Task | Command Pattern |
|------|-----------------|
| Deploy | `helm upgrade --install todo-app ./helm/todo-app -n todo-app` |
| Status | `kubectl get all -n todo-app` |
| Logs | `kubectl logs -l app=backend -n todo-app --tail=100 -f` |
| Scale | `kubectl scale deployment/backend --replicas=5 -n todo-app` |
| Exec | `kubectl exec -it deployment/backend -n todo-app -- /bin/sh` |
| Port Forward | `kubectl port-forward svc/frontend 3000:80 -n todo-app` |
| Restart | `kubectl rollout restart deployment/backend -n todo-app` |
| Events | `kubectl get events -n todo-app --sort-by='.lastTimestamp'` |
| Resources | `kubectl top pods -n todo-app` |

## Platform-Specific Notes

### Minikube
- Use `minikube docker-env` to build images locally
- Access services: `minikube service frontend -n todo-app`
- Dashboard: `minikube dashboard`

### GKE (Google Kubernetes Engine)
- Use Workload Identity for secrets
- Configure Cloud SQL Proxy for PostgreSQL (optional)
- Set up GCE Ingress for external access

### EKS (Amazon EKS)
- Use IAM roles for service accounts
- Configure ALB Ingress Controller
- Consider RDS for PostgreSQL (optional)

### AKS (Azure Kubernetes Service)
- Use Azure AD Pod Identity
- Configure Application Gateway Ingress
- Consider Azure Database for PostgreSQL (optional)

## Monitoring Recommendations

1. **Metrics Server**: Enabled by default in Minikube
2. **Prometheus**: For detailed metrics collection
3. **Grafana**: For visualization
4. **Loki**: For log aggregation
5. **Jaeger**: For distributed tracing (if needed)

## Further Reading

- [KUBERNETES.md](./KUBERNETES.md) - Complete deployment guide
- [QUICK_START_K8S.md](./QUICK_START_K8S.md) - Quick start guide
- [helm/todo-app/README.md](./helm/todo-app/README.md) - Helm chart documentation
- [Kubernetes Documentation](https://kubernetes.io/docs/)
- [Helm Documentation](https://helm.sh/docs/)

---

**Last Updated**: 2026-02-12
**Kubernetes Version**: 1.28+
**Helm Version**: 3.8+
