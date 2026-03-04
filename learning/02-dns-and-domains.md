# 02 - DNS & Domain Management

## What You'll Learn
- How DNS works (translating domain names to IPs)
- DNS record types (A, AAAA, CNAME, MX, TXT)
- How to manage DNS for YOUR_DOMAIN.com
- Hetzner DNS management
- Subdomains and routing

---

## 1. What is DNS?

DNS (Domain Name System) = The phonebook of the internet.

Humans remember: `YOUR_DOMAIN.com`
Computers need: `YOUR_SERVER_IP`

DNS translates one to the other.

### How DNS Resolution Works (Step by Step):

```
Customer types: YOUR_DOMAIN.com

Step 1: Browser Cache
   Browser checks: "Do I already know this IP?"
   If yes -> use cached IP (skip remaining steps)

Step 2: OS Cache
   OS checks its DNS cache
   If yes -> return cached IP

Step 3: Router/ISP DNS
   Asks ISP's DNS server (e.g., Jio DNS)
   If cached -> return IP

Step 4: Root DNS Servers
   ISP asks root server: "Who handles .in domains?"
   Root says: "Ask the .in TLD server at x.x.x.x"

Step 5: TLD (Top Level Domain) Server
   ISP asks .in server: "Who handles YOUR_DOMAIN.com?"
   TLD says: "Ask the nameserver at ns1.your-registrar.com"

Step 6: Authoritative Nameserver
   ISP asks your nameserver: "What's the IP for YOUR_DOMAIN.com?"
   Nameserver responds: "YOUR_SERVER_IP"

Step 7: Response Cached
   ISP caches this for TTL duration (e.g., 300 seconds)
   Browser caches it too

Total time: First lookup ~50-200ms, Cached: ~0ms
```

---

## 2. DNS Record Types

### Records You Need to Know:

| Record | Purpose | Example |
|--------|---------|---------|
| **A** | Maps domain to IPv4 address | YOUR_DOMAIN.com -> YOUR_SERVER_IP |
| **AAAA** | Maps domain to IPv6 address | YOUR_DOMAIN.com -> YOUR_IPV6... |
| **CNAME** | Alias pointing to another domain | www -> YOUR_DOMAIN.com |
| **MX** | Mail server for the domain | mail -> YOUR_SMTP_HOST |
| **TXT** | Text records (verification, SPF, etc.) | SPF email verification |
| **NS** | Nameserver delegation | ns1.hetzner.com |
| **SRV** | Service location | Used by some apps |
| **CAA** | Certificate authority authorization | letsencrypt.org allowed |

### Your DNS Records (What They Should Look Like):

```
# A Records (IPv4)
YOUR_DOMAIN.com.        A     YOUR_SERVER_IP
api.YOUR_DOMAIN.com.    A     YOUR_SERVER_IP
www.YOUR_DOMAIN.com.    A     YOUR_SERVER_IP

# AAAA Records (IPv6)
YOUR_DOMAIN.com.        AAAA  YOUR_IPV6_ADDRESS

# CNAME Records (Aliases)
www.YOUR_DOMAIN.com.    CNAME YOUR_DOMAIN.com.

# MX Records (Email)
YOUR_DOMAIN.com.        MX    10 YOUR_SMTP_HOST.

# TXT Records (Email authentication)
YOUR_DOMAIN.com.        TXT   "v=spf1 include:YOUR_EMAIL_PROVIDER ~all"
```

---

## 3. DNS in Hetzner

### Hetzner DNS Console
Hetzner provides free DNS hosting. You can manage it from:
- **Hetzner Console** -> Left sidebar -> DNS
- Or via Hetzner DNS API

### Setting Up DNS in Hetzner:

```bash
# Using Hetzner API to manage DNS (optional, advanced)
# Get your API token from Hetzner Console -> Security -> API Tokens

# List DNS zones
curl -H "Auth-API-Token: YOUR_TOKEN" \
  https://dns.hetzner.com/api/v1/zones

# List records for a zone
curl -H "Auth-API-Token: YOUR_TOKEN" \
  https://dns.hetzner.com/api/v1/records?zone_id=YOUR_ZONE_ID
```

---

## 4. Subdomains

### What is a Subdomain?
A subdomain is a prefix added to your main domain.

```
YOUR_DOMAIN.com          -> Main website (Angular frontend)
api.YOUR_DOMAIN.com      -> Backend API (Spring Boot)
admin.YOUR_DOMAIN.com    -> Admin panel (if separate)
staging.YOUR_DOMAIN.com  -> Testing environment
```

### How Subdomains Work with Your Nginx:

```
All subdomains point to same IP: YOUR_SERVER_IP
Nginx decides where to route based on the "Host" header.

Request to YOUR_DOMAIN.com:
  Nginx -> serves Angular static files

Request to api.YOUR_DOMAIN.com:
  Nginx -> proxy_pass to Spring Boot (port 8082)
```

### Nginx Config for Subdomains:

```nginx
# Main website
server {
    server_name YOUR_DOMAIN.com www.YOUR_DOMAIN.com;

    location / {
        root /var/www/frontend;
        try_files $uri $uri/ /index.html;
    }
}

# API subdomain
server {
    server_name api.YOUR_DOMAIN.com;

    location / {
        proxy_pass http://localhost:8082;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

---

## 5. TTL (Time To Live)

### What is TTL?
TTL tells DNS caches how long to remember a record (in seconds).

```
Low TTL (300 = 5 minutes):
  + Changes take effect quickly
  - More DNS lookups (slightly slower)
  Use when: You're about to change servers/IPs

High TTL (86400 = 24 hours):
  + Fewer DNS lookups (faster for users)
  - Changes take up to 24 hours to propagate
  Use when: Your IP rarely changes
```

### Recommended TTL for Your Setup:
```
A records:     3600  (1 hour) - good balance
MX records:    86400 (24 hours) - mail servers rarely change
TXT records:   3600  (1 hour)
CNAME records: 3600  (1 hour)
```

### Before Server Migration - Lower TTL First!
```
Current: TTL 3600 (1 hour)

# 24 hours before migration:
Change TTL to 300 (5 minutes)

# Wait 24 hours for old TTL to expire

# Change IP to new server
A record -> new_server_ip

# Users switch to new server within 5 minutes

# After migration is stable:
Change TTL back to 3600
```

---

## 6. DNS Propagation

When you change DNS records, the change doesn't happen instantly worldwide.

### Why?
Every ISP, router, and browser caches DNS responses for the TTL duration.

```
DNS Change Timeline:
0 min   - You change A record from old_ip to new_ip
5 min   - Users with 5-min TTL see new IP
1 hour  - Users with 1-hour TTL see new IP
24 hours - Almost everyone sees new IP
48 hours - Global propagation complete
```

### Check DNS Propagation:
```bash
# Check from your server
dig YOUR_DOMAIN.com

# Check from multiple locations online:
# https://www.whatsmydns.net/#A/YOUR_DOMAIN.com

# Check specific DNS server
dig @8.8.8.8 YOUR_DOMAIN.com      # Google DNS
dig @1.1.1.1 YOUR_DOMAIN.com      # Cloudflare DNS
dig @208.67.222.222 YOUR_DOMAIN.com # OpenDNS
```

---

## 7. DNS Security

### Common DNS Attacks:

| Attack | What Happens | Protection |
|--------|-------------|------------|
| DNS Spoofing | Attacker returns fake IP | DNSSEC |
| DNS Hijacking | Attacker changes DNS records | 2FA on registrar account |
| DDoS on DNS | Overwhelm DNS servers | Use managed DNS (Cloudflare) |

### DNSSEC (DNS Security Extensions):
```
Without DNSSEC:
  DNS response: YOUR_DOMAIN.com -> YOUR_SERVER_IP
  (No way to verify this is the real answer)

With DNSSEC:
  DNS response: YOUR_DOMAIN.com -> YOUR_SERVER_IP
  + Digital signature proving this is authentic
```

### Protect Your DNS:
1. **Enable 2FA** on your domain registrar account
2. **Use registrar lock** to prevent unauthorized transfers
3. **Consider DNSSEC** if your registrar supports it
4. **Monitor DNS changes** - set up alerts

---

## 8. Email DNS Records (Important for Your App)

Your app sends emails from `noreply@YOUR_DOMAIN.com` via Hostinger SMTP.

### Required Email DNS Records:

```
# SPF (Sender Policy Framework) - Who can send email from your domain
YOUR_DOMAIN.com.  TXT  "v=spf1 include:YOUR_EMAIL_PROVIDER ~all"

# DKIM (DomainKeys Identified Mail) - Email signature
# Get this value from Hostinger's email settings
default._domainkey.YOUR_DOMAIN.com.  TXT  "v=DKIM1; k=rsa; p=MIG..."

# DMARC (Domain-based Message Authentication)
_dmarc.YOUR_DOMAIN.com.  TXT  "v=DMARC1; p=quarantine; rua=mailto:admin@YOUR_DOMAIN.com"
```

### Why This Matters:
Without proper email DNS records:
- Your order confirmation emails go to **spam folder**
- Your OTP emails might not be delivered
- Your domain reputation decreases

### Verify Email DNS:
```bash
# Check SPF
dig TXT YOUR_DOMAIN.com

# Check DKIM
dig TXT default._domainkey.YOUR_DOMAIN.com

# Check DMARC
dig TXT _dmarc.YOUR_DOMAIN.com

# Online tool: https://mxtoolbox.com/
```

---

## 9. Hands-On Practice Commands

```bash
# Run these on your server or local machine:

# 1. Full DNS lookup with all details
dig YOUR_DOMAIN.com +trace

# 2. Check all record types
dig YOUR_DOMAIN.com ANY

# 3. Check A record
dig YOUR_DOMAIN.com A +short
# Expected output: YOUR_SERVER_IP

# 4. Check MX records (email)
dig YOUR_DOMAIN.com MX +short

# 5. Check nameservers
dig YOUR_DOMAIN.com NS +short

# 6. Reverse DNS lookup (IP to domain)
dig -x YOUR_SERVER_IP

# 7. Check response time of DNS
dig YOUR_DOMAIN.com | grep "Query time"

# 8. Use different DNS resolvers
dig @8.8.8.8 YOUR_DOMAIN.com +short    # Google
dig @1.1.1.1 YOUR_DOMAIN.com +short    # Cloudflare

# 9. Check if your server has proper reverse DNS
host YOUR_SERVER_IP

# 10. See your local DNS cache (Linux)
systemd-resolve --statistics
```

---

## Key Takeaways

1. **DNS** translates domain names to IP addresses
2. **A record** is the most important - points your domain to your server IP
3. **Subdomains** (api., www.) all point to the same IP, Nginx routes them
4. **TTL** controls how long DNS is cached - lower it before migrations
5. **Email DNS records** (SPF, DKIM, DMARC) prevent emails going to spam
6. **DNS changes take time** to propagate globally (minutes to hours)
7. **Secure your registrar account** - if someone steals your domain, they control everything

---

## Next: [03 - SSL/TLS & HTTPS](./03-ssl-tls-https.md)
