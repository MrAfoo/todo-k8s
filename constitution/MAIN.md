# Todo App Kubernetes Deployment Constitution

**Version:** 2.0  
**Last Updated:** 2026-02-12  
**Status:** Active

## Purpose

This constitution defines the core principles, standards, and governance for deploying and operating the AI-Powered Todo Application on Kubernetes. It serves as the foundational document for all deployment decisions and operational practices.

## Core Principles

### 1. Cloud-Native First

**We build for cloud-native environments from the ground up.**

- All services are containerized and stateless (except databases)
- Applications follow the 12-factor app methodology
- Infrastructure is declarative and version-controlled
- Deployments are immutable and reproducible

### 2. Security by Default

**Security is not optional; it's built into every layer.**

- No root containers - all services run as non-root users
- Secrets are never hardcoded or committed to version control
- Network policies enforce least-privilege communication
- Regular security scanning of images and dependencies
- HTTPS/TLS for all external communication

### 3. Observability & Transparency

**We cannot manage what we cannot measure.**

- All services expose health and readiness probes
- Structured logging with appropriate log levels
- Metrics exposed for monitoring (Prometheus-compatible)
- Distributed tracing for request flows
- Clear error messages and debugging information

### 4. Automation Over Manual Work

**Automate everything that can be automated.**

- Infrastructure as Code (Helm charts, K8s manifests)
- CI/CD pipelines for build, test, and deploy
- AI DevOps tools (Gordon, kubectl-ai, Kagent) for operations
- Automated backups and disaster recovery
- Self-healing through health checks and autoscaling

### 5. Scalability & Performance

**Design for growth from day one.**

- Horizontal scaling preferred over vertical
- Resource requests and limits defined for all workloads
- Horizontal Pod Autoscaling (HPA) for variable load
- Performance budgets and monitoring
- Efficient database queries and caching strategies

### 6. Developer Experience

**Make it easy to build, test, and deploy.**

- Local development matches production environment
- Quick setup with Minikube and Helm
- Clear documentation and examples
- Fast feedback loops (< 5 min from code to deployed)
- Troubleshooting guides for common issues

## Architecture Principles

### Service Architecture

**Three-Tier Separation:**
1. **Frontend** - User interface (Next.js)
2. **Backend** - Business logic API (FastAPI)
3. **MCP Server** - Task management operations (FastAPI)
4. **Database** - Data persistence (PostgreSQL)

**Communication Patterns:**
- Frontend → Backend (HTTP/REST)
- Backend → Database (PostgreSQL protocol)
- Backend ↔ MCP Server (HTTP/REST, internal only)
- External → Frontend only (via Ingress/LoadBalancer)

### Deployment Model

**Stateless Services:**
- Frontend and Backend run as Deployments
- Multiple replicas for high availability
- Rolling updates with zero downtime
- Pod disruption budgets for stability

**Stateful Services:**
- PostgreSQL runs as StatefulSet (or managed service)
- Persistent Volume Claims for data durability
- Regular automated backups
- Point-in-time recovery capability

### Resource Management

**Resource Allocation Strategy:**
```yaml
Small Service (Frontend/Backend/MCP):
  requests:
    memory: 256Mi
    cpu: 250m
  limits:
    memory: 512Mi
    cpu: 500m

Database (PostgreSQL):
  requests:
    memory: 1Gi
    cpu: 500m
  limits:
    memory: 2Gi
    cpu: 1000m
```

**Autoscaling Thresholds:**
- Minimum replicas: 2 (high availability)
- Maximum replicas: 10 (cost control)
- Target CPU: 70-80%
- Scale-up: Fast (1-2 minutes)
- Scale-down: Slow (5-10 minutes)

## Operational Standards

### Environments

**Environment Hierarchy:**
1. **Local** - Developer workstations (Minikube/Docker Desktop)
2. **Staging** - Pre-production testing (namespace: `todo-app-staging`)
3. **Production** - Live user traffic (namespace: `todo-app`)

**Environment Parity:**
- Same Helm charts across all environments
- Values files differentiate configuration
- Staging mirrors production configuration
- Test data in staging, real data in production

### Deployment Process

**Standard Deployment Flow:**
1. Code commit → Git repository
2. CI builds and tests → Container images
3. Push images → Container registry
4. Update Helm values → Git commit
5. Helm upgrade → Kubernetes cluster
6. Health checks → Verify deployment
7. Monitoring → Observe metrics

**Rollback Strategy:**
- Helm rollback on deployment failure
- Keep last 5 revisions for quick recovery
- Automated rollback on health check failures
- Manual approval for production deployments

### Configuration Management

**Configuration Hierarchy:**
1. **Helm Values** - Infrastructure and service config
2. **ConfigMaps** - Non-sensitive application config
3. **Secrets** - Sensitive data (passwords, API keys)
4. **Environment Variables** - Runtime configuration

**Secret Management:**
- Development: Kubernetes Secrets (base64 encoded)
- Production: External secret manager (AWS Secrets Manager, HashiCorp Vault, etc.)
- Rotation: Automated secret rotation every 90 days
- Access: Principle of least privilege

### Monitoring & Alerting

**Key Metrics:**
- Pod health and restart counts
- Resource utilization (CPU, memory, disk)
- Request rates and latencies
- Error rates and status codes
- Database connection pool usage

**Alert Conditions:**
- Pod restart loops (> 3 restarts in 5 minutes)
- High error rate (> 5% of requests)
- Resource exhaustion (> 90% CPU/memory)
- Database connection failures
- Disk space critically low (< 10%)

## Governance

### Change Management

**Architecture Decision Records (ADRs):**
- All significant decisions documented in `specs/`
- Template: Context, Decision, Consequences, Alternatives
- Reviewed and approved by team
- Immutable once approved (new ADR to change)

**Code Review Requirements:**
- All changes via pull requests
- At least one approval required
- Automated tests must pass
- Security scanning must pass
- Documentation updated

### Quality Gates

**Pre-Deployment Checks:**
- [ ] Unit tests pass (> 80% coverage)
- [ ] Integration tests pass
- [ ] Security scan clean (no high/critical vulnerabilities)
- [ ] Performance tests meet budgets
- [ ] Documentation updated
- [ ] Helm chart lints successfully

**Post-Deployment Verification:**
- [ ] All pods running and ready
- [ ] Health endpoints responding
- [ ] Smoke tests pass
- [ ] Metrics flowing to monitoring
- [ ] Logs being collected

## AI DevOps Integration

### Gordon (Docker Build Automation)

**Role:** Automated container image building
**Usage:**
```bash
./scripts/gordon-build.sh         # Build all images
gordon build backend              # Build specific service
gordon build --push --tag v1.0.0  # Build and push with tag
```

**Principles:**
- Multi-stage builds for efficiency
- Layer caching for speed
- Security scanning in build pipeline
- Semantic versioning for tags

### kubectl-ai (Kubernetes Operations)

**Role:** Natural language Kubernetes operations
**Usage:**
```bash
kubectl-ai deploy todo app using helm
kubectl-ai scale backend to 5 replicas in todo-app
kubectl-ai show logs for failing pods in todo-app
```

**Principles:**
- Human-friendly commands
- Namespace awareness
- Safety checks before destructive operations
- Context-aware suggestions

### Kagent (Monitoring & Optimization)

**Role:** Intelligent monitoring and resource optimization
**Usage:**
```bash
kagent monitor todo-app namespace
kagent optimize resources for backend
kagent suggest scaling for frontend
```

**Principles:**
- Proactive issue detection
- Resource optimization recommendations
- Cost-aware scaling suggestions
- Anomaly detection and alerting

## References

- [Deployment Guidelines](./deployment.md) - Detailed deployment procedures
- [Security Best Practices](./security.md) - Security hardening guide
- [AI DevOps Integration](./ai-devops.md) - Gordon/kubectl-ai/Kagent usage
- [12-Factor App](https://12factor.net/) - Application design principles
- [Kubernetes Best Practices](https://kubernetes.io/docs/concepts/configuration/overview/)

---

**Document History:**
- **2.0** (2026-02-12): Restructured into constitution/ directory, added MCP server
- **1.0** (2026-02-12): Initial constitution created

**Maintained by:** Todo App Team  
**Review Cycle:** Quarterly or on major architecture changes
