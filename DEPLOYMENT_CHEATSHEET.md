# 🚀 DEPLOYMENT CHEAT SHEET - NEVER WASTE TIME AGAIN!

## 🔥 FASTEST COMMANDS (Copy & Paste)

### From Your Local Machine (Windows)
```bash
# Push code to GitHub
cd D:\AAWS\nammaooru\shop-management-system
git add .
git commit -m "Update"
git push origin main
```

### On Server (65.21.4.236)
```bash
# SSH to server
ssh root@65.21.4.236

# Go to project
cd /opt/shop-management

# OPTION 1: Full deployment (30 seconds)
./NEVER_WASTE_TIME_DEPLOY.sh

# OPTION 2: Quick restart (10 seconds)
./deploy-in-10-seconds.sh

# OPTION 3: Interactive menu
./ULTRA_FAST_DEPLOY.sh
```

---

## ⚡ ONE-LINERS FOR COMMON TASKS

```bash
# Full deployment from SSH
ssh root@65.21.4.236 "cd /opt/shop-management && ./NEVER_WASTE_TIME_DEPLOY.sh"

# Quick restart from SSH
ssh root@65.21.4.236 "cd /opt/shop-management && docker-compose restart"

# Check status from SSH
ssh root@65.21.4.236 "docker ps --format 'table {{.Names}}\t{{.Status}}'"

# View backend logs from SSH
ssh root@65.21.4.236 "cd /opt/shop-management && docker-compose logs --tail=50 backend"
```

---

## 🔧 QUICK FIXES (5 seconds each)

### Backend not working?
```bash
docker-compose restart backend
```

### Frontend not loading?
```bash
docker-compose restart frontend
```

### Database issues?
```bash
docker-compose restart postgres
sleep 10
docker-compose restart backend
```

### CORS errors?
```bash
systemctl reload nginx
```

### Everything broken?
```bash
cd /opt/shop-management
./NEVER_WASTE_TIME_DEPLOY.sh
```

---

## 📊 QUICK STATUS CHECKS

```bash
# All services status
docker ps

# Backend health
curl http://localhost:8082/actuator/health

# Frontend status
curl -I http://localhost:8080

# Database status
docker exec shop-postgres pg_isready

# Redis status
docker exec shop-redis redis-cli ping
```

---

## 🔑 ACCESS URLS

- **Production**: https://nammaoorudelivary.in
- **API**: https://api.nammaoorudelivary.in
- **Backend Health**: http://65.21.4.236:8082/actuator/health
- **Frontend Direct**: http://65.21.4.236:8080

**Login**: superadmin / password

---

## 📁 IMPORTANT PATHS

- **Server Project**: `/opt/shop-management`
- **Local Project**: `D:\AAWS\nammaooru\shop-management-system`
- **Mobile App**: `D:\AAWS\nammaooru\shop-management-system\mobile\nammaooru_mobile_app`

---

## 🚨 EMERGENCY CONTACTS

If deployment fails:
1. Check logs: `docker-compose logs`
2. Run: `./NEVER_WASTE_TIME_DEPLOY.sh`
3. If still broken: `docker-compose down -v && ./NEVER_WASTE_TIME_DEPLOY.sh`

---

## ⏱️ TIME SAVED

- **Old way**: 3 hours 😫
- **New way**: 30 seconds 🚀
- **Time saved per deployment**: 2 hours 59 minutes 30 seconds 🎉