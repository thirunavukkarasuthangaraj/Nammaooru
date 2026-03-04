# 15 - Complete Architecture Diagram

## Your Current Architecture

```
                                    INTERNET
                                       |
                          ┌────────────┴────────────┐
                          |                          |
                    [Mobile App]              [Web Browser]
                    (Flutter)                 (Angular)
                    Customers &               Shop Owners &
                    Delivery Partners          Admin Panel
                          |                          |
                          └────────────┬─────────────┘
                                       |
                              [DNS Resolution]
                          YOUR_DOMAIN.com
                              -> YOUR_SERVER_IP
                                       |
                          ┌────────────┴────────────┐
                          |                          |
                   Port 443 (HTTPS)           Port 443 (HTTPS)
                   YOUR_DOMAIN.com       api.YOUR_DOMAIN.com
                          |                          |
═══════════════════════════════════════════════════════════════
                 HETZNER CLOUD SERVER (CX33)
                 YOUR_SERVER_IP | Helsinki, Finland
                 4 vCPU | 8GB RAM | 80GB Disk
═══════════════════════════════════════════════════════════════
                          |                          |
                    ┌─────┴──────┐            ┌──────┴─────┐
                    |   NGINX    |            |   NGINX    |
                    | (Frontend) |            |   (API)    |
                    | Port 80    |            | Port 443   |
                    | Static     |            | SSL Term   |
                    | Files      |            | Proxy Pass |
                    └─────┬──────┘            └──────┬─────┘
                          |                          |
                    ┌─────┴──────┐            ┌──────┴─────┐
                    |  DOCKER    |            |  DOCKER    |
                    | Frontend   |            | Backend    |
                    | Container  |            | Container  |
                    |            |            |            |
                    | Angular    |            | Spring Boot|
                    | Built      |            | Java 17    |
                    | Static     |            | Port 8082  |
                    | Files      |            |            |
                    | Nginx      |            | JWT Auth   |
                    | Alpine     |            | REST API   |
                    |            |            | WebSocket  |
                    └────────────┘            └──────┬─────┘
                                                     |
                          ┌──────────────────────────┼───────────────┐
                          |                          |               |
                    ┌─────┴──────┐            ┌──────┴─────┐  ┌─────┴──────┐
                    | PostgreSQL |            |  Hetzner   |  | External   |
                    | Database   |            |  Volume    |  | Services   |
                    |            |            |            |  |            |
                    | Port 5432  |            | 10GB       |  | Firebase   |
                    | localhost  |            | /mnt/HC_.. |  | Razorpay   |
                    | only!      |            |            |  | MSG91      |
                    |            |            | Product    |  | Gemini AI  |
                    | Users      |            | Images     |  | Hostinger  |
                    | Orders     |            | Documents  |  | SMTP       |
                    | Shops      |            | Uploads    |  |            |
                    | Products   |            |            |  |            |
                    └────────────┘            └────────────┘  └────────────┘


═══════════════════════════════════════════════════════════════
                    DEPLOYMENT PIPELINE
═══════════════════════════════════════════════════════════════

  [Developer Pushes to GitHub main branch]
              |
              v
  [GitHub Actions Triggered]
              |
              v
  [SSH to Hetzner Server]
              |
              v
  [zero-downtime-deploy.sh]
              |
    ┌─────────┴──────────┐
    |                     |
  [Build New        [Build New
   Backend           Frontend
   Docker Image]     Docker Image]
    |                     |
  [Start New         [Switch to
   Container]         New Build]
    |                     |
  [Health Check      [Nginx
   Passes?]           Reload]
    |                     |
  [Switch Nginx      [Cleanup
   to New]            Old Build]
    |                     |
  [Stop Old          [Done!]
   Container]
    |
  [Done!]
```

---

## Future Architecture (When You Scale)

```
                                    INTERNET
                                       |
                              [Cloudflare CDN]
                          (Static files cached globally)
                          (DDoS protection)
                          (Indian PoP for low latency)
                                       |
                         ┌─────────────┴──────────────┐
                         |                             |
                   [Hetzner Load                 [Cloudflare]
                    Balancer]                    Serves cached
                    HTTPS termination            JS/CSS/Images
                    Health checks                from India PoP
                         |
              ┌──────────┼──────────┐
              |          |          |
         [Server 1] [Server 2] [Server 3]
         Backend     Backend    Backend
         Frontend    Frontend   Frontend
         Docker      Docker     Docker
              |          |          |
              └──────────┼──────────┘
                         |
              ┌──────────┼──────────┐
              |          |          |
         [Primary DB] [Read     [Redis
          PostgreSQL]  Replica]  Cache]
              |
         [Hetzner Object Storage]
         (Product images, documents)
         (Replaces local volume)
```

---

## Network Flow Diagram

```
Request: Customer orders "Rice 5kg" from Krishna Store

1. MOBILE APP (Flutter)
   POST /api/orders
   Body: {shopId: 5, items: [{name: "Rice 5kg", qty: 1}]}
   Header: Authorization: Bearer eyJhbG...
          |
          v

2. DNS RESOLUTION (10ms)
   api.YOUR_DOMAIN.com -> YOUR_SERVER_IP
          |
          v

3. INTERNET TRANSIT (150-200ms)
   India -> undersea cable -> Europe -> Finland
          |
          v

4. NGINX (1ms)
   - Receives on port 443
   - Terminates SSL
   - Reads Host header: api.YOUR_DOMAIN.com
   - Forwards to localhost:8082
          |
          v

5. DOCKER NETWORK (1ms)
   - Routes to backend container
   - Container port 8080
          |
          v

6. SPRING SECURITY (5ms)
   - Extracts JWT from Authorization header
   - Validates signature with JWT_SECRET
   - Extracts user ID and roles
   - Passes to controller
          |
          v

7. ORDER CONTROLLER (2ms)
   - @PostMapping("/api/orders")
   - Validates request body
   - Calls OrderService
          |
          v

8. ORDER SERVICE (10ms)
   - Checks shop exists
   - Checks products available
   - Calculates total price
   - Creates order in DB
          |
          v

9. POSTGRESQL (5ms)
   - INSERT INTO orders (...)
   - INSERT INTO order_items (...)
   - COMMIT transaction
          |
          v

10. NOTIFICATIONS (async, 50-200ms)
    - Firebase push notification to shop owner
    - WebSocket message to shop owner's dashboard
    - SMS/WhatsApp via MSG91 (if enabled)
          |
          v

11. RESPONSE (travels back same path)
    - Spring Boot returns JSON: {orderId: 12345, status: "PLACED"}
    - Docker -> Nginx -> Internet -> Customer's phone

TOTAL TIME: ~300-500ms
```

---

## Port Map

```
┌───────────────────────────────────────────┐
│           Your Server: YOUR_SERVER_IP         │
│                                            │
│  EXTERNAL (Internet-accessible):           │
│  ├── :22   SSH (restrict to your IP!)      │
│  ├── :80   HTTP (redirects to 443)         │
│  └── :443  HTTPS (Nginx)                   │
│                                            │
│  INTERNAL (localhost only):                │
│  ├── :5432  PostgreSQL                     │
│  ├── :8080  Backend container 1            │
│  ├── :8081  Backend container 2 (if scaled)│
│  ├── :8082  Backend container 3 (current)  │
│  ├── :8083  Backend container 4 (if scaled)│
│  ├── :8084  Backend container 5 (if scaled)│
│  └── :8085  Backend container 6 (if scaled)│
│                                            │
│  DOCKER INTERNAL:                          │
│  ├── backend:8080   (Docker service name)  │
│  └── frontend:80    (Docker service name)  │
│                                            │
└───────────────────────────────────────────┘
```

---

## Security Layers

```
Layer 1: HETZNER CLOUD FIREWALL
  Only ports 22, 80, 443 allowed through

Layer 2: UFW (HOST FIREWALL)
  Same rules as above, defense in depth

Layer 3: NGINX
  Rate limiting, SSL enforcement, security headers

Layer 4: DOCKER ISOLATION
  Containers can't access host filesystem (except volumes)
  Non-root user inside containers

Layer 5: SPRING SECURITY
  JWT authentication on all /api/* endpoints
  Role-based access control (CUSTOMER, SHOP_OWNER, ADMIN)

Layer 6: DATABASE
  Listens on localhost only
  Application user has limited permissions
  Parameterized queries prevent SQL injection
```
