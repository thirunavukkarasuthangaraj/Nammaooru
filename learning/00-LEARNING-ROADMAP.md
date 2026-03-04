# YourApp Server Architecture - Learning Roadmap

## Your Current Setup (Hetzner Cloud)
- **Server**: CX33 (4 vCPU, 8GB RAM, 80GB Disk + 10GB Volume)
- **IP**: YOUR_SERVER_IP
- **Location**: Helsinki, Finland (hel1-dc2)
- **Domain**: YOUR_DOMAIN.com
- **Stack**: Spring Boot + Angular + PostgreSQL + Docker + Nginx

---

## Learning Path (Start Here, Go in Order)

### Phase 1: Foundations
| # | Topic | File | Priority |
|---|-------|------|----------|
| 1 | Networking Basics | `01-networking-basics.md` | Must Learn |
| 2 | DNS & Domain Management | `02-dns-and-domains.md` | Must Learn |
| 3 | SSL/TLS & HTTPS | `03-ssl-tls-https.md` | Must Learn |

### Phase 2: Web Server & Proxy
| # | Topic | File | Priority |
|---|-------|------|----------|
| 4 | Nginx Deep Dive | `04-nginx-reverse-proxy.md` | Must Learn |
| 5 | Load Balancing | `05-load-balancing.md` | Must Learn |

### Phase 3: Containerization & Deployment
| # | Topic | File | Priority |
|---|-------|------|----------|
| 6 | Docker & Containers | `06-docker-containers.md` | Must Learn |
| 7 | CI/CD & Zero Downtime | `07-cicd-deployment.md` | Important |

### Phase 4: Security & Traffic
| # | Topic | File | Priority |
|---|-------|------|----------|
| 8 | Firewalls & Security | `08-firewalls-security.md` | Must Learn |
| 9 | Traffic Management | `09-traffic-management.md` | Important |

### Phase 5: Production Operations
| # | Topic | File | Priority |
|---|-------|------|----------|
| 10 | Monitoring & Logging | `10-monitoring-logging.md` | Important |
| 11 | Scaling Strategies | `11-scaling-strategies.md` | Good to Know |
| 12 | Backup & Disaster Recovery | `12-backup-disaster-recovery.md` | Must Learn |
| 13 | Database Administration | `13-database-admin.md` | Important |

### Phase 6: Server Setup (What We Actually Did)
| # | Topic | File | Priority |
|---|-------|------|----------|
| 17 | Fresh Server Setup - Complete Guide | `17-fresh-server-setup.md` | Must Learn |
| 18 | Linux Commands - Essentials | `18-linux-commands-essentials.md` | Must Learn |

### Phase 7: Hands-On Practice (RUN THESE!)
| # | Topic | File | Priority |
|---|-------|------|----------|
| 14 | Load Testing (Theory + Tools) | `14-load-testing-practical.md` | Must Do |
| 15 | Architecture Diagram | `15-architecture-diagram.md` | Reference |
| 16 | Real-Time Scenarios & Troubleshooting | `16-real-time-scenarios.md` | Must Learn |

### Load Test Scripts (Ready to Run!)
| Script | Purpose | Command |
|--------|---------|---------|
| `load-test-scripts/01-health-check.js` | Basic server health test | `k6 run 01-health-check.js` |
| `load-test-scripts/02-api-load-test.js` | Multiple API endpoints | `k6 run 02-api-load-test.js` |
| `load-test-scripts/03-stress-test.js` | Find breaking point | `k6 run 03-stress-test.js` |
| `load-test-scripts/04-spike-test.js` | Sudden traffic spike | `k6 run 04-spike-test.js` |
| `load-test-scripts/05-soak-test.js` | Long-running stability | `k6 run 05-soak-test.js` |
| `load-test-scripts/06-websocket-test.js` | Real-time WebSocket | `k6 run 06-websocket-test.js` |
| `load-test-scripts/07-real-user-simulation.js` | Full user journey | `k6 run 07-real-user-simulation.js` |
| `load-test-scripts/08-concurrent-api-test.sh` | Multiple APIs with curl | `bash 08-concurrent-api-test.sh` |
| `load-test-scripts/09-load-balancer-test.sh` | LB distribution test | `bash 09-load-balancer-test.sh` |
| `load-test-scripts/10-full-scenario-test.js` | Full production sim | `k6 run 10-full-scenario-test.js` |

---

## How to Use This Guide
1. Read each file in order (Phase 1 -> Phase 6)
2. Each file has **Theory + Your Server Examples + Hands-On Commands**
3. Practice the commands on your Hetzner server
4. Files marked "Must Learn" are critical for running your server safely
5. **Install k6** (`snap install k6` or `choco install k6`) to run load tests
6. Update `load-test-scripts/config.js` with your JWT token before testing

## Quick Start for Load Testing
```bash
# 1. Install k6
choco install k6    # Windows
# or: snap install k6  # Ubuntu

# 2. Edit config
cd learning/load-test-scripts
# Edit config.js -> add your JWT token

# 3. Run first test
k6 run 01-health-check.js

# 4. Run all tests
bash run-all-tests.sh
```
