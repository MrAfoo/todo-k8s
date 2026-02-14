# PowerShell script to deploy to Kubernetes using Helm

Write-Host "🚀 Deploying Todo App using Helm..." -ForegroundColor Green

# Check if helm is installed
if (-not (Get-Command helm -ErrorAction SilentlyContinue)) {
    Write-Host "❌ Helm is not installed. Please install it first." -ForegroundColor Red
    exit 1
}

# Deploy using Helm
Write-Host "📦 Installing/Upgrading Helm chart..." -ForegroundColor Green
helm upgrade --install todo-app .\helm\todo-app `
    --namespace todo-app `
    --create-namespace `
    --wait `
    --timeout 10m

Write-Host ""
Write-Host "✅ Deployment complete!" -ForegroundColor Green
Write-Host ""
Write-Host "📊 Deployment status:" -ForegroundColor Yellow
kubectl get all -n todo-app

Write-Host ""
Write-Host "🌐 Access the application:" -ForegroundColor Yellow
if (Get-Command minikube -ErrorAction SilentlyContinue) {
    Write-Host "  Run: minikube service frontend -n todo-app"
} else {
    Write-Host "  Run: kubectl port-forward -n todo-app svc/frontend 3000:80"
    Write-Host "  Then open: http://localhost:3000"
}

Write-Host ""
Write-Host "📝 Helm release info:" -ForegroundColor Yellow
helm list -n todo-app
