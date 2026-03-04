# Microservice Patterns — Manual Test Guide

## Test User
- Email: thirunacse75@gmail.com
- Password: Test@123

## Monolith: https://api.nammaoorudelivary.in
## User-Service: https://user-api.nammaoorudelivary.in

---

## Pattern 1: Bulkhead (Max 10 concurrent calls)

**What:** Only 10 login calls can run at the same time. 11th call gets rejected.

**Check it's registered:**
```bash
curl https://api.nammaoorudelivary.in/actuator/bulkheads
```
**Expected:** `{"bulkheads":["userServiceLogin"]}`

**How it works:** If 10 people login at exact same time, 11th person gets "Bulkhead full" error. Protects user-service from overload.

---

## Pattern 2: Rate Limiter (Max 50 calls per second)

**What:** Only 50 login calls per second allowed. Prevents brute force attacks.

**Check it's registered:**
```bash
curl https://api.nammaoorudelivary.in/actuator/ratelimiters
```
**Expected:** `{"rateLimiters":["userServiceLogin"]}`

**How it works:** If someone tries 60 logins in 1 second, first 50 work, last 10 get "Rate limit exceeded".

---

## Pattern 3: Caching (5 minute cache)

**What:** After first login, user data is cached for 5 minutes. Second login is faster.

**Test — Login twice, compare speed:**
```bash
# First login (slow — calls user-service over network)
curl -w "\nTime: %{time_total}s\n" -X POST https://api.nammaoorudelivary.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"thirunacse75@gmail.com","password":"Test@123"}'

# Second login (fast — uses cache, no network call)
curl -w "\nTime: %{time_total}s\n" -X POST https://api.nammaoorudelivary.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"thirunacse75@gmail.com","password":"Test@123"}'
```
**Expected:** Second login is 2-3x faster than first.

---

## Pattern 4: API Key Security

**What:** User-service /internal/** endpoints are protected by API key. Without key = 401.

**Test 1 — Without API key (should fail):**
```bash
curl https://user-api.nammaoorudelivary.in/internal/users/1
```
**Expected:** `{"error":"Unauthorized","message":"Invalid or missing API key"}`

**Test 2 — With wrong API key (should fail):**
```bash
curl -H "X-API-Key: wrong-key" https://user-api.nammaoorudelivary.in/internal/users/1
```
**Expected:** `{"error":"Unauthorized","message":"Invalid or missing API key"}`

**Test 3 — With correct API key (should work):**
```bash
curl -H "X-API-Key: nammaooru-internal-secret-2024" https://user-api.nammaoorudelivary.in/internal/users/1
```
**Expected:** Returns user data (HTTP 200)

**Test 4 — Public endpoints work without key:**
```bash
curl https://user-api.nammaoorudelivary.in/actuator/health
```
**Expected:** `{"status":"UP"}` — no API key needed for non-internal endpoints.

---

## Pattern 5: Correlation ID (Distributed Tracing)

**What:** Every request gets a unique UUID. Same UUID appears in both monolith and user-service logs.

**Test 1 — Auto-generated ID:**
```bash
curl -v https://user-api.nammaoorudelivary.in/actuator/health 2>&1 | grep -i "X-Correlation-ID"
```
**Expected:** `X-Correlation-ID: some-uuid-here`

**Test 2 — Pass your own ID:**
```bash
curl -v -H "X-Correlation-ID: my-test-trace-123" https://user-api.nammaoorudelivary.in/actuator/health 2>&1 | grep -i "X-Correlation-ID"
```
**Expected:** `X-Correlation-ID: my-test-trace-123` (same ID returned)

**Test 3 — Login and trace across both servers:**
```bash
curl -v -X POST https://api.nammaoorudelivary.in/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Correlation-ID: trace-login-test-001" \
  -d '{"email":"thirunacse75@gmail.com","password":"Test@123"}' 2>&1 | grep -i "X-Correlation-ID"
```
Then check both server logs:
```bash
# Monolith logs
docker logs shop-management --tail 30 | grep "trace-login-test-001"

# User-service logs
docker logs user-service --tail 30 | grep "trace-login-test-001"
```
**Expected:** Same `trace-login-test-001` appears in both logs.

---

## Pattern 6: Custom Health Indicator

**What:** Monolith /actuator/health shows if user-service is UP or DOWN.

**Test — Check health:**
```bash
curl https://api.nammaoorudelivary.in/actuator/health
```
**Expected:** `{"status":"UP"}` (includes userService component when microservice mode enabled)

**Test — Stop user-service, then check health again:**
```bash
# On user-service server (46.225.224.191):
docker stop user-service

# Wait 30 seconds, then check monolith health:
curl https://api.nammaoorudelivary.in/actuator/health

# Start user-service again:
docker start user-service
```
**Expected:** Health shows DOWN when user-service is stopped.

---

## Pattern 7: RestTemplate Interceptor

**What:** Every call from monolith to user-service automatically adds: API Key, Correlation ID, Service Name headers. Also logs duration.

**Test — Login and check monolith logs:**
```bash
curl -X POST https://api.nammaoorudelivary.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"thirunacse75@gmail.com","password":"Test@123"}'
```
Then check monolith logs:
```bash
docker logs shop-management --tail 20 | grep "Interceptor"
```
**Expected:**
```
[Interceptor] POST https://user-api... | headers: API-Key=present, Correlation-ID=xxx, Service=shop-management-monolith
[Interceptor] POST https://user-api... → 200 OK | 150ms
```

---

## Pattern 8: Login Event Publishing

**What:** Every login publishes an event. Listener logs audit trail.

**Test — Login and check monolith logs:**
```bash
curl -X POST https://api.nammaoorudelivary.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"thirunacse75@gmail.com","password":"Test@123"}'
```
Then check logs:
```bash
docker logs shop-management --tail 20 | grep "AUDIT"
```
**Expected:** `[AUDIT] Login SUCCESS | user=thirunacse75@gmail.com | source=microservice`

**Test — Wrong password:**
```bash
curl -X POST https://api.nammaoorudelivary.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"thirunacse75@gmail.com","password":"WrongPass"}'
```
Check logs:
```bash
docker logs shop-management --tail 20 | grep "AUDIT"
```
**Expected:** `[AUDIT] Login FAILURE | user=thirunacse75@gmail.com | source=microservice | error=...`

---

## Pattern 9: Service Name Header

**What:** Monolith sends X-Service-Name header. User-service logs which service called it.

**Test — Login and check user-service logs:**
```bash
curl -X POST https://api.nammaoorudelivary.in/api/auth/login \
  -H "Content-Type: application/json" \
  -d '{"email":"thirunacse75@gmail.com","password":"Test@123"}'
```
Then check user-service logs:
```bash
docker logs user-service --tail 20
```
**Expected:** Log lines show `[shop-management-monolith]` identifying the calling service.

---

## Quick Test — All Patterns at Once

One login call triggers patterns 1, 2, 3, 5, 7, 8, 9:
```bash
curl -v -X POST https://api.nammaoorudelivary.in/api/auth/login \
  -H "Content-Type: application/json" \
  -H "X-Correlation-ID: test-all-patterns-001" \
  -d '{"email":"thirunacse75@gmail.com","password":"Test@123"}'
```

Then check:
```bash
# Monolith logs — Pattern 7 (Interceptor) + Pattern 8 (Audit)
docker logs shop-management --tail 30 | grep -E "Interceptor|AUDIT|test-all-patterns"

# User-service logs — Pattern 5 (Correlation ID) + Pattern 9 (Service Name)
docker logs user-service --tail 30 | grep "test-all-patterns"
```

---

## Already Existing Patterns (before this update)

| Pattern | What | How to Test |
|---------|------|-------------|
| Feature Flag | Toggle local DB vs user-service | Set `MICROSERVICE_USER_ENABLED=true/false` in .env |
| Circuit Breaker | Opens after 50% failures | Stop user-service → login fails → circuit opens → fallback to local DB |
| Retry | 3 attempts on connection errors | Briefly stop user-service → monolith retries 3 times |
| Timeout | 5s per call | Slow user-service → monolith times out after 5s |
| Fallback | Local DB when circuit OPEN | Circuit opens → login uses local DB automatically |

---

## Environment Variables

**Monolith (.env):**
```
MICROSERVICE_USER_ENABLED=true
MICROSERVICE_API_KEY=nammaooru-internal-secret-2024
```

**User-service (.env):**
```
INTERNAL_API_KEY=nammaooru-internal-secret-2024
```

Both API keys must match!
