# Load Test Scripts for YourApp

## Setup
1. Install k6: https://k6.io/docs/get-started/installation/
2. Update `config.js` with your server details and JWT token
3. Run tests from this folder

## Scripts

| Script | Purpose | Command |
|--------|---------|---------|
| `config.js` | Shared configuration | (imported by other scripts) |
| `01-health-check.js` | Basic server health test | `k6 run 01-health-check.js` |
| `02-api-load-test.js` | Multiple API endpoint test | `k6 run 02-api-load-test.js` |
| `03-stress-test.js` | Find server breaking point | `k6 run 03-stress-test.js` |
| `04-spike-test.js` | Sudden traffic spike simulation | `k6 run 04-spike-test.js` |
| `05-soak-test.js` | Long-running stability test | `k6 run 05-soak-test.js` |
| `06-websocket-test.js` | Real-time WebSocket test | `k6 run 06-websocket-test.js` |
| `07-real-user-simulation.js` | Simulate real user journey | `k6 run 07-real-user-simulation.js` |
| `08-concurrent-api-test.sh` | Multiple API calls with curl | `bash 08-concurrent-api-test.sh` |
| `09-load-balancer-test.sh` | Test load balancer distribution | `bash 09-load-balancer-test.sh` |
| `10-full-scenario-test.js` | Complete production simulation | `k6 run 10-full-scenario-test.js` |

## Quick Start
```bash
# 1. Edit config.js with your details
# 2. Run basic test
k6 run 01-health-check.js

# 3. Run all tests
bash run-all-tests.sh
```
