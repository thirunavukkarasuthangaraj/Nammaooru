# CI/CD Documentation

Complete guide for Continuous Integration and Continuous Deployment with Zero Downtime.

## 📁 Folder Structure

```
shop-management-system/
├── .github/
│   └── workflows/
│       ├── deploy-production-zero-downtime.yml  ← ACTIVE workflow
│       ├── README.md                            ← Workflows documentation
│       └── archive/
│           ├── deploy.yml                       ← Old workflow (archived)
│           └── deploy-with-validation.yml       ← Old workflow (archived)
│
├── deployment/
│   ├── zero-downtime-deploy.sh                  ← Backend deployment script
│   ├── zero-downtime-frontend-deploy.sh         ← Frontend deployment script
│   ├── setup-zero-downtime.sh                   ← One-time setup script
│   ├── nginx-api-updated.conf                   ← Nginx config
│   ├── SIMPLE-VISUAL-GUIDE.md                   ← Visual guide
│   ├── QUICKSTART-ZERO-DOWNTIME.md              ← Quick start guide
│   └── ZERO-DOWNTIME-DEPLOYMENT.md              ← Technical details
│
└── ci-cd-docs/                                   ← You are here!
    ├── README.md                                 ← This file
    ├── SETUP-GUIDE.md                            ← Setup instructions
    ├── DEPLOYMENT-PROCESS.md                     ← Deployment flow
    └── TROUBLESHOOTING.md                        ← Common issues
```

---

## 🎯 Quick Links

### **For First-Time Setup:**
1. [Setup Guide](./SETUP-GUIDE.md) - Complete setup instructions
2. [GitHub Actions Workflows](../.github/workflows/README.md) - Workflow documentation
3. [Deployment Scripts](../deployment/README.md) - Script documentation

### **For Daily Deployments:**
1. [Deployment Process](./DEPLOYMENT-PROCESS.md) - How deployments work
2. [Simple Visual Guide](../deployment/SIMPLE-VISUAL-GUIDE.md) - Visual explanation

### **For Troubleshooting:**
1. [Troubleshooting Guide](./TROUBLESHOOTING.md) - Common issues
2. [Quick Start Guide](../deployment/QUICKSTART-ZERO-DOWNTIME.md) - FAQ

---

## 🚀 What is CI/CD?

**CI/CD** = **Continuous Integration** + **Continuous Deployment**

### **Continuous Integration (CI)**
Automatically build and test code when you push to GitHub:
- ✅ Build backend (Maven)
- ✅ Build frontend (npm)
- ✅ Run tests
- ✅ Validate code quality

### **Continuous Deployment (CD)**
Automatically deploy to production when tests pass:
- ✅ Deploy backend with zero downtime
- ✅ Deploy frontend with zero downtime
- ✅ Verify deployment
- ✅ Auto-rollback if issues

---

## 📊 How It Works

### **Current Setup (Zero Downtime)**

```
Developer                  GitHub Actions              Production Server
─────────                  ──────────────              ─────────────────

  git push
     │
     ├──────────────────→  Workflow Triggered
     │                          │
     │                          ├─ Build Backend
     │                          ├─ Build Frontend
     │                          ├─ Run Tests
     │                          │
     │                    ✅ Validation Passed
     │                          │
     │                          ├─ Copy code to server ──→  Receive code
     │                          │                           │
     │                          ├─ Deploy backend ────────→ ├─ Start new container
     │                          │                           ├─ Health check passes
     │                          │                           ├─ Switch traffic
     │                          │                           └─ Stop old container
     │                          │
     │                    ✅ Backend deployed                ⏱️ Downtime: 0s
     │                          │
     │                          ├─ Deploy frontend ───────→ ├─ Upload build
     │                          │                           ├─ Atomic symlink swap
     │                          │                           └─ Reload Nginx
     │                          │
     │                    ✅ Frontend deployed               ⏱️ Downtime: 0s
     │                          │
     │                          ├─ Health checks ──────────→ ✅ All healthy
     │                          │
     │                    ✅ Deployment complete
     │                          │
     │                          └─ Send notification
     │
  ✅ Done!
```

**Total Downtime:** 0 seconds ✨

---

## 🔧 Setup Process

### **1. One-Time Setup (Already Done)**

- ✅ Zero-downtime scripts created
- ✅ Nginx configured for load balancing
- ✅ Frontend release structure created
- ✅ GitHub Actions workflow created

### **2. Configure GitHub Secrets**

Required secrets for CI/CD:

| Secret | Value | Purpose |
|--------|-------|---------|
| `HETZNER_HOST` | `65.21.4.236` | Server IP |
| `HETZNER_USER` | `root` | SSH username |
| `HETZNER_PASSWORD` | `your-password` | SSH password |

**How to add:**
1. Go to repository on GitHub
2. Settings → Secrets and variables → Actions
3. New repository secret
4. Add each secret

---

## 📖 Documentation Index

### **Setup & Configuration**
- [Setup Guide](./SETUP-GUIDE.md) - Complete setup walkthrough
- [GitHub Secrets](../.github/workflows/README.md#-setting-up-secrets) - Configure secrets
- [Server Setup](../deployment/SIMPLE-VISUAL-GUIDE.md#-setup) - Prepare server

### **Deployment**
- [Deployment Process](./DEPLOYMENT-PROCESS.md) - Detailed deployment flow
- [Visual Guide](../deployment/SIMPLE-VISUAL-GUIDE.md) - Box models & diagrams
- [Quick Start](../deployment/QUICKSTART-ZERO-DOWNTIME.md) - Quick reference

### **Workflows**
- [Active Workflows](../.github/workflows/README.md) - Current workflows
- [Workflow Configuration](../.github/workflows/deploy-production-zero-downtime.yml) - YAML file

### **Scripts**
- [Deployment Scripts](../deployment/README.md) - Script documentation
- [Backend Script](../deployment/zero-downtime-deploy.sh) - Backend deployment
- [Frontend Script](../deployment/zero-downtime-frontend-deploy.sh) - Frontend deployment

### **Troubleshooting**
- [Troubleshooting Guide](./TROUBLESHOOTING.md) - Common issues & solutions
- [Rollback Guide](../deployment/QUICKSTART-ZERO-DOWNTIME.md#-rollback-guide) - How to rollback

---

## 🎯 Daily Usage

### **Automatic Deployment (Recommended)**

Just push to main branch:

```bash
# Make changes
git add .
git commit -m "feat: Add new feature"

# Push to trigger deployment
git push origin main
```

**What happens:**
1. GitHub Actions validates code
2. Deploys backend (zero downtime)
3. Deploys frontend (zero downtime)
4. Sends you notification

**Time:** ~5-10 minutes
**Downtime:** 0 seconds ✨

---

### **Manual Deployment**

If you need to deploy manually:

1. Go to GitHub → Actions tab
2. Select "Deploy to Production (Zero Downtime)"
3. Click "Run workflow"
4. Choose branch (usually `main`)
5. Click "Run workflow" button

---

## 📊 Monitoring

### **GitHub Actions Dashboard**

Monitor deployments:
1. Go to **Actions** tab on GitHub
2. View running/completed workflows
3. Click workflow to see logs
4. Check each step's status

### **Server Health**

After deployment, verify:

```bash
# Backend health
curl https://api.nammaoorudelivary.in/actuator/health

# Frontend
curl -I https://nammaoorudelivary.in

# Container status
ssh root@65.21.4.236 "docker ps"
```

---

## 🔄 Deployment Flow

```
┌─────────────────────────────────────────────────────────┐
│  1. CODE PUSH                                            │
│  ─────────────                                           │
│  Developer pushes code to GitHub                         │
│  Trigger: git push origin main                           │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  2. VALIDATION (GitHub Actions)                          │
│  ────────────────────────────────                        │
│  ✓ Checkout code                                         │
│  ✓ Set up Java 17                                        │
│  ✓ Build backend (mvn clean package)                     │
│  ✓ Set up Node.js 18                                     │
│  ✓ Build frontend (npm run build)                        │
│  ✓ Validate both succeed                                 │
└─────────────────────────────────────────────────────────┘
                         ↓ (Only if validation passes)
┌─────────────────────────────────────────────────────────┐
│  3. DEPLOY BACKEND (Server)                              │
│  ─────────────────────────                               │
│  ✓ Copy code to server via SCP                           │
│  ✓ SSH to server                                         │
│  ✓ Run: ./deployment/zero-downtime-deploy.sh            │
│                                                          │
│  Script does:                                            │
│  ├─ Build new Docker image                               │
│  ├─ Start new container (port 8083)                      │
│  ├─ Wait for health check                                │
│  ├─ Update Nginx (route to new container)                │
│  ├─ Wait 30s for connections to drain                    │
│  └─ Stop old container                                   │
│                                                          │
│  ⏱️  Downtime: 0 seconds                                  │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  4. DEPLOY FRONTEND (Server)                             │
│  ──────────────────────────                              │
│  ✓ Build frontend locally                                │
│  ✓ Package as tar.gz                                     │
│  ✓ Upload to server via SCP                              │
│  ✓ SSH to server                                         │
│  ✓ Run: ./deployment/zero-downtime-frontend-deploy.sh   │
│                                                          │
│  Script does:                                            │
│  ├─ Extract build to new release directory               │
│  ├─ Verify files exist                                   │
│  ├─ Atomic symlink swap (instant!)                       │
│  ├─ Reload Nginx                                         │
│  └─ Clean old releases (keep 5)                          │
│                                                          │
│  ⏱️  Downtime: 0 seconds                                  │
└─────────────────────────────────────────────────────────┘
                         ↓
┌─────────────────────────────────────────────────────────┐
│  5. VERIFICATION                                         │
│  ──────────────                                          │
│  ✓ Check backend health                                  │
│  ✓ Check frontend accessibility                          │
│  ✓ Display deployment summary                            │
│  ✓ Show container status                                 │
└─────────────────────────────────────────────────────────┘
                         ↓
                  ✅ DEPLOYMENT COMPLETE!
```

---

## ✅ Checklist

### **Before First Deployment**

- [ ] GitHub secrets configured
- [ ] Server setup complete
- [ ] Zero-downtime scripts on server
- [ ] Nginx configured
- [ ] Frontend release structure created

### **Before Each Deployment**

- [ ] Code tested locally
- [ ] All changes committed
- [ ] Ready to deploy to production

### **After Each Deployment**

- [ ] Check GitHub Actions workflow succeeded
- [ ] Verify backend health endpoint
- [ ] Verify frontend loads
- [ ] Check for any errors in logs

---

## 🎉 Benefits

| Feature | Old Method | New CI/CD |
|---------|-----------|-----------|
| Deployment Method | Manual SSH | **Automated via GitHub** |
| Testing | Manual | **Automated in workflow** |
| Downtime | 30-60s | **0 seconds** ✨ |
| Rollback | 5 minutes | **Automatic** (or 5s manual) |
| Error Handling | Manual | **Auto-rollback** |
| Visibility | SSH logs | **GitHub Actions dashboard** |
| Safety | Low | **High** (validation required) |

---

## 📚 Learn More

- **GitHub Actions**: https://docs.github.com/actions
- **Docker**: https://docs.docker.com
- **Nginx**: https://nginx.org/en/docs/
- **Zero Downtime Deployments**: ../deployment/SIMPLE-VISUAL-GUIDE.md

---

**Questions? Check the troubleshooting guide or deployment documentation!**
