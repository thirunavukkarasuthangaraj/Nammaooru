# 🚀 NEVER WASTE TIME - QUICK DEPLOYMENT GUIDE

## ⚡ ONE-COMMAND DEPLOYMENT (30 seconds)

### On your server, just run:
```bash
cd /opt/shop-management
./NEVER_WASTE_TIME_DEPLOY.sh
```

That's it! The script does EVERYTHING automatically.

---

## 📋 COMMON SCENARIOS

### 1️⃣ **Regular Deployment (After Code Changes)**
```bash
cd /opt/shop-management
git pull origin main
docker-compose restart backend frontend
```

### 2️⃣ **Quick Restart (No Code Changes)**
```bash
cd /opt/shop-management
docker-compose restart
```

### 3️⃣ **Check Status**
```bash
docker ps
curl http://localhost:8082/actuator/health
```

### 4️⃣ **View Logs**
```bash
docker-compose logs -f backend    # Backend logs
docker-compose logs -f frontend   # Frontend logs
docker-compose logs -f            # All logs
```

### 5️⃣ **Emergency Fix**
```bash
cd /opt/shop-management
docker-compose down
docker-compose up -d
```

---

## 🔥 TROUBLESHOOTING (5-second fixes)

### Backend Not Starting?
```bash
docker-compose restart backend
```

### Database Connection Error?
```bash
docker-compose restart postgres
sleep 10
docker-compose restart backend
```

### Frontend Not Loading?
```bash
docker-compose restart frontend
```

### Port Already in Use?
```bash
# Kill process using port 8082
kill -9 $(lsof -t -i:8082)
# Kill process using port 8080
kill -9 $(lsof -t -i:8080)
# Restart
docker-compose up -d
```

### Complete Reset (Nuclear Option)?
```bash
docker-compose down -v
./NEVER_WASTE_TIME_DEPLOY.sh
```

---

## 🎯 DEPLOYMENT CHECKLIST

Before deploying, make sure:
- [ ] Code is pushed to GitHub from local
- [ ] You're in `/opt/shop-management` directory
- [ ] You have the `.env` file

After deploying, verify:
- [ ] All containers running: `docker ps`
- [ ] Backend healthy: `curl http://localhost:8082/actuator/health`
- [ ] Can login at https://nammaoorudelivary.in

---

## 📌 IMPORTANT PATHS & PORTS

| Service | Port | Path | Check Command |
|---------|------|------|---------------|
| Frontend | 8080 | /opt/shop-management/frontend | `curl http://localhost:8080` |
| Backend | 8082 | /opt/shop-management/backend | `curl http://localhost:8082/actuator/health` |
| PostgreSQL | 5432 | Docker volume | `docker exec shop-postgres pg_isready` |
| Redis | 6379 | Docker volume | `docker exec shop-redis redis-cli ping` |

---

## 🔑 DEFAULT CREDENTIALS

| Username | Password | Role |
|----------|----------|------|
| superadmin | password | SUPER_ADMIN |
| admin | password | ADMIN |
| testuser | password | SUPER_ADMIN |

---

## 📱 MOBILE APP DEPLOYMENT

Update API URL in mobile app:
```dart
// File: mobile/nammaooru_mobile_app/lib/core/constants/app_constants.dart
static const String baseUrl = 'https://api.nammaoorudelivary.in';
```

Then rebuild APK:
```bash
cd mobile/nammaooru_mobile_app
flutter build apk --release
```

---

## 🎉 THAT'S IT!

**From now on, deployment = 30 seconds, not 3 hours!**

Just run: `./NEVER_WASTE_TIME_DEPLOY.sh`