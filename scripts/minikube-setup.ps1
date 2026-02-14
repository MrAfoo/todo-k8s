# PowerShell script for Minikube setup on Windows

Write-Host "🚀 Starting Minikube setup for Todo App..." -ForegroundColor Green

# Check if minikube is installed
if (-not (Get-Command minikube -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Minikube is not installed. Please install it first." -ForegroundColor Red
    Write-Host "Visit: https://minikube.sigs.k8s.io/docs/start/"
    exit 1
}

# Check if kubectl is installed
if (-not (Get-Command kubectl -ErrorAction SilentlyContinue)) {
    Write-Host "❌ kubectl is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Check if helm is installed
if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "⚠️  Helm is not installed. Please install it from https://helm.sh/docs/intro/install/" -ForegroundColor Yellow
}

# Start Minikube with recommended settings
Write-Host "📦 Starting Minikube cluster..." -ForegroundColor Green
minikube start `
    --cpus=4 `
    --memory=8192 `
    --disk-size=20g `
    --driver=docker `
    --kubernetes-version=v1.28.0

# Enable required addons
Write-Host "🔌 Enabling Minikube addons..." -ForegroundColor Green
minikube addons enable ingress
minikube addons enable metrics-server
minikube addons enable dashboard
minikube addons enable storage-provisioner

# Configure kubectl context
Write-Host "⚙️  Configuring kubectl context..." -ForegroundColor Green
kubectl config use-context minikube

# Configure Docker environment to use Minikube's Docker daemon
Write-Host "🐳 Configuring Docker environment..." -ForegroundColor Green
Write-Host "Run: minikube docker-env | Invoke-Expression" -ForegroundColor Yellow

Write-Host "✅ Minikube setup complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "  1. Configure Docker environment:"
Write-Host "     minikube docker-env | Invoke-Expression"
Write-Host ""
Write-Host "  2. Build Docker images:"
Write-Host "     .\scripts\build-images.ps1"
Write-Host ""
Write-Host "  3. Deploy using Helm:"
Write-Host "     .\scripts\deploy-helm.ps1"
Write-Host ""
Write-Host "  4. Or deploy using kubectl:"
Write-Host "     .\scripts\deploy-k8s.ps1"
Write-Host ""
Write-Host "🔍 Useful commands:" -ForegroundColor Yellow
Write-Host "  - View cluster status: minikube status"
Write-Host "  - Access dashboard: minikube dashboard"
Write-Host "  - Get service URL: minikube service frontend -n todo-app"
Write-Host "  - Stop cluster: minikube stop"
Write-Host "  - Delete cluster: minikube delete"
