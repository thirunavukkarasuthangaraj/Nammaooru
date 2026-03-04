# 13 - Database Administration

## What You'll Learn
- PostgreSQL basics for your YourApp app
- Connection pooling (HikariCP)
- Query optimization
- Monitoring database performance

---

## 1. Your Database Setup

```
Database: PostgreSQL (running on host, not Docker)
Name: shop_management_db
Port: 5432
Connection: host.docker.internal:5432 (from Docker)
Migrations: Flyway (db/migration/2025/, db/migration/2026/)
Connection Pool: HikariCP (Spring Boot default)
```

---

## 2. Essential PostgreSQL Commands

```bash
# Connect to database
psql -U postgres -d shop_management_db

# List all tables
\dt

# Describe a table
\d+ shops

# Check database size
SELECT pg_size_pretty(pg_database_size('shop_management_db'));

# Check table sizes
SELECT tablename, pg_size_pretty(pg_total_relation_size(tablename::text))
FROM pg_tables WHERE schemaname = 'public'
ORDER BY pg_total_relation_size(tablename::text) DESC;

# Active connections
SELECT count(*) FROM pg_stat_activity;

# Slow queries (currently running)
SELECT pid, now() - pg_stat_activity.query_start AS duration, query
FROM pg_stat_activity
WHERE state != 'idle'
ORDER BY duration DESC;

# Kill a slow query
SELECT pg_terminate_backend(pid);
```

---

## 3. Connection Pooling

```yaml
# application.yml
spring:
  datasource:
    hikari:
      maximum-pool-size: 20      # Max 20 connections to DB
      minimum-idle: 5            # Keep 5 idle connections ready
      connection-timeout: 30000  # Wait 30s for a connection
      idle-timeout: 600000       # Close idle after 10 minutes
      max-lifetime: 1800000      # Recycle connections after 30 min
```

```
Why pooling matters:
  Without pool: Each request opens new DB connection (slow, ~50ms)
  With pool: Connections reused from pool (fast, ~1ms)

  20 pool size = can handle ~20 concurrent DB queries
  If 21st query comes in, it waits up to 30 seconds
```

---

## 4. Query Optimization

```sql
-- Find slow queries
SELECT query, calls, mean_exec_time, total_exec_time
FROM pg_stat_statements
ORDER BY mean_exec_time DESC
LIMIT 10;

-- Analyze a specific query
EXPLAIN ANALYZE SELECT * FROM orders WHERE shop_id = 5 AND status = 'PENDING';

-- Add missing indexes
CREATE INDEX idx_orders_shop_status ON orders(shop_id, status);

-- Check existing indexes
SELECT indexname, tablename FROM pg_indexes
WHERE schemaname = 'public'
ORDER BY tablename;
```

---

## 5. Database Security

```sql
-- Don't use superuser for app! Create dedicated user:
CREATE USER yourapp_app WITH PASSWORD 'strong_password';
GRANT CONNECT ON DATABASE shop_management_db TO yourapp_app;
GRANT SELECT, INSERT, UPDATE, DELETE ON ALL TABLES IN SCHEMA public TO yourapp_app;

-- PostgreSQL should listen on localhost only:
-- In /etc/postgresql/*/main/postgresql.conf:
listen_addresses = 'localhost'    -- NOT '*'
```

---

## Key Takeaways

1. **Connection pooling** (HikariCP) is critical for performance
2. **Add indexes** on columns used in WHERE clauses
3. **Monitor slow queries** with pg_stat_statements
4. **PostgreSQL on localhost only** - never expose to internet
5. **Use dedicated DB user** - don't use postgres superuser for the app

---

## This completes the theory files! Now see the practical files:
- [14 - Load Testing (Hands-On)](./14-load-testing-practical.md)
- [15 - Architecture Diagram](./15-architecture-diagram.md)
