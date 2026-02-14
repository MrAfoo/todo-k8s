# PowerShell script to deploy to Kubernetes using kubectl

Write-Host "🚀 Deploying Todo App to Kubernetes..." -ForegroundColor Green

# Apply Kubernetes manifests in order
Write-Host "📝 Creating namespace..." -ForegroundColor Green
kubectl apply -f k8s\namespace.yaml

Write-Host "📝 Creating ConfigMaps and Secrets..." -ForegroundColor Green
kubectl apply -f k8s\postgres-configmap.yaml
kubectl apply -f k8s\postgres-secret.yaml
kubectl apply -f k8s\backend-configmap.yaml
kubectl apply -f k8s\backend-secret.yaml
kubectl apply -f k8s\mcp-configmap.yaml

Write-Host "📝 Creating PersistentVolumeClaims..." -ForegroundColor Green
kubectl apply -f k8s\postgres-pvc.yaml

Write-Host "📝 Deploying PostgreSQL..." -ForegroundColor Green
kubectl apply -f k8s\postgres-deployment.yaml
kubectl apply -f k8s\postgres-service.yaml

Write-Host "⏳ Waiting for PostgreSQL to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=postgres -n todo-app --timeout=300s

Write-Host "📝 Deploying Backend API..." -ForegroundColor Green
kubectl apply -f k8s\backend-deployment.yaml
kubectl apply -f k8s\backend-service.yaml

Write-Host "⏳ Waiting for Backend to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=backend -n todo-app --timeout=300s

Write-Host "📝 Deploying MCP Server..." -ForegroundColor Green
kubectl apply -f k8s\mcp-deployment.yaml
kubectl apply -f k8s\mcp-service.yaml

Write-Host "⏳ Waiting for MCP Server to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=mcp -n todo-app --timeout=300s

Write-Host "📝 Deploying Frontend..." -ForegroundColor Green
kubectl apply -f k8s\frontend-deployment.yaml
kubectl apply -f k8s\frontend-service.yaml

Write-Host "⏳ Waiting for Frontend to be ready..." -ForegroundColor Yellow
kubectl wait --for=condition=ready pod -l app=frontend -n todo-app --timeout=300s

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
