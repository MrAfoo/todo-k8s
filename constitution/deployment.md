# Deployment Guidelines

**Part of:** Todo App Kubernetes Constitution  
**Version:** 1.0  
**Last Updated:** 2026-02-12

## Overview

This document provides detailed guidelines for deploying the Todo App to Kubernetes environments using Helm charts. It complements the main constitution with operational procedures and best practices.

## Pre-Deployment Checklist

### Local Development (Minikube)

**Prerequisites:**
- [ ] Minikube installed (v1.28+)
- [ ] kubectl installed and configured
- [ ] Helm installed (v3.8+)
- [ ] Docker installed (for image builds)
- [ ] Git repository cloned

**Environment Setup:**
```bash
# Start Minikube cluster
minikube start --cpus=4 --memory=8192 --driver=docker

# Enable required addons
minikube addons enable metrics-server
minikube addons enable ingress

# Verify cluster
kubectl cluster-info
kubectl get nodes
```

### Staging/Production

**Prerequisites:**
- [ ] Kubernetes cluster provisioned (GKE/EKS/AKS)
- [ ] kubectl configured with cluster credentials
- [ ] Helm installed
- [ ] Container registry access configured
- [ ] DNS records configured (if using Ingress)
- [ ] SSL/TLS certificates provisioned
- [ ] Secrets created in cluster

## Deployment Methods

### Method 1: Helm Chart (Recommended)

**Advantages:**
- Atomic deployments
- Easy rollbacks
- Templated configuration
- Release management
- Values file organization

**Quick Deploy:**
```bash
# Deploy with default values (local/dev)
helm upgrade --install todo-app ./helm/todo-app \
  --namespace todo-app \
  --create-namespace

# Deploy to staging
helm upgrade --install todo-app ./helm/todo-app \
  --namespace todo-app-staging \
  --create-namespace \
  --values ./helm/todo-app/values-staging.yaml

# Deploy to production
helm upgrade --install todo-app ./helm/todo-app \
  --namespace todo-app \
  --create-namespace \
  --values ./helm/todo-app/values-production.yaml
```

**Custom Values:**
```bash
# Override specific values
helm upgrade --install todo-app ./helm/todo-app \
  --namespace todo-app \
  --set backend.replicaCount=5 \
  --set frontend.service.type=NodePort \
  --set postgresql.auth.password=MySecurePassword123
```

### Method 2: Raw Kubernetes Manifests

**Use Case:** CI/CD pipelines, GitOps workflows

**Deploy:**
```bash
# Apply all manifests in order
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/postgres-secret.yaml
kubectl apply -f k8s/postgres-configmap.yaml
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/backend-secret.yaml
kubectl apply -f k8s/backend-configmap.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/mcp-deployment.yaml
kubectl apply -f k8s/mcp-service.yaml
kubectl apply -f k8s/frontend-deployment.yaml
kubectl apply -f k8s/frontend-service.yaml

# Or use the script
./scripts/deploy-k8s.sh
```

### Method 3: AI-Assisted with kubectl-ai

**Interactive Deployment:**
```bash
# Natural language deployment
kubectl-ai deploy the todo app using helm chart at ./helm/todo-app

# Check deployment status
kubectl-ai show status of all pods in todo-app namespace

# Troubleshoot issues
kubectl-ai diagnose failing pods in todo-app namespace
```

## Deployment Order

**Critical Order for Raw Manifests:**

1. **Namespace** - Create isolated environment
2. **Secrets** - Must exist before pods reference them
3. **ConfigMaps** - Configuration data for applications
4. **PersistentVolumeClaims** - Storage for database
5. **PostgreSQL** - Database must be ready first
6. **Backend & MCP Server** - Application services
7. **Frontend** - User interface (depends on backend)

**Helm handles this automatically!**

## Configuration Management

### Secrets Configuration

**Development/Local:**
```bash
# Use default secrets (NOT for production)
kubectl create secret generic backend-secret \
  --from-literal=BETTER_AUTH_SECRET=dev-secret-32-chars-minimum-length \
  --from-literal=SECRET_KEY=dev-secret-key \
  --from-literal=GROQ_API_KEY=gsk_your_groq_api_key_here \
  -n todo-app
```

**Production:**
```bash
# Generate secure secrets
BETTER_AUTH_SECRET=$(openssl rand -base64 32)
SECRET_KEY=$(openssl rand -base64 32)

# Create from secure source
kubectl create secret generic backend-secret \
  --from-literal=BETTER_AUTH_SECRET=$BETTER_AUTH_SECRET \
  --from-literal=SECRET_KEY=$SECRET_KEY \
  --from-literal=GROQ_API_KEY=$GROQ_API_KEY \
  -n todo-app

# Or use external secret manager
kubectl apply -f external-secret.yaml
```

### Environment-Specific Values

**values-staging.yaml:**
```yaml
backend:
  replicaCount: 2
  config:
    debug: true  # More logging
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 5

frontend:
  replicaCount: 2

ingress:
  enabled: true
  hosts:
    - host: staging.todo-app.example.com
```

**values-production.yaml:**
```yaml
backend:
  replicaCount: 3
  config:
    debug: false  # Production logging only
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 10
  resources:
    requests:
      memory: "512Mi"
      cpu: "500m"
    limits:
      memory: "1Gi"
      cpu: "1000m"

postgresql:
  persistence:
    size: 20Gi
  resources:
    requests:
      memory: "2Gi"
      cpu: "1000m"

ingress:
  enabled: true
  hosts:
    - host: todo-app.example.com
  tls:
    - secretName: todo-app-tls
      hosts:
        - todo-app.example.com
```

## Post-Deployment Verification

### Automated Verification Script

```bash
./scripts/verify-deployment.sh
```

### Manual Verification Steps

**1. Check Pod Status:**
```bash
kubectl get pods -n todo-app

# Expected output: All pods Running and Ready
NAME                        READY   STATUS    RESTARTS   AGE
backend-xxx                 1/1     Running   0          2m
backend-yyy                 1/1     Running   0          2m
frontend-xxx                1/1     Running   0          2m
frontend-yyy                1/1     Running   0          2m
mcp-server-xxx              1/1     Running   0          2m
postgres-0                  1/1     Running   0          3m
```

**2. Check Services:**
```bash
kubectl get svc -n todo-app

# Expected output: All services with ClusterIP or LoadBalancer
NAME         TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)
backend      ClusterIP      10.96.x.x       <none>        8000/TCP
frontend     LoadBalancer   10.96.x.x       <pending>     80:xxxxx/TCP
mcp-server   ClusterIP      10.96.x.x       <none>        8001/TCP
postgres     ClusterIP      10.96.x.x       <none>        5432/TCP
```

**3. Check Logs:**
```bash
# Backend logs
kubectl logs -l app=backend -n todo-app --tail=50

# Frontend logs
kubectl logs -l app=frontend -n todo-app --tail=50

# MCP Server logs
kubectl logs -l app=mcp-server -n todo-app --tail=50

# PostgreSQL logs
kubectl logs postgres-0 -n todo-app --tail=50
```

**4. Test Health Endpoints:**
```bash
# Port-forward and test
kubectl port-forward svc/backend 8000:8000 -n todo-app &
curl http://localhost:8000/health
# Expected: {"status": "healthy"}

kubectl port-forward svc/mcp-server 8001:8001 -n todo-app &
curl http://localhost:8001/health
# Expected: {"status": "healthy"}
```

**5. Test Frontend Access:**
```bash
# For Minikube
minikube service frontend -n todo-app

# For LoadBalancer
kubectl get svc frontend -n todo-app -o jsonpath='{.status.loadBalancer.ingress[0].ip}'
# Open browser to: http://<EXTERNAL-IP>
```

**6. Verify Database Connection:**
```bash
# Connect to PostgreSQL
kubectl exec -it postgres-0 -n todo-app -- psql -U postgres -d todo_db

# Run test query
\dt  # List tables (should show users, tasks, conversations)
SELECT COUNT(*) FROM users;  # Should work without error
\q
```

## Monitoring Setup

### Metrics Collection

**Enable Metrics Server:**
```bash
# Minikube
minikube addons enable metrics-server

# Other clusters
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml
```

**View Resource Usage:**
```bash
kubectl top nodes
kubectl top pods -n todo-app
```

### Log Aggregation

**View Logs:**
```bash
# All backend logs
kubectl logs -l app=backend -n todo-app --tail=100 -f

# All logs in namespace
kubectl logs -l app -n todo-app --all-containers=true --tail=100 -f

# Logs from specific time
kubectl logs deployment/backend -n todo-app --since=1h
```

**Export Logs:**
```bash
# Export to file for analysis
kubectl logs -l app=backend -n todo-app --tail=1000 > backend-logs.txt
```

## Scaling Operations

### Manual Scaling

```bash
# Scale backend
kubectl scale deployment backend --replicas=5 -n todo-app

# Scale frontend
kubectl scale deployment frontend --replicas=5 -n todo-app

# Scale MCP server
kubectl scale deployment mcp-server --replicas=3 -n todo-app
```

### Autoscaling

**Enable HPA via Helm:**
```yaml
# values.yaml
backend:
  autoscaling:
    enabled: true
    minReplicas: 2
    maxReplicas: 10
    targetCPUUtilizationPercentage: 70
```

**Manual HPA Creation:**
```bash
kubectl autoscale deployment backend \
  --min=2 --max=10 --cpu-percent=70 \
  -n todo-app
```

**Monitor Autoscaling:**
```bash
kubectl get hpa -n todo-app
kubectl describe hpa backend -n todo-app
```

## Rollback Procedures

### Helm Rollback

```bash
# List releases
helm list -n todo-app

# View history
helm history todo-app -n todo-app

# Rollback to previous version
helm rollback todo-app -n todo-app

# Rollback to specific revision
helm rollback todo-app 3 -n todo-app
```

### Deployment Rollback

```bash
# Rollback backend deployment
kubectl rollout undo deployment/backend -n todo-app

# Rollback to specific revision
kubectl rollout undo deployment/backend --to-revision=2 -n todo-app

# Check rollout status
kubectl rollout status deployment/backend -n todo-app
```

## Troubleshooting

### Common Issues

**1. Pods Not Starting**
```bash
# Check pod events
kubectl describe pod <pod-name> -n todo-app

# Common causes:
# - Image pull errors (check image name/tag)
# - Resource limits (check node capacity)
# - Failed health checks (check logs)
```

**2. Database Connection Errors**
```bash
# Verify PostgreSQL is running
kubectl get pods -l app=postgres -n todo-app

# Check service endpoints
kubectl get endpoints postgres -n todo-app

# Test connection from backend pod
kubectl exec -it deployment/backend -n todo-app -- \
  nc -zv postgres 5432
```

**3. Frontend Not Accessible**
```bash
# Check frontend service
kubectl get svc frontend -n todo-app

# For LoadBalancer, check external IP
kubectl describe svc frontend -n todo-app

# For Minikube, use tunnel
minikube tunnel  # Run in separate terminal
```

**4. High Memory/CPU Usage**
```bash
# Check resource usage
kubectl top pods -n todo-app

# View resource limits
kubectl describe deployment backend -n todo-app | grep -A 5 Limits

# Increase limits if needed (Helm)
helm upgrade todo-app ./helm/todo-app \
  --set backend.resources.limits.memory=1Gi \
  -n todo-app
```

## Backup and Recovery

### Database Backup

**Manual Backup:**
```bash
# Dump database
kubectl exec postgres-0 -n todo-app -- \
  pg_dump -U postgres todo_db > backup-$(date +%Y%m%d).sql

# Copy from pod
kubectl cp todo-app/postgres-0:/tmp/backup.sql ./backup.sql
```

**Automated Backup (CronJob):**
```yaml
# See k8s/backup-cronjob.yaml
apiVersion: batch/v1
kind: CronJob
metadata:
  name: postgres-backup
spec:
  schedule: "0 2 * * *"  # Daily at 2 AM
  jobTemplate:
    spec:
      template:
        spec:
          containers:
          - name: backup
            image: postgres:16-alpine
            command:
            - sh
            - -c
            - pg_dump -U postgres -h postgres todo_db > /backup/backup-$(date +%Y%m%d).sql
```

### Disaster Recovery

**Restore from Backup:**
```bash
# Copy backup to pod
kubectl cp ./backup.sql todo-app/postgres-0:/tmp/backup.sql

# Restore database
kubectl exec postgres-0 -n todo-app -- \
  psql -U postgres -d todo_db -f /tmp/backup.sql
```

## CI/CD Integration

### GitHub Actions

**See:** `.github/workflows/build-and-deploy.yml`

**Workflow:**
1. Code push to `develop` or `main`
2. Build Docker images
3. Push to GitHub Container Registry
4. Update Helm values with new image tags
5. Deploy to staging (develop) or production (main)
6. Run smoke tests
7. Send notifications

### Manual CI/CD Trigger

```bash
# Build and push images
./scripts/build-images.sh --push

# Deploy with new images
helm upgrade todo-app ./helm/todo-app \
  --set backend.image.tag=v1.2.3 \
  --set frontend.image.tag=v1.2.3 \
  -n todo-app
```

## Best Practices

1. **Always use Helm for deployments** - Easier management and rollbacks
2. **Never commit secrets** - Use Kubernetes Secrets or external managers
3. **Test in staging first** - Validate changes before production
4. **Monitor after deployment** - Watch logs and metrics for 15+ minutes
5. **Use resource limits** - Prevent resource exhaustion
6. **Enable autoscaling** - Handle traffic spikes automatically
7. **Regular backups** - Automate database backups
8. **Document changes** - Update ADRs and changelogs
9. **Use AI DevOps tools** - Gordon, kubectl-ai, Kagent for efficiency
10. **Follow deployment checklist** - Consistency prevents errors

---

**See Also:**
- [Main Constitution](./MAIN.md)
- [Security Best Practices](./security.md)
- [AI DevOps Integration](./ai-devops.md)
