# 05 - Load Balancing

## What You'll Learn
- What load balancing is and why you need it
- Load balancing algorithms
- Hetzner Load Balancer vs Nginx load balancing
- Setting up load balancing for YourApp
- Session stickiness with JWT
- Health checks

---

## 1. What is Load Balancing?

### Without Load Balancer:
```
1000 users --> [Single Server] --> Server overloaded, slow, crashes!
```

### With Load Balancer:
```
1000 users --> [Load Balancer]
                  |--- 334 users --> [Server 1]
                  |--- 333 users --> [Server 2]
                  |--- 333 users --> [Server 3]
              Each server handles 1/3 of traffic = fast & reliable
```

### Load Balancer Benefits:

| Benefit | Explanation |
|---------|------------|
| **Scalability** | Handle more users by adding servers |
| **Reliability** | If one server dies, others continue |
| **Zero Downtime** | Deploy updates one server at a time |
| **Performance** | No single server is overwhelmed |

---

## 2. Your Current Setup vs Future

### Current (Single Server):
```
Users --> Nginx (YOUR_SERVER_IP)
            |
            +--> Docker: Backend (port 8082)
            +--> Docker: Frontend (port 80)
            +--> PostgreSQL (port 5432)
```

### Future (Load Balanced):
```
Users --> [Hetzner Load Balancer] (public IP)
              |
              +--> Server 1 (backend + frontend)
              +--> Server 2 (backend + frontend)
              +--> Server 3 (backend + frontend)
              |
              All connect to:
              +--> Database Server (PostgreSQL)
              +--> File Storage (Hetzner Volume / Object Storage)
```

---

## 3. Load Balancing Algorithms

### Round Robin (Default):
```
Request 1 --> Server A
Request 2 --> Server B
Request 3 --> Server C
Request 4 --> Server A  (starts over)
Request 5 --> Server B
...

Best when: All servers are identical
```

### Weighted Round Robin:
```
Server A (weight=3): Gets 3 out of 6 requests (50%)
Server B (weight=2): Gets 2 out of 6 requests (33%)
Server C (weight=1): Gets 1 out of 6 requests (17%)

Best when: Servers have different capacities
Example: Server A has 8GB RAM, Server C has 2GB RAM
```

### Least Connections:
```
Server A: 5 active connections
Server B: 2 active connections  <-- next request goes here
Server C: 8 active connections

Best when: Requests take varying time to process
Example: Some API calls are quick, some (like report generation) take long
```

### IP Hash:
```
User with IP 1.2.3.4 --> always goes to Server A
User with IP 5.6.7.8 --> always goes to Server B

Best when: You need session stickiness without cookies
Note: Not needed for your JWT-based app!
```

### Least Response Time:
```
Server A: avg 50ms response
Server B: avg 30ms response  <-- next request goes here
Server C: avg 80ms response

Best when: You want the fastest response times
```

---

## 4. Nginx Load Balancing Configuration

### Basic Setup (Multiple Spring Boot Instances):

```nginx
# Define backend servers
upstream yourapp_backend {
    # Algorithm: least connections
    least_conn;

    # Your Docker containers on different ports
    server 127.0.0.1:8080;
    server 127.0.0.1:8081;
    server 127.0.0.1:8082;
}

server {
    listen 443 ssl;
    server_name api.YOUR_DOMAIN.com;

    ssl_certificate     /etc/letsencrypt/live/YOUR_DOMAIN.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/YOUR_DOMAIN.com/privkey.pem;

    location / {
        proxy_pass http://yourapp_backend;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### Advanced Setup with Health Checks:

```nginx
upstream yourapp_backend {
    least_conn;

    # max_fails: mark as down after N failed attempts
    # fail_timeout: how long to wait before retrying
    server 127.0.0.1:8080 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:8081 max_fails=3 fail_timeout=30s;
    server 127.0.0.1:8082 max_fails=3 fail_timeout=30s;

    # Backup: only used when all primary servers are down
    server 127.0.0.1:8083 backup;

    # Keep persistent connections to backends
    keepalive 32;
}
```

### Docker Compose for Multiple Backends:

```yaml
# docker-compose.yml - Scale backend to 3 instances
services:
  backend:
    build: ./backend
    deploy:
      replicas: 3                    # Run 3 instances
      resources:
        limits:
          cpus: '1.0'
          memory: 768M
    environment:
      - SPRING_PROFILES_ACTIVE=prod
    healthcheck:
      test: ["CMD", "curl", "-f", "http://localhost:8080/actuator/health"]
      interval: 30s
      retries: 3
```

```bash
# Scale manually
docker-compose up -d --scale backend=3
```

---

## 5. Hetzner Load Balancer

Hetzner offers a managed load balancer service (visible in your dashboard sidebar).

### Hetzner LB vs Nginx LB:

| Feature | Nginx LB (your setup) | Hetzner LB |
|---------|----------------------|------------|
| Cost | Free (runs on your server) | From ~5 EUR/month |
| Setup | Manual config | UI/API based |
| SSL | You manage (Certbot) | Managed SSL available |
| Health checks | Basic | Advanced |
| Single point of failure | Yes (if server dies) | No (Hetzner manages) |
| Multiple servers | Same server only | Across servers |

### When to Use Hetzner LB:
- When you have **multiple servers** (not just containers)
- When you need **high availability** (server failure tolerance)
- When you want **managed SSL certificates**

### Setting Up Hetzner Load Balancer:

```
1. Hetzner Console -> Networking -> Load Balancers -> Create

2. Configuration:
   Name: yourapp-lb
   Type: LB11 (~5 EUR/month)
   Location: Helsinki (same as your server)
   Network: eu-central

3. Targets:
   Add your server (CX33) as a target

4. Services:
   Protocol: HTTPS
   Listen Port: 443
   Target Port: 8082 (your Spring Boot)

   Health Check:
   Protocol: HTTP
   Port: 8082
   Path: /actuator/health
   Interval: 15s
   Timeout: 10s
   Retries: 3

5. Certificate:
   Upload or create Let's Encrypt cert
   Domain: api.YOUR_DOMAIN.com

6. Algorithm: Round Robin or Least Connections

7. DNS:
   Point api.YOUR_DOMAIN.com -> Load Balancer IP
```

---

## 6. Session Handling with Load Balancing

### The Problem:
```
Request 1 (Login)  --> Server A  (JWT token created)
Request 2 (Get Orders) --> Server B  (JWT token still valid? YES!)

JWT tokens are STATELESS - any server can validate them.
This is why JWT is perfect for load-balanced applications!
```

### Your App Uses JWT - No Session Problem!
```
Your JWT Flow:
1. User logs in -> Any backend creates JWT
2. JWT contains: user ID, roles, expiration
3. JWT is signed with JWT_SECRET (same on all servers)
4. Any server can validate the JWT
5. No need for session stickiness!
```

### Important: Same JWT_SECRET Everywhere!
```yaml
# ALL backend instances must have the same JWT_SECRET
# In docker-compose.yml:
services:
  backend:
    environment:
      JWT_SECRET: ${JWT_SECRET}    # Same env variable for all instances
```

### If You Used Session-Based Auth (Don't, but FYI):
```nginx
upstream backend {
    ip_hash;  # Same user always goes to same server
    server 127.0.0.1:8080;
    server 127.0.0.1:8081;
}
# Problem: If that server dies, user loses session
```

---

## 7. WebSocket Load Balancing

Your app uses WebSocket for real-time features. WebSocket needs special handling:

```nginx
upstream ws_backend {
    # ip_hash ensures WebSocket stays connected to same server
    ip_hash;

    server 127.0.0.1:8080;
    server 127.0.0.1:8081;
    server 127.0.0.1:8082;
}

location /ws {
    proxy_pass http://ws_backend;
    proxy_http_version 1.1;
    proxy_set_header Upgrade $http_upgrade;
    proxy_set_header Connection "upgrade";
    proxy_read_timeout 86400;
}
```

### Why ip_hash for WebSocket?
WebSocket is a persistent connection. If the load balancer switches servers mid-connection, the WebSocket breaks. ip_hash ensures the same user always connects to the same backend.

---

## 8. Health Checks

### What Are Health Checks?
The load balancer periodically asks each server: "Are you alive and healthy?"

```
Load Balancer:
  Every 15 seconds:
    GET http://server1:8082/actuator/health  --> {"status": "UP"} OK!
    GET http://server2:8082/actuator/health  --> Connection refused  DEAD!
    GET http://server3:8082/actuator/health  --> {"status": "UP"} OK!

  Result: Stop sending traffic to Server 2
```

### Your Spring Boot Health Check:
```
Endpoint: /actuator/health

Response when healthy:
{
  "status": "UP",
  "components": {
    "db": { "status": "UP" },
    "diskSpace": { "status": "UP" }
  }
}

Response when unhealthy:
{
  "status": "DOWN",
  "components": {
    "db": { "status": "DOWN", "details": { "error": "Connection refused" } }
  }
}
```

### Health Check Types:

| Type | Checks | When to Use |
|------|--------|-------------|
| **TCP** | Can I connect to the port? | Basic, fast |
| **HTTP** | Does /health return 200? | Standard, recommended |
| **Deep** | Is DB connected? Is disk OK? | Thorough, slower |

---

## 9. Zero-Downtime Deployment with Load Balancing

### Your Current Zero-Downtime Deploy:
```
1. Build new backend Docker image
2. Start new container (old still running)
3. Wait for health check to pass
4. Switch Nginx to new container
5. Stop old container

Timeline:
[Old Container: serving traffic]
                    [New Container: starting up...]
                              [New Container: healthy!]
                    [Switch!]
                              [New Container: serving traffic]
[Old Container: draining... stopped]

Result: Users experience zero downtime
```

### With Load Balancer (Rolling Deploy):
```
Server 1: v1.0  |  Server 2: v1.0  |  Server 3: v1.0

Step 1: Remove Server 1 from LB
   Server 1: deploying v1.1...
   Server 2: v1.0 (serving traffic)
   Server 3: v1.0 (serving traffic)

Step 2: Server 1 healthy with v1.1, add back to LB
   Server 1: v1.1 (serving traffic)
   Server 2: v1.0 (serving traffic)
   Server 3: v1.0 (serving traffic)

Step 3: Repeat for Server 2, then Server 3

Final: All servers on v1.1, zero downtime!
```

---

## 10. Monitoring Your Load Balancer

```bash
# Check Nginx upstream status
# Add this to your Nginx config:
location /nginx_status {
    stub_status on;
    allow 127.0.0.1;
    deny all;
}

# Then check:
curl http://localhost/nginx_status
# Active connections: 15
# server accepts handled requests
#  1234 1234 5678
# Reading: 0 Writing: 5 Waiting: 10

# Check backend health
curl http://localhost:8080/actuator/health
curl http://localhost:8081/actuator/health
curl http://localhost:8082/actuator/health

# Watch traffic distribution (access log)
tail -f /var/log/nginx/access.log | awk '{print $7}' | sort | uniq -c

# Monitor with htop
htop  # Watch CPU/RAM usage across all containers
```

---

## 11. When Do You Actually Need Load Balancing?

### You DON'T Need It Yet If:
- Your server handles current traffic fine
- CPU stays under 70%
- Response times are acceptable
- You have fewer than ~500 concurrent users

### You NEED It When:
- Single server can't handle the load
- You need zero downtime guarantees
- You're serving multiple regions
- Your app is business-critical (can't afford server failure)

### Your Current Capacity (CX33: 4 vCPU, 8GB RAM):
```
Estimated capacity (rough):
- Spring Boot: ~200-500 concurrent requests
- PostgreSQL: ~100-200 concurrent queries
- Nginx: ~10,000+ concurrent connections

For YourApp's current scale, single server is likely sufficient.
Consider load balancing when you consistently see:
- CPU > 70% during peak hours
- Response times > 2 seconds
- Server crashes under load
```

---

## Key Takeaways

1. **Load balancing** distributes traffic across multiple servers
2. **Least connections** is usually the best algorithm for APIs
3. **JWT is perfect** for load balancing - no session stickiness needed
4. **WebSocket needs ip_hash** to maintain persistent connections
5. **Health checks** automatically remove dead servers
6. **Hetzner LB** is useful when you have multiple physical servers
7. **Nginx LB** is free and works great for multiple containers on one server
8. **You probably don't need it yet** - but learn it for when you scale

---

## Next: [06 - Docker & Containers](./06-docker-containers.md)
