# Phase IV: MCP Server Deployment - Specification

**Project:** Todo App Kubernetes Deployment  
**Phase:** IV - MCP Server Containerization  
**Status:** Planning  
**Created:** 2026-02-12  
**Owner:** DevOps Team

## Executive Summary

Deploy the Model Context Protocol (MCP) server as a separate, independently scalable microservice within the Todo App Kubernetes architecture. This enables better resource management, independent scaling, and clearer separation of concerns between the main API and task management operations.

## Objectives

### Primary Goals

1. **Containerize MCP Server**: Package the MCP server (`backend/app/mcp_server.py`) as a separate Docker container
2. **Kubernetes Deployment**: Deploy MCP server as an independent Kubernetes Deployment
3. **Service Discovery**: Enable backend to communicate with MCP server via Kubernetes Service
4. **Helm Integration**: Add MCP server to the existing Helm chart for unified deployment
5. **Documentation**: Update all documentation to reflect the new architecture

### Success Criteria

- ✅ MCP server runs as separate deployment with 1-3 replicas
- ✅ Backend can successfully communicate with MCP server
- ✅ Helm chart deploys all components (frontend, backend, mcp-server, postgres)
- ✅ Health checks and monitoring configured for MCP server
- ✅ Documentation complete and accurate
- ✅ All tests passing

## Background

### Current State

**Existing Architecture:**
```
Frontend (Next.js) → Backend (FastAPI) → PostgreSQL
                      ↓
                MCP Server Code (embedded)
```

**Current Implementation:**
- MCP server code exists in `backend/app/mcp_server.py`
- MCP server is not deployed separately
- Task management operations handled by MCP server module

**Limitations:**
- Cannot scale MCP server independently
- Resource allocation tied to backend
- No isolation between API and task operations

### Desired State

**Target Architecture:**
```
Frontend (Next.js) → Backend (FastAPI) ←→ MCP Server (FastAPI)
                          ↓                      ↓
                      PostgreSQL ←────────────────┘
```

**Benefits:**
- Independent scaling of MCP server
- Resource isolation (CPU/memory)
- Better fault isolation
- Clearer service boundaries

## Requirements

### Functional Requirements

**FR-1: MCP Server Deployment**
- MCP server must run as separate Kubernetes Deployment
- Minimum 1 replica, maximum 3 replicas
- Must be accessible via ClusterIP Service on port 8001

**FR-2: Backend Integration**
- Backend must communicate with MCP server via HTTP
- Service discovery via Kubernetes DNS (mcp-server:8001)
- Graceful handling of MCP server unavailability

**FR-3: Health Checks**
- Liveness probe on `/health` endpoint
- Readiness probe on `/health` endpoint
- Startup probe with 40-second grace period

**FR-4: Configuration**
- Environment variables for database connection
- ConfigMap for non-sensitive configuration
- Secrets for sensitive data (if needed)

**FR-5: Helm Chart**
- MCP server templates in existing Helm chart
- Values file configuration for MCP server
- Optional enable/disable via values

### Non-Functional Requirements

**NFR-1: Performance**
- MCP server response time < 200ms (p95)
- Startup time < 30 seconds
- Resource usage < 512Mi memory, < 500m CPU

**NFR-2: Scalability**
- Support horizontal scaling (1-3 replicas)
- Optional HPA based on CPU utilization (70%)
- Handle 100+ concurrent requests

**NFR-3: Reliability**
- 99.9% uptime (same as backend)
- Zero-downtime deployments
- Automatic pod restart on failure

**NFR-4: Security**
- Run as non-root user (UID 1000)
- No privileged containers
- ClusterIP only (not exposed externally)
- Network policies to restrict access

**NFR-5: Observability**
- Structured logging to stdout
- Prometheus metrics endpoint (if applicable)
- Kubernetes events for lifecycle changes

## Architecture

### Component Diagram

```
┌─────────────────────────────────────────────────────────────┐
│                    Kubernetes Cluster                        │
│                                                              │
│  ┌──────────────┐     ┌──────────────┐    ┌──────────────┐ │
│  │   Frontend   │────▶│   Backend    │───▶│ MCP Server   │ │
│  │ Deployment   │     │ Deployment   │    │ Deployment   │ │
│  │ (2+ pods)    │     │ (2+ pods)    │    │ (1-3 pods)   │ │
│  └──────┬───────┘     └──────┬───────┘    └──────┬───────┘ │
│         │                    │                   │          │
│  ┌──────▼───────┐     ┌──────▼───────┐    ┌──────▼───────┐ │
│  │   frontend   │     │   backend    │    │  mcp-server  │ │
│  │   Service    │     │   Service    │    │   Service    │ │
│  │ (LB:80→3000) │     │ (CIP:8000)   │    │  (CIP:8001)  │ │
│  └──────────────┘     └──────┬───────┘    └──────┬───────┘ │
│                              │                   │          │
│                       ┌──────▼───────────────────▼───────┐  │
│                       │        PostgreSQL                │  │
│                       │       StatefulSet                │  │
│                       │    (1 replica + PVC)             │  │
│                       └──────────────────────────────────┘  │
└─────────────────────────────────────────────────────────────┘
```

### Communication Flow

**1. Task Creation (Frontend → Backend → MCP Server):**
```
1. User creates task in Frontend
2. Frontend sends POST /api/tasks to Backend
3. Backend validates request
4. Backend calls MCP Server POST /tasks
5. MCP Server saves to PostgreSQL
6. MCP Server returns task to Backend
7. Backend returns task to Frontend
```

**2. MCP Server Internal (MCP Server → PostgreSQL):**
```
1. MCP Server receives task operation
2. MCP Server validates data
3. MCP Server executes database query
4. PostgreSQL returns result
5. MCP Server returns formatted response
```

### Data Flow

**Database Connection:**
- Backend → PostgreSQL (direct connection)
- MCP Server → PostgreSQL (direct connection)
- Shared database `todo_db`
- Same credentials from `postgres-secret`

**Service Discovery:**
- Backend connects to MCP Server: `http://mcp-server:8001`
- DNS resolution via Kubernetes CoreDNS
- No external exposure of MCP Server

## Technical Specifications

### Docker Image

**Option A: Reuse Backend Image (Recommended)**
```dockerfile
# Use same backend Dockerfile
# Different CMD in Kubernetes deployment
FROM python:3.13-slim
# ... (same as backend)
CMD ["uvicorn", "app.mcp_server:app", "--host", "0.0.0.0", "--port", "8001"]
```

**Option B: Separate Dockerfile**
```dockerfile
# backend/mcp.Dockerfile
FROM python:3.13-slim as builder
# ... (similar to backend)
CMD ["uvicorn", "app.mcp_server:app", "--host", "0.0.0.0", "--port", "8001"]
```

**Decision: Option A** (reuse backend image, different CMD)
- Rationale: Shared codebase, simpler build process, less storage

### Kubernetes Resources

**Deployment Spec:**
```yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: mcp-server
  namespace: todo-app
spec:
  replicas: 1
  selector:
    matchLabels:
      app: mcp-server
  template:
    metadata:
      labels:
        app: mcp-server
    spec:
      containers:
      - name: mcp-server
        image: todo-backend:latest  # Reuse backend image
        command: ["uvicorn", "app.mcp_server:app", "--host", "0.0.0.0", "--port", "8001"]
        ports:
        - containerPort: 8001
        env:
        - name: DATABASE_URL
          value: "postgresql://postgres:$(POSTGRES_PASSWORD)@postgres:5432/todo_db"
        - name: POSTGRES_PASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: POSTGRES_PASSWORD
        resources:
          requests:
            memory: "256Mi"
            cpu: "250m"
          limits:
            memory: "512Mi"
            cpu: "500m"
        livenessProbe:
          httpGet:
            path: /health
            port: 8001
          initialDelaySeconds: 30
          periodSeconds: 10
        readinessProbe:
          httpGet:
            path: /health
            port: 8001
          initialDelaySeconds: 10
          periodSeconds: 5
```

**Service Spec:**
```yaml
apiVersion: v1
kind: Service
metadata:
  name: mcp-server
  namespace: todo-app
spec:
  selector:
    app: mcp-server
  ports:
  - port: 8001
    targetPort: 8001
  type: ClusterIP
```

### Helm Values

**helm/todo-app/values.yaml:**
```yaml
mcpServer:
  enabled: true
  replicaCount: 1
  image:
    repository: todo-backend  # Reuse backend image
    tag: latest
  service:
    type: ClusterIP
    port: 8001
  resources:
    requests:
      memory: "256Mi"
      cpu: "250m"
    limits:
      memory: "512Mi"
      cpu: "500m"
  autoscaling:
    enabled: false
    minReplicas: 1
    maxReplicas: 3
    targetCPUUtilizationPercentage: 70
  config:
    logLevel: info
```

## Implementation Strategy

### Phase 1: Preparation (Est. 30 min)
- [ ] Create specs/ directory structure
- [ ] Document architecture decisions
- [ ] Update constitution/ with principles

### Phase 2: Helm Chart Development (Est. 45 min)
- [ ] Create `helm/todo-app/templates/mcp-configmap.yaml`
- [ ] Create `helm/todo-app/templates/mcp-deployment.yaml`
- [ ] Create `helm/todo-app/templates/mcp-service.yaml`
- [ ] Create `helm/todo-app/templates/mcp-hpa.yaml` (optional)
- [ ] Update `helm/todo-app/values.yaml`
- [ ] Update `helm/todo-app/Chart.yaml` version to 0.2.0

### Phase 3: Testing (Est. 30 min)
- [ ] Deploy to Minikube
- [ ] Verify pod starts successfully
- [ ] Test backend → MCP server communication
- [ ] Test database connectivity
- [ ] Load testing (if applicable)

### Phase 4: Documentation (Est. 45 min)
- [ ] Update README.md
- [ ] Update CLAUDE.md
- [ ] Update AGENTS.md
- [ ] Update helm/todo-app/README.md
- [ ] Create deployment guide

### Phase 5: CI/CD Integration (Est. 30 min)
- [ ] Update build scripts
- [ ] Update deployment scripts
- [ ] Update GitHub Actions workflow

## Testing Plan

### Unit Tests
- MCP server endpoints respond correctly
- Health check returns 200 OK
- Database connection succeeds

### Integration Tests
- Backend can call MCP server endpoints
- MCP server can read/write to PostgreSQL
- Task CRUD operations work end-to-end

### Performance Tests
- Response time < 200ms for task operations
- Handle 100 concurrent requests
- Resource usage within limits

### Deployment Tests
- Helm chart deploys successfully
- All pods reach Ready state
- Rolling updates work without downtime
- Rollback works correctly

## Rollout Plan

### Stage 1: Development (Week 1)
- Create Helm templates
- Test locally with Minikube
- Verify functionality

### Stage 2: Staging (Week 2)
- Deploy to staging environment
- Run integration tests
- Performance testing

### Stage 3: Production (Week 3)
- Deploy to production with gradual rollout
- Monitor metrics closely
- Rollback plan ready

## Risk Assessment

### Risks and Mitigation

**Risk 1: MCP Server Unavailable**
- **Impact:** Backend cannot perform task operations
- **Probability:** Low
- **Mitigation:** Health checks, auto-restart, circuit breaker pattern

**Risk 2: Performance Degradation**
- **Impact:** Slower task operations due to network hop
- **Probability:** Medium
- **Mitigation:** Keep-alive connections, connection pooling, monitoring

**Risk 3: Database Connection Pool Exhaustion**
- **Impact:** Both backend and MCP server use PostgreSQL
- **Probability:** Low
- **Mitigation:** Increase max_connections, implement connection limits

**Risk 4: Network Policy Issues**
- **Impact:** Backend cannot reach MCP server
- **Probability:** Low
- **Mitigation:** Test network policies, document allowed traffic

## Monitoring and Metrics

### Key Metrics

**Application Metrics:**
- Request rate (requests/second)
- Response time (p50, p95, p99)
- Error rate (%)
- Active connections to PostgreSQL

**Infrastructure Metrics:**
- CPU utilization (%)
- Memory usage (MB)
- Pod restart count
- Network throughput (bytes/sec)

### Alerts

**Critical:**
- Pod restart loop (> 3 restarts in 5 min)
- High error rate (> 5%)
- Service unavailable

**Warning:**
- High CPU (> 80%)
- High memory (> 90%)
- Slow responses (p95 > 500ms)

## Dependencies

### Internal Dependencies
- Backend application (must integrate with MCP server)
- PostgreSQL database (shared database)
- Helm chart infrastructure

### External Dependencies
- Kubernetes cluster (v1.28+)
- Docker/container runtime
- Helm (v3.8+)

## Open Questions

1. **Q:** Should MCP server have its own database user?
   **A:** No, share postgres user for simplicity in Phase IV

2. **Q:** Should we implement authentication between backend and MCP server?
   **A:** Not in Phase IV (internal ClusterIP only), consider for Phase V

3. **Q:** What's the fallback if MCP server is down?
   **A:** Backend should return 503 Service Unavailable, implement circuit breaker

## References

- [MCP Server Implementation](../../backend/app/mcp_server.py)
- [Backend Application](../../backend/app/main.py)
- [Existing Helm Chart](../../helm/todo-app/)
- [CONSTITUTION.md](../../constitution/MAIN.md)

---

**Document Status:** Draft  
**Next Review:** 2026-02-15  
**Approval Required:** DevOps Lead, Backend Lead
