# PowerShell script to cleanup Kubernetes resources

Write-Host "🧹 Cleaning up Todo App resources..." -ForegroundColor Green

# Check if using Helm or kubectl
$helmRelease = helm list -n todo-app 2>$null | Select-String "todo-app"
if ($helmRelease) {
    Write-Host "🗑️  Uninstalling Helm release..." -ForegroundColor Yellow
    helm uninstall todo-app -n todo-app
} else {
    Write-Host "🗑️  Deleting Kubernetes resources..." -ForegroundColor Yellow
    kubectl delete -f k8s\ --ignore-not-found=true
}

Write-Host "🗑️  Deleting namespace..." -ForegroundColor Yellow
kubectl delete namespace todo-app --ignore-not-found=true

Write-Host "✅ Cleanup complete!" -ForegroundColor Green

Write-Host ""
$stopMinikube = Read-Host "Do you want to stop Minikube? (y/N)"
if ($stopMinikube -eq "y" -or $stopMinikube -eq "Y") {
    Write-Host "⏹️  Stopping Minikube..." -ForegroundColor Yellow
    minikube stop
    Write-Host "✅ Minikube stopped!" -ForegroundColor Green
}

Write-Host ""
$deleteMinikube = Read-Host "Do you want to DELETE Minikube cluster? (y/N)"
if ($deleteMinikube -eq "y" -or $deleteMinikube -eq "Y") {
    Write-Host "🗑️  Deleting Minikube cluster..." -ForegroundColor Red
    minikube delete
    Write-Host "✅ Minikube cluster deleted!" -ForegroundColor Green
}
