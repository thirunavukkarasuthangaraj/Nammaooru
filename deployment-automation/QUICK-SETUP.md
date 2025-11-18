# ⚡ Quick Setup - 3 Steps

Everything for deployment in ONE folder!

---

## 📁 One Folder Structure

```
deployment-automation/          ← EVERYTHING IS HERE!
├── workflows/                  ← GitHub Actions
├── scripts/                    ← Deployment scripts
├── configs/                    ← Configuration files
└── docs/                       ← All documentation
```

---

## 🚀 Quick Setup (5 Minutes)

### **Step 1: Copy Workflow to GitHub**

```bash
# From project root
cp deployment-automation/workflows/deploy-production-zero-downtime.yml .github/workflows/

# OR create symlink (recommended)
cd .github/workflows
ln -s ../../deployment-automation/workflows/deploy-production-zero-downtime.yml
```

### **Step 2: Configure GitHub Secrets**

1. Go to GitHub repository
2. **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Add these 3 secrets:

```
Name: HETZNER_HOST
Value: 65.21.4.236

Name: HETZNER_USER
Value: root

Name: HETZNER_PASSWORD
Value: [your-server-password]
```

### **Step 3: Run Server Setup**

```bash
# From project root
cd deployment-automation/scripts
chmod +x setup-zero-downtime.sh
./setup-zero-downtime.sh
```

**Done!** ✅

---

## 🎯 Deploy

### **Automatic (Recommended)**

```bash
git add .
git commit -m "feat: My changes"
git push origin main
```

GitHub Actions automatically deploys with zero downtime!

### **Manual (On Server)**

```bash
ssh root@65.21.4.236
cd /opt/shop-management/deployment-automation/scripts
./zero-downtime-deploy.sh
```

---

## 📖 Documentation

All docs in one place: `deployment-automation/docs/`

- **SIMPLE-VISUAL-GUIDE.md** - Visual guide
- **SETUP-GUIDE.md** - Complete setup
- **QUICKSTART-ZERO-DOWNTIME.md** - Quick reference
- **CI-CD-OVERVIEW.md** - Understanding CI/CD
- **ZERO-DOWNTIME-DEPLOYMENT.md** - Technical details

---

## ✅ Verify Setup

```bash
# Check workflow copied
ls -la .github/workflows/deploy-production-zero-downtime.yml

# Check GitHub secrets
# GitHub → Settings → Secrets → Actions
# Should see: HETZNER_HOST, HETZNER_USER, HETZNER_PASSWORD

# Test deployment
git add .
git commit -m "test: CI/CD"
git push origin main

# Watch in GitHub Actions tab
```

---

## 🎉 That's It!

**One folder. Everything organized. Zero downtime deployments.** ✨

**Questions?** Read `deployment-automation/docs/SIMPLE-VISUAL-GUIDE.md`
