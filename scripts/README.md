# Deployment Scripts

Automation scripts for Kubernetes deployment and management.

## Overview

These scripts simplify the deployment and management of the Todo App on Kubernetes, with specific support for Minikube for local development.

## Scripts

### Setup and Build

#### `minikube-setup.sh` / `minikube-setup.ps1`
Sets up a local Minikube cluster with recommended settings.

**Features:**
- Starts Minikube with 4 CPUs and 8GB RAM
- Enables ingress, metrics-server, dashboard, and storage
- Configures kubectl context

**Usage:**
```bash
# Linux/macOS
./scripts/minikube-setup.sh

# Windows
.\scripts\minikube-setup.ps1
```

#### `build-images.sh` / `build-images.ps1`
Builds Docker images for frontend and backend in Minikube's Docker environment.

**Usage:**
```bash
# Linux/macOS
./scripts/build-images.sh

# Windows
.\scripts\build-images.ps1
```

### Deployment

#### `deploy-helm.sh` / `deploy-helm.ps1`
Deploys the application using Helm charts (recommended method).

**Features:**
- Installs/upgrades Helm release
- Waits for all pods to be ready
- Shows deployment status

**Usage:**
```bash
# Linux/macOS
./scripts/deploy-helm.sh

# Windows
.\scripts\deploy-helm.ps1
```

#### `deploy-k8s.sh` / `deploy-k8s.ps1`
Deploys the application using raw kubectl manifests.

**Features:**
- Applies manifests in correct order
- Waits for each component to be ready
- Shows deployment status

**Usage:**
```bash
# Linux/macOS
./scripts/deploy-k8s.sh

# Windows
.\scripts\deploy-k8s.ps1
```

### Monitoring

#### `logs.sh` / `logs.ps1`
View logs from specific components.

**Usage:**
```bash
# Linux/macOS
./scripts/logs.sh backend   # Backend logs
./scripts/logs.sh frontend  # Frontend logs
./scripts/logs.sh postgres  # Database logs
./scripts/logs.sh all       # List all pods

# Windows
.\scripts\logs.ps1 -Component backend
.\scripts\logs.ps1 -Component frontend
.\scripts\logs.ps1 -Component postgres
.\scripts\logs.ps1            # List all pods
```

### Cleanup

#### `cleanup.sh` / `cleanup.ps1`
Removes all Todo App resources from Kubernetes.

**Features:**
- Detects and removes Helm releases or kubectl resources
- Optionally stops/deletes Minikube cluster
- Interactive prompts for safety

**Usage:**
```bash
# Linux/macOS
./scripts/cleanup.sh

# Windows
.\scripts\cleanup.ps1
```

## Complete Workflow

### First Time Setup

**Linux/macOS:**
```bash
# 1. Setup Minikube
./scripts/minikube-setup.sh

# 2. Build images
./scripts/build-images.sh

# 3. Deploy with Helm
./scripts/deploy-helm.sh

# 4. Access application
minikube service frontend -n todo-app
```

**Windows:**
```powershell
# 1. Setup Minikube
.\scripts\minikube-setup.ps1

# 2. Configure Docker environment
minikube docker-env | Invoke-Expression

# 3. Build images
.\scripts\build-images.ps1

# 4. Deploy with Helm
.\scripts\deploy-helm.ps1

# 5. Access application
minikube service frontend -n todo-app
```

### Daily Development

```bash
# Build new images
./scripts/build-images.sh

# Update deployment
./scripts/deploy-helm.sh

# View logs
./scripts/logs.sh backend
```

### Cleanup

```bash
# Remove all resources
./scripts/cleanup.sh
```

## Script Features

### Cross-Platform Support
- **Bash scripts** (`.sh`) for Linux/macOS
- **PowerShell scripts** (`.ps1`) for Windows
- Identical functionality across platforms

### Error Handling
- Scripts exit on error (`set -e` / `$ErrorActionPreference`)
- Dependency checks (kubectl, minikube, helm, docker)
- Clear error messages

### Color Output
- Green for success messages
- Yellow for warnings and prompts
- Red for errors
- Improved readability

### Wait Conditions
- Waits for PostgreSQL before deploying backend
- Waits for backend before deploying frontend
- Ensures clean deployments

## Environment Variables

Scripts use these environment variables:

```bash
NAMESPACE=todo-app              # Kubernetes namespace
MINIKUBE_CPUS=4                # Minikube CPU allocation
MINIKUBE_MEMORY=8192           # Minikube memory (MB)
MINIKUBE_DISK=20g              # Minikube disk size
```

Override if needed:
```bash
NAMESPACE=my-todo ./scripts/deploy-helm.sh
```

## Troubleshooting

### Scripts not executable (Linux/macOS)

```bash
chmod +x scripts/*.sh
```

### Docker environment not configured (Windows)

After running `minikube-setup.ps1`, configure Docker:
```powershell
minikube docker-env | Invoke-Expression
```

### Images not found

Ensure you're using Minikube's Docker daemon:
```bash
# Linux/macOS
eval $(minikube docker-env)

# Windows
minikube docker-env | Invoke-Expression
```

Then rebuild:
```bash
./scripts/build-images.sh
```

### Script execution policy (Windows)

If you get "running scripts is disabled", run PowerShell as Administrator:
```powershell
Set-ExecutionPolicy -ExecutionPolicy RemoteSigned -Scope CurrentUser
```

## Advanced Usage

### Custom Helm Values

```bash
# Deploy with custom values
helm upgrade --install todo-app ./helm/todo-app \
  --namespace todo-app \
  --values my-values.yaml
```

### Deploy to Specific Namespace

```bash
# Modify scripts or use kubectl directly
kubectl apply -f k8s/ --namespace=my-namespace
```

### Build Images for Remote Registry

```bash
# Don't use Minikube's Docker daemon
docker build -t registry.example.com/todo-backend:v1.0 ./backend
docker push registry.example.com/todo-backend:v1.0
```

## CI/CD Integration

These scripts can be used in CI/CD pipelines:

```yaml
# Example GitHub Actions
- name: Setup and Deploy
  run: |
    ./scripts/minikube-setup.sh
    ./scripts/build-images.sh
    ./scripts/deploy-helm.sh
```

For production CI/CD, see [.github/workflows/build-and-deploy.yml](../.github/workflows/build-and-deploy.yml).

## Additional Resources

- [QUICK_START_K8S.md](../QUICK_START_K8S.md) - Quick start guide
- [KUBERNETES.md](../KUBERNETES.md) - Complete deployment guide
- [helm/todo-app/README.md](../helm/todo-app/README.md) - Helm chart docs

## Support

For issues:
1. Check script output for error messages
2. Verify dependencies are installed
3. Check [KUBERNETES.md](../KUBERNETES.md) troubleshooting section
4. Review Kubernetes events: `kubectl get events -n todo-app`
