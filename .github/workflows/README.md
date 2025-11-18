# GitHub Actions Workflows

## ✅ Active Workflow

**`deploy-production-zero-downtime.yml`** - Production deployment with zero downtime

**Triggers:**
- Push to `main` or `master` branch
- Manual workflow dispatch

**Source:** Copied from `../../deployment-automation/workflows/`

---

## 📖 Documentation

For complete workflow documentation, see:
- **Source files:** `../../deployment-automation/workflows/`
- **Documentation:** `../../deployment-automation/docs/`
- **Setup guide:** `../../DEPLOYMENT-START-HERE.md`

---

## 🔧 Workflow Features

✅ Automated validation (build & test)
✅ Zero downtime backend deployment
✅ Zero downtime frontend deployment
✅ Health checks and verification
✅ Auto-rollback on failure

---

## 🎯 How It Works

1. **Validate** - Build backend & frontend, run tests
2. **Deploy Backend** - Zero downtime using blue-green strategy
3. **Deploy Frontend** - Atomic symlink swap
4. **Verify** - Health checks and deployment summary

**Downtime:** 0 seconds ✨

---

## 📦 Archived Workflows

Old workflows moved to: `archive/`

These are **no longer active** (had downtime):
- `deploy.yml` - Original deployment
- `deploy-with-validation.yml` - Deployment with validation

---

## 🚀 Usage

### Automatic Deployment

```bash
git add .
git commit -m "feat: My changes"
git push origin main  # Triggers workflow
```

### Manual Deployment

1. Go to **Actions** tab on GitHub
2. Select "Deploy to Production (Zero Downtime)"
3. Click "Run workflow"
4. Choose branch (`main`)
5. Click "Run workflow"

---

## ⚙️ Configuration

**Required GitHub Secrets:**

| Secret | Value | Purpose |
|--------|-------|---------|
| `HETZNER_HOST` | `65.21.4.236` | Production server IP |
| `HETZNER_USER` | `root` | SSH username |
| `HETZNER_PASSWORD` | Your password | SSH password |

**Setup:** GitHub → Settings → Secrets and variables → Actions

---

## 📁 Related Files

- **Deployment scripts:** `../../deployment-automation/scripts/`
- **Documentation:** `../../deployment-automation/docs/`
- **Configs:** `../../deployment-automation/configs/`

---

## 🆘 Troubleshooting

See: `../../deployment-automation/docs/QUICKSTART-ZERO-DOWNTIME.md`

---

**For more info, see:** `../../DEPLOYMENT-START-HERE.md`
