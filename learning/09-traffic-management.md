# 09 - Traffic Management

## What You'll Learn
- Understanding traffic flow to your server
- Rate limiting (protect from abuse)
- CDN (Content Delivery Network)
- Cloudflare for YourApp
- Bandwidth optimization
- DDoS protection
- Traffic monitoring

---

## 1. Traffic Flow to Your Server

```
Users in India
    |
    v
[DNS: YOUR_DOMAIN.com -> YOUR_SERVER_IP]
    |
    v
[Internet backbone: India -> Europe ~200ms]
    |
    v
[Hetzner Network: eu-central, Helsinki]
    |
    v
[Your Server: YOUR_SERVER_IP]
    |
    v
[Nginx: Route by domain/path]
    |
    ├── Static files (Angular) --> Serve directly (fast)
    ├── API calls (/api/*) --> Spring Boot (8082)
    └── WebSocket (/ws) --> Spring Boot (8082)
```

### Types of Traffic:

| Type | Example | Size | Frequency |
|------|---------|------|-----------|
| Static assets | JS, CSS, images | 50KB-5MB | Cached after first load |
| API calls | GET /api/shops | 1-50KB | Every user action |
| File uploads | Product images | 100KB-10MB | Shop owners adding products |
| WebSocket | Real-time orders | ~1KB/message | Continuous when app open |

---

## 2. Rate Limiting

### Why Rate Limit?
```
Without rate limiting:
  Bot sends 10,000 requests/second --> Server crashes
  Hacker tries 1000 passwords/second --> Account compromised
  Scraper downloads all your data --> Bandwidth wasted

With rate limiting:
  More than 10 requests/second from same IP --> HTTP 429 (Too Many Requests)
```

### Nginx Rate Limiting:

```nginx
# In /etc/nginx/nginx.conf (http block):

# Zone 1: General API - 10 requests/second per IP
limit_req_zone $binary_remote_addr zone=api:10m rate=10r/s;

# Zone 2: Login - 1 request/second per IP
limit_req_zone $binary_remote_addr zone=login:10m rate=1r/s;

# Zone 3: File upload - 2 requests/second per IP
limit_req_zone $binary_remote_addr zone=upload:10m rate=2r/s;

# In server block:
server {
    # General API
    location /api/ {
        limit_req zone=api burst=20 nodelay;
        #                  burst=20: allow 20 extra requests in queue
        #                  nodelay: process burst immediately, don't delay
        proxy_pass http://localhost:8082;
    }

    # Login endpoint (strict)
    location /api/auth/login {
        limit_req zone=login burst=3;
        proxy_pass http://localhost:8082;
    }

    # File upload
    location /api/upload {
        limit_req zone=upload burst=5;
        client_max_body_size 10M;
        proxy_pass http://localhost:8082;
    }
}
```

### Spring Boot Rate Limiting (Application Level):

```java
// Using a filter or interceptor
@Component
public class RateLimitFilter extends OncePerRequestFilter {
    private final Map<String, AtomicInteger> requestCounts = new ConcurrentHashMap<>();

    @Override
    protected void doFilterInternal(HttpServletRequest request,
                                     HttpServletResponse response,
                                     FilterChain chain) {
        String clientIp = request.getRemoteAddr();
        AtomicInteger count = requestCounts.computeIfAbsent(clientIp,
            k -> new AtomicInteger(0));

        if (count.incrementAndGet() > 100) {  // 100 requests per window
            response.setStatus(429);
            return;
        }
        chain.doFilter(request, response);
    }
}
```

---

## 3. CDN (Content Delivery Network)

### What is a CDN?
A network of servers around the world that cache your static files.

```
Without CDN:
  User in Mumbai --> Request travels to Helsinki (200ms) --> Gets response

With CDN (Cloudflare):
  User in Mumbai --> Request goes to Cloudflare Mumbai PoP (10ms) --> Gets cached response
  (If not cached, Cloudflare fetches from Helsinki, caches it for next user)
```

### CDN Caches:
```
Cacheable (static, same for everyone):
  ✅ JavaScript files (app.js)
  ✅ CSS files (styles.css)
  ✅ Images (logo.png, product photos)
  ✅ Fonts (woff2 files)

Not Cacheable (dynamic, different per user):
  ❌ API responses (/api/orders - different per user)
  ❌ Authentication tokens
  ❌ WebSocket connections
```

---

## 4. Setting Up Cloudflare for YourApp

### Why Cloudflare?
- **Free tier** available
- CDN with servers in India (Mumbai, Chennai)
- DDoS protection
- Free SSL certificate
- Analytics and traffic insights

### Setup Steps:

```
1. Create Cloudflare account (free)
2. Add site: YOUR_DOMAIN.com
3. Cloudflare gives you nameservers:
   ns1.cloudflare.com
   ns2.cloudflare.com
4. Update nameservers at your domain registrar
5. Configure DNS in Cloudflare:
   A  YOUR_DOMAIN.com  YOUR_SERVER_IP  (Proxied - orange cloud)
   A  api.YOUR_DOMAIN.com  YOUR_SERVER_IP  (DNS Only - gray cloud)
```

### Important: API Should NOT Be Proxied:
```
YOUR_DOMAIN.com      -> Proxied (orange cloud) ✅
  Static files benefit from CDN caching

api.YOUR_DOMAIN.com  -> DNS Only (gray cloud) ✅
  API calls need to go directly to your server
  WebSocket won't work well through Cloudflare free tier
```

### Cloudflare Benefits for Your App:
```
Before Cloudflare:
  User in India -> Helsinki: 200ms per request
  Angular app loads: ~3 seconds (all files from Helsinki)

After Cloudflare:
  User in India -> Cloudflare Mumbai: 10ms for cached files
  Angular app loads: ~1 second (static files from Mumbai CDN)
  API calls still go to Helsinki (200ms) - this won't change
```

---

## 5. Bandwidth Optimization

### Gzip Compression (Already in Your Nginx):
```nginx
gzip on;
gzip_types text/plain text/css application/json application/javascript;
gzip_min_length 1024;

# Effect:
# Without gzip: app.js = 500KB
# With gzip:    app.js = 120KB (76% smaller!)
# Users download less data, pages load faster
```

### Image Optimization:
```bash
# Product images can be huge. Optimize them!

# Install imagemagick
apt install imagemagick

# Resize and compress product images
convert input.jpg -resize 800x800 -quality 80 output.jpg
# Original: 5MB -> Optimized: 200KB

# For your app, consider:
# 1. Resize images on upload (in Spring Boot)
# 2. Serve different sizes for mobile vs desktop
# 3. Use WebP format (40% smaller than JPEG)
```

### Lazy Loading:
```
In your Angular app:
- Don't load all product images at once
- Load them as user scrolls (lazy loading)
- Use Angular's built-in lazy loading for routes
```

---

## 6. DDoS Protection

### What is DDoS?
```
DDoS = Distributed Denial of Service
Thousands of computers send fake traffic to your server
Your server gets overwhelmed and can't serve real users
```

### Protection Layers:

```
Layer 1: Cloudflare (if enabled)
  Filters obvious bot traffic before it reaches your server

Layer 2: Hetzner DDoS Protection
  Hetzner automatically detects and mitigates large attacks

Layer 3: Nginx Rate Limiting
  Limits requests per IP

Layer 4: Fail2Ban
  Bans IPs that show attack patterns

Layer 5: Application
  JWT authentication blocks unauthenticated requests
```

### Quick DDoS Mitigation:
```bash
# See top IPs hitting your server
awk '{print $1}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -20

# Block a specific attacking IP
iptables -A INPUT -s 1.2.3.4 -j DROP

# Block a whole subnet
iptables -A INPUT -s 1.2.3.0/24 -j DROP

# Or use Hetzner Firewall (preferred - blocks at network level)
```

---

## 7. Traffic Monitoring

### Nginx Access Log Analysis:
```bash
# Requests per minute
awk '{print $4}' /var/log/nginx/access.log | cut -d: -f1-2 | sort | uniq -c | tail -20

# Top requested URLs
awk '{print $7}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -20

# HTTP status code distribution
awk '{print $9}' /var/log/nginx/access.log | sort | uniq -c | sort -rn

# Top user agents (find bots)
awk -F'"' '{print $6}' /var/log/nginx/access.log | sort | uniq -c | sort -rn | head -10

# Bandwidth by URL
awk '{print $10, $7}' /var/log/nginx/access.log | sort -rn | head -20
```

### Real-time Monitoring Tools:
```bash
# GoAccess - real-time web log analyzer
apt install goaccess
goaccess /var/log/nginx/access.log --log-format=COMBINED -o /var/www/html/report.html --real-time-html

# Then visit: https://YOUR_DOMAIN.com/report.html

# vnstat - network traffic monitor
apt install vnstat
vnstat -l  # Live traffic
vnstat -d  # Daily summary
vnstat -m  # Monthly summary
```

---

## Key Takeaways

1. **Rate limiting** is essential - protect login and API endpoints
2. **CDN (Cloudflare)** dramatically improves speed for Indian users
3. **Gzip compression** reduces bandwidth by 60-80%
4. **DDoS protection** works in layers (Cloudflare -> Hetzner -> Nginx -> App)
5. **Monitor your traffic** to detect issues early
6. **Proxy frontend through Cloudflare**, keep API direct

---

## Next: [10 - Monitoring & Logging](./10-monitoring-logging.md)
