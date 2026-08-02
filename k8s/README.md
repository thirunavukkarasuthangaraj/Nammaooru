# NammaOoru - Kubernetes Setup

## Folder Structure

```
k8s/
├── namespace.yaml            # nammaooru namespace
├── configmap.yaml            # App config (non-sensitive)
├── secret.yaml               # Passwords & API keys (sensitive)
├── postgres-pvc.yaml         # PostgreSQL storage (10GB)
├── postgres-deployment.yaml  # PostgreSQL pod
├── postgres-service.yaml     # PostgreSQL internal service
├── uploads-pvc.yaml          # File uploads storage (20GB)
├── backend-deployment.yaml   # Spring Boot (2 pods)
├── backend-service.yaml      # Backend internal service
├── ingress.yaml              # Expose API to internet
└── hpa.yaml                  # Auto scaling (2-5 pods)
```

## Prerequisites

- Minikube installed (for local practice)
- kubectl installed
- Docker image built: `nammaooru-backend:1.0.267`

## How to Practice (Local - Minikube)

### 1. Start Minikube
```bash
minikube start --memory=4096 --cpus=2
minikube addons enable ingress
```

### 2. Build your backend image inside Minikube
```bash
eval $(minikube docker-env)
docker build -t nammaooru-backend:1.0.267 ./backend
```

### 3. Fill in your secrets
Edit `secret.yaml` and replace all `your-*-here` values with real values.

### 4. Deploy everything
```bash
kubectl apply -f k8s/namespace.yaml
kubectl apply -f k8s/secret.yaml
kubectl apply -f k8s/configmap.yaml
kubectl apply -f k8s/postgres-pvc.yaml
kubectl apply -f k8s/postgres-deployment.yaml
kubectl apply -f k8s/postgres-service.yaml
kubectl apply -f k8s/uploads-pvc.yaml
kubectl apply -f k8s/backend-deployment.yaml
kubectl apply -f k8s/backend-service.yaml
kubectl apply -f k8s/hpa.yaml
kubectl apply -f k8s/ingress.yaml
```

Or deploy all at once:
```bash
kubectl apply -f k8s/
```

### 5. Check everything is running
```bash
kubectl get all -n nammaooru
kubectl get pods -n nammaooru
kubectl logs -f deployment/nammaooru-backend -n nammaooru
```

### 6. Access locally
```bash
minikube service backend-service -n nammaooru --url
```

## Useful Commands

```bash
# Check pods
kubectl get pods -n nammaooru

# Check logs
kubectl logs -f deployment/nammaooru-backend -n nammaooru

# Check services
kubectl get services -n nammaooru

# Scale manually
kubectl scale deployment nammaooru-backend --replicas=3 -n nammaooru

# Check auto scaler
kubectl get hpa -n nammaooru

# Enter a pod (like docker exec)
kubectl exec -it <pod-name> -n nammaooru -- /bin/sh

# Remove everything
kubectl delete -f k8s/
```

## When Moving to Production (Hetzner Server)

1. Install K3s: `curl -sfL https://get.k3s.io | sh -`
2. Build and push image to registry (Docker Hub or private)
3. Update image name in `backend-deployment.yaml`
4. Fill real secrets in `secret.yaml`
5. Apply all files: `kubectl apply -f k8s/`
```
