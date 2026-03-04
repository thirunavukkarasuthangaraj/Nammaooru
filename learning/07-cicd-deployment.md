# 07 - CI/CD & Zero Downtime Deployment

## What You'll Learn
- What CI/CD is
- Your GitHub Actions pipeline
- Zero downtime deployment strategy
- Rolling deployments
- Rollback strategies

---

## 1. What is CI/CD?

```
CI (Continuous Integration):
  Developer pushes code --> Auto build --> Auto test --> Report
  "Does my code compile? Do tests pass?"

CD (Continuous Deployment):
  Tests pass --> Auto deploy to server --> Users get new version
  "Ship to production automatically"

Your Pipeline:
  Push to main --> GitHub Actions --> Build --> Deploy to Hetzner --> Zero Downtime
```

---

## 2. Your GitHub Actions Pipeline

```yaml
# .github/workflows/deploy-production-zero-downtime.yml
name: Deploy Production

on:
  push:
    branches: [main]        # Trigger on push to main

jobs:
  deploy:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Deploy to Server
        uses: appleboy/ssh-action@v1
        with:
          host: YOUR_SERVER_IP
          username: root
          key: ${{ secrets.SSH_PRIVATE_KEY }}
          script: |
            cd /opt/shop-management
            git pull origin main
            ./zero-downtime-deploy.sh
```

---

## 3. Zero Downtime Deployment Flow

```
Timeline:
0s  [Old v1.0.259 running, serving users]
     |
1s  [Build new image v1.0.260]
     |
30s [Start new container v1.0.260]
     |
60s [Wait for health check: /actuator/health = UP]
     |
65s [Switch Nginx upstream to new container]
     |
66s [New v1.0.260 serving all traffic]
     |
70s [Gracefully stop old v1.0.259 container]
     |
75s [Cleanup old Docker images]

User experience: ZERO interruption
```

### The Deployment Script Logic:

```bash
#!/bin/bash
# zero-downtime-deploy.sh (simplified)

# 1. Build new image
docker build -t yourapp-backend:new ./backend

# 2. Start new container on different port
docker run -d --name backend-new -p 8083:8080 \
  --env-file .env \
  yourapp-backend:new

# 3. Wait for health check
for i in {1..30}; do
  if curl -s http://localhost:8083/actuator/health | grep -q "UP"; then
    echo "New container is healthy!"
    break
  fi
  sleep 2
done

# 4. Switch Nginx to new container
sed -i 's/localhost:8082/localhost:8083/' /etc/nginx/sites-enabled/api
nginx -t && systemctl reload nginx

# 5. Stop old container
docker stop backend-old
docker rm backend-old

# 6. Rename new to current
docker rename backend-new backend-current

echo "Deployment complete!"
```

---

## 4. Rollback Strategy

```bash
# If new version has bugs:

# Option 1: Quick rollback (keep old image)
docker stop backend-new
docker start backend-old
# Switch Nginx back to old port
systemctl reload nginx

# Option 2: Git rollback + redeploy
git revert HEAD
git push origin main
# Pipeline deploys previous version

# Option 3: Deploy specific version
docker run -d yourapp-backend:v1.0.259  # Previous version tag
```

---

## Key Takeaways

1. **CI/CD automates** build, test, and deploy on every push
2. **Zero downtime** = start new before stopping old
3. **Health checks** ensure new version works before switching traffic
4. **Always keep** the previous version for quick rollback
5. **GitHub Actions** connects to your Hetzner server via SSH

---

## Next: [08 - Firewalls & Security](./08-firewalls-security.md)
