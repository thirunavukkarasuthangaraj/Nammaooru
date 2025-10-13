# Guide: Copy Images from Local to Production Server

## Overview

This guide helps you copy uploaded images from your local development machine to the production server.

**Source (Local):** `D:\AAWS\nammaooru\uploads`
**Destination (Server):** `/opt/shop-management/uploads`

---

## Prerequisites

Before copying, ensure:
1. ✅ Production server is running
2. ✅ `/opt/shop-management/uploads` directory exists on server
3. ✅ You have SSH access to the server
4. ✅ Database data is already migrated

---

## Method 1: Automated Script (Recommended)

### Option A: PowerShell Script

```powershell
# Run from project root
.\copy-images-to-server.ps1
```

### Option B: Batch Script

```cmd
# Run from project root
copy-images-to-server.bat
```

---

## Method 2: Manual SCP Command (Command Line)

### Step 1: Open Command Prompt or PowerShell

```bash
# Navigate to project root
cd D:\AAWS\nammaooru\shop-management-system
```

### Step 2: Copy Files Using SCP

```bash
# Copy all files and subdirectories
scp -r D:\AAWS\nammaooru\uploads\* root@65.21.4.236:/opt/shop-management/uploads/
```

**Note:** You'll be prompted for the server password unless you have SSH keys configured.

---

## Method 3: Using WinSCP (GUI Tool)

WinSCP is a free SFTP/SCP client for Windows with a user-friendly interface.

### Step 1: Download WinSCP
- Download from: https://winscp.net/eng/download.php
- Install with default settings

### Step 2: Connect to Server

1. Open WinSCP
2. Click "New Session"
3. Enter connection details:
   ```
   File protocol: SFTP
   Host name: 65.21.4.236
   Port number: 22
   User name: root
   Password: [your server password]
   ```
4. Click "Login"

### Step 3: Navigate to Folders

**Left Panel (Local):**
- Navigate to: `D:\AAWS\nammaooru\uploads`

**Right Panel (Server):**
- Navigate to: `/opt/shop-management/uploads`

### Step 4: Copy Files

1. Select all files/folders in the left panel
2. Drag and drop to the right panel
3. Wait for upload to complete

### Step 5: Verify

Check the right panel to ensure all files are uploaded.

---

## Method 4: Using FileZilla (Alternative GUI)

### Step 1: Download FileZilla
- Download from: https://filezilla-project.org/download.php?type=client
- Install with default settings

### Step 2: Connect to Server

1. Open FileZilla
2. Enter at the top:
   ```
   Host: sftp://65.21.4.236
   Username: root
   Password: [your server password]
   Port: 22
   ```
3. Click "Quickconnect"

### Step 3: Navigate and Transfer

**Left Panel (Local):**
- Navigate to: `D:\AAWS\nammaooru\uploads`

**Right Panel (Server):**
- Navigate to: `/opt/shop-management/uploads`

**Transfer:**
- Right-click on the uploads folder (left panel)
- Select "Upload"
- Wait for transfer to complete

---

## Method 5: Using rsync (Advanced - Requires WSL)

If you have Windows Subsystem for Linux (WSL) installed:

```bash
# From WSL terminal
rsync -avz --progress /mnt/d/AAWS/nammaooru/uploads/ root@65.21.4.236:/opt/shop-management/uploads/
```

**Advantages:**
- Resumes interrupted transfers
- Only copies changed files
- Shows progress
- Faster than SCP for large transfers

---

## Post-Copy Verification

### On Your Local Machine

Check how many files you're copying:

```powershell
# PowerShell
(Get-ChildItem -Path D:\AAWS\nammaooru\uploads -Recurse -File).Count

# Check total size
(Get-ChildItem -Path D:\AAWS\nammaooru\uploads -Recurse | Measure-Object -Property Length -Sum).Sum / 1MB
```

```cmd
# Command Prompt
dir /s /b D:\AAWS\nammaooru\uploads\* | find /c "\"
```

### On the Server

SSH to the server and verify:

```bash
# SSH to server
ssh root@65.21.4.236

# Navigate to uploads directory
cd /opt/shop-management/uploads

# Count files
find . -type f | wc -l

# Check total size
du -sh .

# Check subdirectories
du -h --max-depth=1 .

# List recent uploads
ls -lhtr products/master/ | tail -10

# List directory structure
tree -L 2
# or
find . -type d -maxdepth 2
```

Expected structure:
```
/opt/shop-management/uploads/
├── products/
│   ├── master/
│   └── shop/
├── shops/
├── delivery-proof/
└── documents/
```

---

## Testing After Copy

### Test 1: Check Files Are Accessible

```bash
# On server
ls -la /opt/shop-management/uploads/products/master/
```

### Test 2: Verify Docker Can Access

```bash
# Check mount
docker exec nammaooru-backend ls -la /app/uploads/

# Should show the same files
```

### Test 3: Verify Nginx Can Serve

```bash
# Create test file
echo "test" > /opt/shop-management/uploads/test.txt

# Test nginx serving
curl http://localhost/uploads/test.txt

# Should return "test"

# Test from outside
curl https://nammaoorudelivary.in/uploads/test.txt

# Clean up
rm /opt/shop-management/uploads/test.txt
```

### Test 4: Test Actual Image URL

```bash
# Find an actual image file
ls /opt/shop-management/uploads/products/master/ | head -1

# Test accessing it (replace with actual filename)
curl -I https://nammaoorudelivary.in/uploads/products/master/your_image_name.jpg

# Should return: HTTP/1.1 200 OK
```

---

## Troubleshooting

### Problem: "Permission denied" during SCP

**Solution 1:** Check SSH access
```bash
ssh root@65.21.4.236
# If this works, SCP should work too
```

**Solution 2:** Use password authentication
```bash
scp -o PreferredAuthentications=password -r D:\AAWS\nammaooru\uploads\* root@65.21.4.236:/opt/shop-management/uploads/
```

### Problem: "Directory not found" on server

**Solution:** Create the directory first
```bash
ssh root@65.21.4.236
mkdir -p /opt/shop-management/uploads
chmod -R 755 /opt/shop-management/uploads
exit
```

### Problem: Files copied but not accessible via URL

**Check 1:** Verify nginx configuration
```bash
ssh root@65.21.4.236
cat /etc/nginx/sites-available/nammaoorudelivary.conf | grep uploads
# Should show: alias /opt/shop-management/uploads/;
```

**Check 2:** Reload nginx
```bash
nginx -t
systemctl reload nginx
```

**Check 3:** Check permissions
```bash
chmod -R 755 /opt/shop-management/uploads
```

### Problem: "Connection refused" or "Connection timed out"

**Check 1:** Verify server is running
```bash
ping 65.21.4.236
```

**Check 2:** Check SSH port
```bash
ssh -v root@65.21.4.236
# Shows verbose connection info
```

**Check 3:** Check firewall
```bash
# On server
ufw status
# Ensure port 22 is allowed
```

### Problem: SCP command not found on Windows

**Solution:** Install OpenSSH
```powershell
# PowerShell (Run as Administrator)
Get-WindowsCapability -Online | ? Name -like 'OpenSSH*'

# Install if not present
Add-WindowsCapability -Online -Name OpenSSH.Client~~~~0.0.1.0
```

Or use WinSCP/FileZilla instead.

---

## Backup Before Copy (Recommended)

Before copying, backup existing server files:

```bash
# SSH to server
ssh root@65.21.4.236

# Create backup
tar -czf /opt/shop-management/uploads_backup_$(date +%Y%m%d).tar.gz /opt/shop-management/uploads/

# List backups
ls -lh /opt/shop-management/uploads_backup_*
```

---

## Performance Tips

### For Large Transfers

1. **Use compression** (if not already compressed images):
   ```bash
   scp -C -r D:\AAWS\nammaooru\uploads\* root@65.21.4.236:/opt/shop-management/uploads/
   ```

2. **Use multiple connections** (with pscp from PuTTY):
   ```bash
   pscp -r -C D:\AAWS\nammaooru\uploads\* root@65.21.4.236:/opt/shop-management/uploads/
   ```

3. **Resume interrupted transfer** (with rsync):
   ```bash
   rsync -avz --partial --progress D:\AAWS\nammaooru\uploads/ root@65.21.4.236:/opt/shop-management/uploads/
   ```

### Monitor Transfer Progress

```bash
# On server (in another SSH session)
watch -n 2 'du -sh /opt/shop-management/uploads && find /opt/shop-management/uploads -type f | wc -l'
```

---

## Quick Reference

| Method | Difficulty | Speed | Resume Support | GUI |
|--------|-----------|-------|----------------|-----|
| Automated Script | Easy | Medium | No | No |
| SCP Command | Medium | Medium | No | No |
| WinSCP | Easy | Medium | Yes | Yes |
| FileZilla | Easy | Medium | Yes | Yes |
| rsync | Hard | Fast | Yes | No |

**Recommendation:**
- **For beginners:** Use WinSCP (GUI, easy to use)
- **For command line users:** Use automated script or SCP
- **For large transfers:** Use rsync (if WSL available)

---

## After Successful Copy

1. ✅ Verify file count matches
2. ✅ Test image URLs in browser
3. ✅ Test upload new image via app
4. ✅ Verify new uploads appear in folder
5. ✅ Delete local backup if everything works

---

## Success Checklist

- [ ] Files copied to `/opt/shop-management/uploads/`
- [ ] File count matches local folder
- [ ] Docker container can access files
- [ ] Nginx serves images correctly
- [ ] Test image URL works: `https://nammaoorudelivary.in/uploads/test.txt`
- [ ] Actual product images load in app
- [ ] New uploads work and persist

---

## Need Help?

If you encounter issues:
1. Check the troubleshooting section above
2. Review `/var/log/nginx/error.log` on server
3. Check Docker logs: `docker logs nammaooru-backend`
4. Verify permissions: `ls -la /opt/shop-management/uploads`
