# Security Best Practices

**Part of:** Todo App Kubernetes Constitution  
**Version:** 1.0  
**Last Updated:** 2026-02-12

## Overview

Security is a foundational principle of the Todo App deployment. This document outlines security best practices, threat models, and hardening guidelines for all deployment environments.

## Security Principles

### Defense in Depth

**Multiple layers of security controls:**
1. Network layer (Network Policies)
2. Pod layer (Security Contexts)
3. Container layer (Non-root users, read-only filesystems)
4. Application layer (Authentication, authorization)
5. Data layer (Encryption at rest and in transit)

### Principle of Least Privilege

**Minimal permissions at every level:**
- Containers run as non-root users
- Service accounts have minimal RBAC permissions
- Network policies restrict pod-to-pod communication
- Secrets accessible only to pods that need them

### Security by Default

**Secure configurations out of the box:**
- TLS/HTTPS for all external communication
- Strong password policies
- Regular security updates
- Automated vulnerability scanning

## Container Security

### Non-Root Containers

**All containers MUST run as non-root users.**

**Backend Dockerfile:**
```dockerfile
# Create non-root user
RUN useradd -m -u 1000 appuser

# Switch to non-root user
USER appuser
```

**Kubernetes Security Context:**
```yaml
securityContext:
  runAsNonRoot: true
  runAsUser: 1000
  fsGroup: 1000
  allowPrivilegeEscalation: false
  capabilities:
    drop:
    - ALL
  readOnlyRootFilesystem: true  # Where possible
```

### Image Security

**Base Image Selection:**
- Use official images from trusted registries
- Prefer Alpine or distroless variants (smaller attack surface)
- Pin specific versions (avoid `latest` tag)

```yaml
# Good
image: postgres:16-alpine
image: python:3.13-slim

# Avoid
image: postgres:latest
image: python
```

**Image Scanning:**
```bash
# Scan images before deployment
docker scan todo-backend:latest
docker scan todo-frontend:latest

# Or use trivy
trivy image todo-backend:latest
trivy image todo-frontend:latest
```

**Vulnerability Thresholds:**
- **Block:** Critical vulnerabilities
- **Warn:** High vulnerabilities (must fix within 7 days)
- **Monitor:** Medium/Low vulnerabilities

### Read-Only Filesystem

**Where applicable, use read-only root filesystems:**

```yaml
securityContext:
  readOnlyRootFilesystem: true

# Mount writable volumes only where needed
volumeMounts:
- name: tmp
  mountPath: /tmp
- name: cache
  mountPath: /app/.cache

volumes:
- name: tmp
  emptyDir: {}
- name: cache
  emptyDir: {}
```

## Secret Management

### Development vs Production

**Development/Local:**
- Kubernetes Secrets (base64 encoded)
- Default passwords documented as "CHANGE IN PRODUCTION"
- Secrets in values files for local testing only

**Production:**
- External secret managers (AWS Secrets Manager, HashiCorp Vault, Azure Key Vault)
- Automated secret rotation
- Audit logging for secret access
- No secrets in Git repositories

### Secret Creation

**Development:**
```bash
# Create backend secret
kubectl create secret generic backend-secret \
  --from-literal=BETTER_AUTH_SECRET=$(openssl rand -base64 32) \
  --from-literal=SECRET_KEY=$(openssl rand -base64 32) \
  --from-literal=GROQ_API_KEY=gsk_your_actual_key_here \
  -n todo-app
```

**Production (External Secrets Operator):**
```yaml
apiVersion: external-secrets.io/v1beta1
kind: ExternalSecret
metadata:
  name: backend-secret
spec:
  refreshInterval: 1h
  secretStoreRef:
    name: aws-secrets-manager
    kind: SecretStore
  target:
    name: backend-secret
  data:
  - secretKey: BETTER_AUTH_SECRET
    remoteRef:
      key: todo-app/backend/auth-secret
  - secretKey: SECRET_KEY
    remoteRef:
      key: todo-app/backend/secret-key
  - secretKey: GROQ_API_KEY
    remoteRef:
      key: todo-app/backend/groq-api-key
```

### Secret Rotation

**Rotation Schedule:**
- Passwords: Every 90 days
- API Keys: Every 180 days or on compromise
- TLS Certificates: 30 days before expiry

**Rotation Process:**
1. Generate new secret
2. Store in secret manager
3. Update Kubernetes secret
4. Restart pods to pick up new secret
5. Verify functionality
6. Deactivate old secret

### Secret Usage

**Environment Variables (Preferred):**
```yaml
env:
- name: SECRET_KEY
  valueFrom:
    secretKeyRef:
      name: backend-secret
      key: SECRET_KEY
```

**Volume Mounts (For Files):**
```yaml
volumeMounts:
- name: secrets
  mountPath: /etc/secrets
  readOnly: true

volumes:
- name: secrets
  secret:
    secretName: backend-secret
    defaultMode: 0400  # Read-only for owner
```

## Network Security

### Network Policies

**Default Deny Policy:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: default-deny-all
  namespace: todo-app
spec:
  podSelector: {}
  policyTypes:
  - Ingress
  - Egress
```

**Frontend Network Policy:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: frontend-network-policy
  namespace: todo-app
spec:
  podSelector:
    matchLabels:
      app: frontend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - namespaceSelector: {}  # Allow from Ingress controller
    ports:
    - protocol: TCP
      port: 3000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: backend
    ports:
    - protocol: TCP
      port: 8000
  - to:  # DNS
    - namespaceSelector:
        matchLabels:
          name: kube-system
    ports:
    - protocol: UDP
      port: 53
```

**Backend Network Policy:**
```yaml
apiVersion: networking.k8s.io/v1
kind: NetworkPolicy
metadata:
  name: backend-network-policy
  namespace: todo-app
spec:
  podSelector:
    matchLabels:
      app: backend
  policyTypes:
  - Ingress
  - Egress
  ingress:
  - from:
    - podSelector:
        matchLabels:
          app: frontend
    ports:
    - protocol: TCP
      port: 8000
  egress:
  - to:
    - podSelector:
        matchLabels:
          app: postgres
    ports:
    - protocol: TCP
      port: 5432
  - to:
    - podSelector:
        matchLabels:
          app: mcp-server
    ports:
    - protocol: TCP
      port: 8001
  - to:  # External APIs (Groq)
    ports:
    - protocol: TCP
      port: 443
```

### TLS/HTTPS

**Ingress TLS:**
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: todo-app-ingress
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  tls:
  - hosts:
    - todo-app.example.com
    secretName: todo-app-tls
  rules:
  - host: todo-app.example.com
    http:
      paths:
      - path: /
        pathType: Prefix
        backend:
          service:
            name: frontend
            port:
              number: 80
```

**Service Mesh (Optional - Advanced):**
- Istio or Linkerd for mutual TLS between services
- Automatic certificate rotation
- Traffic encryption without application changes

## Authentication & Authorization

### User Authentication

**Backend (FastAPI):**
- JWT tokens with HS256 algorithm
- Token expiry: 30 minutes (configurable)
- Refresh tokens for long-lived sessions
- Password hashing with bcrypt

**Security Headers:**
```python
# app/main.py
app.add_middleware(
    CORSMiddleware,
    allow_origins=settings.allowed_origins_list,
    allow_credentials=True,
    allow_methods=["GET", "POST", "PUT", "DELETE"],
    allow_headers=["*"],
)

# Add security headers
@app.middleware("http")
async def add_security_headers(request, call_next):
    response = await call_next(request)
    response.headers["X-Content-Type-Options"] = "nosniff"
    response.headers["X-Frame-Options"] = "DENY"
    response.headers["X-XSS-Protection"] = "1; mode=block"
    response.headers["Strict-Transport-Security"] = "max-age=31536000; includeSubDomains"
    return response
```

### Service Account RBAC

**Minimal Service Account Permissions:**

```yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: backend-sa
  namespace: todo-app
---
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  name: backend-role
  namespace: todo-app
rules:
- apiGroups: [""]
  resources: ["configmaps"]
  verbs: ["get", "list"]
- apiGroups: [""]
  resources: ["secrets"]
  verbs: ["get"]
  resourceNames: ["backend-secret"]
---
apiVersion: rbac.authorization.k8s.io/v1
kind: RoleBinding
metadata:
  name: backend-rolebinding
  namespace: todo-app
subjects:
- kind: ServiceAccount
  name: backend-sa
roleRef:
  kind: Role
  name: backend-role
  apiGroup: rbac.authorization.k8s.io
```

## Database Security

### PostgreSQL Hardening

**Connection Security:**
```yaml
# PostgreSQL ConfigMap
data:
  postgresql.conf: |
    # Network
    listen_addresses = '*'
    port = 5432
    
    # SSL (production)
    ssl = on
    ssl_cert_file = '/etc/ssl/certs/server.crt'
    ssl_key_file = '/etc/ssl/private/server.key'
    
    # Authentication
    password_encryption = scram-sha-256
    
    # Logging
    log_connections = on
    log_disconnections = on
    log_statement = 'mod'  # Log all modifications
```

**pg_hba.conf (Host-Based Authentication):**
```
# TYPE  DATABASE        USER            ADDRESS                 METHOD
host    all             all             10.0.0.0/8              scram-sha-256
host    all             all             127.0.0.1/32            scram-sha-256
local   all             postgres                                peer
```

**Backup Encryption:**
```bash
# Encrypted backup
kubectl exec postgres-0 -n todo-app -- \
  pg_dump -U postgres todo_db | \
  gpg --encrypt --recipient admin@example.com > backup.sql.gpg

# Restore encrypted backup
gpg --decrypt backup.sql.gpg | \
  kubectl exec -i postgres-0 -n todo-app -- \
  psql -U postgres -d todo_db
```

### Data Encryption

**At Rest:**
- Use encrypted persistent volumes (cloud provider encryption)
- Encrypt database backups
- Store encryption keys in KMS (AWS KMS, Google Cloud KMS)

**In Transit:**
- TLS for PostgreSQL connections (production)
- HTTPS for all HTTP traffic
- Mutual TLS for service-to-service (optional)

## Compliance & Auditing

### Audit Logging

**Kubernetes Audit Policy:**
```yaml
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
- level: Metadata
  namespaces: ["todo-app"]
  verbs: ["create", "update", "patch", "delete"]
  resources:
  - group: ""
    resources: ["secrets", "configmaps"]
- level: Request
  namespaces: ["todo-app"]
  verbs: ["create", "delete"]
  resources:
  - group: "apps"
    resources: ["deployments", "statefulsets"]
```

**Application Logging:**
- Log all authentication attempts (success and failure)
- Log all data modifications
- Log all API errors
- Sanitize logs (no secrets or PII)

### Security Scanning

**Continuous Scanning:**
```bash
# Daily cron job to scan running images
0 3 * * * kubectl get pods -n todo-app -o json | \
  jq -r '.items[].spec.containers[].image' | \
  xargs -I {} trivy image {}
```

**Pre-Deployment Scanning:**
```yaml
# GitHub Actions
- name: Scan Docker image
  uses: aquasecurity/trivy-action@master
  with:
    image-ref: 'todo-backend:${{ github.sha }}'
    format: 'sarif'
    output: 'trivy-results.sarif'
    severity: 'CRITICAL,HIGH'
    exit-code: '1'  # Fail on critical/high
```

## Incident Response

### Security Incident Procedure

**1. Detection:**
- Automated alerts from monitoring
- Security scan findings
- User reports

**2. Containment:**
```bash
# Isolate compromised pod
kubectl label pod <pod-name> quarantine=true -n todo-app
kubectl apply -f network-policy-quarantine.yaml

# Scale down compromised deployment
kubectl scale deployment <deployment> --replicas=0 -n todo-app
```

**3. Investigation:**
```bash
# Collect logs
kubectl logs <pod-name> -n todo-app --previous > incident-logs.txt

# Collect events
kubectl get events -n todo-app --sort-by='.lastTimestamp' > incident-events.txt

# Collect pod spec
kubectl get pod <pod-name> -n todo-app -o yaml > incident-pod.yaml
```

**4. Eradication:**
- Rotate all secrets
- Deploy patched version
- Update security policies

**5. Recovery:**
- Deploy clean version
- Verify functionality
- Monitor for re-infection

**6. Post-Mortem:**
- Document incident
- Update security policies
- Implement preventive controls

### Emergency Contacts

- **Security Team:** security@example.com
- **On-Call Engineer:** oncall@example.com
- **Incident Commander:** incident-commander@example.com

## Security Checklist

### Pre-Deployment

- [ ] All images scanned for vulnerabilities
- [ ] No critical/high vulnerabilities present
- [ ] Secrets rotated within policy
- [ ] Network policies defined and tested
- [ ] Pod security contexts configured
- [ ] Resource limits set
- [ ] RBAC policies reviewed
- [ ] TLS certificates valid

### Post-Deployment

- [ ] All pods running as non-root
- [ ] Network policies enforced
- [ ] Secrets not exposed in logs
- [ ] Audit logging enabled
- [ ] Monitoring alerts configured
- [ ] Backup encryption verified
- [ ] Incident response plan reviewed

### Regular Maintenance

- [ ] Weekly: Review security alerts
- [ ] Monthly: Scan running images
- [ ] Quarterly: Rotate secrets
- [ ] Quarterly: Security audit
- [ ] Annually: Penetration testing

## Security Tools

### Recommended Tools

**Scanning:**
- Trivy - Container vulnerability scanning
- Falco - Runtime security monitoring
- Kube-bench - CIS Kubernetes benchmark

**Secret Management:**
- External Secrets Operator
- HashiCorp Vault
- AWS Secrets Manager

**Network Security:**
- Calico - Advanced network policies
- Istio/Linkerd - Service mesh with mTLS

**Compliance:**
- Open Policy Agent (OPA) - Policy enforcement
- Kyverno - Kubernetes policy engine

## References

- [CIS Kubernetes Benchmark](https://www.cisecurity.org/benchmark/kubernetes)
- [OWASP Top 10](https://owasp.org/www-project-top-ten/)
- [Kubernetes Security Best Practices](https://kubernetes.io/docs/concepts/security/)
- [NIST Cybersecurity Framework](https://www.nist.gov/cyberframework)

---

**See Also:**
- [Main Constitution](./MAIN.md)
- [Deployment Guidelines](./deployment.md)
- [AI DevOps Integration](./ai-devops.md)
