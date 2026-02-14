# Todo App Helm Chart

A Helm chart for deploying the Todo App with AI-powered features to Kubernetes.

## Introduction

This chart bootstraps a Todo App deployment on a Kubernetes cluster using the Helm package manager. It includes:

- **Frontend**: Next.js web application
- **Backend**: FastAPI REST API with AI chatbot
- **Database**: PostgreSQL for data persistence

## Prerequisites

- Kubernetes 1.24+
- Helm 3.8+
- PV provisioner support in the underlying infrastructure (for PostgreSQL persistence)

## Installing the Chart

### Quick Install

```bash
helm install todo-app ./helm/todo-app --namespace todo-app --create-namespace
```

### Install with Custom Values

```bash
helm install todo-app ./helm/todo-app \
  --namespace todo-app \
  --create-namespace \
  --values my-values.yaml
```

### Install from Repository (Future)

```bash
helm repo add todo-app https://charts.example.com
helm install todo-app todo-app/todo-app
```

## Uninstalling the Chart

```bash
helm uninstall todo-app --namespace todo-app
```

This removes all Kubernetes components associated with the chart and deletes the release.

## Configuration

The following table lists the configurable parameters of the Todo App chart and their default values.

### Global Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `namespace` | Kubernetes namespace | `todo-app` |
| `global.imagePullPolicy` | Image pull policy | `IfNotPresent` |

### PostgreSQL Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `postgresql.enabled` | Enable PostgreSQL | `true` |
| `postgresql.image.repository` | PostgreSQL image repository | `postgres` |
| `postgresql.image.tag` | PostgreSQL image tag | `16-alpine` |
| `postgresql.persistence.enabled` | Enable persistence | `true` |
| `postgresql.persistence.size` | PVC size | `5Gi` |
| `postgresql.persistence.storageClass` | Storage class | `""` |
| `postgresql.config.database` | Database name | `todo_db` |
| `postgresql.config.user` | Database user | `postgres` |
| `postgresql.auth.password` | Database password | `changeme_postgres_password` ⚠️ |
| `postgresql.resources.requests.memory` | Memory request | `256Mi` |
| `postgresql.resources.requests.cpu` | CPU request | `250m` |
| `postgresql.resources.limits.memory` | Memory limit | `512Mi` |
| `postgresql.resources.limits.cpu` | CPU limit | `500m` |

### Backend Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `backend.enabled` | Enable backend | `true` |
| `backend.replicaCount` | Number of replicas | `2` |
| `backend.image.repository` | Backend image repository | `todo-backend` |
| `backend.image.tag` | Backend image tag | `latest` |
| `backend.service.type` | Service type | `ClusterIP` |
| `backend.service.port` | Service port | `8000` |
| `backend.secrets.betterAuthSecret` | JWT secret | `your-secret-key...` ⚠️ |
| `backend.secrets.secretKey` | App secret key | `your-secret-key...` ⚠️ |
| `backend.secrets.groqApiKey` | Groq API key | `your-groq-api-key...` ⚠️ |
| `backend.config.algorithm` | JWT algorithm | `HS256` |
| `backend.config.accessTokenExpireMinutes` | Token expiration | `30` |
| `backend.config.debug` | Debug mode | `false` |
| `backend.config.allowedOrigins` | CORS origins | `http://localhost:3000,...` |
| `backend.resources.requests.memory` | Memory request | `256Mi` |
| `backend.resources.requests.cpu` | CPU request | `250m` |
| `backend.resources.limits.memory` | Memory limit | `512Mi` |
| `backend.resources.limits.cpu` | CPU limit | `500m` |
| `backend.autoscaling.enabled` | Enable HPA | `false` |
| `backend.autoscaling.minReplicas` | Minimum replicas | `2` |
| `backend.autoscaling.maxReplicas` | Maximum replicas | `10` |
| `backend.autoscaling.targetCPUUtilizationPercentage` | Target CPU % | `80` |

### Frontend Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `frontend.enabled` | Enable frontend | `true` |
| `frontend.replicaCount` | Number of replicas | `2` |
| `frontend.image.repository` | Frontend image repository | `todo-frontend` |
| `frontend.image.tag` | Frontend image tag | `latest` |
| `frontend.service.type` | Service type | `LoadBalancer` |
| `frontend.service.port` | Service port | `80` |
| `frontend.service.targetPort` | Container port | `3000` |
| `frontend.env.nextPublicApiUrl` | Backend API URL | `http://backend:8000` |
| `frontend.env.nodeEnv` | Node environment | `production` |
| `frontend.resources.requests.memory` | Memory request | `256Mi` |
| `frontend.resources.requests.cpu` | CPU request | `250m` |
| `frontend.resources.limits.memory` | Memory limit | `512Mi` |
| `frontend.resources.limits.cpu` | CPU limit | `500m` |
| `frontend.autoscaling.enabled` | Enable HPA | `false` |
| `frontend.autoscaling.minReplicas` | Minimum replicas | `2` |
| `frontend.autoscaling.maxReplicas` | Maximum replicas | `10` |
| `frontend.autoscaling.targetCPUUtilizationPercentage` | Target CPU % | `80` |

### Ingress Parameters

| Parameter | Description | Default |
|-----------|-------------|---------|
| `ingress.enabled` | Enable ingress | `false` |
| `ingress.className` | Ingress class | `nginx` |
| `ingress.annotations` | Ingress annotations | `cert-manager.io/cluster-issuer: "letsencrypt-prod"` |
| `ingress.hosts[0].host` | Hostname | `todo-app.example.com` |
| `ingress.hosts[0].paths[0].path` | Path | `/` |
| `ingress.hosts[0].paths[0].pathType` | Path type | `Prefix` |
| `ingress.tls[0].secretName` | TLS secret | `todo-app-tls` |
| `ingress.tls[0].hosts[0]` | TLS host | `todo-app.example.com` |

## Examples

### Minimal Installation

```bash
helm install todo-app ./helm/todo-app --namespace todo-app --create-namespace
```

### Production Installation with Custom Secrets

```yaml
# production-values.yaml
postgresql:
  auth:
    password: "STRONG_RANDOM_PASSWORD"
  persistence:
    size: 20Gi
    storageClass: fast-ssd

backend:
  replicaCount: 3
  secrets:
    betterAuthSecret: "YOUR_32_CHAR_MINIMUM_SECRET_KEY"
    secretKey: "ANOTHER_SECURE_SECRET_KEY"
    groqApiKey: "gsk_your_actual_groq_api_key"
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 20

frontend:
  replicaCount: 3
  autoscaling:
    enabled: true
    minReplicas: 3
    maxReplicas: 20

ingress:
  enabled: true
  hosts:
    - host: todo.yourdomain.com
      paths:
        - path: /
          pathType: Prefix
  tls:
    - secretName: todo-app-tls
      hosts:
        - todo.yourdomain.com
```

Deploy:

```bash
helm install todo-app ./helm/todo-app \
  --namespace todo-app \
  --create-namespace \
  --values production-values.yaml
```

### Development with NodePort

```yaml
# dev-values.yaml
frontend:
  service:
    type: NodePort

backend:
  replicaCount: 1

postgresql:
  persistence:
    size: 1Gi
```

### High Availability Setup

```yaml
# ha-values.yaml
backend:
  replicaCount: 5
  autoscaling:
    enabled: true
    minReplicas: 5
    maxReplicas: 50
  resources:
    requests:
      memory: 512Mi
      cpu: 500m
    limits:
      memory: 1Gi
      cpu: 1000m

frontend:
  replicaCount: 5
  autoscaling:
    enabled: true
    minReplicas: 5
    maxReplicas: 50
  resources:
    requests:
      memory: 512Mi
      cpu: 500m
    limits:
      memory: 1Gi
      cpu: 1000m

postgresql:
  persistence:
    size: 50Gi
    storageClass: premium-ssd
  resources:
    requests:
      memory: 1Gi
      cpu: 1000m
    limits:
      memory: 2Gi
      cpu: 2000m
```

## Upgrading

### Upgrade Release

```bash
helm upgrade todo-app ./helm/todo-app --namespace todo-app
```

### Upgrade with New Values

```bash
helm upgrade todo-app ./helm/todo-app \
  --namespace todo-app \
  --values new-values.yaml
```

### Set Individual Values

```bash
helm upgrade todo-app ./helm/todo-app \
  --namespace todo-app \
  --set backend.replicaCount=5 \
  --set frontend.replicaCount=5
```

## Rollback

```bash
# View release history
helm history todo-app --namespace todo-app

# Rollback to previous version
helm rollback todo-app --namespace todo-app

# Rollback to specific revision
helm rollback todo-app 2 --namespace todo-app
```

## Accessing the Application

### LoadBalancer (Cloud)

```bash
# Get external IP
kubectl get svc frontend -n todo-app

# Access at http://<EXTERNAL-IP>
```

### Minikube

```bash
minikube service frontend -n todo-app
```

### Port Forward

```bash
kubectl port-forward -n todo-app svc/frontend 3000:80
# Access at http://localhost:3000
```

## Security Recommendations

⚠️ **IMPORTANT**: The default values include placeholder secrets. Always override these in production!

### 1. Use External Secret Management

Consider using:
- **Sealed Secrets**: Encrypt secrets for Git storage
- **External Secrets Operator**: Sync from cloud secret managers
- **HashiCorp Vault**: Enterprise secret management

### 2. Override Default Secrets

Never use default secrets in production:

```bash
helm install todo-app ./helm/todo-app \
  --namespace todo-app \
  --set postgresql.auth.password="$(openssl rand -base64 32)" \
  --set backend.secrets.betterAuthSecret="$(openssl rand -base64 32)" \
  --set backend.secrets.secretKey="$(openssl rand -base64 32)" \
  --set backend.secrets.groqApiKey="your-actual-api-key"
```

### 3. Enable Network Policies

Add network policies to restrict pod-to-pod communication.

### 4. Use TLS/HTTPS

Enable ingress with TLS certificates:

```yaml
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: "letsencrypt-prod"
  tls:
    - secretName: todo-app-tls
      hosts:
        - your-domain.com
```

## Troubleshooting

### View Chart Values

```bash
helm get values todo-app --namespace todo-app
```

### View All Resources

```bash
helm get manifest todo-app --namespace todo-app
```

### Debug Template Rendering

```bash
helm template todo-app ./helm/todo-app --debug
```

### Check Release Status

```bash
helm status todo-app --namespace todo-app
```

## License

Copyright © 2026 Todo App Team
