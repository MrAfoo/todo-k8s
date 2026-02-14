# PowerShell verification script for Kubernetes deployment

Write-Host "🔍 Verifying Kubernetes Deployment Files..." -ForegroundColor Green
Write-Host ""

$errors = 0

# Check Dockerfiles
Write-Host "Checking Dockerfiles..." -ForegroundColor Yellow
$dockerfiles = @(
    "backend/Dockerfile",
    "frontend/Dockerfile",
    "backend/.dockerignore",
    "frontend/.dockerignore"
)

foreach ($file in $dockerfiles) {
    if (Test-Path $file) {
        Write-Host "✓ $file" -ForegroundColor Green
    } else {
        Write-Host "✗ $file missing" -ForegroundColor Red
        $errors++
    }
}
Write-Host ""

# Check Kubernetes manifests
Write-Host "Checking Kubernetes manifests..." -ForegroundColor Yellow
$k8sFiles = @(
    "k8s/namespace.yaml",
    "k8s/postgres-configmap.yaml",
    "k8s/postgres-secret.yaml",
    "k8s/postgres-pvc.yaml",
    "k8s/postgres-deployment.yaml",
    "k8s/postgres-service.yaml",
    "k8s/backend-configmap.yaml",
    "k8s/backend-secret.yaml",
    "k8s/backend-deployment.yaml",
    "k8s/backend-service.yaml",
    "k8s/frontend-deployment.yaml",
    "k8s/frontend-service.yaml"
)

foreach ($file in $k8sFiles) {
    if (Test-Path $file) {
        Write-Host "✓ $file" -ForegroundColor Green
    } else {
        Write-Host "✗ $file missing" -ForegroundColor Red
        $errors++
    }
}
Write-Host ""

# Check Helm chart
Write-Host "Checking Helm chart..." -ForegroundColor Yellow
$helmFiles = @(
    "helm/todo-app/Chart.yaml",
    "helm/todo-app/values.yaml",
    "helm/todo-app/values-staging.yaml",
    "helm/todo-app/values-production.yaml",
    "helm/todo-app/README.md"
)

foreach ($file in $helmFiles) {
    if (Test-Path $file) {
        Write-Host "✓ $file" -ForegroundColor Green
    } else {
        Write-Host "✗ $file missing" -ForegroundColor Red
        $errors++
    }
}

# Check templates
$templateCount = (Get-ChildItem -Path helm/todo-app/templates -Include *.yaml,*.txt -File -Recurse).Count
Write-Host "✓ helm/todo-app/templates ($templateCount files)" -ForegroundColor Green
Write-Host ""

# Check scripts
Write-Host "Checking deployment scripts..." -ForegroundColor Yellow
$scripts = @(
    "scripts/minikube-setup.ps1",
    "scripts/build-images.ps1",
    "scripts/deploy-helm.ps1",
    "scripts/deploy-k8s.ps1",
    "scripts/cleanup.ps1",
    "scripts/logs.ps1",
    "scripts/minikube-setup.sh",
    "scripts/build-images.sh",
    "scripts/deploy-helm.sh",
    "scripts/deploy-k8s.sh",
    "scripts/cleanup.sh",
    "scripts/logs.sh"
)

foreach ($script in $scripts) {
    if (Test-Path $script) {
        Write-Host "✓ $script" -ForegroundColor Green
    } else {
        Write-Host "✗ $script missing" -ForegroundColor Red
        $errors++
    }
}
Write-Host ""

# Check documentation
Write-Host "Checking documentation..." -ForegroundColor Yellow
$docs = @(
    "KUBERNETES.md",
    "QUICK_START_K8S.md",
    "DEPLOYMENT_SUMMARY.md",
    "AGENTS.md",
    "helm/todo-app/README.md",
    "k8s/README.md",
    "scripts/README.md"
)

foreach ($doc in $docs) {
    if (Test-Path $doc) {
        Write-Host "✓ $doc" -ForegroundColor Green
    } else {
        Write-Host "✗ $doc missing" -ForegroundColor Red
        $errors++
    }
}
Write-Host ""

# Check CI/CD
Write-Host "Checking CI/CD..." -ForegroundColor Yellow
if (Test-Path ".github/workflows/build-and-deploy.yml") {
    Write-Host "✓ .github/workflows/build-and-deploy.yml" -ForegroundColor Green
} else {
    Write-Host "✗ .github/workflows/build-and-deploy.yml missing" -ForegroundColor Red
    $errors++
}
Write-Host ""

# Summary
Write-Host "==========================================" -ForegroundColor Cyan
if ($errors -eq 0) {
    Write-Host "✅ All deployment files verified successfully!" -ForegroundColor Green
    Write-Host ""
    Write-Host "Next steps:" -ForegroundColor Yellow
    Write-Host "  1. Start Minikube: .\scripts\minikube-setup.ps1"
    Write-Host "  2. Configure Docker: minikube docker-env | Invoke-Expression"
    Write-Host "  3. Build images: .\scripts\build-images.ps1"
    Write-Host "  4. Deploy: .\scripts\deploy-helm.ps1"
    exit 0
} else {
    Write-Host "❌ Verification failed with $errors error(s)" -ForegroundColor Red
    exit 1
}
