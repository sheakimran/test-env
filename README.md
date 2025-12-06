# SkillShare Platform Deployment

A comprehensive guide for deploying the SkillShare Platform using Docker, Docker Compose, and Kubernetes.

## Overview

The SkillShare Platform consists of three main components:
- **Backend**: Node.js API server with Express, PostgreSQL database, JWT authentication
- **Frontend**: React single-page application with Ant Design UI
- **Database**: PostgreSQL for persistent data storage

This deployment guide focuses on containerized deployments ensuring consistent and scalable environments.

## Prerequisites

### Docker Compose Deployment
- **Docker**: Version 18.03+ (for multi-stage builds)
- **Docker Compose**: Version 1.25+
- **Git**: For repository cloning
- **System**: 4GB+ RAM, multi-core CPU

### Kubernetes Deployment
- **Kubernetes cluster**: Version 1.16+ (Minikube for local testing)
- **kubectl**: CLI tool configured for cluster access
- **Git**: For repository cloning
- **Storage**: Persistent volume support for database data

## Installation

Clone the repository:
```bash
git clone <repository-url>
cd node-react-postgres
```

## Docker Compose Deployment

Docker Compose orchestrates multi-container applications for local development and testing.

### Environment Configuration
Create a `.env` file in the project root:

```env
# Database
POSTGRES_DB=skillshare
POSTGRES_USER=admin
POSTGRES_PASSWORD=securepassword123

# Backend
NODE_ENV=production
API_PORT=5000
JWT_SECRET=your-256-bit-secret
DATABASE_URL=postgresql://admin:securepassword123@postgres:5432/skillshare

# Frontend
REACT_APP_API_URL=http://localhost:5000
REACT_APP_ENV=production
```

### Services Configuration
The `docker-compose.yml` defines three services:

```yaml
version: '3.8'
services:
  postgres:
    image: postgres:14
    environment:
      POSTGRES_DB: ${POSTGRES_DB}
      POSTGRES_USER: ${POSTGRES_USER}
      POSTGRES_PASSWORD: ${POSTGRES_PASSWORD}
    volumes:
      - postgres_data:/var/lib/postgresql/data
    ports:
      - "5432:5432"
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U ${POSTGRES_USER}"]

  backend:
    build:
      context: .
      dockerfile: Dockerfile.backend
    environment:
      NODE_ENV: ${NODE_ENV}
      DATABASE_URL: ${DATABASE_URL}
      JWT_SECRET: ${JWT_SECRET}
    ports:
      - "${API_PORT:-5000}:5000"
    depends_on:
      postgres:
        condition: service_healthy

  frontend:
    build:
      context: .
      dockerfile: Dockerfile.frontend
    environment:
      REACT_APP_API_URL: ${REACT_APP_API_URL}
    ports:
      - "3000:80"
    depends_on:
      - backend

volumes:
  postgres_data:
```

### Deployment Steps

1. **Build and run**:
   ```bash
   docker-compose up --build
   ```

2. **Verify services**:
   ```bash
   docker-compose ps
   ```

3. **Access application**:
   - Frontend: http://localhost:3000
   - Backend API: http://localhost:5000/api/v1/health
   - Database: localhost:5432

### Scaling and Management

**Scale backend instances**:
```bash
docker-compose up -d --scale backend=3
```

**Update application**:
```bash
docker-compose up --build -d
```

**View logs**:
```bash
docker-compose logs -f
docker-compose logs -f backend
```

### Troubleshooting Docker Compose

**Common Issues**:

1. **Port conflicts**: Change ports in `.env` or stop conflicting services
2. **Build failures**: Run `docker-compose build --no-cache`
3. **Database connection**: Check `docker-compose logs postgres`
4. **Memory issues**: Increase Docker memory limits

## Kubernetes Deployment

Kubernetes provides production-grade orchestration with scaling, self-healing, and service discovery.

### Key Resources
- **Deployments**: Manage replica sets and rolling updates
- **Services**: Network abstractions for pod access
- **PersistentVolumeClaims**: Storage for PostgreSQL data
- **ConfigMaps/Secrets**: Configuration management
- **Ingress**: External access routing

### Environment Setup

1. **Create namespace**:
   ```bash
   kubectl create namespace skillshare-dev
   kubectl config set-context --current --namespace=skillshare-dev
   ```

2. **Configure secrets** (base64 encoded):
   ```bash
   echo -n "your-jwt-secret" | base64
   echo -n "db-password" | base64
   ```

   Update `k8s/app-secret.yaml` and `k8s/app-configmap.yaml` accordingly.

### Namespace Configuration

Kubernetes manifests are organized in the `k8s/` directory:

- **`namespace-dev.yaml`**: Namespace creation
- **`postgres-pvc.yaml`**: Persistent volume claim (5Gi storage)
- **`postgres-statefulset.yaml`**: Database with persistent storage
- **`postgres-service.yaml`**: Internal database service
- **`app-configmap.yaml`**: Non-sensitive configuration
- **`app-secret.yaml`**: Sensitive secrets (base64 encoded)
- **`backend-deployment.yaml`**: API server deployment (3 replicas)
- **`backend-service.yaml`**: Backend service (port 5000)
- **`frontend-deployment.yaml`**: React app deployment (2 replicas)
- **`frontend-service.yaml`**: Frontend service (port 80)
- **`ingress-dev.yaml`**: External access with TLS

### Deployment Steps

1. **Apply manifests**:
   ```bash
   kubectl apply -f k8s/
   ```

2. **Monitor deployment**:
   ```bash
   kubectl get all
   kubectl get pods -o wide
   ```

3. **Configure ingress**:
   Edit `k8s/ingress-dev.yaml` with your domain and apply:
   ```bash
   kubectl apply -f k8s/ingress-dev.yaml
   ```

4. **Verify access**:
   - Frontend: https://your-domain.com
   - API: https://api.your-domain.com

### Scaling and Updates

**Scale deployments**:
```bash
kubectl scale deployment backend-deployment --replicas=5
kubectl scale deployment frontend-deployment --replicas=3
```

**Rolling updates**:
```bash
kubectl set image deployment/backend-deployment backend=new-image:v2.0
kubectl rollout status deployment/backend-deployment
```

**Rollback**:
```bash
kubectl rollout undo deployment/backend-deployment
```

### Monitoring and Logs

**View pod logs**:
```bash
kubectl logs -f deployment/backend-deployment
kubectl logs -f deployment/frontend-deployment
kubectl logs -f statefulset/postgres-statefulset
```

**Resource usage**:
```bash
kubectl top pods
kubectl top nodes
```

**Describe resources**:
```bash
kubectl describe pod backend-pod-name
kubectl describe service backend-service
```

### Troubleshooting Kubernetes

**Common Issues**:

1. **Pods not starting**:
   ```bash
   kubectl describe pod <pod-name>
   kubectl logs <pod-name> --previous
   ```

2. **Service unreachable**:
   ```bash
   kubectl get endpoints
   kubectl describe service <service-name>
   ```

3. **Ingress not working**:
   ```bash
   kubectl get ingress
   kubectl describe ingress skillshare-ingress
   ```

4. **Resource constraints**:
   ```bash
   kubectl top pods
   kubectl top nodes
   ```

## Configuration Reference

### Required Environment Variables

Backend:
- `DATABASE_URL`: PostgreSQL connection string
- `JWT_SECRET`: JWT signing secret (256-bit recommended)
- `JWT_REFRESH_SECRET`: Refresh token secret

Frontend:
- `REACT_APP_API_URL`: Backend API URL
- `REACT_APP_ENV`: Environment (development/production)

Database:
- `POSTGRES_DB`: Database name
- `POSTGRES_USER`: Admin username
- `POSTGRES_PASSWORD`: Admin password

### Port Configuration

Docker Compose:
- Backend: 5000 (configurable via `API_PORT`)
- Frontend: 3000
- Database: 5432 (configurable via `POSTGRES_PORT`)

Kubernetes:
- Backend: 5000 (internally)
- Frontend: 80 (internally)
- Database: 5432 (internally)
- Ingress: 80/443 (externally)

### Docker Compose Override Files

Create environment-specific files:
- `docker-compose.dev.yml`: Development overrides
- `docker-compose.test.yml`: Testing environment
- `docker-compose.prod.yml`: Production settings

Example:
```bash
docker-compose -f docker-compose.yml -f docker-compose.prod.yml up
```

## Security Considerations

### Container Security
1. **Base images**: Use official, trusted images
2. **Non-root users**: Run applications as non-root
3. **Image scanning**: Scan for vulnerabilities before deployment
4. **Secret management**: Never store secrets in images

### Kubernetes Security
1. **RBAC**: Implement role-based access control
2. **Network policies**: Restrict pod communication
3. **TLS**: Configure HTTPS with certificates
4. **Security contexts**: Define pod security policies

### Environment Security
- Store sensitive data in Kubernetes Secrets
- Use managed identity for cloud services
- Rotate secrets regularly
- Audit access logs

## Performance Optimization

### Docker Compose
1. **Multi-stage builds**: Reduce image size
2. **Layer caching**: Order commands for cache efficiency
3. **Resource limits**: Set CPU/memory limits

### Kubernetes
1. **Horizontal Pod Autoscaling**:
   ```yaml
   apiVersion: autoscaling/v2
   kind: HorizontalPodAutoscaler
   spec:
     minReplicas: 2
     maxReplicas: 10
     metrics:
     - type: Resource
       resource:
         name: cpu
         target:
           type: Utilization
           averageUtilization: 70
   ```

2. **Resource requests/limits**: Right-size resource allocation
3. **Pod affinity**: Optimize pod placement
4. **Connection pooling**: Database connection pooling

### Performance Monitoring
```bash
# Docker
docker stats

# Kubernetes
kubectl top pods
kubectl top nodes
```

## Backup and Recovery

### Database Backup

**Docker Compose**:
```bash
docker-compose exec postgres pg_dump -U admin skillshare > backup.sql
docker-compose exec -T postgres psql -U admin skillshare < backup.sql
```

**Kubernetes**:
```bash
kubectl exec -it postgres-pod -- pg_dump -U admin skillshare > backup.sql
kubectl exec -it postgres-pod -- psql -U admin skillshare < backup.sql
```

### Automated Backups

Example CronJob for Kubernetes:
```yaml
apiVersion: batch/v1beta1
kind: CronJob
spec:
  schedule: "0 2 * * *"
  jobTemplate:
    spec:
      containers:
      - name: backup
        image: postgres:14
        command: ["pg_dump"]
        args: ["-h", "postgres-service", "-U", "admin", "skillshare"]
        env:
        - name: PGPASSWORD
          valueFrom:
            secretKeyRef:
              name: postgres-secret
              key: password
```

### Application Backup
- Git: Store manifests and configs
- Registry: Push images regularly
- Data: Regular database backups
- Documentation: Keep deployment runbooks

## Troubleshooting Guide

### Logs Analysis

**Docker Compose**:
```bash
docker-compose logs -f backend
docker-compose logs --tail=100 frontend
```

**Kubernetes**:
```bash
kubectl logs -f deployment/backend-deployment
kubectl logs -f statefulset/postgres-statefulset
kubectl logs -f pod/specific-pod-name --previous
```

### Network Issues

**Service discovery**:
```bash
kubectl get endpoints
kubectl describe service <service-name>
```

**DNS resolution**:
```bash
kubectl exec -it pod -- nslookup postgres-service
```

**Connectivity testing**:
```bash
kubectl port-forward svc/backend-service 8080:5000
curl http://localhost:8080/health
```

### Database Issues

**Health check**:
```bash
kubectl exec -it postgres-pod -- psql -U admin -d skillshare -c "SELECT version();"
```

**Connection debugging**:
- Check DATABASE_URL configuration
- Verify service endpoints
- Review pod logs for connection errors

## Best Practices

### Development
1. Keep manifests version-controlled
2. Use environment-specific configurations
3. Automate testing and validation
4. Document deployment processes

### Production
1. Implement monitoring and alerting
2. Set up log aggregation
3. Regular backup verification
4. Security patches and updates

### Performance
1. Optimize Docker images (use Alpine, multi-stage builds)
2. Configure appropriate resource limits
3. Implement caching strategies
4. Use CDNs for static assets

## Migration Guide

### Local Development → Docker Compose
1. Create Dockerfiles for backend and frontend
2. Set up `docker-compose.yml` with services
3. Migrate database data
4. Update environment variables

### Docker Compose → Kubernetes
1. Use Kompose to convert docker-compose.yml
2. Convert volumes to PersistentVolumeClaims
3. Add Ingress for external access
4. Implement security policies

### Updates Strategy
1. Deploy canary releases for testing
2. Use rolling updates with health checks
3. Have rollback plans ready
4. Monitor application metrics

## Support and Resources

### Official Documentation
- [Docker Docs](https://docs.docker.com/)
- [Docker Compose](https://docs.docker.com/compose/)
- [Kubernetes](https://kubernetes.io/docs/)

### Community Resources
- Docker Forums: https://forums.docker.com/
- Kubernetes Slack: https://slack.k8s.io/
- Stack Overflow: linux/docker tags

### Tools and Utilities
- **k9s**: Terminal-based Kubernetes UI
- **Lens**: Kubernetes IDE
- **Kompose**: Docker Compose → Kubernetes converter
- **kustomize**: Kubernetes configuration management

### Useful Commands

**Docker Compose**:
```bash
docker-compose build --no-cache    # Force rebuild
docker-compose up -d               # Detached mode
docker-compose down -v            # Remove volumes
docker-compose logs -f backend     # Follow logs
```

**Kubernetes**:
```bash
kubectl get all                   # All resources
kubectl describe pod <name>       # Pod details
kubectl exec -it <pod> -- sh      # Pod shell
kubectl port-forward svc/service 8080:80  # Port forward
kubectl scale deployment <name> --replicas=5  # Scale
