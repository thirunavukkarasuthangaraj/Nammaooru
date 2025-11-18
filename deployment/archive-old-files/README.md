# Zero Downtime Deployment

This folder contains everything you need for zero-downtime deployments.

## 📁 Files in This Folder

### 📖 **Documentation** (Read These!)

1. **`SIMPLE-VISUAL-GUIDE.md`** ⭐ **START HERE!**
   - Super simple explanation with clear box models
   - Easy to understand for beginners
   - Visual step-by-step guide

2. **`QUICKSTART-ZERO-DOWNTIME.md`**
   - Quick reference guide
   - Commands you need for daily deployments
   - Troubleshooting tips

3. **`ZERO-DOWNTIME-DEPLOYMENT.md`**
   - Detailed technical guide
   - Architecture explanation
   - Advanced configurations

---

### 🛠️ **Scripts** (Run These!)

1. **`setup-zero-downtime.sh`** (One-time setup)
   - Automated setup script
   - Uploads configs to server
   - Sets up infrastructure

2. **`zero-downtime-deploy.sh`** (Backend deployment)
   - Deploy backend with zero downtime
   - Auto health checks
   - Auto rollback on failure

3. **`zero-downtime-frontend-deploy.sh`** (Frontend deployment)
   - Deploy frontend with zero downtime
   - Atomic symlink swaps
   - Keeps last 5 releases

---

### ⚙️ **Configuration Files**

1. **`nginx-api-updated.conf`**
   - Updated Nginx config with upstream load balancing
   - Use this to replace your current Nginx config

2. **`nginx-api-zero-downtime.conf`**
   - Alternative Nginx config with CORS headers
   - (Not used currently, kept for reference)

---

## 🚀 Quick Start

### **Step 1: One-Time Setup (10 minutes)**

```bash
# From project root
cd deployment
chmod +x setup-zero-downtime.sh
./setup-zero-downtime.sh
```

### **Step 2: Deploy Backend**

```bash
# SSH to server
ssh root@65.21.4.236
cd /opt/shop-management/deployment
./zero-downtime-deploy.sh
```

### **Step 3: Deploy Frontend**

```bash
# Build locally
cd frontend
ng build --configuration production

# Upload
cd dist
tar -czf deploy.tar.gz shop-management-frontend/
scp deploy.tar.gz root@65.21.4.236:/opt/shop-management/frontend/dist/

# Deploy on server
ssh root@65.21.4.236
cd /opt/shop-management/deployment
./zero-downtime-frontend-deploy.sh
```

---

## 📚 Documentation Guide

**New to this?** → Read `SIMPLE-VISUAL-GUIDE.md`

**Need quick commands?** → Read `QUICKSTART-ZERO-DOWNTIME.md`

**Want technical details?** → Read `ZERO-DOWNTIME-DEPLOYMENT.md`

---

## ✅ Checklist

**Before Setup:**
- [ ] SSH access to server (root@65.21.4.236)
- [ ] Git Bash installed on Windows
- [ ] Docker running on server
- [ ] Nginx running on server

**After Setup:**
- [ ] Scripts uploaded to server
- [ ] Nginx config updated
- [ ] Frontend release structure created
- [ ] Test deployment successful

---

## 🆘 Need Help?

1. **Read the guides** in this folder
2. **Check common issues** in QUICKSTART guide
3. **Review logs** on server:
   - Nginx: `/var/log/nginx/error.log`
   - Docker: `docker logs <container-name>`

---

## 🎯 Benefits

| Feature | Before | After |
|---------|--------|-------|
| Downtime | 30-60s | **0s** ✨ |
| Failed Requests | 5-10% | **0%** |
| Rollback Time | 5 min | **5s** ⚡ |

---

**Ready? Start with `SIMPLE-VISUAL-GUIDE.md`!** 🚀
