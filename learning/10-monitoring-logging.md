# 10 - Monitoring & Logging

## What You'll Learn
- Why monitoring matters
- Spring Boot Actuator (your health endpoints)
- Nginx logging
- Docker logging
- Prometheus + Grafana setup
- Alert systems

---

## 1. What to Monitor

```
Server Level:
  CPU usage, RAM usage, Disk space, Network I/O

Application Level:
  Response times, Error rates, Active users, API call counts

Database Level:
  Query times, Connection pool, Disk usage

Docker Level:
  Container health, Resource limits, Restart counts
```

---

## 2. Spring Boot Actuator (Already in Your App)

Your app exposes `/actuator/*` endpoints:

```bash
# Health check
curl http://localhost:8082/actuator/health
# {"status":"UP","components":{"db":{"status":"UP"},"diskSpace":{"status":"UP"}}}

# Application info
curl http://localhost:8082/actuator/info

# Metrics (response times, JVM memory, etc.)
curl http://localhost:8082/actuator/metrics
curl http://localhost:8082/actuator/metrics/jvm.memory.used
curl http://localhost:8082/actuator/metrics/http.server.requests

# Environment
curl http://localhost:8082/actuator/env
```

---

## 3. Quick Server Monitoring Commands

```bash
# CPU and RAM
htop

# Disk usage
df -h

# Docker container resources
docker stats

# Who's using the most CPU
ps aux --sort=-%cpu | head -10

# Check for OOM (Out of Memory) kills
dmesg | grep -i "oom"

# PostgreSQL connections
psql -c "SELECT count(*) FROM pg_stat_activity;"

# Nginx active connections
curl http://localhost/nginx_status
```

---

## 4. Log Locations

```bash
# Nginx logs
/var/log/nginx/access.log     # All requests
/var/log/nginx/error.log      # Errors only

# Docker container logs
docker logs <container-name>
docker logs --tail 100 -f <container-name>

# System logs
journalctl -u nginx --since "1 hour ago"
journalctl -u docker --since today

# PostgreSQL logs
/var/log/postgresql/postgresql-*.log
```

---

## 5. Setting Up Prometheus + Grafana (Advanced)

```yaml
# Add to docker-compose.yml:
prometheus:
  image: prom/prometheus
  ports:
    - "9090:9090"
  volumes:
    - ./prometheus.yml:/etc/prometheus/prometheus.yml

grafana:
  image: grafana/grafana
  ports:
    - "3000:3000"
  environment:
    - GF_SECURITY_ADMIN_PASSWORD=your_password
```

```yaml
# prometheus.yml
scrape_configs:
  - job_name: 'spring-boot'
    metrics_path: '/actuator/prometheus'
    static_configs:
      - targets: ['backend:8080']
```

This gives you dashboards for CPU, memory, request rates, error rates, etc.

---

## Key Takeaways

1. **Actuator** gives you health and metrics out of the box
2. **`docker stats`** for quick container monitoring
3. **Check logs** when things break (Nginx, Docker, system)
4. **Prometheus + Grafana** for production dashboards
5. **Monitor disk space** - logs and uploads fill up fast

---

## Next: [11 - Scaling Strategies](./11-scaling-strategies.md)
