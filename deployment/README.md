# Deployment Folder

## ⚠️ Note: Deployment Files Moved!

**All CI/CD and zero-downtime deployment files have been moved to:**
```
../deployment-automation/
```

---

## 📁 What's in This Folder Now

This folder contains **legacy deployment files** that may still be needed for reference:

- **Hetzner Setup Scripts** - Original server setup files
  - `connect_to_hetzner.bat`
  - `create_ssh_key.bat`
  - `setup_server.sh`
  - `setup-api-ssl.sh`
  - etc.

- **Nginx Configs** - Various Nginx configurations
  - `nginx-api.conf`
  - `nginx-api-updated.conf` (also in deployment-automation/configs/)
  - `nginx-api-zero-downtime.conf`

- **Docker Files** - Old Dockerfiles
  - `Dockerfile.backend`
  - `Dockerfile.frontend`

- **Old Guides**
  - `HETZNER_DEPLOYMENT_GUIDE.md`

---

## 🚀 For Active Deployment, Use:

```
../deployment-automation/
```

**See:** `../DEPLOYMENT-START-HERE.md` for navigation

---

## 📦 Archived Files

Old zero-downtime files moved to: `archive-old-files/`

These are **duplicates** - the active versions are in `deployment-automation/`

---

## 🎯 Quick Links

- **New Deployment Files:** `../deployment-automation/`
- **GitHub Actions Workflow:** `../.github/workflows/deploy-production-zero-downtime.yml`
- **Start Here:** `../DEPLOYMENT-START-HERE.md`
