# 08 - Firewalls & Security

## What You'll Learn
- What a firewall is and how it works
- Hetzner Cloud Firewall (your dashboard shows this)
- UFW (host-level firewall)
- iptables basics
- Security best practices for your server

---

## 1. What is a Firewall?

A firewall decides which network traffic is allowed in/out of your server.

```
Without Firewall:
  Internet --> ALL ports open --> Hackers scan and attack PostgreSQL (5432),
                                   SSH brute force (22), etc.

With Firewall:
  Internet --> Firewall checks rules:
                Port 22 (SSH)?  --> ALLOW (from your IP only)
                Port 80 (HTTP)? --> ALLOW
                Port 443 (HTTPS)? --> ALLOW
                Port 5432 (DB)?  --> DENY (blocked!)
                Everything else? --> DENY
```

---

## 2. Hetzner Cloud Firewall

Your dashboard sidebar shows "Firewalls" under CLOUD.

### Setting Up Hetzner Firewall:

```
Hetzner Console -> Firewalls -> Create Firewall

Inbound Rules:
┌──────────┬──────────┬─────────────────┬────────────┐
│ Protocol │ Port     │ Source          │ Action     │
├──────────┼──────────┼─────────────────┼────────────┤
│ TCP      │ 22       │ YOUR_IP/32      │ ALLOW      │ SSH (your IP only!)
│ TCP      │ 80       │ 0.0.0.0/0      │ ALLOW      │ HTTP (everyone)
│ TCP      │ 443      │ 0.0.0.0/0      │ ALLOW      │ HTTPS (everyone)
│ TCP      │ 5432     │ -               │ DENY       │ PostgreSQL (blocked!)
│ *        │ *        │ *              │ DENY       │ Everything else
└──────────┴──────────┴─────────────────┴────────────┘

Outbound Rules: Allow all (server needs to reach internet)

Apply to: YOUR_APP_NAME server
```

### Why Block PostgreSQL (5432)?
```
If port 5432 is open to internet:
  - Hackers can try to brute-force your database password
  - Even if password is strong, it's an unnecessary risk
  - Your app connects to DB via localhost (127.0.0.1) - doesn't need external access
```

---

## 3. UFW (Uncomplicated Firewall) - Host Level

```bash
# Check UFW status
ufw status verbose

# Enable UFW
ufw enable

# Default: deny incoming, allow outgoing
ufw default deny incoming
ufw default allow outgoing

# Allow SSH (ALWAYS do this before enabling UFW!)
ufw allow 22/tcp

# Allow HTTP and HTTPS
ufw allow 80/tcp
ufw allow 443/tcp

# Allow SSH only from your IP
ufw allow from YOUR_IP to any port 22

# Block a specific IP (attacker)
ufw deny from 1.2.3.4

# Check rules
ufw status numbered

# Delete a rule
ufw delete 3    # Delete rule number 3
```

---

## 4. Security Best Practices for Your Server

### SSH Security:
```bash
# 1. Disable password login (use SSH keys only)
# Edit /etc/ssh/sshd_config:
PasswordAuthentication no
PermitRootLogin prohibit-password

# 2. Change SSH port (optional, reduces automated attacks)
Port 2222

# 3. Restart SSH
systemctl restart sshd
```

### Fail2Ban (Auto-block attackers):
```bash
# Install
apt install fail2ban

# Configure /etc/fail2ban/jail.local:
[sshd]
enabled = true
port = 22
maxretry = 3          # 3 failed attempts
bantime = 3600        # Ban for 1 hour
findtime = 600        # Within 10 minutes

[nginx-http-auth]
enabled = true

# Check banned IPs
fail2ban-client status sshd
```

### Automatic Security Updates:
```bash
# Install unattended-upgrades
apt install unattended-upgrades
dpkg-reconfigure unattended-upgrades

# This auto-installs security patches
```

---

## 5. Security Checklist for YourApp

```
[ ] Hetzner Firewall: Only ports 22, 80, 443 open
[ ] UFW enabled on server
[ ] SSH: Key-based auth only (no passwords)
[ ] PostgreSQL: Listening on localhost only (not 0.0.0.0)
[ ] Fail2Ban: Installed and active
[ ] SSL/TLS: All traffic encrypted
[ ] Docker: Containers run as non-root
[ ] Secrets: .env file not in Git, environment variables used
[ ] Backups: Enabled in Hetzner dashboard
[ ] Updates: Automatic security updates enabled
```

---

## Key Takeaways

1. **Firewall = first line of defense** - block all unnecessary ports
2. **Use Hetzner Cloud Firewall** (network level) + UFW (host level) together
3. **Never expose PostgreSQL** (5432) to the internet
4. **SSH keys only** - disable password authentication
5. **Fail2Ban** auto-blocks brute force attackers

---

## Next: [09 - Traffic Management](./09-traffic-management.md)
