# 🚀 Quick Start Guide - Get Running in 5 Minutes!

This guide will get your AI-powered Todo app running on Kubernetes as quickly as possible.

## 📋 Prerequisites Check

Before starting, make sure you have installed:

- ✅ Docker Desktop
- ✅ Minikube
- ✅ kubectl
- ✅ Helm

**Verify your installations:**

```powershell
# Windows PowerShell
docker --version
minikube version
kubectl version --client
helm version --short
```

```bash
# Linux/Mac
docker --version
minikube version
kubectl version --client
helm version --short
```

All commands should return version numbers. If not, install the missing tools.

---

## ⚡ Option 1: Automated Setup (Recommended)

### Step 1: Get a Groq API Key (Free!)

1. Visit [console.groq.com](https://console.groq.com/)
2. Sign up for a free account
3. Go to [API Keys](https://console.groq.com/keys)
4. Click "Create API Key"
5. Copy your key

### Step 2: Configure API Key

Edit the Helm configuration file:

```powershell
# Windows
notepad helm\todo-app\values.yaml
```

```bash
# Linux/Mac
nano helm/todo-app/values.yaml
```

Find this section and paste your API key:

```yaml
backend:
  secrets:
    groqApiKey: "gsk_your_actual_api_key_here"  # ← Paste your key here
```

Save and close the file.

### Step 3: Run the Setup Script

```powershell
# Windows PowerShell
.\scripts\minikube-setup.ps1
```

```bash
# Linux/Mac
./scripts/minikube-setup.sh
```

**What happens:**
- ⏳ Minikube starts (creates local Kubernetes cluster)
- 🐳 Docker images are built (frontend, backend, MCP server)
- 📦 Application deploys via Helm
- 🌐 Browser opens automatically to your app

**Time:** 3-5 minutes

### Step 4: Access Your App

The script will automatically open your browser. If not, use:

```bash
minikube service frontend -n todo-app
```

**Your app is ready!** 🎉

---

## 🛠️ Option 2: Manual Setup (Step-by-Step)

If you want to understand each step:

### Step 1: Start Minikube

```bash
minikube start --driver=docker --cpus=4 --memory=8192
```

**What this does:** Creates a local Kubernetes cluster with 4 CPU cores and 8GB RAM

**Expected output:**
```
✓ minikube v1.38.0
✓ Using the docker driver
✓ Starting control plane node minikube
✓ Done! kubectl is now configured to use "minikube"
```

**Time:** 2-3 minutes

---

### Step 2: Configure Docker Environment

Point Docker to Minikube's internal Docker daemon:

```powershell
# Windows PowerShell
& minikube -p minikube docker-env --shell powershell | Invoke-Expression
```

```bash
# Linux/Mac
eval $(minikube docker-env)
```

**What this does:** Makes Docker build images directly inside Minikube

**Verify:**
```bash
docker info | grep Name
# Should show: Name: minikube
```

---

### Step 3: Build Docker Images

```bash
# Build Backend
docker build -t todo-backend:latest ./backend

# Build Frontend
docker build -t todo-frontend:latest ./frontend

# Build MCP Server (uses same backend Dockerfile)
docker build -t todo-mcp:latest ./backend
```

**What this does:** Creates container images for all three services

**Time:** 3-5 minutes (depending on internet speed)

**Expected output:**
```
Successfully built abc123def456
Successfully tagged todo-backend:latest
```

**Verify images:**
```bash
docker images | grep todo-
```

You should see:
- `todo-backend:latest`
- `todo-frontend:latest`
- `todo-mcp:latest`

---

### Step 4: Configure Groq API Key

Edit `helm/todo-app/values.yaml`:

```yaml
backend:
  secrets:
    groqApiKey: "gsk_your_actual_api_key_here"
```

---

### Step 5: Deploy with Helm

```bash
helm upgrade --install todo-app ./helm/todo-app \
  --namespace todo-app \
  --create-namespace \
  --set backend.image.tag=latest \
  --set frontend.image.tag=latest \
  --set mcp.image.tag=latest
```

**What this does:** Deploys all Kubernetes resources (pods, services, configmaps, secrets)

**Expected output:**
```
Release "todo-app" has been upgraded. Happy Helming!
NAME: todo-app
NAMESPACE: todo-app
STATUS: deployed
```

**Time:** 10-20 seconds

---

### Step 6: Wait for Pods to Start

```bash
kubectl get pods -n todo-app -w
```

**Watch the pods become Ready:**
```
NAME                        READY   STATUS    RESTARTS   AGE
postgres-xxx               1/1     Running   0          30s
backend-xxx                1/1     Running   0          25s
mcp-server-xxx             1/1     Running   0          25s
frontend-xxx               1/1     Running   0          20s
```

Press `Ctrl+C` when all pods show `1/1 Running`

**Time:** 30-60 seconds

---

### Step 7: Access the Application

```bash
minikube service frontend -n todo-app
```

**What this does:** Opens a tunnel to the frontend service and launches your browser

**Expected output:**
```
|-----------|----------|-------------|---------------------------|
| NAMESPACE |   NAME   | TARGET PORT |            URL            |
|-----------|----------|-------------|---------------------------|
| todo-app  | frontend | 80          | http://127.0.0.1:53322    |
|-----------|----------|-------------|---------------------------|
🎉  Opening service todo-app/frontend in default browser...
```

**Your app is now running!** 🚀

---

## 🎯 First Steps with Your App

### 1. Register an Account

1. Browser opens to the app
2. Click **"Register"** or **"Sign Up"**
3. Enter:
   - Username: `your_name`
   - Email: `you@example.com`
   - Password: `secure_password`
4. Click **"Create Account"**

### 2. Create Your First Task

**Traditional Way:**
1. Go to **Dashboard**
2. Click **"Add Task"** or **"New Task"**
3. Enter task details:
   - Title: `Buy groceries`
   - Description: `Milk, eggs, bread`
   - Priority: `Medium`
   - Category: `Shopping`
   - Due Date: Tomorrow
4. Click **"Create"**

**AI Way (Cooler!):**
1. Go to **Chat**
2. Type: `Create a task to buy groceries tomorrow`
3. Press Enter
4. AI creates the task automatically! 🤖

### 3. Try the AI Assistant

Ask the AI to help you:

```
You: "What tasks do I have?"
AI: [Lists all your tasks]

You: "Create an urgent task to finish the report by Friday"
AI: [Creates task with high priority and due date]

You: "Mark the grocery task as done"
AI: [Completes the task]

You: "Show me all urgent tasks"
AI: [Filters and displays urgent tasks]
```

---

## 📊 Verify Everything is Working

### Check Pod Status

```bash
kubectl get pods -n todo-app
```

**All pods should show:**
- `READY: 1/1`
- `STATUS: Running`
- `RESTARTS: 0` (or low number)

### Check Logs

```bash
# Backend logs
kubectl logs -l app=backend -n todo-app --tail=20

# Frontend logs
kubectl logs -l app=frontend -n todo-app --tail=20

# MCP Server logs
kubectl logs -l app=mcp-server -n todo-app --tail=20
```

**Look for:**
- ✅ No error messages
- ✅ "Application startup complete" messages
- ✅ Successful database connections

### Check Services

```bash
kubectl get svc -n todo-app
```

**You should see:**
- `postgres` (ClusterIP)
- `backend` (ClusterIP)
- `mcp-server` (ClusterIP)
- `frontend` (LoadBalancer)

---

## 🔧 Common Issues & Solutions

### Issue 1: Minikube Won't Start

**Error:** `Exiting due to HOST_JUJU_LOCK_PERMISSION`

**Solution:**
```bash
minikube delete
minikube start --driver=docker --cpus=4 --memory=8192
```

---

### Issue 2: Pods Stuck in "ImagePullBackOff"

**Cause:** Docker images not in Minikube's registry

**Solution:**
```bash
# Re-configure Docker environment
eval $(minikube docker-env)  # Linux/Mac
& minikube -p minikube docker-env --shell powershell | Invoke-Expression  # Windows

# Rebuild images
docker build -t todo-backend:latest ./backend
docker build -t todo-frontend:latest ./frontend
docker build -t todo-mcp:latest ./backend

# Restart pods
kubectl delete pods --all -n todo-app
```

---

### Issue 3: Backend Pods Crashing (CrashLoopBackOff)

**Cause:** Database connection issues or missing API key

**Check:**
```bash
kubectl logs -l app=backend -n todo-app --tail=50
```

**Common fixes:**

**Missing Groq API Key:**
```bash
# Check if secret exists
kubectl get secret todo-app-backend-secret -n todo-app -o yaml

# Update Helm values and redeploy
helm upgrade todo-app ./helm/todo-app -n todo-app
```

**Database not ready:**
```bash
# Check postgres pod
kubectl get pod -l app=postgres -n todo-app

# Wait for postgres to be ready
kubectl wait --for=condition=ready pod -l app=postgres -n todo-app --timeout=120s
```

---

### Issue 4: Can't Access Frontend

**Solution:**
```bash
# Check if frontend service is running
kubectl get svc frontend -n todo-app

# Try port-forward instead
kubectl port-forward svc/frontend 3000:80 -n todo-app

# Then open: http://localhost:3000
```

---

### Issue 5: "No space left on device"

**Cause:** Docker or Minikube ran out of disk space

**Solution:**
```bash
# Clean up Docker
docker system prune -a

# Restart Minikube
minikube delete
minikube start --driver=docker --cpus=4 --memory=8192
```

---

## 🎓 Next Steps

Now that your app is running:

1. **Learn How It Works** - Read [HOW_IT_WORKS.md](HOW_IT_WORKS.md) for a complete beginner-friendly explanation
2. **Explore Kubernetes** - Read [KUBERNETES.md](KUBERNETES.md) for detailed deployment documentation
3. **Monitor Your App** - Try these commands:
   ```bash
   # Watch pods in real-time
   kubectl get pods -n todo-app -w
   
   # View logs
   kubectl logs -f -l app=backend -n todo-app
   
   # Access Kubernetes dashboard
   minikube dashboard
   ```

4. **Experiment** - Try scaling your application:
   ```bash
   # Scale backend to 3 replicas
   kubectl scale deployment backend --replicas=3 -n todo-app
   
   # Watch it scale
   kubectl get pods -n todo-app -w
   ```

---

## 🧹 Stopping and Cleaning Up

### Stop Everything (Keep Data)

```bash
# Stop Minikube
minikube stop
```

**To restart later:**
```bash
minikube start
minikube service frontend -n todo-app
```

### Delete Everything (Fresh Start)

```bash
# Delete the application
helm uninstall todo-app -n todo-app

# Delete the namespace
kubectl delete namespace todo-app

# Delete Minikube cluster
minikube delete
```

⚠️ **Warning:** This deletes all your data!

---

## 📚 Additional Resources

- **README.md** - Complete project documentation
- **HOW_IT_WORKS.md** - Architecture explained for beginners
- **KUBERNETES.md** - Advanced Kubernetes guide
- **helm/todo-app/README.md** - Helm chart documentation

---

## 🎉 Success!

You now have a fully functional AI-powered Todo application running on Kubernetes!

**What you've achieved:**
- ✅ Set up a local Kubernetes cluster
- ✅ Built and deployed containerized applications
- ✅ Configured services, pods, and networking
- ✅ Deployed a multi-tier application with database
- ✅ Integrated AI capabilities with Groq

**Keep the terminal running** where you ran `minikube service frontend -n todo-app` to maintain access to your app!

---

**Need Help?** Check [HOW_IT_WORKS.md](HOW_IT_WORKS.md) for detailed explanations! 🚀
