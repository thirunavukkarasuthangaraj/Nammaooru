# 06 - Docker & Containers

## What You'll Learn
- What Docker is and why you use it
- Containers vs VMs
- Your Docker setup explained
- Docker networking (how containers talk to each other)
- Docker Compose deep dive
- Useful Docker commands for daily operations

---

## 1. What is Docker?

### The Problem Docker Solves:
```
Without Docker:
  "It works on my machine!" -- Developer
  "It doesn't work on the server!" -- DevOps

  Why? Different Java versions, different OS, missing libraries,
  different config files...

With Docker:
  Package your app + ALL its dependencies into a "container"
  Same container runs identically everywhere.
  Developer's laptop = Staging server = Production server
```

### Container = Lightweight, Isolated Environment:
```
┌──────────── Your Server (Host OS: Ubuntu) ────────────┐
│                                                        │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────┐  │
│  │ Container 1 │  │ Container 2 │  │ Container 3  │  │
│  │ Spring Boot │  │   Angular   │  │  PostgreSQL  │  │
│  │ Java 17     │  │   Nginx     │  │     16       │  │
│  │ Port 8082   │  │   Port 80   │  │  Port 5432   │  │
│  └─────────────┘  └─────────────┘  └──────────────┘  │
│                                                        │
│  [Docker Engine]                                       │
│  [Host OS: Ubuntu 22.04]                               │
│  [Hardware: CX33 - 4 vCPU, 8GB RAM]                   │
└────────────────────────────────────────────────────────┘
```

---

## 2. Container vs Virtual Machine

```
Virtual Machine:                    Container:
┌────────────┐                     ┌────────────┐
│    App      │                     │    App      │
│   Libraries │                     │   Libraries │
│   Guest OS  │  <-- Full OS!       │             │  <-- No OS!
│   (2-3 GB)  │                     │  (~200 MB)  │
└────────────┘                     └────────────┘
│ Hypervisor  │                     │Docker Engine│
│   Host OS   │                     │   Host OS   │
│  Hardware   │                     │  Hardware   │
└─────────────┘                     └─────────────┘

VM: Heavy, slow to start (minutes), uses lots of RAM
Container: Light, starts in seconds, shares host OS kernel
```

| Feature | VM | Container |
|---------|------|-----------|
| Size | 2-10 GB | 50-500 MB |
| Start time | 1-5 minutes | 1-5 seconds |
| RAM usage | Full OS + App | App only |
| Isolation | Complete | Process-level |
| Use case | Different OS needed | Same app packaging |

---

## 3. Your Docker Setup Explained

### Backend Dockerfile (Multi-stage Build):

```dockerfile
# Stage 1: BUILD
FROM maven:3.9.6-eclipse-temurin-17 AS builder
WORKDIR /app
COPY pom.xml .
RUN mvn dependency:go-offline          # Download deps (cached layer)
COPY src ./src
RUN mvn clean package -DskipTests     # Build the JAR

# Stage 2: RUN (smaller image)
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app
COPY --from=builder /app/target/*.jar app.jar

# Run as non-root user (security)
RUN addgroup -S appgroup && adduser -S appuser -G appgroup
USER appuser

EXPOSE 8080
ENTRYPOINT ["java", "-Xms512m", "-Xmx768m", "-jar", "app.jar"]
```

### Why Multi-stage?
```
Stage 1 (builder): Has Maven, JDK, source code = ~800MB
Stage 2 (runtime): Only JRE + JAR file = ~200MB

You ship the small image! Build tools are NOT included.
```

### Frontend Dockerfile:

```dockerfile
# Stage 1: BUILD Angular
FROM node:18-alpine AS builder
WORKDIR /app
COPY package*.json ./
RUN npm ci                             # Install exact versions
COPY . .
RUN npm run build -- --configuration=production

# Stage 2: SERVE with Nginx
FROM nginx:alpine
COPY --from=builder /app/dist/your-app /usr/share/nginx/html
COPY nginx.conf /etc/nginx/conf.d/default.conf

EXPOSE 80
CMD ["nginx", "-g", "daemon off;"]
```

---

## 4. Docker Compose (Your docker-compose.yml Explained)

```yaml
version: '3.8'

services:
  # --- Backend Service ---
  backend:
    build:
      context: ./backend
      dockerfile: Dockerfile
    ports:
      - "8082:8080"                    # Host:Container
    environment:
      - DB_URL=jdbc:postgresql://host.docker.internal:5432/shop_management_db
      - DB_USERNAME=${DB_USERNAME}
      - DB_PASSWORD=${DB_PASSWORD}
      - JWT_SECRET=${JWT_SECRET}
      - FILE_UPLOAD_PATH=/app/uploads
    volumes:
      - /mnt/HC_Volume_XXXXXX:/app/uploads     # Persistent file storage
      - ./firebase-config:/app/firebase-config:ro  # Read-only Firebase config
    deploy:
      resources:
        limits:
          cpus: '1.5'                  # Max 1.5 CPU cores
          memory: 1024M               # Max 1GB RAM
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s                    # Check every 30 seconds
      timeout: 10s                     # Fail if no response in 10s
      retries: 3                       # Mark unhealthy after 3 failures
      start_period: 60s               # Wait 60s before first check (app startup)
    labels:
      com.shop.service: backend
    restart: unless-stopped            # Auto-restart on crash

  # --- Frontend Service ---
  frontend:
    build:
      context: ./frontend
      dockerfile: Dockerfile
    ports:
      - "80:80"                        # Serve on port 80
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:80/health"]
      interval: 30s
      retries: 3
    labels:
      com.shop.service: frontend
    restart: unless-stopped
    depends_on:
      backend:
        condition: service_healthy     # Wait for backend to be healthy
```

### Key Concepts Explained:

**ports: "8082:8080"**
```
Host Port : Container Port
8082      : 8080

Outside world connects to port 8082
Inside container, Spring Boot listens on 8080
Docker maps between them
```

**volumes:**
```
/mnt/HC_Volume_XXXXXX:/app/uploads
│                         │
│ Host path (Hetzner Vol) │ Container path
│                         │
│ Product images, documents saved here
│ Data persists even if container is destroyed
```

**host.docker.internal:**
```
Special DNS name that points to the host machine from inside a container.
Your PostgreSQL runs directly on the host (not in Docker).
Container uses host.docker.internal:5432 to reach it.
```

---

## 5. Docker Networking

### Network Types:

```
1. Bridge (default): Containers on same machine talk to each other
   backend <--> frontend (via container name)

2. Host: Container uses host's network directly
   No port mapping needed, but less isolation

3. None: No networking (isolated)
```

### Your Network Setup:
```
┌─── Docker Bridge Network (172.17.0.0/16) ───┐
│                                               │
│  backend (172.17.0.2)                         │
│     |                                         │
│     |--- can reach --> frontend (172.17.0.3)  │
│     |--- can reach --> host.docker.internal    │
│                           |                   │
│                           v                   │
│                     Host (172.17.0.1)         │
│                           |                   │
│                     PostgreSQL (5432)          │
│                                               │
└───────────────────────────────────────────────┘

External traffic:
Internet --> Host:8082 --> Docker maps --> backend:8080
Internet --> Host:80   --> Docker maps --> frontend:80
```

### Container Communication:
```bash
# Containers can talk to each other by service name
# In frontend nginx.conf:
proxy_pass http://backend:8082;
#                ^^^^^^^ Docker resolves this to backend's IP

# This is why Docker Compose is powerful:
# Services discover each other by NAME, not IP
```

---

## 6. Docker Images & Layers

### How Layers Work:
```dockerfile
FROM eclipse-temurin:17-jre-alpine   # Layer 1: Base OS + JRE (cached)
WORKDIR /app                          # Layer 2: Set directory (cached)
COPY app.jar .                        # Layer 3: Your app (changes each build)
```

```
Each instruction = a layer
Layers are CACHED - if nothing changed, Docker reuses the layer
This is why we copy pom.xml BEFORE source code:

COPY pom.xml .              # Layer: dependencies definition (rarely changes)
RUN mvn dependency:go-offline # Layer: downloaded dependencies (cached!)
COPY src ./src               # Layer: your code (changes often)
RUN mvn package              # Layer: only rebuilds your code

If you only changed Java code, Docker reuses the dependency layer.
Build: 30 seconds instead of 5 minutes!
```

---

## 7. Essential Docker Commands

### Container Management:
```bash
# List running containers
docker ps

# List ALL containers (including stopped)
docker ps -a

# Start containers defined in docker-compose.yml
docker-compose up -d    # -d = detached (background)

# Stop all containers
docker-compose down

# Restart a specific service
docker-compose restart backend

# View container logs
docker logs backend-container-name
docker logs -f backend-container-name  # Follow (real-time)
docker logs --tail 100 backend-container-name  # Last 100 lines

# Execute command inside container
docker exec -it backend-container-name bash
docker exec -it backend-container-name sh   # Alpine (no bash)

# Check container resource usage
docker stats

# Output:
# CONTAINER      CPU %   MEM USAGE / LIMIT   NET I/O
# backend        15.2%   650MiB / 1GiB       5.2MB / 12MB
# frontend       0.1%    10MiB / 256MiB      1.1MB / 8.5MB
```

### Image Management:
```bash
# List images
docker images

# Remove unused images (free disk space!)
docker image prune

# Remove ALL unused data (images, containers, volumes)
docker system prune -a
# WARNING: This deletes stopped containers too!

# Check disk usage by Docker
docker system df

# Build image
docker build -t yourapp-backend:v1.0.260 ./backend
```

### Debugging:
```bash
# See container details
docker inspect backend-container-name

# See container network
docker inspect backend-container-name | grep -A 20 "NetworkSettings"

# Check health status
docker inspect --format='{{.State.Health.Status}}' backend-container-name

# See container environment variables
docker exec backend-container-name env

# Copy file from container to host
docker cp backend-container-name:/app/logs/app.log ./app.log

# Copy file from host to container
docker cp ./fix.sql backend-container-name:/tmp/fix.sql
```

---

## 8. Docker Volumes (Data Persistence)

### The Problem:
```
Container is destroyed --> ALL data inside is LOST
Product images? GONE. Upload documents? GONE.
```

### The Solution: Volumes
```yaml
volumes:
  - /mnt/HC_Volume_XXXXXX:/app/uploads
  #   Host path                Container path
  #   (Hetzner Cloud Volume)   (where app writes)
  #
  #   Data lives on the host volume
  #   Container can be destroyed and recreated
  #   Data survives!
```

### Your Volumes:
```
/mnt/HC_Volume_XXXXXX/          # Hetzner 10GB Volume
├── products/                       # Product images
├── documents/
│   ├── shops/                      # Shop documents
│   └── delivery-partners/          # Delivery partner docs
└── ...

This volume persists even if you:
- Delete Docker containers
- Rebuild images
- Restart the server
```

---

## 9. Docker Security Best Practices

### What You're Already Doing Right:
```
1. Multi-stage builds (smaller attack surface)
2. Non-root user in container
3. Read-only volume for firebase config (:ro)
4. Resource limits (CPU, memory)
5. Health checks
```

### Additional Security:
```yaml
services:
  backend:
    # Don't run as root
    user: "1000:1000"

    # Read-only filesystem (app can only write to volumes)
    read_only: true
    tmpfs:
      - /tmp

    # Drop unnecessary capabilities
    cap_drop:
      - ALL

    # No new privileges
    security_opt:
      - no-new-privileges:true

    # Don't expose ports to host unless needed
    # Use Docker network instead
    expose:
      - "8080"    # Only visible to other containers
    # vs
    ports:
      - "8082:8080"  # Visible to the whole internet!
```

---

## 10. Docker Compose Scaling

```bash
# Scale backend to 3 instances
docker-compose up -d --scale backend=3

# This creates:
# shop-management-system_backend_1 (port auto-assigned)
# shop-management-system_backend_2 (port auto-assigned)
# shop-management-system_backend_3 (port auto-assigned)

# Then configure Nginx to load balance across them
# (see 05-load-balancing.md)
```

---

## Key Takeaways

1. **Docker** packages your app with all dependencies - runs the same everywhere
2. **Multi-stage builds** keep your images small (build tools not included)
3. **Docker Compose** orchestrates multiple services (backend + frontend)
4. **Volumes** persist data outside containers (your product images are safe)
5. **Container networking** lets services find each other by name
6. **Health checks** automatically restart unhealthy containers
7. **Resource limits** prevent one container from killing the whole server
8. **`docker stats`** is your friend for monitoring resource usage

---

## Next: [07 - CI/CD & Zero Downtime Deployment](./07-cicd-deployment.md)
