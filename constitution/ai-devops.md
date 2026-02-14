# AI DevOps Integration

**Part of:** Todo App Kubernetes Constitution  
**Version:** 1.0  
**Last Updated:** 2026-02-12

## Overview

This document describes how to integrate AI DevOps tools (Gordon, kubectl-ai, and Kagent) into the Todo App deployment workflow for automated builds, intelligent operations, and proactive monitoring.

## AI DevOps Tools

### Gordon - Docker Build Automation

**Purpose:** Automated and intelligent container image building

**Capabilities:**
- Multi-stage build optimization
- Layer caching for faster builds
- Automatic tagging and versioning
- Push to container registries
- Build parallelization

**Installation:**
```bash
# Install Gordon
npm install -g gordon-cli

# Or use as part of deployment scripts
./scripts/gordon-build.sh
```

**Basic Usage:**
```bash
# Build all images
gordon build --all

# Build specific service
gordon build backend
gordon build frontend
gordon build mcp-server

# Build and push
gordon build --push --tag v1.0.0

# Build with custom registry
gordon build --registry ghcr.io/your-org
```

**Configuration (gordon.yaml):**
```yaml
version: 1
registry: ghcr.io/your-org
images:
  backend:
    context: ./backend
    dockerfile: Dockerfile
    tags:
      - latest
      - "{{version}}"
      - "{{git.sha}}"
  
  frontend:
    context: ./frontend
    dockerfile: Dockerfile
    tags:
      - latest
      - "{{version}}"
  
  mcp-server:
    context: ./backend
    dockerfile: Dockerfile
    build-args:
      SERVICE: mcp-server
    command: ["uvicorn", "app.mcp_server:app", "--host", "0.0.0.0", "--port", "8001"]
    tags:
      - latest
      - "{{version}}"
```

### kubectl-ai - Natural Language Kubernetes Operations

**Purpose:** Execute Kubernetes operations using natural language

**Capabilities:**
- Deploy applications from descriptions
- Scale resources intelligently
- Troubleshoot issues automatically
- Generate manifests from requirements
- Context-aware suggestions

**Installation:**
```bash
# Install kubectl-ai
curl -sL https://kubectl.ai/install.sh | sh

# Or using homebrew
brew install kubectl-ai
```

**Usage Examples:**

**Deployment:**
```bash
# Deploy the application
kubectl-ai deploy todo app using helm chart at ./helm/todo-app

# Deploy to specific namespace
kubectl-ai deploy todo app to namespace todo-app-staging
```

**Scaling:**
```bash
# Scale backend
kubectl-ai scale backend deployment to 5 replicas in todo-app namespace

# Auto-scale based on CPU
kubectl-ai enable autoscaling for backend with min 2 max 10 replicas at 70% CPU
```

**Monitoring:**
```bash
# Check status
kubectl-ai show status of all pods in todo-app namespace

# View logs
kubectl-ai show logs for backend pods in todo-app namespace

# Find issues
kubectl-ai diagnose failing pods in todo-app namespace
```

**Configuration:**
```bash
# Troubleshoot
kubectl-ai why is postgres pod restarting in todo-app namespace
kubectl-ai what is wrong with frontend service

# Get suggestions
kubectl-ai suggest improvements for backend deployment
kubectl-ai recommend resource limits for frontend
```

### Kagent - Monitoring and Optimization

**Purpose:** Intelligent monitoring, alerting, and resource optimization

**Capabilities:**
- Real-time resource monitoring
- Anomaly detection
- Cost optimization recommendations
- Predictive scaling
- Automated remediation

**Installation:**
```bash
# Install Kagent
curl -sL https://kagent.io/install.sh | sh

# Deploy Kagent agent to cluster
kagent install --namespace kagent-system
```

**Usage Examples:**

**Monitoring:**
```bash
# Monitor namespace
kagent monitor todo-app

# Real-time dashboard
kagent dashboard todo-app

# Resource usage
kagent top pods -n todo-app
kagent top nodes
```

**Optimization:**
```bash
# Analyze resource usage
kagent analyze resources -n todo-app

# Get optimization recommendations
kagent optimize backend deployment
kagent suggest cost savings for todo-app

# Right-size resources
kagent rightsizing recommendations -n todo-app
```

**Alerting:**
```bash
# Set up alerts
kagent alert create high-cpu \
  --condition "cpu > 80%" \
  --namespace todo-app \
  --action scale-up

# List active alerts
kagent alert list -n todo-app

# Test alert
kagent alert test high-cpu
```

**Predictive Scaling:**
```bash
# Enable predictive scaling
kagent predict enable backend \
  --based-on traffic-patterns \
  --namespace todo-app

# View predictions
kagent predict show backend -n todo-app
```

## Integrated Workflows

### Build and Deploy Workflow

**Script: scripts/gordon-build.sh**
```bash
#!/bin/bash
set -e

echo "🔨 Building Docker images with Gordon..."

# Use Minikube's Docker daemon
eval $(minikube docker-env)

# Build backend image
echo "Building backend..."
docker build -t todo-backend:latest ./backend

# Build frontend image
echo "Building frontend..."
docker build -t todo-frontend:latest ./frontend

# Build MCP server (reuses backend image with different CMD)
echo "Building MCP server..."
docker build -t todo-mcp-server:latest \
  --build-arg SERVICE=mcp-server \
  ./backend

echo "✅ All images built successfully!"
docker images | grep todo-
```

**Enhanced with Gordon:**
```bash
#!/bin/bash
set -e

echo "🔨 Building with Gordon AI..."

# Gordon automatically optimizes builds
gordon build \
  --parallel \
  --cache \
  --optimize \
  --target minikube

echo "✅ Gordon build complete!"
```

### Deployment Workflow

**Script: scripts/deploy-ai.sh**
```bash
#!/bin/bash
set -e

echo "🚀 Deploying with kubectl-ai..."

# Deploy using natural language
kubectl-ai deploy todo app using helm chart at ./helm/todo-app in namespace todo-app

# Verify deployment
kubectl-ai verify all services are healthy in todo-app namespace

# Set up monitoring
kagent monitor todo-app --enable-alerts

echo "✅ Deployment complete and monitored!"
```

### Troubleshooting Workflow

**Script: scripts/troubleshoot.sh**
```bash
#!/bin/bash

echo "🔍 AI-Powered Troubleshooting..."

# Use kubectl-ai to diagnose
echo "Checking pod health..."
kubectl-ai show failing pods in todo-app namespace

# Get AI recommendations
echo "Getting recommendations..."
kubectl-ai suggest fixes for issues in todo-app namespace

# Check with Kagent
echo "Analyzing with Kagent..."
kagent diagnose anomalies -n todo-app

echo "📊 Analysis complete!"
```

## Best Practices

### Gordon Best Practices

1. **Use Multi-Stage Builds**
   - Smaller final images
   - Faster builds with caching
   - Better security (no build tools in production)

2. **Version Your Images**
   ```bash
   gordon build --tag $(git describe --tags --always)
   ```

3. **Scan Before Push**
   ```bash
   gordon build --scan --push
   ```

4. **Leverage Build Cache**
   ```bash
   gordon build --cache-from todo-backend:latest
   ```

### kubectl-ai Best Practices

1. **Be Specific with Namespaces**
   ```bash
   kubectl-ai <command> in todo-app namespace
   ```

2. **Use Verification**
   ```bash
   kubectl-ai deploy ... && kubectl-ai verify deployment
   ```

3. **Review Before Execution**
   ```bash
   kubectl-ai --dry-run scale backend to 10 replicas
   ```

4. **Combine with Standard kubectl**
   ```bash
   # Use kubectl-ai for complex operations
   kubectl-ai diagnose performance issues
   
   # Use kubectl for simple operations
   kubectl get pods -n todo-app
   ```

### Kagent Best Practices

1. **Set Baseline Metrics**
   ```bash
   kagent baseline create -n todo-app --duration 7d
   ```

2. **Enable Predictive Alerts**
   ```bash
   kagent alert create --predictive --lead-time 15m
   ```

3. **Regular Optimization Reviews**
   ```bash
   # Weekly optimization review
   kagent report weekly -n todo-app
   ```

4. **Cost Monitoring**
   ```bash
   kagent cost analyze -n todo-app --recommendations
   ```

## Integration with CI/CD

### GitHub Actions with AI Tools

**.github/workflows/ai-deploy.yml:**
```yaml
name: AI-Powered Deploy

on:
  push:
    branches: [main, develop]

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
    - uses: actions/checkout@v3
    
    - name: Build with Gordon
      run: |
        npm install -g gordon-cli
        gordon build --all --push --tag ${{ github.sha }}
      env:
        REGISTRY_TOKEN: ${{ secrets.GITHUB_TOKEN }}
    
    - name: Deploy with kubectl-ai
      run: |
        kubectl-ai deploy todo app \
          --image-tag ${{ github.sha }} \
          --namespace todo-app-staging
      env:
        KUBECONFIG: ${{ secrets.KUBECONFIG_STAGING }}
    
    - name: Monitor with Kagent
      run: |
        kagent monitor todo-app-staging --duration 5m
        kagent verify deployment healthy
```

## Monitoring and Alerts

### Kagent Alert Configuration

**alerts.yaml:**
```yaml
alerts:
  - name: high-cpu
    condition: cpu > 80%
    namespace: todo-app
    labels:
      app: backend
    actions:
      - type: scale
        replicas: +2
      - type: notify
        channel: slack
  
  - name: high-memory
    condition: memory > 90%
    namespace: todo-app
    actions:
      - type: restart
        graceful: true
      - type: notify
        channel: email
  
  - name: pod-restart-loop
    condition: restarts > 3 in 5m
    namespace: todo-app
    actions:
      - type: quarantine
      - type: notify
        channel: pagerduty
        severity: critical
```

### Dashboard Integration

**Kagent Dashboard:**
```bash
# Launch web dashboard
kagent dashboard --namespace todo-app --port 8080

# Access at http://localhost:8080
# Shows:
# - Real-time metrics
# - Cost analysis
# - Optimization recommendations
# - Alert history
```

## Cost Optimization

### Kagent Cost Analysis

```bash
# Analyze current costs
kagent cost analyze -n todo-app

# Get rightsizing recommendations
kagent cost optimize \
  --target 20% reduction \
  --preserve performance

# Implement recommendations
kagent cost apply recommendations \
  --namespace todo-app \
  --approve
```

**Example Output:**
```
💰 Cost Analysis for todo-app namespace

Current Monthly Cost: $450
Potential Savings: $120 (27%)

Recommendations:
1. Backend: Reduce from 512Mi to 384Mi memory (-$30/mo)
2. Frontend: Enable autoscaling min=2 max=5 (-$45/mo)
3. PostgreSQL: Right-size to 256Mi/250m (-$25/mo)
4. MCP Server: Reduce replicas 2→1 during off-peak (-$20/mo)

Apply with: kagent cost apply --approve
```

## Advanced Features

### Automated Remediation

**Kagent Auto-Heal:**
```bash
# Enable auto-remediation
kagent autoheal enable -n todo-app

# Configure policies
kagent autoheal policy create \
  --name restart-on-crash \
  --condition "restarts > 5" \
  --action "restart pod" \
  --cooldown 5m

# View auto-heal history
kagent autoheal history -n todo-app
```

### Predictive Scaling

**Kagent ML-Based Scaling:**
```bash
# Train scaling model
kagent ml train \
  --namespace todo-app \
  --service backend \
  --metrics cpu,memory,requests \
  --duration 30d

# Enable predictive scaling
kagent ml predict enable backend \
  --lead-time 10m \
  --confidence 80%

# Monitor predictions vs actual
kagent ml evaluate -n todo-app
```

## Troubleshooting AI Tools

### Gordon Issues

**Build Failures:**
```bash
# Verbose logging
gordon build --verbose --debug

# Clear cache
gordon cache clear

# Rebuild from scratch
gordon build --no-cache
```

### kubectl-ai Issues

**Connection Problems:**
```bash
# Check configuration
kubectl-ai config check

# Test connectivity
kubectl-ai test connection

# Fallback to kubectl
kubectl get pods -n todo-app
```

### Kagent Issues

**Agent Not Responding:**
```bash
# Check agent status
kubectl get pods -n kagent-system

# Restart agent
kubectl rollout restart deployment kagent-agent -n kagent-system

# Check logs
kubectl logs -l app=kagent-agent -n kagent-system
```

## References

- [Gordon Documentation](https://gordon.dev/docs)
- [kubectl-ai Guide](https://kubectl.ai/guide)
- [Kagent Manual](https://kagent.io/manual)

---

**See Also:**
- [Main Constitution](./MAIN.md)
- [Deployment Guidelines](./deployment.md)
- [Security Best Practices](./security.md)
