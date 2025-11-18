# 🚀 Deployment Automation - All-in-One Folder

**Everything you need for CI/CD and Zero Downtime Deployment in ONE place!**

---

## 📁 Folder Structure

```
deployment-automation/
├── 📂 workflows/          ← GitHub Actions workflows
│   └── deploy-production-zero-downtime.yml
│
├── 📂 scripts/            ← Deployment scripts
│   ├── zero-downtime-deploy.sh
│   ├── zero-downtime-frontend-deploy.sh
│   └── setup-zero-downtime.sh
│
├── 📂 configs/            ← Configuration files
│   └── nginx-api-updated.conf
│
├── 📂 docs/               ← All documentation
│   ├── CI-CD-OVERVIEW.md
│   ├── SETUP-GUIDE.md
│   ├── SIMPLE-VISUAL-GUIDE.md
│   ├── QUICKSTART-ZERO-DOWNTIME.md
│   └── ZERO-DOWNTIME-DEPLOYMENT.md
│
└── 📄 README.md           ← You are here!
```

---

## 🎯 Quick Start (3 Steps)

### **Step 1: Setup (One-Time)**

```bash
# Navigate to this folder
cd deployment-automation

# Read the setup guide
# Open: docs/SETUP-GUIDE.md

# Run setup script
cd scripts
chmod +x setup-zero-downtime.sh
./setup-zero-downtime.sh
```

### **Step 2: Configure GitHub Actions**

```bash
# Copy workflow to .github/workflows/
cp workflows/deploy-production-zero-downtime.yml ../.github/workflows/

# Configure GitHub Secrets (see docs/SETUP-GUIDE.md)
# Settings → Secrets → Actions
# Add: HETZNER_HOST, HETZNER_USER, HETZNER_PASSWORD
```

### **Step 3: Deploy**

```bash
# Automatic (just push code)
git add .
git commit -m "feat: My changes"
git push origin main  # Auto-deploys with zero downtime!

# OR Manual (on server)
ssh root@65.21.4.236
cd /opt/shop-management/deployment-automation/scripts
./zero-downtime-deploy.sh
```

---

## 📖 Documentation Index

### **🔰 New to This?**
**Start Here:** [`docs/SIMPLE-VISUAL-GUIDE.md`](./docs/SIMPLE-VISUAL-GUIDE.md)
- Visual box models
- Easy explanations
- Step-by-step diagrams

### **⚙️ Setting Up?**
**Follow This:** [`docs/SETUP-GUIDE.md`](./docs/SETUP-GUIDE.md)
- Complete setup walkthrough
- GitHub Secrets configuration
- Server setup instructions

### **📚 Understanding CI/CD?**
**Read This:** [`docs/CI-CD-OVERVIEW.md`](./docs/CI-CD-OVERVIEW.md)
- What is CI/CD?
- How it works
- Deployment flow

### **⚡ Quick Reference?**
**Use This:** [`docs/QUICKSTART-ZERO-DOWNTIME.md`](./docs/QUICKSTART-ZERO-DOWNTIME.md)
- Common commands
- FAQ
- Troubleshooting

### **🔧 Technical Details?**
**Deep Dive:** [`docs/ZERO-DOWNTIME-DEPLOYMENT.md`](./docs/ZERO-DOWNTIME-DEPLOYMENT.md)
- Architecture
- Advanced configuration
- How zero downtime works

---

## 🛠️ Scripts Reference

### **`scripts/setup-zero-downtime.sh`**
**Purpose:** One-time server setup
```bash
cd scripts
./setup-zero-downtime.sh
```
**What it does:**
- Uploads deployment scripts to server
- Updates Nginx configuration
- Creates frontend release structure
- Verifies setup

---

### **`scripts/zero-downtime-deploy.sh`**
**Purpose:** Deploy backend with zero downtime
```bash
# On server
./zero-downtime-deploy.sh
```
**What it does:**
- Builds new Docker image
- Starts new container (old keeps running)
- Waits for health check
- Switches Nginx traffic
- Stops old container

**Downtime:** 0 seconds ✨

---

### **`scripts/zero-downtime-frontend-deploy.sh`**
**Purpose:** Deploy frontend with zero downtime
```bash
# On server
./zero-downtime-frontend-deploy.sh
```
**What it does:**
- Creates new release directory
- Copies files
- Atomic symlink swap
- Reloads Nginx
- Keeps last 5 releases

**Downtime:** 0 seconds ✨

---

## ⚙️ Configuration Files

### **`configs/nginx-api-updated.conf`**
**Purpose:** Nginx configuration with upstream load balancing

**Location on server:** `/etc/nginx/sites-available/api.nammaoorudelivary.in`

**Features:**
- Upstream load balancing
- Auto-retry on failure
- Zero downtime support
- Health check routing

---

## 🔄 GitHub Actions Workflow

### **`workflows/deploy-production-zero-downtime.yml`**
**Purpose:** Automated CI/CD pipeline

**Triggers:**
- Push to `main` or `master` branch
- Manual workflow dispatch

**Steps:**
1. **Validate** - Build and test code
2. **Deploy Backend** - Zero downtime deployment
3. **Deploy Frontend** - Zero downtime deployment
4. **Verify** - Health checks and summary

**Usage:**
```bash
# Copy to GitHub workflows folder
cp workflows/deploy-production-zero-downtime.yml ../.github/workflows/

# Or create symlink
cd ../.github/workflows
ln -s ../../deployment-automation/workflows/deploy-production-zero-downtime.yml
```

---

## 📊 Complete Deployment Flow

```
┌─────────────────────────────────────────────────────────┐
│  1. DEVELOPER PUSHES CODE                                │
│     git push origin main                                 │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│  2. GITHUB ACTIONS VALIDATES                             │
│     workflows/deploy-production-zero-downtime.yml        │
│     ✓ Build backend                                      │
│     ✓ Build frontend                                     │
│     ✓ Run tests                                          │
└────────────────────┬────────────────────────────────────┘
                     │ (Only if validation passes)
                     ↓
┌─────────────────────────────────────────────────────────┐
│  3. DEPLOY BACKEND (Server)                              │
│     scripts/zero-downtime-deploy.sh                      │
│     ✓ Start new container                                │
│     ✓ Health check passes                                │
│     ✓ Switch traffic                                     │
│     ✓ Stop old container                                 │
│     ⏱️ Downtime: 0 seconds                                │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
┌─────────────────────────────────────────────────────────┐
│  4. DEPLOY FRONTEND (Server)                             │
│     scripts/zero-downtime-frontend-deploy.sh             │
│     ✓ Create new release                                 │
│     ✓ Atomic symlink swap                                │
│     ✓ Reload Nginx                                       │
│     ⏱️ Downtime: 0 seconds                                │
└────────────────────┬────────────────────────────────────┘
                     │
                     ↓
                 ✅ DONE!
```

---

## 🎯 Usage Scenarios

### **Scenario 1: First-Time Setup**

```bash
# 1. Read documentation
cd deployment-automation/docs
# Open SETUP-GUIDE.md

# 2. Run setup script
cd ../scripts
chmod +x setup-zero-downtime.sh
./setup-zero-downtime.sh

# 3. Copy workflow to GitHub
cp ../workflows/deploy-production-zero-downtime.yml ../../.github/workflows/

# 4. Configure GitHub Secrets
# GitHub → Settings → Secrets → Actions
# Add: HETZNER_HOST, HETZNER_USER, HETZNER_PASSWORD

# 5. Test deployment
git add .
git commit -m "test: CI/CD setup"
git push origin main
```

---

### **Scenario 2: Manual Backend Deployment**

```bash
# SSH to server
ssh root@65.21.4.236

# Navigate to scripts folder
cd /opt/shop-management/deployment-automation/scripts

# Pull latest code
cd ../..
git pull

# Run deployment
cd deployment-automation/scripts
./zero-downtime-deploy.sh

# Verify
curl https://api.nammaoorudelivary.in/actuator/health
```

---

### **Scenario 3: Manual Frontend Deployment**

```bash
# Build on local machine
cd frontend
ng build --configuration production

# Package
cd dist
tar -czf deploy.tar.gz shop-management-frontend/

# Upload to server
scp deploy.tar.gz root@65.21.4.236:/opt/shop-management/frontend/dist/

# Deploy on server
ssh root@65.21.4.236
cd /opt/shop-management/frontend/dist
tar -xzf deploy.tar.gz
cd ../../deployment-automation/scripts
./zero-downtime-frontend-deploy.sh

# Verify
curl -I https://nammaoorudelivary.in
```

---

### **Scenario 4: Rollback**

**Frontend Rollback (5 seconds):**
```bash
ssh root@65.21.4.236
cd /var/www/releases
ls -lt  # List releases
sudo ln -sfn /var/www/releases/PREVIOUS_TIMESTAMP /var/www/html
sudo systemctl reload nginx
```

**Backend Rollback (2 minutes):**
```bash
ssh root@65.21.4.236
cd /opt/shop-management
git checkout PREVIOUS_COMMIT
cd deployment-automation/scripts
./zero-downtime-deploy.sh
```

---

## ✅ Checklist

### **Setup Checklist**
- [ ] Read docs/SETUP-GUIDE.md
- [ ] Run scripts/setup-zero-downtime.sh
- [ ] Copy workflow to .github/workflows/
- [ ] Configure GitHub Secrets
- [ ] Test deployment

### **Daily Deployment Checklist**
- [ ] Code tested locally
- [ ] Changes committed
- [ ] Push to main branch
- [ ] Monitor GitHub Actions
- [ ] Verify deployment

### **Verification Checklist**
- [ ] Backend health: `curl https://api.nammaoorudelivary.in/actuator/health`
- [ ] Frontend loads: `curl -I https://nammaoorudelivary.in`
- [ ] Containers running: `docker ps`
- [ ] No errors in logs

---

## 📞 Need Help?

| Question | Documentation |
|----------|---------------|
| "How does it work?" | [`docs/SIMPLE-VISUAL-GUIDE.md`](./docs/SIMPLE-VISUAL-GUIDE.md) |
| "How do I set it up?" | [`docs/SETUP-GUIDE.md`](./docs/SETUP-GUIDE.md) |
| "Quick commands?" | [`docs/QUICKSTART-ZERO-DOWNTIME.md`](./docs/QUICKSTART-ZERO-DOWNTIME.md) |
| "What is CI/CD?" | [`docs/CI-CD-OVERVIEW.md`](./docs/CI-CD-OVERVIEW.md) |
| "Technical details?" | [`docs/ZERO-DOWNTIME-DEPLOYMENT.md`](./docs/ZERO-DOWNTIME-DEPLOYMENT.md) |

---

## 🎉 Benefits

| Feature | Before | After |
|---------|--------|-------|
| File Organization | Scattered | **One folder** |
| Deployment Method | Manual | **Automated** |
| Downtime | 30-60s | **0 seconds** ✨ |
| Rollback | 5 min | **5 seconds** ⚡ |
| Documentation | Multiple places | **One folder** |
| Setup Complexity | High | **Simple** |

---

## 🚀 Summary

**Everything for deployment in ONE folder:**
- ✅ GitHub Actions workflows
- ✅ Deployment scripts
- ✅ Configuration files
- ✅ Complete documentation

**How to use:**
1. **Setup once:** Follow `docs/SETUP-GUIDE.md`
2. **Deploy always:** Just `git push origin main`

**Result:** Zero downtime, automated deployments! ✨

---

**Questions? Start with `docs/SIMPLE-VISUAL-GUIDE.md`!** 🎯
