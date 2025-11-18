# CI/CD Setup Guide

Complete guide to setting up Continuous Integration and Continuous Deployment with Zero Downtime.

## 📋 Prerequisites

Before starting, ensure you have:

- ✅ GitHub repository with your code
- ✅ Production server (65.21.4.236)
- ✅ SSH access to server (root user)
- ✅ Docker installed on server
- ✅ Nginx installed on server

---

## 🎯 Setup Overview

```
┌──────────────────────────────────────────────┐
│ Step 1: Configure GitHub Secrets (5 min)     │
├──────────────────────────────────────────────┤
│ Step 2: Setup Server Infrastructure (10 min) │
├──────────────────────────────────────────────┤
│ Step 3: Test Zero-Downtime Scripts (5 min)   │
├──────────────────────────────────────────────┤
│ Step 4: Test GitHub Actions Workflow (10 min)│
└──────────────────────────────────────────────┘

Total Time: ~30 minutes
```

---

## Step 1: Configure GitHub Secrets

### **1.1 Navigate to GitHub Secrets**

1. Go to your repository on GitHub
2. Click **Settings** tab
3. Click **Secrets and variables** → **Actions**
4. You should see "Actions secrets" page

### **1.2 Add Required Secrets**

Click **"New repository secret"** and add each of these:

#### **Secret 1: HETZNER_HOST**
```
Name: HETZNER_HOST
Value: 65.21.4.236
```

#### **Secret 2: HETZNER_USER**
```
Name: HETZNER_USER
Value: root
```

#### **Secret 3: HETZNER_PASSWORD**
```
Name: HETZNER_PASSWORD
Value: [your-server-password]
```

### **1.3 Verify Secrets**

After adding, you should see:
- ✅ HETZNER_HOST
- ✅ HETZNER_USER
- ✅ HETZNER_PASSWORD

**Security Note:** These secrets are encrypted and never exposed in logs!

---

## Step 2: Setup Server Infrastructure

### **2.1 Run One-Time Setup Script**

On your **local machine** (Windows with Git Bash):

```bash
cd D:\AAWS\nammaooru\shop-management-system
cd deployment
chmod +x setup-zero-downtime.sh
./setup-zero-downtime.sh
```

**What this does:**
```
✓ Uploads deployment scripts to server
✓ Updates Nginx configuration
✓ Creates frontend release directory structure
✓ Sets up load balancing
✓ Verifies everything works
```

**Expected Output:**
```
🔧 Setting up Zero Downtime Deployment Infrastructure
======================================================

This script will:
1. Upload deployment scripts to server
2. Update Nginx configuration for zero downtime
3. Setup frontend release directory structure
4. Make scripts executable

Continue? (y/n) y

✓ Step 1/4: Uploading deployment scripts to server...
✓ Step 2/4: Updating Nginx configuration...
✓ Step 3/4: Setting up frontend release directory structure...
✓ Step 4/4: Making deployment scripts executable...

✅ Zero Downtime Infrastructure Setup Complete!
```

### **2.2 Verify Server Setup**

SSH to server and check:

```bash
ssh root@65.21.4.236

# Check deployment scripts exist
ls -la /opt/shop-management/deployment/

# Should show:
# zero-downtime-deploy.sh
# zero-downtime-frontend-deploy.sh

# Check Nginx config
cat /etc/nginx/sites-available/api.nammaoorudelivary.in | grep "upstream"

# Should show:
# upstream backend_servers {

# Check frontend structure
ls -la /var/www/

# Should show:
# html -> releases/TIMESTAMP (symlink)
# releases/
```

---

## Step 3: Test Zero-Downtime Scripts

### **3.1 Test Backend Deployment**

On the **server**:

```bash
ssh root@65.21.4.236
cd /opt/shop-management
git pull  # Get latest code
./deployment/zero-downtime-deploy.sh
```

**Expected flow:**
```
🚀 Starting Zero Downtime Deployment...
✓ Detect current container: nammaooru-backend
✓ Build new Docker image
✓ Start new container (port 8083)
✓ Wait for health check...
✓ New container HEALTHY!
✓ Update Nginx configuration
✓ Reload Nginx
✓ Wait 30s for connections to drain
✓ Stop old container
✓ Clean up old images
✅ Zero Downtime Deployment Complete!

Total time: ~2 minutes
Downtime: 0 seconds
```

**Verify:**
```bash
# Check health
curl https://api.nammaoorudelivary.in/actuator/health

# Should return: {"status":"UP"}
```

### **3.2 Test Frontend Deployment**

On your **local machine**, build frontend:

```bash
cd frontend
ng build --configuration production
cd dist
tar -czf deploy.tar.gz shop-management-frontend/
scp deploy.tar.gz root@65.21.4.236:/opt/shop-management/frontend/dist/
```

On the **server**:

```bash
ssh root@65.21.4.236
cd /opt/shop-management/frontend/dist
tar -xzf deploy.tar.gz
cd /opt/shop-management
./deployment/zero-downtime-frontend-deploy.sh
```

**Expected flow:**
```
🚀 Starting Zero Downtime Frontend Deployment...
✓ Create new release directory: /var/www/releases/20250118_153045
✓ Copy files to new release
✓ Set permissions
✓ Verify index.html exists
✓ Atomic symlink swap (INSTANT!)
✓ Reload Nginx
✓ Clean old releases (keep last 5)
✅ Frontend Deployment Complete!

Total time: ~20 seconds
Downtime: 0 seconds
```

**Verify:**
```bash
# Check frontend
curl -I https://nammaoorudelivary.in

# Should return: HTTP/1.1 200 OK

# Check current release
readlink /var/www/html

# Should show: /var/www/releases/20250118_153045
```

---

## Step 4: Test GitHub Actions Workflow

### **4.1 Enable Workflow**

1. Go to GitHub repository
2. Click **Actions** tab
3. If prompted "Workflows aren't being run on this forked repository"
   - Click **"I understand my workflows, go ahead and enable them"**

### **4.2 Make a Test Change**

On your **local machine**:

```bash
# Make a small change
echo "# CI/CD Test" >> README.md

# Commit and push
git add README.md
git commit -m "test: Trigger CI/CD workflow"
git push origin main
```

### **4.3 Watch Workflow Run**

1. Go to **Actions** tab on GitHub
2. You should see workflow "Deploy to Production (Zero Downtime)" running
3. Click on the running workflow
4. Watch each step execute:

```
✓ validate
  ✓ Pre-Deployment Validation
  ✓ Set up JDK 17
  ✓ Build and test backend
  ✓ Set up Node.js
  ✓ Build frontend
  ✓ Validation Summary

✓ deploy-backend
  ✓ Checkout code
  ✓ Copy deployment scripts to server
  ✓ Copy source code to server
  ✓ Deploy backend with zero downtime
  ✓ Verify backend deployment

✓ deploy-frontend
  ✓ Checkout code
  ✓ Set up Node.js
  ✓ Build frontend
  ✓ Package frontend build
  ✓ Upload frontend build to server
  ✓ Deploy frontend with zero downtime
  ✓ Verify frontend deployment

✓ deployment-summary
  ✓ Generate deployment summary
```

### **4.4 Verify Deployment**

After workflow completes:

```bash
# Check backend
curl https://api.nammaoorudelivary.in/actuator/health

# Check frontend
curl -I https://nammaoorudelivary.in

# Check containers
ssh root@65.21.4.236 "docker ps"
```

---

## ✅ Setup Complete Checklist

### **GitHub**
- [ ] GitHub secrets configured
  - [ ] HETZNER_HOST
  - [ ] HETZNER_USER
  - [ ] HETZNER_PASSWORD
- [ ] Workflows enabled
- [ ] Test workflow ran successfully

### **Server**
- [ ] Deployment scripts uploaded
- [ ] Nginx configured with upstream
- [ ] Frontend release structure created
- [ ] Zero-downtime backend deployment tested
- [ ] Zero-downtime frontend deployment tested

### **Verification**
- [ ] Backend health check passes
- [ ] Frontend loads successfully
- [ ] Containers running
- [ ] GitHub Actions workflow succeeds

---

## 🎉 You're All Set!

Your CI/CD pipeline is now configured!

### **What happens now:**

Every time you push to `main` branch:
1. ✅ GitHub Actions validates code
2. ✅ Deploys backend (zero downtime)
3. ✅ Deploys frontend (zero downtime)
4. ✅ Verifies deployment
5. ✅ Notifies you of status

**Total Downtime:** 0 seconds ✨

---

## 🔄 Next Steps

1. **Read**: [Deployment Process](./DEPLOYMENT-PROCESS.md) - Understand deployment flow
2. **Bookmark**: [Troubleshooting Guide](./TROUBLESHOOTING.md) - Common issues
3. **Deploy**: Make changes and push to trigger deployment!

---

## 🆘 Troubleshooting

### **Setup script fails**

**Problem:** `./setup-zero-downtime.sh` fails

**Solution:**
```bash
# Check SSH connection
ssh root@65.21.4.236 "echo 'Connection OK'"

# Manual setup
ssh root@65.21.4.236
mkdir -p /opt/shop-management/deployment
# Then manually upload files with scp
```

---

### **GitHub Actions can't connect to server**

**Problem:** SSH action fails with "Connection refused"

**Solution:**
1. Verify secrets are correct:
   - Go to Settings → Secrets → Actions
   - Check HETZNER_HOST, HETZNER_USER, HETZNER_PASSWORD
2. Test SSH manually:
   ```bash
   ssh root@65.21.4.236
   ```

---

### **Deployment scripts not found**

**Problem:** `./zero-downtime-deploy.sh: not found`

**Solution:**
```bash
ssh root@65.21.4.236
cd /opt/shop-management/deployment
chmod +x zero-downtime-deploy.sh
chmod +x zero-downtime-frontend-deploy.sh
```

---

**Setup complete? Start deploying!** 🚀
