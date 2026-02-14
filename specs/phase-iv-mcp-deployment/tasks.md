# Phase IV: MCP Server Deployment - Implementation Tasks

**Project:** Todo App Kubernetes Deployment  
**Phase:** IV - MCP Server Containerization  
**Status:** In Progress  
**Created:** 2026-02-12

## Task Overview

This document provides a detailed, testable task breakdown for implementing the MCP server deployment to Kubernetes.

---

## Task 1: Create Helm Chart Templates

### T1.1: Create MCP ConfigMap Template

**File:** `helm/todo-app/templates/mcp-configmap.yaml`

**Requirements:**
- ConfigMap with MCP server configuration
- Conditional rendering based on `mcpServer.enabled`
- LOG_LEVEL configuration from values

**Test Cases:**
```bash
# TC1.1.1: ConfigMap renders when enabled
helm template todo-app ./helm/todo-app --set mcpServer.enabled=true | grep -A5 "kind: ConfigMap"

# TC1.1.2: ConfigMap not rendered when disabled
helm template todo-app ./helm/todo-app --set mcpServer.enabled=false | grep "mcp-config" && echo "FAIL" || echo "PASS"

# TC1.1.3: LOG_LEVEL value from values.yaml
helm template todo-app ./helm/todo-app --set mcpServer.config.logLevel=debug | grep "logLevel: debug"
```

**Acceptance Criteria:**
- [ ] ConfigMap created with correct metadata
- [ ] Conditional rendering works
- [ ] Values properly templated
- [ ] All test cases pass

---

### T1.2: Create MCP Deployment Template

**File:** `helm/todo-app/templates/mcp-deployment.yaml`

**Requirements:**
- Deployment with configurable replicas
- Reuses backend image with different command
- Environment variables from secrets and configmaps
- Resource limits and requests
- Health probes (liveness, readiness, startup)
- Security context (non-root)

**Test Cases:**
```bash
# TC1.2.1: Deployment renders correctly
helm template todo-app ./helm/todo-app --set mcpServer.enabled=true | grep -A50 "kind: Deployment" | grep "mcp-server"

# TC1.2.2: Replica count from values
helm template todo-app ./helm/todo-app --set mcpServer.replicaCount=3 | grep "replicas: 3"

# TC1.2.3: Custom image tag
helm template todo-app ./helm/todo-app --set mcpServer.image.tag=v1.0.0 | grep "image.*v1.0.0"

# TC1.2.4: Resource limits set
helm template todo-app ./helm/todo-app | grep -A5 "resources:" | grep "512Mi"

# TC1.2.5: Health probes configured
helm template todo-app ./helm/todo-app | grep -A3 "livenessProbe:"

# TC1.2.6: Non-root user
helm template todo-app ./helm/todo-app | grep "runAsNonRoot: true"

# TC1.2.7: Command override
helm template todo-app ./helm/todo-app | grep "app.mcp_server:app"
```

**Acceptance Criteria:**
- [ ] Deployment created with correct spec
- [ ] Uses backend image
- [ ] Command override to run MCP server
- [ ] All environment variables set
- [ ] Health probes configured
- [ ] Security context non-root
- [ ] All test cases pass

---

### T1.3: Create MCP Service Template

**File:** `helm/todo-app/templates/mcp-service.yaml`

**Requirements:**
- ClusterIP service on port 8001
- Selector matches deployment labels
- Conditional rendering

**Test Cases:**
```bash
# TC1.3.1: Service renders correctly
helm template todo-app ./helm/todo-app --set mcpServer.enabled=true | grep -A10 "kind: Service" | grep "mcp-server"

# TC1.3.2: ClusterIP type
helm template todo-app ./helm/todo-app | grep -A5 "name: mcp-server" | grep "type: ClusterIP"

# TC1.3.3: Port 8001
helm template todo-app ./helm/todo-app | grep -A10 "name: mcp-server" | grep "port: 8001"

# TC1.3.4: Selector matches deployment
helm template todo-app ./helm/todo-app | grep -A10 "mcp-server-service" | grep "app: mcp-server"
```

**Acceptance Criteria:**
- [ ] Service created with correct type
- [ ] Port 8001 configured
- [ ] Selector matches deployment
- [ ] All test cases pass

---

### T1.4: Create MCP HPA Template (Optional)

**File:** `helm/todo-app/templates/mcp-hpa.yaml`

**Requirements:**
- HorizontalPodAutoscaler for MCP server
- Conditional rendering based on `mcpServer.autoscaling.enabled`
- Min/max replicas from values
- CPU target from values

**Test Cases:**
```bash
# TC1.4.1: HPA renders when enabled
helm template todo-app ./helm/todo-app --set mcpServer.autoscaling.enabled=true | grep -A10 "kind: HorizontalPodAutoscaler"

# TC1.4.2: HPA not rendered when disabled
helm template todo-app ./helm/todo-app --set mcpServer.autoscaling.enabled=false | grep "HorizontalPodAutoscaler.*mcp" && echo "FAIL" || echo "PASS"

# TC1.4.3: Min/max replicas
helm template todo-app ./helm/todo-app --set mcpServer.autoscaling.enabled=true --set mcpServer.autoscaling.minReplicas=2 --set mcpServer.autoscaling.maxReplicas=5 | grep -E "minReplicas: 2|maxReplicas: 5"

# TC1.4.4: CPU target
helm template todo-app ./helm/todo-app --set mcpServer.autoscaling.enabled=true | grep "targetCPUUtilizationPercentage: 70"
```

**Acceptance Criteria:**
- [ ] HPA created when enabled
- [ ] Not created when disabled
- [ ] Min/max replicas configurable
- [ ] CPU target configurable
- [ ] All test cases pass

---

## Task 2: Update Helm Chart Configuration

### T2.1: Update values.yaml

**File:** `helm/todo-app/values.yaml`

**Requirements:**
- Add `mcpServer` section
- Default values for deployment, service, resources, autoscaling

**Test Cases:**
```bash
# TC2.1.1: mcpServer section exists
grep -A20 "mcpServer:" helm/todo-app/values.yaml

# TC2.1.2: Default replica count is 1
grep "replicaCount: 1" helm/todo-app/values.yaml | grep -A1 "mcpServer"

# TC2.1.3: Autoscaling disabled by default
grep "enabled: false" helm/todo-app/values.yaml | grep -A5 "autoscaling"

# TC2.1.4: Resource requests/limits defined
grep -A10 "mcpServer:" helm/todo-app/values.yaml | grep "256Mi"
```

**Acceptance Criteria:**
- [ ] mcpServer section added
- [ ] All required fields present
- [ ] Sensible defaults set
- [ ] All test cases pass

---

### T2.2: Update Chart.yaml

**File:** `helm/todo-app/Chart.yaml`

**Requirements:**
- Bump version from 0.1.0 to 0.2.0
- Update appVersion if needed
- Add MCP server to description/keywords

**Test Cases:**
```bash
# TC2.2.1: Version is 0.2.0
grep "version: 0.2.0" helm/todo-app/Chart.yaml

# TC2.2.2: Description mentions MCP or task management
grep -i "mcp\|task management" helm/todo-app/Chart.yaml
```

**Acceptance Criteria:**
- [ ] Version bumped to 0.2.0
- [ ] Description updated
- [ ] All test cases pass

---

### T2.3: Update values-production.yaml (Optional)

**File:** `helm/todo-app/values-production.yaml`

**Requirements:**
- Override mcpServer settings for production
- At least 2 replicas for HA
- Higher resource limits
- Enable autoscaling

**Test Cases:**
```bash
# TC2.3.1: Production has 2+ replicas
grep "replicaCount: [2-9]" helm/todo-app/values-production.yaml | grep -A1 "mcpServer"

# TC2.3.2: Autoscaling enabled
grep "enabled: true" helm/todo-app/values-production.yaml | grep -A5 "autoscaling"
```

**Acceptance Criteria:**
- [ ] Production overrides defined
- [ ] HA configuration (2+ replicas)
- [ ] Autoscaling enabled
- [ ] All test cases pass

---

## Task 3: Implementation Testing

### T3.1: Helm Lint and Template

**Requirements:**
- Helm chart passes linting
- Templates render without errors

**Test Cases:**
```bash
# TC3.1.1: Helm lint passes
helm lint ./helm/todo-app && echo "PASS" || echo "FAIL"

# TC3.1.2: Template renders successfully
helm template todo-app ./helm/todo-app > /tmp/rendered.yaml && echo "PASS" || echo "FAIL"

# TC3.1.3: All expected resources present
helm template todo-app ./helm/todo-app | grep "kind: Deployment" | wc -l | grep 3  # backend, frontend, mcp-server
```

**Acceptance Criteria:**
- [ ] Helm lint passes with no errors
- [ ] Templates render successfully
- [ ] All expected resources present
- [ ] All test cases pass

---

### T3.2: Deploy to Minikube

**Requirements:**
- Full stack deploys to Minikube
- All pods reach Running state
- All services created

**Test Cases:**
```bash
# TC3.2.1: Helm install succeeds
helm upgrade --install todo-app ./helm/todo-app --namespace todo-app --create-namespace && echo "PASS" || echo "FAIL"

# TC3.2.2: MCP server pod running
kubectl get pods -n todo-app -l app=mcp-server -o jsonpath='{.items[0].status.phase}' | grep "Running"

# TC3.2.3: MCP service exists
kubectl get svc mcp-server -n todo-app -o jsonpath='{.spec.type}' | grep "ClusterIP"

# TC3.2.4: All pods healthy
kubectl get pods -n todo-app | grep -v "Running" | grep -v "NAME" && echo "FAIL" || echo "PASS"

# TC3.2.5: Pod is ready
kubectl get pods -n todo-app -l app=mcp-server -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' | grep "True"
```

**Acceptance Criteria:**
- [ ] Helm install succeeds
- [ ] MCP server pod running
- [ ] MCP service created
- [ ] All pods healthy and ready
- [ ] All test cases pass

---

### T3.3: Test MCP Server Health

**Requirements:**
- Health endpoint responds with 200 OK
- Pod passes health checks

**Test Cases:**
```bash
# TC3.3.1: Health endpoint responds
kubectl port-forward -n todo-app svc/mcp-server 8001:8001 &
sleep 5
curl -f http://localhost:8001/health && echo "PASS" || echo "FAIL"
kill %1

# TC3.3.2: Liveness probe passing
kubectl get pods -n todo-app -l app=mcp-server -o jsonpath='{.items[0].status.conditions[?(@.type=="Ready")].status}' | grep "True"

# TC3.3.3: No restart loops
kubectl get pods -n todo-app -l app=mcp-server -o jsonpath='{.items[0].status.containerStatuses[0].restartCount}' | grep "^0$"
```

**Acceptance Criteria:**
- [ ] Health endpoint returns 200
- [ ] Probes passing
- [ ] No restart loops
- [ ] All test cases pass

---

### T3.4: Test Backend to MCP Communication

**Requirements:**
- Backend can reach MCP server
- DNS resolution works
- Network connectivity established

**Test Cases:**
```bash
# TC3.4.1: DNS resolves
kubectl exec -n todo-app deployment/backend -- nslookup mcp-server && echo "PASS" || echo "FAIL"

# TC3.4.2: Port accessible
kubectl exec -n todo-app deployment/backend -- nc -zv mcp-server 8001 && echo "PASS" || echo "FAIL"

# TC3.4.3: HTTP request succeeds
kubectl exec -n todo-app deployment/backend -- curl -f http://mcp-server:8001/health && echo "PASS" || echo "FAIL"
```

**Acceptance Criteria:**
- [ ] DNS resolution works
- [ ] Port accessible from backend
- [ ] HTTP requests succeed
- [ ] All test cases pass

---

### T3.5: Test Database Connectivity

**Requirements:**
- MCP server can connect to PostgreSQL
- Database operations succeed

**Test Cases:**
```bash
# TC3.5.1: Database connection from MCP pod
kubectl exec -n todo-app deployment/mcp-server -- nc -zv postgres 5432 && echo "PASS" || echo "FAIL"

# TC3.5.2: No connection errors in logs
kubectl logs -n todo-app -l app=mcp-server --tail=50 | grep -i "database.*error" && echo "FAIL" || echo "PASS"

# TC3.5.3: MCP server logs show successful startup
kubectl logs -n todo-app -l app=mcp-server --tail=50 | grep -i "started\|listening\|ready"
```

**Acceptance Criteria:**
- [ ] Database port accessible
- [ ] No connection errors
- [ ] Successful startup logged
- [ ] All test cases pass

---

## Task 4: Documentation Updates

### T4.1: Update README.md

**File:** `README.md`

**Requirements:**
- Add MCP server to architecture diagram
- Document three-tier architecture
- Update deployment instructions
- Add quick start section

**Test Cases:**
```bash
# TC4.1.1: README mentions MCP server
grep -i "mcp server" README.md && echo "PASS" || echo "FAIL"

# TC4.1.2: Architecture diagram updated
grep -i "three-tier\|3-tier\|backend.*mcp" README.md && echo "PASS" || echo "FAIL"

# TC4.1.3: Deployment section exists
grep -i "## deployment\|## quick start" README.md && echo "PASS" || echo "FAIL"
```

**Acceptance Criteria:**
- [ ] MCP server documented
- [ ] Architecture diagram includes MCP
- [ ] Deployment instructions updated
- [ ] All test cases pass

---

### T4.2: Update CLAUDE.md

**File:** `CLAUDE.md`

**Requirements:**
- Add sp.plan usage examples
- Add sp.impl implementation patterns
- Add sp.test testing guidelines
- Document Phase IV workflow

**Test Cases:**
```bash
# TC4.2.1: sp.plan documented
grep "sp.plan" CLAUDE.md && echo "PASS" || echo "FAIL"

# TC4.2.2: sp.impl documented
grep "sp.impl" CLAUDE.md && echo "PASS" || echo "FAIL"

# TC4.2.3: sp.test documented
grep "sp.test" CLAUDE.md && echo "PASS" || echo "FAIL"

# TC4.2.4: Phase IV mentioned
grep -i "phase iv\|phase 4" CLAUDE.md && echo "PASS" || echo "FAIL"
```

**Acceptance Criteria:**
- [ ] sp.* commands documented
- [ ] Usage examples provided
- [ ] Phase IV workflow described
- [ ] All test cases pass

---

### T4.3: Update AGENTS.md

**File:** `AGENTS.md`

**Requirements:**
- Add MCP server deployment patterns
- Document kubectl-ai commands for MCP
- Add troubleshooting scenarios

**Test Cases:**
```bash
# TC4.3.1: MCP server deployment commands
grep -i "mcp.*server\|mcp-server" AGENTS.md && echo "PASS" || echo "FAIL"

# TC4.3.2: kubectl-ai examples
grep "kubectl-ai.*mcp" AGENTS.md && echo "PASS" || echo "FAIL"

# TC4.3.3: Troubleshooting section
grep -i "troubleshoot.*mcp\|mcp.*debug" AGENTS.md && echo "PASS" || echo "FAIL"
```

**Acceptance Criteria:**
- [ ] MCP deployment patterns documented
- [ ] kubectl-ai commands added
- [ ] Troubleshooting guide included
- [ ] All test cases pass

---

### T4.4: Update Helm Chart README

**File:** `helm/todo-app/README.md`

**Requirements:**
- Document mcpServer values
- Add configuration examples
- Update architecture section

**Test Cases:**
```bash
# TC4.4.1: mcpServer values documented
grep "mcpServer" helm/todo-app/README.md && echo "PASS" || echo "FAIL"

# TC4.4.2: Configuration examples present
grep -A10 "mcpServer:" helm/todo-app/README.md | grep "replicaCount"

# TC4.4.3: Values table updated
grep -i "mcp.*server" helm/todo-app/README.md | grep -i "description\|default"
```

**Acceptance Criteria:**
- [ ] mcpServer values documented
- [ ] Examples provided
- [ ] Values table updated
- [ ] All test cases pass

---

## Task 5: CI/CD Integration

### T5.1: Update Build Scripts

**Files:** `scripts/build-images.sh`, `scripts/build-images.ps1`

**Requirements:**
- Document that MCP server reuses backend image
- Add comment about shared image

**Test Cases:**
```bash
# TC5.1.1: Script mentions MCP server
grep -i "mcp" scripts/build-images.sh && echo "PASS" || echo "FAIL"

# TC5.1.2: Comment about shared image
grep -i "reuse.*backend\|shared.*image" scripts/build-images.sh
```

**Acceptance Criteria:**
- [ ] MCP server documented in script
- [ ] Shared image noted
- [ ] All test cases pass

---

### T5.2: Update Deployment Scripts

**Files:** `scripts/deploy-helm.sh`, `scripts/deploy-helm.ps1`

**Requirements:**
- Verify MCP server deployment
- Check MCP server health

**Test Cases:**
```bash
# TC5.2.1: Script checks MCP server
grep "mcp.*server" scripts/deploy-helm.sh && echo "PASS" || echo "FAIL"

# TC5.2.2: Health verification
grep -i "health\|ready" scripts/deploy-helm.sh | grep -i "mcp"
```

**Acceptance Criteria:**
- [ ] MCP server verification added
- [ ] Health check included
- [ ] All test cases pass

---

### T5.3: Update Verification Script

**File:** `scripts/verify-deployment.sh`

**Requirements:**
- Check MCP server pod status
- Verify MCP service
- Test MCP health endpoint

**Test Cases:**
```bash
# TC5.3.1: Script checks MCP pod
grep "mcp.*server.*pod" scripts/verify-deployment.sh && echo "PASS" || echo "FAIL"

# TC5.3.2: Service verification
grep "mcp.*server.*service" scripts/verify-deployment.sh

# TC5.3.3: Health endpoint test
grep "curl.*mcp.*health\|mcp.*8001" scripts/verify-deployment.sh
```

**Acceptance Criteria:**
- [ ] MCP pod check added
- [ ] Service verification included
- [ ] Health test implemented
- [ ] All test cases pass

---

## Task 6: Final Verification

### T6.1: Full Stack Deployment Test

**Requirements:**
- Deploy entire stack from scratch
- All components running
- End-to-end functionality verified

**Test Cases:**
```bash
# TC6.1.1: Clean deployment
helm uninstall todo-app -n todo-app
kubectl delete namespace todo-app
helm install todo-app ./helm/todo-app --namespace todo-app --create-namespace
kubectl wait --for=condition=ready pod --all -n todo-app --timeout=300s && echo "PASS" || echo "FAIL"

# TC6.1.2: All pods running
kubectl get pods -n todo-app | grep -v "Running" | grep -v "NAME" && echo "FAIL" || echo "PASS"

# TC6.1.3: Frontend accessible
minikube service frontend -n todo-app --url

# TC6.1.4: Backend API working
kubectl port-forward -n todo-app svc/backend 8000:8000 &
sleep 5
curl -f http://localhost:8000/health && echo "PASS" || echo "FAIL"
kill %1

# TC6.1.5: MCP server working
kubectl port-forward -n todo-app svc/mcp-server 8001:8001 &
sleep 5
curl -f http://localhost:8001/health && echo "PASS" || echo "FAIL"
kill %1
```

**Acceptance Criteria:**
- [ ] Clean deployment succeeds
- [ ] All pods running
- [ ] All services accessible
- [ ] Health checks passing
- [ ] All test cases pass

---

### T6.2: Rolling Update Test

**Requirements:**
- Update deployment without downtime
- Rollback works correctly

**Test Cases:**
```bash
# TC6.2.1: Update image tag
helm upgrade todo-app ./helm/todo-app --set mcpServer.image.tag=latest-v2 -n todo-app
kubectl rollout status deployment/mcp-server -n todo-app && echo "PASS" || echo "FAIL"

# TC6.2.2: No downtime (pods available during update)
kubectl get pods -n todo-app -l app=mcp-server -w

# TC6.2.3: Rollback works
helm rollback todo-app -n todo-app
kubectl rollout status deployment/mcp-server -n todo-app && echo "PASS" || echo "FAIL"
```

**Acceptance Criteria:**
- [ ] Rolling update succeeds
- [ ] Zero downtime
- [ ] Rollback works
- [ ] All test cases pass

---

### T6.3: Resource Usage Verification

**Requirements:**
- Resource usage within limits
- No OOM kills
- CPU usage reasonable

**Test Cases:**
```bash
# TC6.3.1: Memory usage < 512Mi
kubectl top pod -n todo-app -l app=mcp-server | awk 'NR>1 {print $3}' | grep -E '^[0-9]+Mi$' | sed 's/Mi//' | awk '$1 < 512 {print "PASS"; exit} {print "FAIL"; exit}'

# TC6.3.2: CPU usage < 500m
kubectl top pod -n todo-app -l app=mcp-server | awk 'NR>1 {print $2}' | grep -E '^[0-9]+m$' | sed 's/m//' | awk '$1 < 500 {print "PASS"; exit} {print "FAIL"; exit}'

# TC6.3.3: No OOMKilled pods
kubectl get pods -n todo-app -l app=mcp-server -o jsonpath='{.items[*].status.containerStatuses[*].lastState.terminated.reason}' | grep "OOMKilled" && echo "FAIL" || echo "PASS"
```

**Acceptance Criteria:**
- [ ] Memory within limits
- [ ] CPU within limits
- [ ] No OOM kills
- [ ] All test cases pass

---

## Summary

**Total Tasks:** 18  
**Estimated Time:** ~2.5 hours

**Task Breakdown:**
- Helm Templates: 4 tasks (T1.1-T1.4)
- Configuration: 3 tasks (T2.1-T2.3)
- Testing: 5 tasks (T3.1-T3.5)
- Documentation: 4 tasks (T4.1-T4.4)
- CI/CD: 3 tasks (T5.1-T5.3)
- Verification: 3 tasks (T6.1-T6.3)

**Success Criteria:**
- All 18 tasks completed ✅
- All test cases passing ✅
- Documentation complete ✅
- Full stack deployed and verified ✅

---

**Document Status:** Ready for Implementation  
**Created:** 2026-02-12  
**Next Review:** Upon completion
