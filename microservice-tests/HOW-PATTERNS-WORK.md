# How All 9 Microservice Patterns Work — Learning Guide

## The Big Picture

When you call login API, here's what happens:

```
User (browser/mobile)
  │
  ▼
Monolith (65.21.4.236)
  │
  │  ① Correlation ID Filter → generates UUID "abc-123"
  │  ② Rate Limiter → checks: less than 50 calls this second? YES → continue
  │  ③ Bulkhead → checks: less than 10 concurrent calls? YES → continue
  │  ④ Circuit Breaker → checks: is circuit CLOSED? YES → continue
  │  ⑤ Retry → wraps the call (will retry if connection fails)
  │  ⑥ RestTemplate Interceptor → adds headers:
  │       X-API-Key: nammaooru-internal-secret-2024
  │       X-Correlation-ID: abc-123
  │       X-Service-Name: shop-management-monolith
  │  ⑦ Caching → checks: is this user cached? NO → make the call
  │
  ▼
User-Service (46.225.224.191)
  │
  │  ⑧ Correlation ID Filter → reads "abc-123", puts in logs
  │  ⑨ API Key Filter → checks X-API-Key header → valid!
  │  ⑩ Service Name → reads "shop-management-monolith", puts in logs
  │
  │  Processes login → returns success
  │
  ▼
Back to Monolith
  │
  │  ⑪ Caching → stores user data for 5 minutes
  │  ⑫ Login Event → publishes SUCCESS event
  │  ⑬ Event Listener → logs [AUDIT] Login SUCCESS
  │
  ▼
Response sent to User
```

---

## Pattern 1: Bulkhead

### What is it?
A bulkhead is like compartments in a ship. If one compartment floods, others stay dry.

### Real-world example:
Imagine a restaurant with 10 tables. If 10 customers come, all get seated. If 11th comes, they wait or leave. The kitchen doesn't get overwhelmed.

### How it works in our code:

```
Login Request #1  → ✅ enters bulkhead (1/10 slots used)
Login Request #2  → ✅ enters bulkhead (2/10 slots used)
Login Request #3  → ✅ enters bulkhead (3/10 slots used)
...
Login Request #10 → ✅ enters bulkhead (10/10 slots used)
Login Request #11 → ❌ REJECTED! "Bulkhead full" (waits 500ms, then fails)
```

### Code location:
```java
// AuthService.java
@Bulkhead(name = "userServiceLogin")  // ← this annotation
public AuthResponse authenticateViaMicroservice(...)
```

### Config:
```yaml
# application.yml
resilience4j:
  bulkhead:
    instances:
      userServiceLogin:
        max-concurrent-calls: 10    # only 10 at same time
        max-wait-duration: 500ms    # wait 500ms if full, then reject
```

### Why do we need it?
Without bulkhead, if 1000 users login at same time, all 1000 calls hit user-service. User-service crashes. With bulkhead, only 10 go through. Others wait or get error. User-service stays alive.

---

## Pattern 2: Rate Limiter

### What is it?
Limits how many requests per second. Like a speed limit on a road.

### Real-world example:
ATM machine: max 3 withdrawals per day. Even if you try 10 times, after 3rd it says "limit exceeded".

### How it works:

```
Second 1:
  Request #1  → ✅ (1/50)
  Request #2  → ✅ (2/50)
  ...
  Request #50 → ✅ (50/50)
  Request #51 → ❌ "Rate limit exceeded"

Second 2: (counter resets)
  Request #1  → ✅ (1/50) fresh start
```

### Code location:
```java
// AuthService.java
@RateLimiter(name = "userServiceLogin")  // ← this annotation
public AuthResponse authenticateViaMicroservice(...)
```

### Config:
```yaml
resilience4j:
  ratelimiter:
    instances:
      userServiceLogin:
        limit-for-period: 50       # max 50 calls
        limit-refresh-period: 1s   # per 1 second
        timeout-duration: 0s       # don't wait, reject immediately
```

### Why do we need it?
Hackers try brute-force: try 10000 passwords per second. Rate limiter blocks after 50 attempts. Your system is safe.

### Difference from Bulkhead:
- **Bulkhead** = limits CONCURRENT (at the same time)
- **Rate Limiter** = limits PER SECOND (total in a time window)

---

## Pattern 3: Caching

### What is it?
Store the result in memory. Don't call user-service again for same data.

### Real-world example:
You call your friend for their address. You write it on a paper. Next time you need it, you look at the paper instead of calling again.

### How it works:

```
1st Login (user: thiru):
  → Check cache: "thiru" not in cache
  → Call user-service → get user data
  → Store in cache: "thiru" = {id:1, role:USER, ...}
  → Return response (SLOW: 2.6 seconds)

2nd Login (user: thiru, within 5 minutes):
  → Check cache: "thiru" FOUND in cache!
  → Skip user-service call
  → Return response (FAST: 1.2 seconds)

After 5 minutes:
  → Cache expired, removed
  → Next login calls user-service again
```

### Code location:
```java
// MicroserviceUserDetailsService.java
@Cacheable(value = "microservice-users", key = "#username")  // ← cache it
public UserDetails loadUserByUsername(String username) {
    // This code only runs if NOT in cache
    log.info("Loading user from user-service (not cached)");
    ...
}
```

### Config:
```java
// CacheConfig.java
Caffeine.newBuilder()
    .expireAfterWrite(5, TimeUnit.MINUTES)  // cache for 5 min
    .maximumSize(1000)                       // max 1000 users cached
```

### Why do we need it?
- Faster response (no network call)
- Less load on user-service
- Works even if user-service is briefly slow

---

## Pattern 4: API Key Security

### What is it?
A secret password between monolith and user-service. Only services with the key can call internal endpoints.

### Real-world example:
Office building. Reception asks for your company ID card. No card = no entry. Visitors can still use the public entrance.

### How it works:

```
Without API Key:
  curl /internal/users/1
  → ApiKeyFilter checks: X-API-Key header? NO
  → 401 Unauthorized ❌

With Wrong Key:
  curl -H "X-API-Key: wrong" /internal/users/1
  → ApiKeyFilter checks: "wrong" == "nammaooru-internal-secret-2024"? NO
  → 401 Unauthorized ❌

With Correct Key:
  curl -H "X-API-Key: nammaooru-internal-secret-2024" /internal/users/1
  → ApiKeyFilter checks: matches! YES
  → 200 OK ✅

Public Endpoints (not /internal/**):
  curl /actuator/health
  → ApiKeyFilter: path doesn't start with /internal → skip check
  → 200 OK ✅ (no key needed)
```

### Code location:

**Monolith sends key (automatically via interceptor):**
```java
// MicroserviceRequestInterceptor.java
request.getHeaders().set("X-API-Key", apiKey);
```

**User-service validates key:**
```java
// ApiKeyFilter.java (user-service)
if (path.startsWith("/internal")) {
    String providedKey = request.getHeader("X-API-Key");
    if (!providedKey.equals(internalApiKey)) {
        response.setStatus(401); // Unauthorized
        return;
    }
}
```

### Why do we need it?
Without API key, anyone who finds the user-service IP can call `/internal/users/1` and get user data. With API key, only the monolith (who knows the secret) can call it.

---

## Pattern 5: Correlation ID (Distributed Tracing)

### What is it?
A unique ID (UUID) that follows a request across all services. Like a tracking number for a package.

### Real-world example:
You order a package on Amazon. Tracking number: ABC123. You can see it at warehouse → truck → delivery. One number, full journey.

### How it works:

```
User sends login request
  │
  ▼
Monolith CorrelationIdFilter:
  → No X-Correlation-ID header? Generate: "a3cc86bc-fa78-..."
  → Put in MDC (logging context)
  → All logs now include: [a3cc86bc-fa78-...]
  │
  ▼
RestTemplate Interceptor:
  → Reads "a3cc86bc-fa78-..." from MDC
  → Adds header: X-Correlation-ID: a3cc86bc-fa78-...
  │
  ▼
User-Service CorrelationIdFilter:
  → Reads X-Correlation-ID: "a3cc86bc-fa78-..."
  → Put in MDC
  → All logs now include: [a3cc86bc-fa78-...]
```

### What you see in logs:

**Monolith log:**
```
18:06:10 [main] [a3cc86bc-fa78-...] INFO AuthService - Calling user-service login
```

**User-service log:**
```
18:06:10 [main] [a3cc86bc-fa78-...] INFO AuthService - Login successful
```

Same ID in both! You can search one ID and find the full journey.

### Code location:
```java
// CorrelationIdFilter.java (monolith)
String correlationId = UUID.randomUUID().toString();
MDC.put("correlationId", correlationId);  // for logging
response.setHeader("X-Correlation-ID", correlationId);  // for response
```

### Why do we need it?
When something fails, you search the correlation ID in both server logs. You see the exact path the request took. Without it, finding related logs across servers is impossible.

---

## Pattern 6: Custom Health Indicator

### What is it?
Monolith's /actuator/health shows if user-service is alive or dead.

### Real-world example:
Hospital monitor shows heartbeat. Green = patient alive. Red = alert! Nurse comes running.

### How it works:

```
Every 30 seconds (automatic):
  Monolith → pings → user-service /actuator/health
  → Response 200? → userServiceUp = true
  → No response?  → userServiceUp = false

When you call /actuator/health:
  → Returns: {
      "status": "UP",
      "components": {
        "userService": {
          "status": "UP",      ← or "DOWN"
          "url": "http://46.225.224.191:8081"
        }
      }
    }
```

### Code location:
```java
// UserServiceHealthIndicator.java
@Scheduled(fixedRate = 30000)  // every 30 seconds
public void checkUserServiceHealth() {
    try {
        restTemplate.getForEntity(url + "/actuator/health", String.class);
        userServiceUp = true;   // ✅ alive
    } catch (Exception e) {
        userServiceUp = false;  // ❌ dead
    }
}
```

### Why do we need it?
Monitoring tools (Prometheus, Grafana) check /actuator/health. If user-service goes DOWN, you get an alert. You fix it before users notice.

---

## Pattern 7: RestTemplate Interceptor

### What is it?
One central place that adds headers to EVERY call from monolith to user-service. Also logs every call with duration.

### Real-world example:
Airport security checkpoint. Everyone goes through it. Passport checked, bag scanned, boarding pass verified. One checkpoint, all passengers.

### How it works:

```
AuthService calls: restTemplate.postForEntity(url, request, Map.class)
  │
  ▼
Interceptor automatically runs BEFORE the call:
  1. Adds: X-API-Key: nammaooru-internal-secret-2024
  2. Adds: X-Correlation-ID: abc-123 (from MDC)
  3. Adds: X-Service-Name: shop-management-monolith
  4. Logs: [Interceptor] POST https://user-api... | API-Key=present
  5. Starts timer
  │
  ▼
Actual HTTP call happens
  │
  ▼
Interceptor runs AFTER the call:
  6. Stops timer
  7. Logs: [Interceptor] POST https://user-api... → 200 | 150ms
```

### Before vs After:

**Before (old code — headers added manually):**
```java
RestTemplate restTemplate = new RestTemplate();  // new one every time!
// No headers, no logging, no timeouts
restTemplate.postForEntity(url, request, Map.class);
```

**After (new code — interceptor handles everything):**
```java
// Just use the injected restTemplate. Headers added automatically!
restTemplate.postForEntity(url, request, Map.class);
```

### Code location:
```java
// MicroserviceRequestInterceptor.java
public ClientHttpResponse intercept(HttpRequest request, byte[] body,
                                     ClientHttpRequestExecution execution) {
    // Add all headers
    request.getHeaders().set("X-API-Key", apiKey);
    request.getHeaders().set("X-Correlation-ID", correlationId);
    request.getHeaders().set("X-Service-Name", "shop-management-monolith");

    // Log and measure
    long startTime = System.currentTimeMillis();
    ClientHttpResponse response = execution.execute(request, body);
    long duration = System.currentTimeMillis() - startTime;
    log.info("[Interceptor] {} {} → {} | {}ms", method, url, status, duration);

    return response;
}
```

### Why do we need it?
Without it, every method that calls user-service must add headers manually. 10 methods = 10 places to add headers. Miss one? Bug. With interceptor, add once, works everywhere.

---

## Pattern 8: Login Event Publishing

### What is it?
Every login (success/failure/fallback) publishes a Spring Event. A listener logs it as audit trail.

### Real-world example:
CCTV camera at office door. Records everyone who enters. Security guard watches the recordings. You can see: "John entered at 9am", "Unknown person tried at 2am — FAILED".

### How it works:

```
Login SUCCESS:
  AuthService → eventPublisher.publishEvent(LoginEvent.SUCCESS)
  → LoginEventListener catches it
  → Logs: [AUDIT] Login SUCCESS | user=thiru@gmail.com | source=microservice

Login FAILURE (wrong password):
  AuthService → eventPublisher.publishEvent(LoginEvent.FAILURE)
  → LoginEventListener catches it
  → Logs: [AUDIT] Login FAILURE | user=thiru@gmail.com | source=microservice | error=Client error: 401

Login FALLBACK (user-service down, used local DB):
  AuthService → eventPublisher.publishEvent(LoginEvent.FALLBACK)
  → LoginEventListener catches it
  → Logs: [AUDIT] Login FALLBACK | user=thiru@gmail.com | source=local-db
```

### Code location:

**Publishing (AuthService.java):**
```java
// On success:
eventPublisher.publishEvent(
    new LoginEvent(this, identifier, LoginEvent.Result.SUCCESS, "microservice", null));

// On failure:
eventPublisher.publishEvent(
    new LoginEvent(this, identifier, LoginEvent.Result.FAILURE, "microservice", "error msg"));
```

**Listening (LoginEventListener.java):**
```java
@EventListener
public void handleLoginEvent(LoginEvent event) {
    switch (event.getResult()) {
        case SUCCESS  → log.info("[AUDIT] Login SUCCESS | user={} | source={}", ...);
        case FAILURE  → log.warn("[AUDIT] Login FAILURE | user={} | source={} | error={}", ...);
        case FALLBACK → log.info("[AUDIT] Login FALLBACK | user={} | source={}", ...);
    }
}
```

### Why do we need it?
- **Audit trail**: who logged in, when, from where
- **Security**: detect failed login attempts (brute force)
- **Decoupled**: AuthService doesn't know about logging. Just publishes event. Listener handles it.
- **Extensible**: later you can add more listeners — send to Kafka, send email alert, etc.

---

## Pattern 9: Service Name Header

### What is it?
Monolith tells user-service "I am shop-management-monolith" in every request.

### Real-world example:
Phone caller ID. When someone calls, you see their name. You know WHO is calling before answering.

### How it works:

```
Monolith sends:
  Header: X-Service-Name: shop-management-monolith

User-service receives:
  CorrelationIdFilter reads: X-Service-Name = "shop-management-monolith"
  Puts in MDC: callingService = "shop-management-monolith"

User-service logs:
  [a3cc86bc] [shop-management-monolith] INFO - Processing login request
```

### Why do we need it?
When you have 5 microservices calling user-service:
```
shop-management-monolith → user-service
order-service            → user-service
payment-service          → user-service
notification-service     → user-service
```
Without service name, you see logs but don't know WHO called. With service name, every log shows the caller.

---

## Order of Execution (Complete Flow)

When `POST /api/auth/login` is called:

```
1. CorrelationIdFilter     → Generate UUID, put in MDC
2. AuthService.authenticate() → Check if microservice mode ON
3. @RateLimiter            → Under 50/sec? Continue. Over? REJECT.
4. @Bulkhead               → Under 10 concurrent? Continue. Over? REJECT.
5. @CircuitBreaker         → Circuit CLOSED? Continue. OPEN? → Fallback.
6. @Retry                  → Try the call. If fails, retry up to 3 times.
7. RestTemplate.post()     → Interceptor adds headers, logs, makes HTTP call
8. User-service processes  → API Key check → login → return response
9. @Cacheable              → Store user data in Caffeine cache (5 min)
10. LoginEvent published   → [AUDIT] logged
11. Response returned       → With X-Correlation-ID header
```

---

## Summary Table

| # | Pattern | Protects Against | Where |
|---|---------|-----------------|-------|
| 1 | Bulkhead | Traffic spike (too many at once) | Monolith |
| 2 | Rate Limiter | Brute force (too many per second) | Monolith |
| 3 | Caching | Slow response, unnecessary calls | Monolith |
| 4 | API Key | Unauthorized access to internal APIs | Both |
| 5 | Correlation ID | Can't trace request across services | Both |
| 6 | Health Check | Don't know if dependency is down | Monolith |
| 7 | Interceptor | Duplicate code, missing headers | Monolith |
| 8 | Login Events | No audit trail, tight coupling | Monolith |
| 9 | Service Name | Don't know who's calling your API | Both |
