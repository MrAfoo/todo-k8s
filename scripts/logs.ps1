# PowerShell script to view logs from Kubernetes pods

param(
    [string]$Component = "all"
)

$namespace = "todo-app"

Write-Host "📋 Viewing logs for: $Component" -ForegroundColor Green
Write-Host ""

switch ($Component) {
    "backend" {
        kubectl logs -n $namespace -l app=backend --tail=100 -f
    }
    "frontend" {
        kubectl logs -n $namespace -l app=frontend --tail=100 -f
    }
    "postgres" {
        kubectl logs -n $namespace -l app=postgres --tail=100 -f
    }
    "all" {
        Write-Host "Available components: backend, frontend, postgres" -ForegroundColor Yellow
        Write-Host "Usage: .\scripts\logs.ps1 -Component [backend|frontend|postgres]"
        Write-Host ""
        Write-Host "Current pods:" -ForegroundColor Green
        kubectl get pods -n $namespace
    }
    default {
        Write-Host "Unknown component: $Component" -ForegroundColor Yellow
        Write-Host "Available: backend, frontend, postgres"
        exit 1
    }
}
