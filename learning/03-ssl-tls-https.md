# 03 - SSL/TLS & HTTPS

## What You'll Learn
- How HTTPS encryption works
- What SSL/TLS certificates are
- Your actual setup: Cloudflare Proxy + Certbot (Let's Encrypt)
- Step-by-step: How you got your SSL certificate
- Certificate renewal
- Common SSL problems and how to fix them

---

## 1. Why HTTPS Matters

### Without HTTPS (HTTP):
```
Customer's Phone ----[plain text]----> Your Server
"password=krishna123"  <-- Anyone in between can read this!

Attackers can:
- Read passwords, JWT tokens
- See what pages users visit
- Modify responses (inject ads, malware)
- Steal payment information
```

### With HTTPS:
```
Customer's Phone ----[encrypted]----> Your Server
"a8f3k2x9m1..." <-- Unreadable to anyone in between

Protection:
- Encryption: Data is scrambled
- Authentication: Server proves its identity
- Integrity: Data can't be modified in transit
```

---

## 2. YOUR Actual SSL Setup

You use **TWO layers** of SSL:

```
Browser (Customer)
    |
    | HTTPS (Cloudflare Universal SSL - auto-managed)
    v
[Cloudflare Edge Server - Orange Cloud Proxy ON]
    |
    | HTTPS (Let's Encrypt certificate on your server)
    v
[Your Hetzner Server - Nginx]
    |
    | HTTP (plain, internal Docker network only)
    v
[Spring Boot Container - port 8082]
```

### Two Certificates Involved:

| Certificate | Where | Who Made It | Validity |
|------------|-------|-------------|----------|
| **Cloudflare Universal SSL** | Cloudflare Edge | Cloudflare (automatic) | Auto-renewed |
| **Let's Encrypt (Certbot)** | Your Nginx Server | You ran `certbot` | 90 days (auto-renewed) |

### Your Certificate Files on Server:
```
/etc/letsencrypt/live/api.YOUR_DOMAIN.com/
├── fullchain.pem     # Certificate + chain (used in Nginx)
├── privkey.pem       # Private key (used in Nginx, KEEP SECRET!)
├── cert.pem          # Just the certificate
└── chain.pem         # Intermediate certificates
```

### Your Nginx Config (from your server):
```nginx
server {
    listen 80;
    server_name api.YOUR_DOMAIN.com;
    return 301 https://$host$request_uri;
}

server {
    listen 443 ssl;
    server_name api.YOUR_DOMAIN.com;

    ssl_certificate /etc/letsencrypt/live/api.YOUR_DOMAIN.com/fullchain.pem;
    ssl_certificate_key /etc/letsencrypt/live/api.YOUR_DOMAIN.com/privkey.pem;

    location / {
        proxy_pass http://localhost:8082;
        proxy_http_version 1.1;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection "upgrade";

        # NO CORS HEADERS - Spring Security handles all CORS
        # Adding CORS headers here causes duplicate headers and login failures
    }

    client_max_body_size 50M;
}
```

### Your Domains Covered:
```
Certificate: /etc/letsencrypt/renewal/api.YOUR_DOMAIN.com.conf
Covers:
  - YOUR_DOMAIN.com
  - api.YOUR_DOMAIN.com
  - www.YOUR_DOMAIN.com (likely)
```

---

## 3. How TLS/SSL Works

### The TLS Handshake:

```
Customer's Browser                    Cloudflare Edge
      |                                      |
      |---1. ClientHello ------------------>|
      |   "I support TLS 1.3"               |
      |                                      |
      |<--2. ServerHello + Certificate ------|
      |   Cloudflare's Universal SSL cert    |
      |                                      |
      |---3. Browser verifies cert           |
      |   "Cloudflare is trusted? YES"       |
      |                                      |
      |<==4. Encrypted connection ==========>|

Then Cloudflare connects to YOUR server:

Cloudflare Edge                       Your Nginx
      |                                      |
      |---Encrypted (Let's Encrypt cert)--->|
      |   Cloudflare verifies your cert      |
      |                                      |
      |<==Encrypted response ===============|
```

### TLS Versions:
| Version | Status | Security |
|---------|--------|----------|
| SSL 2.0, 3.0 | Deprecated | Broken, never use |
| TLS 1.0, 1.1 | Deprecated | Weak, disable these |
| TLS 1.2 | Active | Good, widely supported |
| **TLS 1.3** | **Current** | **Best, use this** |

---

## 4. Step-by-Step: How You Got Your Certificate

### Prerequisites Done:
```
- Cloudflare account created
- Domain added to Cloudflare
- Nameservers changed to Cloudflare's
- Cloudflare proxy: Orange cloud ON
- DNS: A records pointing to YOUR_SERVER_IP
```

### Certificate Generation Steps:

```bash
# Step 1: SSH into your server
ssh root@YOUR_SERVER_IP
# (or: ssh thiru@YOUR_SERVER_IP, then use sudo)

# Step 2: Install Certbot + Nginx plugin
sudo apt update
sudo apt install certbot python3-certbot-nginx

# Step 3: Generate certificate for all your domains
sudo certbot --nginx \
  -d YOUR_DOMAIN.com \
  -d api.YOUR_DOMAIN.com \
  -d www.YOUR_DOMAIN.com

# Certbot asked you:
#   1. Enter email address: your-email@gmail.com
#   2. Agree to terms: Y
#   3. Share email with EFF: N (optional)
#   4. Redirect HTTP to HTTPS: 2 (Yes, redirect)

# Certbot automatically:
#   - Connected to Let's Encrypt servers
#   - Proved you own the domain (HTTP-01 challenge)
#   - Generated RSA certificate
#   - Saved cert to /etc/letsencrypt/live/api.YOUR_DOMAIN.com/
#   - Added ssl_certificate lines to Nginx config
#   - Set up auto-renewal timer

# Step 4: Verify it worked
sudo nginx -t
sudo systemctl reload nginx
curl -I https://api.YOUR_DOMAIN.com
```

### That's It! Certbot Did Everything Automatically.

---

## 5. Certificate Renewal

### Auto-Renewal (Already Set Up):
```
Certbot installed a systemd timer that runs twice daily.
It checks if your cert expires within 30 days.
If yes, it auto-renews. If no, it does nothing.

Your cert renews automatically - you don't need to do anything!
```

### Check Auto-Renewal Status:
```bash
# Check if timer is active
sudo systemctl list-timers | grep certbot
# Should show: certbot.timer    active

# Or check cron
cat /etc/cron.d/certbot
```

### Test Renewal (Dry Run):
```bash
# IMPORTANT: Always use sudo!
sudo certbot renew --dry-run

# Expected output:
# "Congratulations, all simulated renewals succeeded"
# (This is what YOUR server showed - it works!)

# Without sudo you get:
# [Errno 13] Permission denied: '/var/log/letsencrypt/.certbot.lock'
# Always use: sudo certbot ...
```

### Force Manual Renewal:
```bash
# If you ever need to manually renew
sudo certbot renew --force-renewal
sudo systemctl reload nginx
```

### Check When Your Certificate Expires:
```bash
# Method 1: Certbot
sudo certbot certificates

# Method 2: OpenSSL
openssl x509 -in /etc/letsencrypt/live/api.YOUR_DOMAIN.com/fullchain.pem -noout -enddate

# Method 3: From outside
echo | openssl s_client -connect YOUR_DOMAIN.com:443 2>/dev/null | openssl x509 -noout -dates
```

### Cloudflare Proxy + Certbot: Why It Works
```
You might wonder: "Certbot needs direct access to verify my domain,
but Cloudflare proxy is in the way?"

It works because:
1. Certbot creates a file at: http://YOUR_DOMAIN.com/.well-known/acme-challenge/xxxxx
2. Let's Encrypt tries to access that URL
3. Cloudflare proxy forwards the request to your server
4. Nginx serves the file
5. Let's Encrypt verifies -> Certificate issued!

Your dry-run confirmed this works: "all simulated renewals succeeded"
```

---

## 6. Cloudflare SSL Settings (What You Should Have)

### Check These in Cloudflare Dashboard:

```
Cloudflare -> Your Domain -> SSL/TLS -> Overview:

  Encryption mode: "Full (strict)"     <-- IMPORTANT!

  Modes explained:
  ┌──────────────────────────────────────────────────┐
  │ Off       : No SSL (NEVER!)                      │
  │ Flexible  : Only browser->Cloudflare encrypted   │
  │             CAUSES REDIRECT LOOPS with your      │
  │             Nginx config! NEVER use this!         │
  │                                                   │
  │ Full      : Both sides encrypted                  │
  │             Doesn't verify your cert              │
  │                                                   │
  │ Full(Strict): Both sides encrypted                │  <-- USE THIS
  │               Verifies your Let's Encrypt cert    │
  │               MOST SECURE                         │
  └──────────────────────────────────────────────────┘
```

```
Cloudflare -> SSL/TLS -> Edge Certificates:

  Always Use HTTPS: ON
  Automatic HTTPS Rewrites: ON
  Minimum TLS Version: TLS 1.2
```

### Cloudflare Pages You Don't Need:

```
SSL/TLS -> Client Certificates:
  This is for mTLS (mutual TLS) - API authentication
  You DON'T need this. Your screenshot showed this empty page.
  This is NOT where your SSL cert comes from.

SSL/TLS -> Origin Server:
  This is for Cloudflare Origin Certificates (alternative to Certbot)
  You're using Certbot instead, so you don't need this either.
  But it's a good alternative (15-year cert, no renewal needed).
```

---

## 7. Cloudflare SSL Pages Explained

```
SSL/TLS in Cloudflare sidebar:

├── Overview          --> Set encryption mode (Full Strict)
├── Edge Certificates --> Cloudflare's cert for browsers (auto-managed)
├── Client Certificates --> mTLS for APIs (you DON'T use this)
├── Origin Server     --> Alternative to Certbot (you DON'T use this)
└── Custom Hostnames  --> For SaaS products (you DON'T use this)

YOU ONLY NEED:
  - Overview: Set to "Full (strict)"
  - Edge Certificates: Enable "Always Use HTTPS"
  - Everything else: Leave as default
```

---

## 8. Adding SSL for a New Subdomain

If you add a new subdomain (e.g., `admin.YOUR_DOMAIN.com`):

```bash
# Step 1: Add DNS record in Cloudflare
#   A record: admin -> YOUR_SERVER_IP (Proxied, orange cloud)

# Step 2: Add to certificate on server
sudo certbot --nginx \
  -d YOUR_DOMAIN.com \
  -d api.YOUR_DOMAIN.com \
  -d www.YOUR_DOMAIN.com \
  -d admin.YOUR_DOMAIN.com

# Certbot will expand the existing certificate to include the new domain

# Step 3: Add Nginx server block for admin subdomain
sudo nano /etc/nginx/sites-available/admin
# Configure the server block
# Enable: sudo ln -s /etc/nginx/sites-available/admin /etc/nginx/sites-enabled/

# Step 4: Test and reload
sudo nginx -t
sudo systemctl reload nginx
```

---

## 9. Common SSL Problems & Solutions

### Problem 1: "ERR_TOO_MANY_REDIRECTS"
```
Cause: Cloudflare SSL mode set to "Flexible"
  Cloudflare connects to your server via HTTP (port 80)
  Your Nginx redirects to HTTPS -> Cloudflare sees HTTP again
  = Infinite loop!

Fix: Cloudflare -> SSL/TLS -> Set to "Full (strict)"
```

### Problem 2: Certificate Expired
```
Browser: "Your connection is not private" / NET::ERR_CERT_DATE_INVALID

Fix:
  sudo certbot renew --force-renewal
  sudo systemctl reload nginx

Prevent: Check auto-renewal is working
  sudo systemctl list-timers | grep certbot
```

### Problem 3: Permission Denied with Certbot
```
Error: [Errno 13] Permission denied: '/var/log/letsencrypt/.certbot.lock'

Fix: Always use sudo!
  sudo certbot renew --dry-run      (NOT: certbot renew --dry-run)
  sudo certbot certificates         (NOT: certbot certificates)
```

### Problem 4: Mixed Content
```
Browser console: "Mixed Content: loaded over HTTPS but requested http://..."

Fix: All URLs in Angular must use https://
In environment.prod.ts:
  apiUrl: 'https://api.YOUR_DOMAIN.com'  (NOT http://)
```

### Problem 5: Redirect Loop on Specific Pages
```
Cause: Both Nginx and Spring Boot trying to redirect

Fix: Tell Spring Boot it's behind a proxy:
# application.yml:
server:
  forward-headers-strategy: framework
```

### Problem 6: "SSL Handshake Failed" (Cloudflare Error 525)
```
Cause: Cert files missing or Nginx not configured properly

Fix:
  # Check cert exists
  sudo ls -la /etc/letsencrypt/live/api.YOUR_DOMAIN.com/

  # Check Nginx config
  sudo nginx -t

  # Regenerate if needed
  sudo certbot --nginx -d api.YOUR_DOMAIN.com
```

---

## 10. SSL Testing & Verification

```bash
# 1. Check your certificate details
sudo certbot certificates
# Shows: domains, expiration date, cert path

# 2. Check from outside (shows Cloudflare cert to browser)
curl -vI https://YOUR_DOMAIN.com 2>&1 | grep -E "subject|issuer|expire"

# 3. Verify Cloudflare is active
curl -I https://YOUR_DOMAIN.com 2>&1 | grep -i "cf-ray\|server"
# Should show: server: cloudflare
# cf-ray: xxxxx-BOM  (BOM = Mumbai edge server)

# 4. Check if auto-renewal timer is active
sudo systemctl list-timers | grep certbot

# 5. Online SSL test
# https://www.ssllabs.com/ssltest/analyze.html?d=YOUR_DOMAIN.com

# 6. Check cert expiration on server
openssl x509 -in /etc/letsencrypt/live/api.YOUR_DOMAIN.com/fullchain.pem -noout -enddate
```

---

## 11. Alternative: Switch to Cloudflare Origin Certificate

If Certbot ever gives you trouble, you can switch to Cloudflare Origin Certificate:

```
Benefits:
  - 15-year validity (no renewal needed!)
  - Generated in Cloudflare dashboard
  - No certbot dependency

Steps:
  1. Cloudflare -> SSL/TLS -> Origin Server -> Create Certificate
  2. Hostnames: *.YOUR_DOMAIN.com, YOUR_DOMAIN.com
  3. Validity: 15 years
  4. Copy cert + key
  5. Save on server:
     /etc/cloudflare/origin-cert.pem
     /etc/cloudflare/origin-key.pem
  6. Update Nginx:
     ssl_certificate /etc/cloudflare/origin-cert.pem;
     ssl_certificate_key /etc/cloudflare/origin-key.pem;
  7. sudo nginx -t && sudo systemctl reload nginx

NOTE: Origin cert ONLY works when Cloudflare proxy is ON (orange cloud).
If you turn proxy off, browsers won't trust this cert.
```

---

## Key Takeaways

1. **You use Certbot (Let's Encrypt)** for SSL, NOT Cloudflare certificates
2. **Cert files at**: `/etc/letsencrypt/live/api.YOUR_DOMAIN.com/`
3. **Cloudflare provides** a second layer of SSL (browser <-> Cloudflare)
4. **SSL mode must be "Full (strict)"** in Cloudflare - NEVER "Flexible"
5. **Auto-renewal works** - confirmed by your dry-run test
6. **Always use `sudo`** with certbot commands
7. **Cloudflare "Client Certificates" page** is NOT your SSL cert - that's for mTLS
8. **Cert renews every 90 days** automatically - you don't need to do anything

---

## Next: [04 - Nginx & Reverse Proxy](./04-nginx-reverse-proxy.md)
