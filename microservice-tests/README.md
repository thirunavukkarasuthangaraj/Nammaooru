# Microservice Pattern Tests

Test each of the 9 microservice patterns implemented on the Login API.

## Prerequisites
- User-service running at: https://user-api.nammaoorudelivary.in
- Monolith running at: https://api.nammaoorudelivary.in
- Test user: thirunacse75@gmail.com / Test@123

## Test Files
| File | Pattern | What it Tests |
|------|---------|---------------|
| 01-bulkhead.sh | Bulkhead | Max 10 concurrent calls |
| 02-rate-limiter.sh | Rate Limiter | Max 50 calls per second |
| 03-caching.sh | Caching | Caffeine cache 5min TTL |
| 04-api-key.sh | API Key Security | X-API-Key validation |
| 05-correlation-id.sh | Correlation ID | UUID tracing across services |
| 06-health-check.sh | Health Indicator | User-service UP/DOWN in actuator |
| 07-interceptor.sh | RestTemplate Interceptor | Centralized header injection |
| 08-login-events.sh | Login Event Publishing | AUDIT logs |
| 09-service-name.sh | Service Name Header | X-Service-Name identity |

## How to Run
```bash
# Run individual test
bash 04-api-key.sh

# Run all tests
bash run-all-tests.sh
```
