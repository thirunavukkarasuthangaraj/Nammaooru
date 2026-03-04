# 04 - Nginx & Reverse Proxy (Your Real Setup)

## What You'll Learn
- What Nginx does in your system (with box model diagrams)
- Your ACTUAL Nginx config files explained line by line
- How every request flows through your system in real-time
- Evolution: Simple -> Zero Downtime setup
- How each config file works together

---

## 1. Box Model: Your Complete Nginx Architecture

```
┌─────────────────────── INTERNET ────────────────────────┐
│                                                          │
│   [Mobile App]    [Browser]    [Delivery App]            │
│   (Flutter)       (Angular)    (Flutter)                 │
│       |               |             |                    │
└───────|───────────────|─────────────|────────────────────┘
        |               |             |
        v               v             v
┌──────────────────────────────────────────────────────────┐
│              CLOUDFLARE (Orange Cloud Proxy)              │
│                                                          │
│  - Universal SSL (browser sees this cert)                │
│  - CDN caching for static files                          │
│  - DDoS protection                                       │
│  - Hides your real server IP                             │
└──────────────────────┬───────────────────────────────────┘
                       |
                       | HTTPS (Let's Encrypt cert)
                       v
┌══════════════════════════════════════════════════════════╗
║         YOUR HETZNER SERVER (CX33 - Helsinki)            ║
║         4 vCPU | 8GB RAM | Ubuntu                        ║
╠══════════════════════════════════════════════════════════╣
║                                                          ║
║  ┌────────────────── NGINX (Host) ─────────────────┐    ║
║  │                                                  │    ║
║  │  Port 80 ──> Redirect to HTTPS (301)             │    ║
║  │                                                  │    ║
║  │  Port 443 (HTTPS) ──> Routes by domain name:     │    ║
║  │  │                                               │    ║
║  │  ├─ api.YOUR_DOMAIN.com                          │    ║
║  │  │    │                                          │    ║
║  │  │    ├─ /           ──> upstream backend_servers │    ║
║  │  │    ├─ /ws         ──> upstream (WebSocket)     │    ║
║  │  │    └─ /actuator/* ──> upstream (health check)  │    ║
║  │  │                                               │    ║
║  │  └─ YOUR_DOMAIN.com / www.YOUR_DOMAIN.com        │    ║
║  │       │                                          │    ║
║  │       ├─ /uploads/*  ──> Static files (disk)      │    ║
║  │       ├─ /api/*      ──> localhost:8082           │    ║
║  │       └─ /           ──> localhost:8080 (Angular)  │    ║
║  │                                                  │    ║
║  └──────────────────────────────────────────────────┘    ║
║           |                    |              |          ║
║           v                    v              v          ║
║  ┌──── DOCKER ─────────────────────────────────────┐    ║
║  │                                                  │    ║
║  │  ┌──────────────┐     ┌──────────────────┐      │    ║
║  │  │  Frontend    │     │  Backend         │      │    ║
║  │  │  Container   │     │  Container       │      │    ║
║  │  │              │     │                  │      │    ║
║  │  │  Nginx       │     │  Spring Boot     │      │    ║
║  │  │  + Angular   │     │  Java 17         │      │    ║
║  │  │  Static      │     │  Port 8080       │      │    ║
║  │  │  Files       │     │  (mapped to 8082)│      │    ║
║  │  │              │     │                  │      │    ║
║  │  │  Port 80     │     │  REST API        │      │    ║
║  │  │  (mapped     │     │  WebSocket       │      │    ║
║  │  │   to 8080)   │     │  JWT Auth        │      │    ║
║  │  └──────────────┘     └────────┬─────────┘      │    ║
║  │                                |                 │    ║
║  └────────────────────────────────|─────────────────┘    ║
║                                   |                      ║
║  ┌────────────────────────────────v─────────────────┐    ║
║  │  PostgreSQL (Host - NOT Docker)                   │    ║
║  │  Port 5432 (localhost only!)                      │    ║
║  │  Database: shop_management_db                     │    ║
║  └──────────────────────────────────────────────────┘    ║
║                                                          ║
║  ┌──────────────────────────────────────────────────┐    ║
║  │  Hetzner Volume: /mnt/HC_Volume_XXXXXX           │    ║
║  │  Product images, documents, uploads (10GB)        │    ║
║  └──────────────────────────────────────────────────┘    ║
║                                                          ║
╚══════════════════════════════════════════════════════════╝
```

---

## 2. You Have 3 Nginx Instances (Yes, THREE!)

Most people think you have one Nginx. You actually have **three**:

```
┌──────────────────────────────────────────────────────┐
│  NGINX #1: Host Nginx (on server directly)            │
│  Location: /etc/nginx/                                │
│  Job: SSL termination, routing, load balancing        │
│  Configs:                                             │
│    - api.YOUR_DOMAIN.com (API reverse proxy)          │
│    - YOUR_DOMAIN.com (main site + uploads)            │
│                                                       │
│  NGINX #2: Frontend Docker Container                  │
│  Location: Inside Docker (frontend/nginx.conf)        │
│  Job: Serve Angular static files, SPA routing         │
│  Port: 80 inside container -> 8080 on host            │
│                                                       │
│  NGINX #3: Cloudflare Edge (not yours, managed)       │
│  Location: Cloudflare servers worldwide                │
│  Job: CDN, DDoS protection, browser-facing SSL        │
└──────────────────────────────────────────────────────┘
```

---

## 3. Real-Time Request Flow: Customer Opens the App

```
STEP 1: Customer opens YOUR_DOMAIN.com on phone
════════════════════════════════════════════════

Phone Browser
    |
    v
DNS Lookup: YOUR_DOMAIN.com -> Cloudflare IP (104.x.x.x)
    |
    v
┌─ CLOUDFLARE ─────────────────────────────────┐
│  Receives request on port 443                 │
│  Decrypts with Universal SSL                  │
│  Checks cache: Static file cached? ──> YES ──>── Return from CDN (10ms!)
│                                     └─ NO     │
│  Re-encrypts with your Let's Encrypt cert     │
│  Forwards to YOUR_SERVER_IP:443               │
└──────────────────────┬────────────────────────┘
                       |
                       v
┌─ HOST NGINX (#1) ───────────────────────────────────────┐
│  File: /etc/nginx/sites-enabled/nammaoorudelivary.conf   │
│                                                          │
│  server_name YOUR_DOMAIN.com www.YOUR_DOMAIN.com;        │
│  listen 80;                                              │
│                                                          │
│  Request: GET /                                          │
│  Matches: location / { proxy_pass http://localhost:8080 } │
│  Action: Forward to Angular container                    │
└──────────────────────┬───────────────────────────────────┘
                       |
                       v
┌─ DOCKER NGINX (#2) ────────────────────────────────────┐
│  File: frontend/nginx.conf                              │
│  Container port 80 -> Host port 8080                    │
│                                                         │
│  Request: GET /                                         │
│  Matches: location / { try_files $uri /index.html }     │
│  Action: Serve /usr/share/nginx/html/index.html         │
│                                                         │
│  Then browser loads JS/CSS:                             │
│  GET /main.js  -> Matches: location ~* \.(js|css)$      │
│                   Serves with 1h cache header            │
│  GET /styles.css -> Same, cached 1 hour                  │
└─────────────────────────────────────────────────────────┘
                       |
                       v
Phone shows the Angular app! (Total: ~300-500ms)
```

---

## 4. Real-Time Request Flow: API Call (Get Shops)

```
STEP 2: Angular app calls GET /api/shops
═════════════════════════════════════════

Angular App (in browser)
    |
    | fetch('https://api.YOUR_DOMAIN.com/api/shops',
    |   { headers: { Authorization: 'Bearer eyJhbG...' } })
    v
┌─ CLOUDFLARE ──────────────────────────────────┐
│  Receives: GET api.YOUR_DOMAIN.com/api/shops   │
│  Not cacheable (has Auth header)               │
│  Forwards to YOUR_SERVER_IP:443                │
└──────────────────────┬─────────────────────────┘
                       |
                       v
┌─ HOST NGINX (#1) ─────────────────────────────────────────┐
│  File: nginx-api-updated.conf (active on server)           │
│                                                            │
│  server {                                                  │
│    listen 443 ssl http2;                                   │
│    server_name api.YOUR_DOMAIN.com;                        │
│    ssl_certificate /etc/letsencrypt/live/.../fullchain.pem; │
│                                                            │
│    location / {                                            │
│      proxy_pass http://backend_servers;  ◄── upstream!     │
│    }                                                       │
│  }                                                         │
│                                                            │
│  upstream backend_servers {                                 │
│    server localhost:8082 max_fails=3 fail_timeout=30s;     │
│    keepalive 32;  ◄── reuse connections (faster)           │
│  }                                                         │
│                                                            │
│  Nginx adds headers before forwarding:                     │
│    Host: api.YOUR_DOMAIN.com                               │
│    X-Real-IP: 103.x.x.x (customer's real IP)              │
│    X-Forwarded-For: 103.x.x.x                             │
│    X-Forwarded-Proto: https                                │
│                                                            │
│  Forwards to: http://localhost:8082/api/shops              │
└──────────────────────┬─────────────────────────────────────┘
                       |
                       v
┌─ SPRING BOOT (Docker Container) ──────────────┐
│  Port 8080 inside container (mapped to 8082)   │
│                                                │
│  1. Security Filter: Extract JWT token         │
│     Validate signature with JWT_SECRET         │
│     Extract userId, roles                      │
│                                                │
│  2. ShopController.getShops()                  │
│     Query PostgreSQL                           │
│                                                │
│  3. Return JSON:                               │
│     [{"id":1,"name":"Krishna Store",...}]       │
└──────────────────────┬─────────────────────────┘
                       |
                       v
Response flows back: Spring Boot -> Host Nginx -> Cloudflare -> Browser
Total: ~200-500ms
```

---

## 5. Real-Time Flow: WebSocket (Live Order Updates)

```
STEP 3: Shop owner's dashboard connects to WebSocket
═════════════════════════════════════════════════════

Angular App (Shop Owner Dashboard)
    |
    | new WebSocket('wss://api.YOUR_DOMAIN.com/ws')
    v
┌─ CLOUDFLARE ──────────────────────────────────┐
│  Detects: WebSocket upgrade request            │
│  Passes through (WebSocket supported on free)  │
└──────────────────────┬─────────────────────────┘
                       |
                       v
┌─ HOST NGINX (#1) ──────────────────────────────────────┐
│                                                         │
│  location /ws {                                         │
│    proxy_pass http://backend_servers/ws;                 │
│    proxy_http_version 1.1;                              │
│    proxy_set_header Upgrade $http_upgrade;  ◄── KEY!    │
│    proxy_set_header Connection "upgrade";   ◄── KEY!    │
│    proxy_read_timeout 86400;  ◄── Keep alive 24 hours   │
│  }                                                      │
│                                                         │
│  HTTP Upgrade handshake:                                │
│    Client: "Upgrade: websocket"                         │
│    Server: "101 Switching Protocols"                    │
│    Connection upgraded to persistent WebSocket          │
│                                                         │
└──────────────────────┬──────────────────────────────────┘
                       |
                       | (persistent connection, stays open)
                       v
┌─ SPRING BOOT (STOMP over WebSocket) ──────────┐
│                                                │
│  Connection stays open.                        │
│  When new order arrives:                       │
│    OrderService -> WebSocket broker             │
│    Broker sends: {"orderId":123,"status":"NEW"} │
│    -> Nginx -> Cloudflare -> Shop owner's phone │
│                                                │
│  Shop owner sees new order INSTANTLY!          │
│  (Latency: ~200ms India to Helsinki)           │
└────────────────────────────────────────────────┘
```

---

## 6. Real-Time Flow: File Upload (Product Image)

```
STEP 4: Shop owner uploads product image
══════════════════════════════════════════

Phone Camera -> Select Image -> Upload
    |
    | POST /api/products/upload
    | Content-Type: multipart/form-data
    | Body: image (2MB JPEG)
    v
┌─ HOST NGINX ──────────────────────────────────────────┐
│                                                        │
│  client_max_body_size 50M;  ◄── Allows up to 50MB     │
│  (Without this, uploads > 1MB would get 413 error!)    │
│                                                        │
│  Receives full 2MB image                               │
│  Forwards to backend_servers                           │
└──────────────────────┬─────────────────────────────────┘
                       |
                       v
┌─ SPRING BOOT ─────────────────────────────────────────┐
│                                                        │
│  FileUploadService.upload(file)                        │
│  Saves to: /app/uploads/products/product_123.jpg       │
│  (Docker volume maps to /mnt/HC_Volume_XXXXXX/)        │
│                                                        │
│  Returns: {"imageUrl": "/uploads/products/product.jpg"} │
└────────────────────────────────────────────────────────┘

Later, when customer views product:
    |
    | GET /uploads/products/product_123.jpg
    v
┌─ HOST NGINX ──────────────────────────────────────────┐
│  File: nammaoorudelivary.conf                          │
│                                                        │
│  location /uploads/ {                                  │
│    alias /opt/shop-management/uploads/;  ◄── Direct!   │
│    expires 30d;  ◄── Browser caches 30 days            │
│    add_header Cache-Control "public, immutable";       │
│    access_log off;  ◄── Don't log image requests       │
│    autoindex off;  ◄── No directory listing (security)  │
│  }                                                     │
│                                                        │
│  Nginx serves the image DIRECTLY from disk.            │
│  Spring Boot is NOT involved! (Much faster)            │
└────────────────────────────────────────────────────────┘
```

---

## 7. Your Config Files: What's Active on Server

### File Map:
```
Your Repo                              On Server
─────────                              ─────────
nginx-fix.conf                    ──>  /etc/nginx/sites-enabled/api.YOUR_DOMAIN.com
 (current active API config)            (this is what's running NOW)

nginx/nammaoorudelivary.conf      ──>  /etc/nginx/sites-enabled/nammaoorudelivary
 (main domain config)                   (frontend + uploads)

frontend/nginx.conf               ──>  Inside Docker frontend container
 (Angular container Nginx)              (/etc/nginx/nginx.conf in container)

deployment/nginx-api-updated.conf ──>  UPGRADE: zero-downtime version
 (next version to deploy)               (not active yet, has upstream block)
```

---

## 8. Config #1: API Config (Currently Active on Server)

This is what your screenshot showed - the simple version:

```nginx
# FILE: nginx-fix.conf (copied to server as api.YOUR_DOMAIN.com)
# This is YOUR current LIVE config

# Remove ALL CORS headers from nginx - let Spring Boot handle it
server {
    listen 443 ssl http2;
    #       ^^^       ^^^^
    #       SSL       HTTP/2 (faster, multiplexed)

    server_name api.YOUR_DOMAIN.com;
    #           ^^^^^^^^^^^^^^^^^^^^^^
    #           Only handles requests for this domain

    ssl_certificate /etc/letsencrypt/live/api.YOUR_DOMAIN.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.YOUR_DOMAIN.com/privkey.pem;
    #                   ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
    #                   Let's Encrypt certificate (auto-renewed by certbot)

    location / {
        proxy_pass http://127.0.0.1:8082;
        #          ^^^^^^^^^^^^^^^^^^^^^^^
        #          Forward ALL requests to Spring Boot on port 8082

        proxy_http_version 1.1;
        #                  ^^^
        #                  HTTP/1.1 needed for WebSocket upgrade + keepalive

        proxy_set_header Host $host;
        #                     ^^^^^
        #                     Pass original domain name to Spring Boot
        #                     Spring Boot sees: api.YOUR_DOMAIN.com

        proxy_set_header X-Real-IP $remote_addr;
        #                          ^^^^^^^^^^^^
        #                          Customer's actual IP address
        #                          Without this, Spring Boot sees 127.0.0.1

        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        #                                ^^^^^^^^^^^^^^^^^^^^^^^^^^^
        #                                Chain of proxy IPs
        #                                e.g., "103.x.x.x, 172.64.x.x"

        proxy_set_header X-Forwarded-Proto $scheme;
        #                                  ^^^^^^^
        #                                  "https" - tells Spring Boot
        #                                  the original request was HTTPS

        # NO CORS HEADERS HERE - Spring Boot handles it
        # You learned this the hard way:
        #   Nginx CORS + Spring Security CORS = DUPLICATE headers = login fails!
    }
}
```

### Why This Config is Simple:
```
Pros:
  + Clean, minimal, easy to understand
  + CORS handled in one place (Spring Security)
  + Works perfectly for single backend

Cons:
  - No zero-downtime deployment (must stop backend to deploy)
  - No WebSocket-specific location block
  - No health check endpoint
  - No file upload size limit (defaults to 1MB)
  - No upstream block (can't load balance)
```

---

## 9. Config #2: Main Domain (nammaoorudelivary.conf)

```nginx
# FILE: nginx/nammaoorudelivary.conf
# Handles: YOUR_DOMAIN.com and www.YOUR_DOMAIN.com

server {
    listen 80;
    server_name YOUR_DOMAIN.com www.YOUR_DOMAIN.com;

    # ┌─────────────────────────────────────────┐
    # │ /uploads/* -> Serve files from DISK      │
    # │ Nginx serves directly, NO Spring Boot!   │
    # │ Product images, shop documents, etc.     │
    # └─────────────────────────────────────────┘
    location /uploads/ {
        alias /opt/shop-management/uploads/;
        #     ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
        #     Actual folder on server disk
        #     Maps to Hetzner Volume via symlink or direct path

        expires 30d;
        #       ^^^
        #       Browser caches images for 30 days
        #       User downloads product photo ONCE, cached for a month

        add_header Cache-Control "public, immutable";
        access_log off;    # Don't log every image request (saves disk)

        # CORS for images (needed when Angular loads images cross-origin)
        add_header 'Access-Control-Allow-Origin' '*' always;
        add_header 'Access-Control-Allow-Methods' 'GET, OPTIONS' always;

        autoindex off;     # SECURITY: Don't show directory listing!
    }

    # ┌─────────────────────────────────────────┐
    # │ / -> Angular Frontend (Docker container) │
    # │ Nginx inside Docker serves static files  │
    # └─────────────────────────────────────────┘
    location / {
        proxy_pass http://localhost:8080;
        #          ^^^^^^^^^^^^^^^^^^^^^
        #          Frontend Docker container (Nginx #2)
        #          Container port 80 -> Host port 8080

        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        #               ^^^^^^^^^^^^^^^^^^^^^^^^^
        #               Support WebSocket from frontend too

        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }

    # ┌─────────────────────────────────────────┐
    # │ /api/* -> Spring Boot Backend            │
    # │ API calls from main domain (alternative) │
    # └─────────────────────────────────────────┘
    location /api {
        proxy_pass http://localhost:8082;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;

        # CORS removed - Spring Security handles it
    }
}
```

---

## 10. Config #3: Frontend Container Nginx (Inside Docker)

```nginx
# FILE: frontend/nginx.conf
# Runs INSIDE the Docker frontend container
# This is Nginx #2 (not the host Nginx)

# ┌─────────────────────────────────────────────────────┐
# │ This Nginx ONLY serves Angular static files          │
# │ It does NOT handle SSL (host Nginx does that)        │
# │ It does NOT face the internet directly                │
# └─────────────────────────────────────────────────────┘

http {
    # Gzip compression (makes files 60-80% smaller!)
    gzip on;
    gzip_comp_level 6;       # Compression level (1-9)
    gzip_min_length 1024;    # Don't compress tiny files
    gzip_types
        text/plain text/css text/xml text/javascript
        application/json application/javascript
        application/xml+rss application/atom+xml
        image/svg+xml;

    # ┌─────────────────────────────────────────┐
    # │  Size savings with Gzip:                 │
    # │  main.js:   500KB -> 120KB  (76% saved)  │
    # │  styles.css: 200KB -> 45KB  (78% saved)  │
    # │  vendor.js: 800KB -> 200KB  (75% saved)  │
    # │  Total page: 1.5MB -> 400KB              │
    # └─────────────────────────────────────────┘

    server {
        listen 80;
        root /usr/share/nginx/html;  # Angular built files live here
        index index.html;

        # Security headers
        add_header X-Frame-Options "SAMEORIGIN" always;
        #          Prevents your site from being embedded in an iframe
        #          (clickjacking protection)

        add_header X-Content-Type-Options "nosniff" always;
        #          Prevents browser from MIME-type sniffing

        add_header X-XSS-Protection "1; mode=block" always;
        #          Enables browser's XSS filter

        # ┌─────────────────────────────────────────┐
        # │ Angular SPA Routing (CRITICAL!)          │
        # │ Without this, /shops/123 returns 404!    │
        # └─────────────────────────────────────────┘
        location / {
            try_files $uri $uri/ /index.html;
            # How it works:
            #   Request: GET /shops/123
            #   1. Try file /shops/123         -> doesn't exist
            #   2. Try directory /shops/123/    -> doesn't exist
            #   3. Serve /index.html           -> Angular router handles /shops/123
        }

        # HTML: NO CACHE (so new deployments take effect immediately)
        location ~* \.(html)$ {
            expires -1;
            add_header Cache-Control "no-store, no-cache, must-revalidate";
            # After deploy, user gets new index.html immediately
            # index.html contains links to new JS/CSS with cache-busting hashes
        }

        # Static assets: CACHE for 1 hour
        location ~* \.(js|css|png|jpg|jpeg|gif|ico|svg|woff|woff2|ttf|eot)$ {
            expires 1h;
            add_header Cache-Control "public, must-revalidate";
            # Angular CLI adds hash to filenames: main.abc123.js
            # New deploy = new hash = new file = cache miss = downloads new version
        }

        # API proxy (backup route, used if frontend calls /api/ directly)
        location /api/ {
            proxy_pass http://backend:8082/api/;
            #          ^^^^^^^ Docker service name (not localhost!)
            #          Docker DNS resolves "backend" to container IP
        }

        # WebSocket proxy
        location /ws {
            proxy_pass http://backend:8082/ws;
            proxy_http_version 1.1;
            proxy_set_header Upgrade $http_upgrade;
            proxy_set_header Connection "upgrade";
        }

        # Health check (Docker uses this)
        location /health {
            return 200 "healthy\n";
            # Docker healthcheck: curl http://localhost:80/health
            # If this fails, Docker restarts the container
        }
    }
}
```

---

## 11. Config #4: Zero Downtime Version (UPGRADE)

```nginx
# FILE: deployment/nginx-api-updated.conf
# This is the UPGRADED version with zero-downtime deployment support
# NOT yet active on your server (nginx-fix.conf is active)

# ┌─────────────────────────────────────────────────────┐
# │  UPSTREAM BLOCK - The key to zero-downtime!          │
# │                                                      │
# │  Instead of: proxy_pass http://localhost:8082;       │
# │  Uses:       proxy_pass http://backend_servers;      │
# │                                                      │
# │  During deploy, the script updates this block:       │
# │    Old: server localhost:8082;                        │
# │    New: server localhost:8082; server localhost:8083; │
# │  Then removes old after health check passes.         │
# └─────────────────────────────────────────────────────┘

upstream backend_servers {
    server localhost:8082 max_fails=3 fail_timeout=30s;
    #                     ^^^^^^^^^                ^^^^^
    #                     After 3 failed requests  Wait 30s before retry
    #                     mark server as "down"    then try again

    keepalive 32;
    #         ^^
    #         Keep 32 persistent connections to backend
    #         Avoids TCP handshake for every request (faster!)
}

server {
    listen 443 ssl http2;
    server_name api.YOUR_DOMAIN.com;

    ssl_certificate /etc/letsencrypt/live/api.YOUR_DOMAIN.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.YOUR_DOMAIN.com/privkey.pem;

    ssl_protocols TLSv1.2 TLSv1.3;
    ssl_session_cache shared:SSL:10m;

    client_max_body_size 50M;  # Allow 50MB uploads

    location / {
        proxy_pass http://backend_servers;  # Uses upstream!

        # Zero downtime settings:
        proxy_connect_timeout 5s;   # Quick timeout = fast failover
        proxy_send_timeout 60s;
        proxy_read_timeout 60s;

        # If backend returns error, try next server
        proxy_next_upstream error timeout invalid_header http_502 http_503 http_504;
        proxy_next_upstream_tries 2;       # Try 2 servers max
        proxy_next_upstream_timeout 10s;   # Give up after 10s total

        # ┌─────────────────────────────────────────┐
        # │  How zero-downtime works:                │
        # │                                          │
        # │  Normal:  upstream has port 8082 only    │
        # │                                          │
        # │  Deploy:  Start new on 8083              │
        # │           upstream: 8082 + 8083          │
        # │           Wait for 8083 health check     │
        # │           Remove 8082 from upstream      │
        # │           Stop old 8082 container        │
        # │                                          │
        # │  Result:  Zero dropped requests!         │
        # └─────────────────────────────────────────┘

        # NO CORS HEADERS - Spring Security handles all CORS
    }

    # Health check (monitoring tools can hit this)
    location /actuator/health {
        proxy_pass http://backend_servers/actuator/health;
        access_log off;  # Don't fill logs with health checks
    }
}
```

---

## 12. Evolution of Your Nginx Config

```
Version 1: nginx-fix.conf (CURRENT - simple)
  ┌─ proxy_pass http://127.0.0.1:8082 ─┐
  │ Simple, direct, one backend          │
  │ No zero-downtime                     │
  │ No upstream block                    │
  │ Works fine for current scale         │
  └──────────────────────────────────────┘
             |
             | UPGRADE TO
             v
Version 2: nginx-api-updated.conf (READY - not deployed yet)
  ┌─ proxy_pass http://backend_servers ─┐
  │ Upstream block with health checks    │
  │ Zero-downtime deployment             │
  │ Retry logic on failure               │
  │ 50MB upload limit                    │
  │ Keepalive connections                │
  └──────────────────────────────────────┘
             |
             | FUTURE UPGRADE TO
             v
Version 3: nginx-api-zero-downtime.conf (ADVANCED)
  ┌─ Everything in v2 PLUS:             ─┐
  │ WebSocket-specific location block     │
  │ CORS handling in Nginx                │
  │ Separate health check endpoint        │
  │ Dynamic upstream from deploy script   │
  └───────────────────────────────────────┘
```

---

## 13. Essential Nginx Commands

```bash
# ALWAYS use sudo on your server!

# Test config (ALWAYS before reloading!)
sudo nginx -t

# Reload (no downtime - applies new config)
sudo systemctl reload nginx

# Restart (brief downtime)
sudo systemctl restart nginx

# Check status
sudo systemctl status nginx

# See which config files are active
ls -la /etc/nginx/sites-enabled/

# See full merged config
sudo nginx -T

# View access logs (real-time)
sudo tail -f /var/log/nginx/api.access.log

# View error logs
sudo tail -f /var/log/nginx/api.error.log

# Check active connections
sudo ss -tlnp | grep nginx
```

---

## 14. Common Nginx Problems You've Faced

### CORS Duplicate Headers (You Fixed This!)
```
Problem: Login fails, CORS errors in browser console
Cause:   Both Nginx AND Spring Security adding CORS headers
         Browser sees duplicate Access-Control-Allow-Origin

Fix:     Remove ALL CORS from Nginx, let Spring Security handle it
         (This is why nginx-fix.conf exists - it was the fix!)

Comment in your config:
  # NO CORS HEADERS - Spring Security handles all CORS
  # Adding CORS headers here causes duplicate headers and login failures
```

### 502 Bad Gateway
```
Cause: Spring Boot container is down or restarting
Fix:   docker ps (check if running)
       docker logs backend (check errors)
       docker-compose restart backend
```

### 413 Request Entity Too Large
```
Cause: File upload > 1MB (default limit)
Fix:   Add to server block:
       client_max_body_size 50M;
       (Your updated config has this, current one doesn't!)
```

---

## Key Takeaways

1. **You have 3 Nginx instances**: Host Nginx, Docker Frontend Nginx, Cloudflare
2. **Host Nginx routes by domain**: api.* goes to backend, main domain goes to frontend
3. **Frontend Nginx** handles SPA routing (`try_files`) + gzip + caching
4. **CORS in Spring Security ONLY** - not in Nginx (learned the hard way!)
5. **nginx-fix.conf is your current live config** (simple, works)
6. **nginx-api-updated.conf is ready** for zero-downtime upgrade
7. **`/uploads/` served directly by Nginx** - no Spring Boot involved (fast!)
8. **Always `sudo nginx -t`** before reloading!

---

## Next: [05 - Load Balancing](./05-load-balancing.md)
