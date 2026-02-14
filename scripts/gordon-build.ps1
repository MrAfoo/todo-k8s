# Docker AI Agent (Gordon) compatible build script - PowerShell version
# Can be invoked by Gordon or run manually as fallback

param(
    [string]$BackendImage = "todo-backend:latest",
    [string]$FrontendImage = "todo-frontend:latest",
    [string]$Registry = "",
    [string]$BuildContext = "minikube",
    [string]$NextPublicApiUrl = "http://backend:8000"
)

$ErrorActionPreference = "Stop"

Write-Host "🤖 Docker AI Agent (Gordon) - Image Build Script" -ForegroundColor Cyan
Write-Host "==================================================" -ForegroundColor Cyan
Write-Host ""

# Functions
function Test-DockerInstalled {
    if (-not (Get-Command docker -ErrorAction SilentlyContinue)) {
        Write-Host "❌ Docker is not installed. Please install Docker first." -ForegroundColor Red
        exit 1
    }
    Write-Host "✅ Docker is available" -ForegroundColor Green
}

function Set-MinikubeDockerEnv {
    if ($BuildContext -eq "minikube") {
        if (Get-Command minikube -ErrorAction SilentlyContinue) {
            Write-Host "🐳 Configuring Docker to use Minikube's daemon..." -ForegroundColor Yellow
            minikube docker-env | Invoke-Expression
            Write-Host "✅ Using Minikube Docker daemon" -ForegroundColor Green
        } else {
            Write-Host "⚠️  Minikube not found, using host Docker daemon" -ForegroundColor Yellow
        }
    }
}

function Build-BackendImage {
    Write-Host ""
    Write-Host "📦 Building Backend Image..." -ForegroundColor Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    
    docker build `
        --tag $BackendImage `
        --file ./backend/Dockerfile `
        --progress=plain `
        --build-arg BUILDKIT_INLINE_CACHE=1 `
        ./backend
    
    Write-Host "✅ Backend image built: $BackendImage" -ForegroundColor Green
}

function Build-FrontendImage {
    Write-Host ""
    Write-Host "📦 Building Frontend Image..." -ForegroundColor Blue
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
    
    docker build `
        --tag $FrontendImage `
        --file ./frontend/Dockerfile `
        --build-arg NEXT_PUBLIC_API_URL=$NextPublicApiUrl `
        --progress=plain `
        --build-arg BUILDKIT_INLINE_CACHE=1 `
        ./frontend
    
    Write-Host "✅ Frontend image built: $FrontendImage" -ForegroundColor Green
}

function Push-ToRegistry {
    if ($Registry) {
        Write-Host ""
        Write-Host "🏷️  Tagging and pushing images to registry..." -ForegroundColor Blue
        Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Blue
        
        # Tag images
        docker tag $BackendImage "$Registry/$BackendImage"
        docker tag $FrontendImage "$Registry/$FrontendImage"
        
        # Push images
        docker push "$Registry/$BackendImage"
        docker push "$Registry/$FrontendImage"
        
        Write-Host "✅ Images pushed to $Registry" -ForegroundColor Green
    }
}

function Show-Summary {
    Write-Host ""
    Write-Host "🎉 Build Complete!" -ForegroundColor Green
    Write-Host "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━" -ForegroundColor Green
    Write-Host ""
    
    Write-Host "📋 Images created:" -ForegroundColor Cyan
    docker images | Select-String -Pattern "todo-backend|todo-frontend" | Select-Object -First 2
    Write-Host ""
    
    # Image sizes
    $backendSize = (docker images --format "{{.Size}}" $BackendImage | Select-Object -First 1)
    $frontendSize = (docker images --format "{{.Size}}" $FrontendImage | Select-Object -First 1)
    
    Write-Host "📊 Image Sizes:" -ForegroundColor Cyan
    Write-Host "  Backend:  $backendSize"
    Write-Host "  Frontend: $frontendSize"
    Write-Host ""
    
    Write-Host "📝 Next Steps:" -ForegroundColor Yellow
    if ($BuildContext -eq "minikube") {
        Write-Host "  1. Deploy to Minikube: .\scripts\deploy-helm.ps1"
        Write-Host "  2. Or use kubectl-ai: kubectl-ai deploy todo app using helm chart at ./helm/todo-app"
    } else {
        Write-Host "  1. Deploy to cluster: helm upgrade --install todo-app ./helm/todo-app -n todo-app"
        Write-Host "  2. Or push to registry: .\scripts\gordon-build.ps1 -Registry ghcr.io/your-org"
    }
    Write-Host ""
}

# Main execution
Write-Host ""
Write-Host "Configuration:" -ForegroundColor Blue
Write-Host "  Backend Image:  $BackendImage"
Write-Host "  Frontend Image: $FrontendImage"
Write-Host "  Registry:       $(if ($Registry) { $Registry } else { '<none - local only>' })"
Write-Host "  Build Context:  $BuildContext"
Write-Host "  API URL:        $NextPublicApiUrl"
Write-Host ""

Test-DockerInstalled
Set-MinikubeDockerEnv
Build-BackendImage
Build-FrontendImage
Push-ToRegistry
Show-Summary

Write-Host "✨ All done!" -ForegroundColor Green
