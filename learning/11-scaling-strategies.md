# 11 - Scaling Strategies

## What You'll Learn
- Vertical vs Horizontal scaling
- When and how to scale your YourApp app
- Database scaling
- Hetzner server upgrade path

---

## 1. Vertical Scaling (Scale Up)

```
Current: CX33 (4 vCPU, 8GB RAM) - $5.99/mo

Upgrade Path in Hetzner:
  CX33  -> 4 vCPU,  8GB RAM  - $5.99/mo   (current)
  CX43  -> 4 vCPU, 16GB RAM  - $12.49/mo
  CX53  -> 8 vCPU, 32GB RAM  - $24.49/mo
  CCX13 -> 2 vCPU,  8GB RAM  - $12.49/mo  (dedicated CPU)
  CCX23 -> 4 vCPU, 16GB RAM  - $24.49/mo  (dedicated CPU)

How: Hetzner Console -> Server -> Rescale (shown in your dashboard)
Takes: ~2 minutes, requires server restart
```

### When to Scale Vertically:
- CPU consistently >70%
- RAM consistently >80%
- Quick fix, no code changes needed

---

## 2. Horizontal Scaling (Scale Out)

```
Current:     1 server running everything
Scaled out:  Multiple servers, each handling part of the work

Architecture:
  [Load Balancer]
       |
  ┌----+----┐
  |         |
[Server1] [Server2]   <-- Both run backend + frontend
  |         |
  └----+----┘
       |
  [DB Server]          <-- Dedicated database server
  [File Storage]       <-- Hetzner Object Storage / Volume
```

### Horizontal Scaling Steps:
```
Step 1: Separate database to its own server
Step 2: Use Hetzner Object Storage for files (instead of volume)
Step 3: Add second app server
Step 4: Add Hetzner Load Balancer
Step 5: Add more servers as needed
```

---

## 3. Database Scaling

```
Level 1: Optimize queries (free, do this first!)
  - Add indexes
  - Use EXPLAIN ANALYZE on slow queries
  - Connection pooling (HikariCP - already have this)

Level 2: Read replicas
  Primary DB (writes) -> Replica DB (reads)
  Spring Boot reads from replica, writes to primary

Level 3: Dedicated DB server
  Move PostgreSQL to its own Hetzner server
  More RAM for caching, dedicated CPU for queries

Level 4: Managed database
  Hetzner Managed PostgreSQL or AWS RDS
  Auto-backups, auto-failover, monitoring
```

---

## 4. Your Scaling Roadmap

```
Current (0-500 users): Single CX33 - FINE
  Just optimize code and queries

Growth (500-2000 users): Upgrade to CX53
  More CPU/RAM, same architecture

Scale (2000-10000 users):
  Separate DB server
  Add CDN (Cloudflare)
  Multiple backend containers

Enterprise (10000+ users):
  Multiple app servers + Load Balancer
  Database replication
  Object storage for files
  Consider moving to cloud provider with Indian datacenter
```

---

## Key Takeaways

1. **Scale vertically first** - it's the easiest (upgrade server in Hetzner)
2. **Optimize before scaling** - fix slow queries, add caching
3. **CDN is the cheapest scaling** - offloads static files
4. **Separate database** when app server needs more resources
5. **Horizontal scaling** when single server can't handle load

---

## Next: [12 - Backup & Disaster Recovery](./12-backup-disaster-recovery.md)
