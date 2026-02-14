# Phase IV: MCP Server Deployment - Architecture Plan

**Project:** Todo App Kubernetes Deployment  
**Phase:** IV - MCP Server Containerization  
**Version:** 1.0  
**Created:** 2026-02-12

## Architecture Decisions

### AD-011: MCP Server Deployment Strategy

**Context:**
The MCP server code (`backend/app/mcp_server.py`) currently exists as part of the backend application but is not deployed separately. We need to deploy it as an independent microservice for better scalability and resource management.

**Decision:**
Deploy MCP server as a separate Kubernetes Deployment, reusing the backend Docker image with a different command.

**Alternatives Considered:**

1. **Embed in Backend (Status Quo)**
   - Pros: Simpler deployment, no network hop
   - Cons: Cannot scale independently, resource coupling
   - Verdict: ❌ Rejected (lacks flexibility)

2. **Separate Docker Image**
   - Pros: Complete isolation, independent versioning
   - Cons: Duplicate dependencies, more build complexity
   - Verdict: ❌ Rejected (unnecessary complexity)

3. **Reuse Backend Image, Different CMD** ✅ **SELECTED**
   - Pros: Shared codebase, simpler builds, less storage
   - Cons: Coupled image versions
   - Verdict: ✅ Best balance of simplicity and isolation

**Rationale:**
- MCP server code is in the same repository (`backend/app/`)
- Shares dependencies with backend (FastAPI, SQLAlchemy, etc.)
- Different entry point: `app.mcp_server:app` vs `app.main:app`
- Kubernetes command override allows different startup

**Consequences:**
- MCP server and backend share Docker image versions
- Updates to shared dependencies affect both services
- Simpler CI/CD pipeline (single image build)
- Reduced storage in container registry

**Implementation:**
```yaml
# Deployment command override
command: ["uvicorn", "app.mcp_server:app", "--host", "0.0.0.0", "--port", "8001"]
```

---

### AD-012: Service Communication Pattern

**Context:**
Backend needs to communicate with MCP server for task management operations. We need to decide on the communication protocol and service discovery mechanism.

**Decision:**
Use HTTP/REST over Kubernetes ClusterIP Service with DNS-based service discovery.

**Alternatives Considered:**

1. **gRPC**
   - Pros: Better performance, type safety
   - Cons: More complexity, requires protobuf definitions
   - Verdict: ❌ Overkill for this use case

2. **Message Queue (RabbitMQ/Kafka)**
   - Pros: Async processing, decoupling
   - Cons: Added infrastructure, complexity
   - Verdict: ❌ Not needed for synchronous operations

3. **HTTP/REST over ClusterIP** ✅ **SELECTED**
   - Pros: Simple, standard, works with existing code
   - Cons: Slightly slower than gRPC
   - Verdict: ✅ Best fit for requirements

**Rationale:**
- MCP server already exposes FastAPI endpoints
- Backend can use standard HTTP client (httpx/requests)
- Kubernetes service discovery via DNS (`mcp-server:8001`)
- No external exposure needed (ClusterIP sufficient)

**Consequences:**
- Backend makes HTTP calls to `http://mcp-server:8001/tasks`
- Service discovery automatic via Kubernetes DNS
- Network policies can restrict access to backend only
- Simple to test and debug

**Implementation:**
```python
# Backend code
import httpx

async def create_task_via_mcp(task_data):
    async with httpx.AsyncClient() as client:
        response = await client.post(
            "http://mcp-server:8001/tasks",
            json=task_data
        )
        return response.json()
```

---

### AD-013: Scaling Strategy

**Context:**
MCP server handles task management operations which may have different load patterns than the main API. We need a scaling strategy that's independent of the backend.

**Decision:**
Start with 1 replica, support manual scaling to 3 replicas, optional HPA on CPU utilization.

**Alternatives Considered:**

1. **Always 2+ Replicas (High Availability)**
   - Pros: No single point of failure
   - Cons: Higher resource cost for low-traffic deployments
   - Verdict: ❌ Overkill for initial deployment

2. **Single Replica Only**
   - Pros: Minimal resource usage
   - Cons: Single point of failure, no scaling
   - Verdict: ❌ Not flexible enough

3. **1 Replica with Optional Scaling** ✅ **SELECTED**
   - Pros: Cost-effective start, can scale when needed
   - Cons: Brief downtime during pod restarts
   - Verdict: ✅ Pragmatic approach

**Rationale:**
- Task operations likely lower volume than main API
- Most deployments won't need multiple replicas initially
- HPA allows automatic scaling if load increases
- Manual scaling available for known traffic spikes

**Consequences:**
- Default: 1 replica (cost-effective)
- Production can override to 2+ replicas via values file
- HPA can scale 1→3 based on CPU (70% threshold)
- Pod disruption budget should be configured for production

**Implementation:**
```yaml
# values.yaml
mcpServer:
  replicaCount: 1  # Default for dev/staging
  autoscaling:
    enabled: false  # Enable in production if needed
    minReplicas: 1
    maxReplicas: 3
    targetCPUUtilizationPercentage: 70

# values-production.yaml override
mcpServer:
  replicaCount: 2  # High availability
  autoscaling:
    enabled: true
```

---

### AD-014: Resource Allocation

**Context:**
MCP server needs CPU and memory resources defined to ensure proper scheduling and prevent resource contention.

**Decision:**
Set resource requests to 256Mi/250m CPU, limits to 512Mi/500m CPU, matching backend defaults.

**Alternatives Considered:**

1. **No Limits (Best Effort)**
   - Pros: Can use excess capacity
   - Cons: Risk of noisy neighbor, OOM kills
   - Verdict: ❌ Not production-ready

2. **Higher Limits (1Gi/1 CPU)**
   - Pros: More headroom
   - Cons: Wastes resources, higher costs
   - Verdict: ❌ Over-provisioned

3. **Match Backend Resources** ✅ **SELECTED**
   - Pros: Consistent, proven in backend
   - Cons: May need adjustment based on actual usage
   - Verdict: ✅ Good starting point

**Rationale:**
- MCP server has similar workload to backend (FastAPI, DB queries)
- Backend resources are already tuned and working
- Consistency simplifies capacity planning
- Can adjust based on actual metrics

**Consequences:**
- Same resource profile as backend
- Predictable scheduling behavior
- May need tuning after production deployment
- Monitor actual usage and adjust

**Implementation:**
```yaml
resources:
  requests:
    memory: "256Mi"
    cpu: "250m"
  limits:
    memory: "512Mi"
    cpu: "500m"
```

---

### AD-015: Configuration Management

**Context:**
MCP server needs database credentials and configuration. We need to decide how to manage these settings.

**Decision:**
Reuse postgres-secret for database credentials, create optional mcp-config ConfigMap for MCP-specific settings.

**Alternatives Considered:**

1. **Separate mcp-secret**
   - Pros: Complete isolation
   - Cons: Duplicate database credentials
   - Verdict: ❌ Unnecessary duplication

2. **All in Helm Values**
   - Pros: Centralized configuration
   - Cons: Secrets in values files
   - Verdict: ❌ Security risk

3. **Reuse Secrets, Optional ConfigMap** ✅ **SELECTED**
   - Pros: DRY principle, secure secrets
   - Cons: Shared secret dependency
   - Verdict: ✅ Pragmatic and secure

**Rationale:**
- MCP server uses same PostgreSQL database
- No need to duplicate postgres password
- MCP-specific config can go in ConfigMap
- Future: can split if auth requirements change

**Consequences:**
- MCP server depends on postgres-secret
- If MCP server needs separate DB user, create new secret
- ConfigMap for non-sensitive MCP settings
- Environment variables constructed in deployment

**Implementation:**
```yaml
env:
- name: DATABASE_URL
  value: "postgresql://postgres:$(POSTGRES_PASSWORD)@postgres:5432/todo_db"
- name: POSTGRES_PASSWORD
  valueFrom:
    secretKeyRef:
      name: postgres-secret
      key: POSTGRES_PASSWORD
- name: LOG_LEVEL
  valueFrom:
    configMapKeyRef:
      name: mcp-config
      key: logLevel
      optional: true
```

---

### AD-016: Health Check Configuration

**Context:**
Kubernetes needs health checks to determine if MCP server is ready and healthy. We need to define appropriate probes.

**Decision:**
Implement liveness, readiness, and startup probes on `/health` endpoint with appropriate timings.

**Alternatives Considered:**

1. **No Health Checks**
   - Pros: Simpler configuration
   - Cons: No automatic recovery, poor orchestration
   - Verdict: ❌ Not production-ready

2. **TCP Probes Only**
   - Pros: Lightweight
   - Cons: Doesn't verify application health
   - Verdict: ❌ Insufficient

3. **HTTP Probes on /health** ✅ **SELECTED**
   - Pros: Verifies application is responding, standard practice
   - Cons: Requires /health endpoint
   - Verdict: ✅ Best practice

**Rationale:**
- MCP server can implement `/health` endpoint easily
- HTTP probes verify actual application health
- Consistent with backend health checks
- Enables proper pod lifecycle management

**Consequences:**
- MCP server must implement `/health` endpoint
- Kubernetes will restart unhealthy pods
- ReadinessProbe prevents traffic to unready pods
- StartupProbe gives extra time for initial startup

**Implementation:**
```yaml
livenessProbe:
  httpGet:
    path: /health
    port: 8001
  initialDelaySeconds: 30
  periodSeconds: 10
  timeoutSeconds: 5
  failureThreshold: 3

readinessProbe:
  httpGet:
    path: /health
    port: 8001
  initialDelaySeconds: 10
  periodSeconds: 5
  timeoutSeconds: 3
  failureThreshold: 2

startupProbe:
  httpGet:
    path: /health
    port: 8001
  initialDelaySeconds: 0
  periodSeconds: 5
  failureThreshold: 12  # 60 seconds total
```

---

### AD-017: Helm Chart Organization

**Context:**
We need to integrate MCP server into the existing Helm chart structure. Should it be a separate chart or part of the main chart?

**Decision:**
Add MCP server templates to the existing `helm/todo-app` chart, with an enable/disable flag.

**Alternatives Considered:**

1. **Separate Helm Chart**
   - Pros: Complete independence
   - Cons: Dependency management complexity
   - Verdict: ❌ Over-engineering

2. **Umbrella Chart**
   - Pros: Modular structure
   - Cons: More complex, harder to manage
   - Verdict: ❌ Overkill for 4 components

3. **Single Chart with Conditionals** ✅ **SELECTED**
   - Pros: Simple, atomic deployments, easy management
   - Cons: Larger chart
   - Verdict: ✅ Best for this scale

**Rationale:**
- All components are tightly coupled (same application)
- Single Helm release easier to manage
- Atomic deployments ensure consistency
- Conditional rendering allows flexibility

**Consequences:**
- MCP server templates in `helm/todo-app/templates/`
- Can disable via `mcpServer.enabled: false`
- Single `helm upgrade` deploys all components
- Chart version bump to 0.2.0

**Implementation:**
```yaml
# templates/mcp-deployment.yaml
{{- if .Values.mcpServer.enabled }}
apiVersion: apps/v1
kind: Deployment
metadata:
  name: {{ include "todo-app.fullname" . }}-mcp-server
# ...
{{- end }}
```

---

## Implementation Checklist

### Helm Chart Files

- [ ] `helm/todo-app/templates/mcp-configmap.yaml` - MCP configuration
- [ ] `helm/todo-app/templates/mcp-deployment.yaml` - MCP deployment
- [ ] `helm/todo-app/templates/mcp-service.yaml` - MCP service
- [ ] `helm/todo-app/templates/mcp-hpa.yaml` - MCP autoscaler (optional)
- [ ] Update `helm/todo-app/values.yaml` - Add mcpServer section
- [ ] Update `helm/todo-app/Chart.yaml` - Bump version to 0.2.0
- [ ] Update `helm/todo-app/README.md` - Document MCP server

### Documentation

- [ ] Update `README.md` - Architecture diagram with MCP server
- [ ] Update `CLAUDE.md` - Add sp.* command patterns
- [ ] Update `AGENTS.md` - MCP server deployment patterns
- [ ] Update `constitution/MAIN.md` - Reference MCP server
- [ ] Create `specs/phase-iv-mcp-deployment/spec.md` ✅
- [ ] Create `specs/phase-iv-mcp-deployment/plan.md` (this file) ✅

### Testing

- [ ] Unit test MCP server health endpoint
- [ ] Integration test backend → MCP server communication
- [ ] Deploy to Minikube and verify
- [ ] Load test MCP server endpoints
- [ ] Test autoscaling behavior (if enabled)

### CI/CD

- [ ] Update `scripts/build-images.sh` (already builds backend image)
- [ ] Update `scripts/deploy-helm.sh` - Verify MCP server deployment
- [ ] Update `.github/workflows/build-and-deploy.yml` if needed

---

## Timeline

**Total Estimated Time: ~2.5 hours**

| Phase | Tasks | Duration |
|-------|-------|----------|
| Helm Templates | Create 4 template files | 30 min |
| Values & Config | Update values.yaml, Chart.yaml | 15 min |
| Documentation | Update 4 docs (README, CLAUDE, AGENTS, etc.) | 45 min |
| Testing | Deploy, verify, integration tests | 30 min |
| Scripts | Update build/deploy scripts | 15 min |
| Verification | Full deployment test, cleanup | 15 min |

---

## Success Metrics

### Technical Metrics

- ✅ MCP server pod starts within 30 seconds
- ✅ Health endpoint returns 200 OK
- ✅ Backend can call MCP server successfully
- ✅ Resource usage within limits (< 512Mi, < 500m CPU)
- ✅ Zero failed deployments

### Operational Metrics

- ✅ Helm chart deploys successfully in one command
- ✅ Documentation complete and accurate
- ✅ All tests passing
- ✅ No manual intervention required

---

## Rollback Plan

If deployment fails or issues arise:

1. **Helm Rollback:**
   ```bash
   helm rollback todo-app -n todo-app
   ```

2. **Disable MCP Server:**
   ```bash
   helm upgrade todo-app ./helm/todo-app \
     --set mcpServer.enabled=false \
     -n todo-app
   ```

3. **Manual Cleanup:**
   ```bash
   kubectl delete deployment mcp-server -n todo-app
   kubectl delete service mcp-server -n todo-app
   ```

---

**Document Status:** Final Draft  
**Approved By:** TBD  
**Implementation Start:** 2026-02-12
