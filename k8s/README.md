# Kubernetes Manifests

This directory contains raw Kubernetes YAML manifests for deploying the Todo App.

## Overview

The manifests are organized by resource type and can be applied using `kubectl`.

## Files

### Core Resources
- `namespace.yaml` - Creates the `todo-app` namespace

### PostgreSQL Database
- `postgres-configmap.yaml` - Database configuration
- `postgres-secret.yaml` - Database credentials
- `postgres-pvc.yaml` - Persistent storage claim
- `postgres-deployment.yaml` - Database deployment
- `postgres-service.yaml` - Database service

### Backend API
- `backend-configmap.yaml` - Backend configuration
- `backend-secret.yaml` - Backend secrets (JWT, API keys)
- `backend-deployment.yaml` - Backend deployment (2 replicas)
- `backend-service.yaml` - Backend service

### Frontend
- `frontend-deployment.yaml` - Frontend deployment (2 replicas)
- `frontend-service.yaml` - Frontend LoadBalancer service

## Usage

### Quick Deploy

```bash
# Deploy everything
kubectl apply -f k8s/

# Or use the deployment script
./scripts/deploy-k8s.sh
```

### Manual Deployment (Recommended Order)

```bash
# 1. Create namespace
kubectl apply -f namespace.yaml

# 2. Create ConfigMaps and Secrets
kubectl apply -f postgres-configmap.yaml
kubectl apply -f postgres-secret.yaml
kubectl apply -f backend-configmap.yaml
kubectl apply -f backend-secret.yaml

# 3. Create storage
kubectl apply -f postgres-pvc.yaml

# 4. Deploy PostgreSQL
kubectl apply -f postgres-deployment.yaml
kubectl apply -f postgres-service.yaml

# Wait for PostgreSQL to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n todo-app --timeout=300s

# 5. Deploy Backend
kubectl apply -f backend-deployment.yaml
kubectl apply -f backend-service.yaml

# Wait for Backend to be ready
kubectl wait --for=condition=ready pod -l app=backend -n todo-app --timeout=300s

# 6. Deploy Frontend
kubectl apply -f frontend-deployment.yaml
kubectl apply -f frontend-service.yaml
```

### Verify Deployment

```bash
# Check all resources
kubectl get all -n todo-app

# Check specific resources
kubectl get pods -n todo-app
kubectl get services -n todo-app
kubectl get deployments -n todo-app
```

## Configuration

### Secrets (⚠️ IMPORTANT)

The default secrets in `postgres-secret.yaml` and `backend-secret.yaml` are **NOT SECURE** and should be changed before production deployment.

**Update secrets:**

```bash
# Generate secure password
POSTGRES_PASSWORD=$(openssl rand -base64 32)
BETTER_AUTH_SECRET=$(openssl rand -base64 32)

# Create secret from command line
kubectl create secret generic postgres-secret \
  --from-literal=POSTGRES_PASSWORD="$POSTGRES_PASSWORD" \
  -n todo-app --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret generic backend-secret \
  --from-literal=BETTER_AUTH_SECRET="$BETTER_AUTH_SECRET" \
  --from-literal=SECRET_KEY="$(openssl rand -base64 32)" \
  --from-literal=GROQ_API_KEY="your-groq-api-key" \
  -n todo-app --dry-run=client -o yaml | kubectl apply -f -
```

### Environment Variables

**Backend ConfigMap** (`backend-configmap.yaml`):
- `ALGORITHM`: JWT algorithm (default: HS256)
- `ACCESS_TOKEN_EXPIRE_MINUTES`: Token expiration (default: 30)
- `DEBUG`: Debug mode (default: False)
- `ALLOWED_ORIGINS`: CORS origins

**Frontend Environment** (in `frontend-deployment.yaml`):
- `NEXT_PUBLIC_API_URL`: Backend API URL
- `NODE_ENV`: Node environment (production)

## Cleanup

```bash
# Delete all resources
kubectl delete -f k8s/

# Or use the cleanup script
./scripts/cleanup.sh
```

## Using Helm Instead

For easier management and templating, consider using the Helm chart instead:

```bash
helm install todo-app ./helm/todo-app --namespace todo-app --create-namespace
```

See [helm/todo-app/README.md](../helm/todo-app/README.md) for details.

## Troubleshooting

### Pods not starting

```bash
kubectl describe pod <pod-name> -n todo-app
kubectl logs <pod-name> -n todo-app
```

### Check events

```bash
kubectl get events -n todo-app --sort-by='.lastTimestamp'
```

### Port forward for debugging

```bash
kubectl port-forward -n todo-app svc/backend 8000:8000
kubectl port-forward -n todo-app svc/frontend 3000:80
kubectl port-forward -n todo-app svc/postgres 5432:5432
```

## Production Recommendations

1. **Use external secret management** (Sealed Secrets, External Secrets Operator)
2. **Configure resource limits** based on your workload
3. **Enable autoscaling** with HorizontalPodAutoscaler
4. **Set up ingress** with TLS certificates
5. **Configure monitoring** and logging
6. **Use the Helm chart** for easier management

For production deployment, see [KUBERNETES.md](../KUBERNETES.md).
