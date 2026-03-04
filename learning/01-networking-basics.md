# 01 - Networking Basics

## What You'll Learn
- How the internet works (IP, TCP, UDP, HTTP)
- How your server communicates with the world
- Ports, protocols, and how traffic flows
- How your YourApp app receives requests

---

## 1. The Internet - How It Actually Works

### The Big Picture
When a customer opens `YOUR_DOMAIN.com` on their phone:

```
Customer's Phone (India)
    |
    v
ISP (Jio/Airtel) --> DNS Server (finds IP: YOUR_SERVER_IP)
    |
    v
Undersea Cable / Internet Backbone
    |
    v
Hetzner Datacenter (Helsinki, Finland)
    |
    v
Your Server (YOUR_SERVER_IP)
    |
    v
Nginx --> Docker --> Spring Boot --> PostgreSQL
    |
    v
Response travels back the same path
    |
    v
Customer sees the app
```

The entire round trip takes ~150-300ms (India to Finland).

---

## 2. IP Addresses

### What is an IP Address?
An IP address is like a postal address for computers. Every device on the internet has one.

### Your Server's IPs:
- **IPv4**: `YOUR_SERVER_IP` (like a house number)
- **IPv6**: `YOUR_IPV6_ADDRESS` (newer, longer format)

### Types of IP Addresses:

| Type | Range | Example | Used For |
|------|-------|---------|----------|
| Public IP | Globally unique | YOUR_SERVER_IP | Your server (internet-facing) |
| Private IP | 10.x.x.x, 172.16-31.x.x, 192.168.x.x | 192.168.1.1 | Internal networks |
| Localhost | 127.0.0.1 | 127.0.0.1 | Same machine communication |

### Check Your Server's IP:
```bash
# SSH into your server first
ssh root@YOUR_SERVER_IP

# See all network interfaces and IPs
ip addr show

# See your public IP
curl ifconfig.me

# See your IPv6
curl -6 ifconfig.me
```

### Hetzner Floating IPs
Your dashboard shows "Add Floating IP" - this is a static IP that can be moved between servers. Useful when you upgrade servers - the IP stays the same.

---

## 3. Ports

### What is a Port?
If an IP address is a building's address, a port is the room number. A single server can run many services, each on a different port.

### Your Server's Important Ports:

| Port | Protocol | Service | Status |
|------|----------|---------|--------|
| 22 | SSH | Remote access to server | Open (must be open) |
| 80 | HTTP | Web traffic (redirects to 443) | Open |
| 443 | HTTPS | Secure web traffic | Open |
| 5432 | PostgreSQL | Database | Should be closed to public! |
| 8080-8085 | HTTP | Spring Boot backends (Docker internal) | Internal only |

### Check Open Ports on Your Server:
```bash
# See what's listening
ss -tlnp

# Or using netstat
netstat -tlnp

# Check if a specific port is open
nc -zv YOUR_SERVER_IP 443

# Check from outside (run from your local machine)
nmap -p 22,80,443,5432 YOUR_SERVER_IP
```

### Port Ranges:
- **0-1023**: Well-known ports (HTTP=80, HTTPS=443, SSH=22)
- **1024-49151**: Registered ports (PostgreSQL=5432, MySQL=3306)
- **49152-65535**: Dynamic/Private ports

---

## 4. Protocols (TCP, UDP, HTTP)

### TCP (Transmission Control Protocol)
- **Reliable**: Guarantees data arrives in order
- **Connection-based**: Handshake before sending data
- **Used by**: HTTP, HTTPS, SSH, PostgreSQL
- **Your app uses TCP for everything**

```
TCP 3-Way Handshake (happens every connection):

Customer          Your Server
   |--- SYN --------->|    "Hey, want to talk?"
   |<-- SYN-ACK ------|    "Sure, I'm ready"
   |--- ACK --------->|    "Great, let's go"
   |                   |
   |--- Data -------->|    (actual request)
   |<-- Data ---------|    (response)
```

### UDP (User Datagram Protocol)
- **Fast but unreliable**: No guarantee of delivery
- **Connectionless**: Just sends data
- **Used by**: DNS lookups, video streaming, gaming
- **Your DNS queries use UDP**

### HTTP (HyperText Transfer Protocol)
- Built on top of TCP
- Request-Response model
- This is what your Angular frontend and Spring Boot backend speak

```
HTTP Request (Customer -> Your Server):
GET /api/shops HTTP/1.1
Host: api.YOUR_DOMAIN.com
Authorization: Bearer eyJhbGciOiJI...

HTTP Response (Your Server -> Customer):
HTTP/1.1 200 OK
Content-Type: application/json
{"shops": [{"name": "Krishna Store", ...}]}
```

### HTTPS = HTTP + TLS Encryption
- Same as HTTP but encrypted
- Uses port 443 instead of 80
- Your server uses Let's Encrypt certificates for this

---

## 5. How a Request Flows Through Your System

### Complete Request Flow (Customer orders from a shop):

```
Step 1: DNS Resolution
   Customer types YOUR_DOMAIN.com
   Browser asks DNS: "What's the IP for YOUR_DOMAIN.com?"
   DNS responds: "YOUR_SERVER_IP"

Step 2: TCP Connection
   Browser connects to YOUR_SERVER_IP:443
   TCP 3-way handshake happens
   TLS handshake happens (encryption setup)

Step 3: HTTP Request
   Browser sends: GET /api/shops/nearby?lat=12.9&lng=77.5
   Headers include: JWT token, Content-Type, etc.

Step 4: Nginx Receives (Port 443)
   Nginx terminates SSL
   Sees /api/ in URL
   Forwards to backend container (port 8082)

Step 5: Docker Networking
   Request enters Docker network
   Routes to Spring Boot container

Step 6: Spring Boot Processes
   Security filter checks JWT token
   Controller receives request
   Service layer queries PostgreSQL
   Returns JSON response

Step 7: Response Travels Back
   Spring Boot -> Docker -> Nginx -> Internet -> Customer's phone

Total time: ~200-500ms
```

---

## 6. Network Layers (OSI Model - Simplified)

You don't need to memorize all 7 layers, but understand these:

```
Layer 7: Application    (HTTP, HTTPS, WebSocket)  <-- Your app code
Layer 4: Transport      (TCP, UDP)                <-- Ports live here
Layer 3: Network        (IP)                      <-- IP addresses live here
Layer 2: Data Link      (Ethernet, MAC)           <-- Physical network
Layer 1: Physical       (Cables, WiFi)            <-- The actual wires
```

### Why This Matters:
- **Nginx** works at Layer 7 (understands HTTP)
- **Load Balancer** can work at Layer 4 (TCP) or Layer 7 (HTTP)
- **Firewalls** typically work at Layer 3/4 (IP + Port rules)
- **Hetzner Firewall** works at Layer 3/4

---

## 7. Your Server's Network Architecture

```
Internet
    |
    v
[Hetzner Network / eu-central]
    |
    v
[Physical Switch in hel1-dc2]
    |
    v
[Your Server: CX33]
    |--- eth0 (public: YOUR_SERVER_IP)  <-- Internet-facing
    |--- docker0 (172.17.0.1)        <-- Docker bridge network
    |     |--- container1 (172.17.0.2) - backend
    |     |--- container2 (172.17.0.3) - frontend
    |
    v
[Hetzner Volume: HC_Volume_XXXXXX]
    Mounted at /mnt/HC_Volume_XXXXXX
    Used for: file uploads, product images
```

---

## 8. Bandwidth & Traffic

### Your Hetzner Plan:
- **Traffic**: 20 TB outbound per month (currently 0 used)
- **Speed**: 1 Gbps connection
- **Inbound traffic**: Free and unlimited

### Check Your Traffic:
```bash
# Real-time bandwidth monitoring
iftop

# Or using vnstat (install first: apt install vnstat)
vnstat

# See traffic per day
vnstat -d

# See traffic per month
vnstat -m

# Check how much data Nginx has served
cat /var/log/nginx/access.log | wc -l
```

### Bandwidth Calculation Example:
```
Average page load = 500 KB
1000 users/day x 10 pages each = 10,000 page loads
10,000 x 500 KB = 5 GB/day = 150 GB/month

Your limit: 20 TB/month = 20,000 GB/month
You're using: ~0.75% of your limit (plenty of room!)
```

---

## 9. Latency

### What is Latency?
Time it takes for data to travel between two points.

### Test Latency to Your Server:
```bash
# From your local machine (India)
ping YOUR_SERVER_IP

# Typical results:
# India to Helsinki: 150-250ms
# Europe to Helsinki: 10-30ms
# Same datacenter: <1ms
```

### Why Latency Matters for YourApp:
Your users are in India, server is in Finland. This adds ~200ms to every request. Solutions:
1. **CDN** (CloudFlare) - cache static files closer to India
2. **Move server to India** - Hetzner doesn't have Indian datacenter
3. **Use a cloud provider with Indian region** (AWS Mumbai, DigitalOcean Bangalore)
4. **Optimize API responses** - fewer round trips = less total latency

---

## 10. Hands-On Practice Commands

### Run these on your Hetzner server:

```bash
# 1. See your network configuration
ip addr show
ip route show

# 2. Check DNS resolution
dig YOUR_DOMAIN.com
nslookup api.YOUR_DOMAIN.com

# 3. See active connections
ss -tunapl

# 4. Check which processes are using which ports
lsof -i -P -n | grep LISTEN

# 5. Trace the route from your server to Google
traceroute google.com

# 6. Check network speed
# Install: apt install speedtest-cli
speedtest-cli

# 7. Monitor network traffic in real-time
# Install: apt install iftop
iftop -i eth0

# 8. See Docker network
docker network ls
docker network inspect bridge

# 9. Check if your services are responding
curl -I https://YOUR_DOMAIN.com
curl -I https://api.YOUR_DOMAIN.com/actuator/health

# 10. See firewall rules
iptables -L -n
```

---

## Key Takeaways

1. **IP Address** = Server's address on the internet (YOUR_SERVER_IP)
2. **Port** = Which service to talk to (443 for HTTPS, 8082 for your backend)
3. **TCP** = Reliable protocol your app uses for all communication
4. **HTTP/HTTPS** = The language browsers and APIs speak
5. **Latency** = Distance matters - India to Finland adds ~200ms
6. **Bandwidth** = You have 20TB/month, more than enough for now
7. **Every request** goes through: DNS -> TCP -> TLS -> Nginx -> Docker -> Spring Boot

---

## Next: [02 - DNS & Domain Management](./02-dns-and-domains.md)
