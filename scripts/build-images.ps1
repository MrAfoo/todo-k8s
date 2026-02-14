# PowerShell script to build Docker images for Minikube

Write-Host "🔨 Building Docker images..." -ForegroundColor Green

# Use Minikube's Docker daemon
Write-Host "🐳 Configuring Docker to use Minikube's daemon..." -ForegroundColor Yellow
minikube docker-env | Invoke-Expression

# Build backend image
Write-Host "📦 Building backend image..." -ForegroundColor Green
docker build -t todo-backend:latest .\backend

# Build frontend image
Write-Host "📦 Building frontend image..." -ForegroundColor Green
docker build -t todo-frontend:latest `
    --build-arg NEXT_PUBLIC_API_URL=http://backend:8000 `
    .\frontend

Write-Host "✅ Docker images built successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📋 Images created:" -ForegroundColor Yellow
docker images | Select-String -Pattern "todo-backend|todo-frontend"
Write-Host ""
Write-Host "📝 Next step:" -ForegroundColor Yellow
Write-Host "  Deploy to Minikube: .\scripts\deploy-helm.ps1 or .\scripts\deploy-k8s.ps1"
