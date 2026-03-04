# Fresh Server Setup - Complete Guide (What We Did)

## Overview
This is the exact step-by-step process we followed to set up a fresh Hetzner server
for the user-service microservice. Follow this same process for any new server.

**Server:** Hetzner CAX11 (ARM64, 4GB RAM, Ubuntu 24.04)
**IP:** YOUR_SERVER_IP
**Domain:** user-api.nammaoorudelivary.in

---

## Step 1: First Login

```bash
ssh root@YOUR_SERVER_IP
```

> Hetzner gives you root access with SSH key. If you need password login temporarily:
> ```bash
> passwd root
> nano /etc/ssh/sshd_config
> # Set: PermitRootLogin yes (temporary only!)
> systemctl restart ssh
> ```

---

## Step 2: Update System

```bash
apt update && apt upgrade -y
```

> **Why?** Fresh servers may have outdated packages with known security vulnerabilities.
> Always update first before installing anything.

---

## Step 3: Firewall (UFW)

```bash
# Install (usually pre-installed on Ubuntu)
apt install -y ufw

# Allow only what you need
ufw allow 22/tcp     # SSH - so you can connect
ufw allow 80/tcp     # HTTP - needed for Certbot SSL verification
ufw allow 443/tcp    # HTTPS - your app via Nginx

# Enable firewall
ufw enable

# Verify
ufw status
```

**Expected output:**
```
Status: active
To                         Action      From
--                         ------      ----
22/tcp                     ALLOW       Anywhere
80/tcp                     ALLOW       Anywhere
443/tcp                    ALLOW       Anywhere
```

> **What is UFW?** "Uncomplicated Firewall" - controls which ports are open.
> Think of it as a door lock. Only ports you allow can receive traffic.
>
> **DO NOT open these ports:**
> - `5432` (PostgreSQL) - attackers will brute-force your database
> - `8081` (app port) - Nginx handles public traffic, app stays internal
>
> **What if I need pgAdmin from my PC?** Use SSH tunnel (explained in Step 14).

---

## Step 4: Install Fail2Ban (Brute Force Protection)

```bash
apt install -y fail2ban

# Create config
cat > /etc/fail2ban/jail.local << 'EOF'
[DEFAULT]
bantime = 3600        # Ban for 1 hour
findtime = 600        # Look at last 10 minutes
maxretry = 5          # 5 failures = banned

[sshd]
enabled = true
port = ssh
maxretry = 3          # Only 3 attempts for SSH
EOF

# Start and enable on boot
systemctl enable fail2ban
systemctl start fail2ban

# Check status
fail2ban-client status sshd
```

> **What is Fail2Ban?** It watches log files for failed login attempts.
> If someone tries wrong passwords 3 times, their IP gets blocked for 1 hour.
>
> **Useful commands:**
> ```bash
> fail2ban-client status sshd           # See banned IPs and stats
> fail2ban-client set sshd unbanip IP   # Unban an IP (if you locked yourself out)
> ```

---

## Step 5: Install Docker

```bash
# Install via snap (simplest on Ubuntu)
snap install docker

# Make Docker start automatically on reboot
systemctl enable snap.docker.dockerd

# Verify
docker --version
```

> **Why Docker?** Your Java app runs inside a container - isolated from the server.
> If the app crashes, it doesn't affect the server. Easy to rebuild and restart.
>
> **`systemctl enable`** = "start this service automatically when server boots"

---

## Step 6: Install PostgreSQL

```bash
# Install
apt install -y postgresql postgresql-contrib

# Start and enable on boot
systemctl start postgresql
systemctl enable postgresql

# Verify
systemctl status postgresql
```

> PostgreSQL runs directly on the server (not in Docker).
> Why? Database needs persistent storage and direct disk access for performance.

---

## Step 7: Create Database & Set Password

```bash
# Create the database
sudo -u postgres psql -c "CREATE DATABASE user_db;"

# Set a STRONG password (not 'postgres'!)
sudo -u postgres psql -c "ALTER USER postgres PASSWORD 'YourStr0ngP@ss!';"
```

> **IMPORTANT:** Never use `postgres` as password in production.
> Use something like: `N@mm4_DB_2024!xK9` (mix of letters, numbers, symbols)
>
> `sudo -u postgres` = run command as the `postgres` Linux user (DB admin user)

---

## Step 8: Configure PostgreSQL Authentication

### 8.1 Change auth method from `peer` to `md5`

```bash
# Find config file
sudo -u postgres psql -t -c "SHOW hba_file;"
# Usually: /etc/postgresql/16/main/pg_hba.conf

# Edit
nano /etc/postgresql/16/main/pg_hba.conf
```

Change this line:
```
local   all   all   peer
```
To:
```
local   all   all   md5
```

> **What is `peer` vs `md5`?**
> - `peer`: Uses Linux username to authenticate (only works if you're logged in as `postgres` user)
> - `md5`: Uses password to authenticate (needed for your Docker app to connect)

### 8.2 Keep listen_addresses as localhost

```bash
nano /etc/postgresql/16/main/postgresql.conf
```

Make sure this line says:
```
listen_addresses = 'localhost'
```

> **DO NOT set `listen_addresses = '*'`** unless you have a specific reason.
> `'*'` means "accept connections from any IP" - dangerous if port 5432 is open.
> `'localhost'` means "only accept connections from this server" - safe.

### 8.3 Restart PostgreSQL

```bash
systemctl restart postgresql
```

---

## Step 9: Install Nginx

```bash
apt install -y nginx

# Enable on boot
systemctl enable nginx
```

> **What is Nginx?** A web server that sits in front of your app.
> It handles HTTPS, forwards requests to your app, and hides your app port.
>
> ```
> Internet → Nginx (port 443, HTTPS) → Your App (port 8081, internal)
> ```

---

## Step 10: Configure Nginx

```bash
nano /etc/nginx/sites-available/user-api
```

Content:
```nginx
server {
    server_name user-api.nammaoorudelivary.in;

    location / {
        proxy_pass http://127.0.0.1:8081;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto $scheme;
    }
}
```

```bash
# Enable the site (create symlink)
ln -s /etc/nginx/sites-available/user-api /etc/nginx/sites-enabled/

# Test config syntax
nginx -t

# Restart
systemctl restart nginx
```

> **What each line means:**
> | Line | Meaning |
> |------|---------|
> | `server_name` | Which domain this config handles |
> | `proxy_pass http://127.0.0.1:8081` | Forward to your Docker app |
> | `X-Real-IP` | Pass visitor's real IP to your app (not Nginx's) |
> | `X-Forwarded-Proto` | Tell app if request is HTTP or HTTPS |
> | `sites-available/` | All config files stored here |
> | `sites-enabled/` | Symlink here = active |
> | `nginx -t` | Test config before restarting (catches syntax errors) |

---

## Step 11: SSL Certificate (HTTPS)

### 11.1 Install Certbot

```bash
apt install -y certbot python3-certbot-nginx
```

### 11.2 Make sure DNS is pointing to your server

Before running Certbot, your domain must point to the server IP.
In Cloudflare: `user-api.nammaoorudelivary.in` → `YOUR_SERVER_IP`

> **If using Cloudflare proxy (orange cloud):** Temporarily set to DNS-only (grey cloud)
> for Certbot to work. You can re-enable proxy after.

### 11.3 Get certificate

```bash
certbot --nginx -d user-api.nammaoorudelivary.in
```

Certbot automatically:
- Gets free SSL certificate from Let's Encrypt
- Modifies your Nginx config to add SSL
- Adds HTTP → HTTPS redirect
- Sets up auto-renewal timer

### 11.4 Verify auto-renewal

```bash
# Check timer is active
systemctl list-timers | grep certbot

# Test renewal (dry run)
certbot renew --dry-run
```

> **After Certbot, your Nginx config becomes:**
> ```nginx
> server {
>     server_name user-api.nammaoorudelivary.in;
>     listen 443 ssl;                              # Added by Certbot
>     ssl_certificate /etc/letsencrypt/live/...;   # Added by Certbot
>     ssl_certificate_key /etc/letsencrypt/live/...; # Added by Certbot
>
>     location / {
>         proxy_pass http://127.0.0.1:8081;
>         ...
>     }
> }
>
> server {                                          # Added by Certbot
>     listen 80;
>     server_name user-api.nammaoorudelivary.in;
>     return 301 https://$host$request_uri;         # Redirect HTTP → HTTPS
> }
> ```

---

## Step 12: Deploy Application Code

### 12.1 Create directory and copy code

```bash
# On server
mkdir -p /opt/user-service

# From your PC
scp -r user-service/* root@YOUR_SERVER_IP:/opt/user-service/
```

> **Note:** `scp -r` does NOT copy hidden files (like `.env`). Create `.env` manually.

### 12.2 Create .env file on server

```bash
nano /opt/user-service/.env
```

```env
DB_URL=jdbc:postgresql://localhost:5432/user_db
DB_USERNAME=postgres
DB_PASSWORD=YourStr0ngP@ss!
JWT_SECRET=<your-jwt-secret>
MAIL_HOST=smtp.hostinger.com
MAIL_PORT=587
MAIL_USERNAME=noreplay@nammaoorudelivary.in
MAIL_PASSWORD=<email-password>
MSG91_AUTH_KEY=<key>
MSG91_SENDER_ID=NAMMAO
MSG91_OTP_TEMPLATE_ID=<id>
MSG91_FORGOT_PASSWORD_TEMPLATE_ID=<id>
SMS_ENABLED=false
```

> **Why `localhost` in DB_URL?** Because Docker uses `--network host`, the container
> shares the server's network. So `localhost` inside container = server's localhost.

### 12.3 Create database tables

```bash
sudo -u postgres psql -d user_db -f /opt/user-service/src/main/resources/db/migration/V1__create_user_tables.sql
```

---

## Step 13: Build & Run Docker Container

```bash
cd /opt/user-service

# Build image
docker build --no-cache -t user-service .

# Run with auto-restart
docker run -d \
  --name user-service \
  --network host \
  --env-file /opt/user-service/.env \
  -m 512m \
  -e JAVA_OPTS="-Xms128m -Xmx384m" \
  --restart unless-stopped \
  user-service
```

> **What each flag means:**
> | Flag | Meaning |
> |------|---------|
> | `-d` | Run in background (detached) |
> | `--name user-service` | Name the container (for `docker logs`, `docker stop`) |
> | `--network host` | Container uses server's network directly |
> | `--env-file` | Load environment variables from file |
> | `-m 512m` | Max 512MB RAM (prevents eating all server memory) |
> | `-Xms128m -Xmx384m` | JVM uses 128-384MB RAM |
> | `--restart unless-stopped` | Auto-restart on crash AND on server reboot |
> | `--no-cache` | Rebuild from scratch (don't use cached layers) |

---

## Step 14: Set Up Database Backups

```bash
mkdir -p /opt/backups

cat > /opt/backups/backup-db.sh << 'EOF'
#!/bin/bash
FILENAME="/opt/backups/user_db_$(date +%Y%m%d_%H%M%S).sql.gz"
sudo -u postgres pg_dump user_db | gzip > "$FILENAME"
# Keep only last 7 days of backups
find /opt/backups -name "*.sql.gz" -mtime +7 -delete
echo "Backup done: $FILENAME"
EOF

chmod +x /opt/backups/backup-db.sh

# Add to cron (runs daily at 2 AM)
(crontab -l 2>/dev/null; echo "0 2 * * * /opt/backups/backup-db.sh") | crontab -

# Verify cron
crontab -l
```

> **What is cron?** A scheduler that runs commands at set times.
> `0 2 * * *` = "at minute 0, hour 2, every day, every month, every weekday"
>
> **To restore a backup:**
> ```bash
> gunzip < /opt/backups/user_db_20240101_020000.sql.gz | sudo -u postgres psql -d user_db
> ```

---

## Step 15: Verify Everything

```bash
# Container running?
docker ps

# App responding?
curl http://localhost:8081/api/version

# HTTPS working?
curl https://user-api.nammaoorudelivary.in/api/version

# Database running?
systemctl status postgresql

# Nginx running?
systemctl status nginx

# Fail2ban active?
fail2ban-client status sshd

# Firewall correct?
ufw status

# Docker enabled on boot?
systemctl is-enabled snap.docker.dockerd

# Certbot renewal timer?
systemctl list-timers | grep certbot
```

---

## Step 16: pgAdmin from PC (SSH Tunnel - Safe Method)

Instead of opening port 5432 to the internet, use SSH tunnel:

**In pgAdmin:**
1. Create Server → **Connection** tab:
   - Host: `localhost`
   - Port: `5432`
   - Username: `postgres`
   - Password: your strong DB password

2. **SSH Tunnel** tab:
   - Use SSH tunneling: Yes
   - Tunnel host: `YOUR_SERVER_IP`
   - Tunnel port: `22`
   - Username: `root`
   - Authentication: Password or SSH key

> **How SSH tunnel works:**
> ```
> Your PC (pgAdmin) → SSH to server → localhost:5432 (PostgreSQL)
> ```
> The database port never touches the internet. Only SSH (port 22) is used.

---

## What Auto-Starts on Reboot?

| Service | Auto-start? | Command that enabled it |
|---------|------------|------------------------|
| PostgreSQL | Yes | `systemctl enable postgresql` |
| Docker | Yes | `systemctl enable snap.docker.dockerd` |
| user-service container | Yes | `--restart unless-stopped` |
| Nginx | Yes | `systemctl enable nginx` |
| Fail2ban | Yes | `systemctl enable fail2ban` |
| UFW (firewall) | Yes | `ufw enable` (persists) |
| Certbot renewal | Yes | Auto-installed timer |
| Cron (backups) | Yes | Cron runs by default |

**Test:** Reboot server with `reboot` and check everything comes back:
```bash
reboot
# Wait 1-2 minutes, then SSH back in
docker ps                    # container should be running
systemctl status postgresql  # should be active
systemctl status nginx       # should be active
```

---

## Security Checklist

| # | Item | Status | Risk if Skipped |
|---|------|--------|-----------------|
| 1 | UFW enabled (only 22, 80, 443) | Must do | Anyone can access any port |
| 2 | Fail2ban installed | Must do | Brute force SSH attacks |
| 3 | Strong DB password | Must do | DB can be hacked |
| 4 | Port 5432 NOT open | Must do | DB exposed to internet |
| 5 | `listen_addresses = 'localhost'` | Must do | DB accepts remote connections |
| 6 | `--restart unless-stopped` | Should do | Container won't restart after reboot |
| 7 | DB backups via cron | Should do | Data loss if disk fails |
| 8 | SSL via Certbot | Must do | Passwords sent in plain text |
| 9 | Port 8081 NOT open | Should do | App bypasses Nginx/SSL |

---

## Quick Reference: Redeploy After Code Changes

```bash
# On server
cd /opt/user-service
docker build --no-cache -t user-service .
docker rm -f user-service
docker run -d \
  --name user-service \
  --network host \
  --env-file /opt/user-service/.env \
  -m 512m \
  -e JAVA_OPTS="-Xms128m -Xmx384m" \
  --restart unless-stopped \
  user-service

# Verify
docker logs -f user-service
```

---

## Flow Diagram

```
User Browser
    │
    ▼
Cloudflare DNS (user-api.nammaoorudelivary.in → YOUR_SERVER_IP)
    │
    ▼
UFW Firewall (allows port 443 only)
    │
    ▼
Nginx (port 443, SSL/HTTPS)
    │  Certbot manages SSL certificate
    │
    ▼
proxy_pass → 127.0.0.1:8081
    │
    ▼
Docker Container (user-service, --network host)
    │  --restart unless-stopped
    │  -m 512m memory limit
    │
    ▼
PostgreSQL (localhost:5432, user_db)
    │  listen_addresses = 'localhost'
    │  md5 authentication
    │  Daily backup via cron
    │
    ▼
Fail2ban watches SSH login attempts
UFW blocks all ports except 22, 80, 443
```
