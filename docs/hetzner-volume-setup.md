# Hetzner Volume Setup Guide - NammaOoru

## Why Use a Volume?

Your server has 40 GB main disk shared between OS, Docker, PostgreSQL, and file uploads. As uploads grow daily, you risk running out of disk space. A Hetzner Volume gives you **separate, expandable storage** for uploads.

| Storage | What it holds |
|---------|--------------|
| **40 GB main disk** | OS, Docker, PostgreSQL, app code |
| **Volume (10 GB+)** | Uploaded files only (expandable anytime) |

---

## Step 1: Purchase a Volume

1. Log in to [Hetzner Cloud Console](https://console.hetzner.cloud)
2. Select your **Project**
3. Click **Volumes** in the left sidebar
4. Click **Create Volume**
5. Configure:
   - **Size**: 10 GB (start small, increase later)
   - **Location**: Must match your server location (e.g., `fsn1`, `nbg1`, `hel1`)
   - **Name**: `nammaooru-uploads`
   - **Automount**: You can choose manual for more control
6. **Attach to server**: Select your production server
7. Click **Create & Buy**

**Pricing**: ~€0.052/GB per month (10 GB ≈ €0.52/month)

---

## Step 2: Format the Volume (First Time Only)

> **WARNING**: Only do this once when the volume is brand new. This erases all data on the volume.

SSH into your server:

```bash
# Check the volume is detected
lsblk

# Format it (REPLACE <VOLUME_ID> with your actual volume ID from Hetzner Console)
mkfs.ext4 -F /dev/disk/by-id/scsi-0HC_Volume_<VOLUME_ID>
```

---

## Step 3: Migrate Existing Uploads to Volume

```bash
# 1. Create temporary mount point
mkdir -p /mnt/volume-data

# 2. Mount the volume temporarily
mount /dev/disk/by-id/scsi-0HC_Volume_<VOLUME_ID> /mnt/volume-data

# 3. Stop the application
cd /opt/shop-management && docker compose down

# 4. Copy existing uploads to the volume (preserves permissions)
cp -a /opt/shop-management/uploads/* /mnt/volume-data/

# 5. Verify files were copied
ls -la /mnt/volume-data/

# 6. Unmount from temporary location
umount /mnt/volume-data

# 7. Mount volume at the uploads path (replaces the old folder)
mount /dev/disk/by-id/scsi-0HC_Volume_<VOLUME_ID> /opt/shop-management/uploads

# 8. Verify uploads are accessible
ls -la /opt/shop-management/uploads/
```

---

## Step 4: Auto-Mount on Reboot

Add the volume to `/etc/fstab` so it mounts automatically when the server restarts:

```bash
echo "/dev/disk/by-id/scsi-0HC_Volume_<VOLUME_ID> /opt/shop-management/uploads ext4 discard,nofail,defaults 0 0" >> /etc/fstab
```

Verify it works:

```bash
# Test fstab without rebooting
mount -a

# Confirm it's mounted
df -h /opt/shop-management/uploads
```

---

## Step 5: Start the Application

```bash
cd /opt/shop-management && docker compose up -d
```

**No code changes or Docker config changes needed.** The `docker-compose.yml` already mounts `/opt/shop-management/uploads` into the container. The app won't know the difference.

---

## Increasing Volume Size Later

When you need more space:

1. Go to **Hetzner Console** → **Volumes** → click your volume → **Resize**
2. Increase to the new size (e.g., 10 GB → 20 GB → 50 GB)
3. SSH into server and run:

```bash
resize2fs /dev/disk/by-id/scsi-0HC_Volume_<VOLUME_ID>
```

4. Verify new size:

```bash
df -h /opt/shop-management/uploads
```

> **Note**: You can only increase size, never decrease. No data loss, no downtime needed.

---

## Monitoring Disk Usage

Check how much space is used:

```bash
# Check volume usage
df -h /opt/shop-management/uploads

# Check main disk usage
df -h /

# Check uploads folder size
du -sh /opt/shop-management/uploads/
```

Set up a simple alert (optional) - add to crontab:

```bash
# Alert when volume is 80% full (check daily at 9 AM)
0 9 * * * [ $(df /opt/shop-management/uploads | tail -1 | awk '{print $5}' | tr -d '%') -gt 80 ] && echo "Volume is over 80% full!" | mail -s "NammaOoru: Disk Alert" your-email@example.com
```

---

## Quick Reference

| Action | Command |
|--------|---------|
| Check volume is mounted | `df -h /opt/shop-management/uploads` |
| Check disk usage | `du -sh /opt/shop-management/uploads/` |
| Resize volume filesystem | `resize2fs /dev/disk/by-id/scsi-0HC_Volume_<VOLUME_ID>` |
| Stop app | `cd /opt/shop-management && docker compose down` |
| Start app | `cd /opt/shop-management && docker compose up -d` |

---

## Current Docker Volume Mapping

From `docker-compose.yml`:

```yaml
volumes:
  - /opt/shop-management/uploads:/app/uploads
```

This means:
- **Host path**: `/opt/shop-management/uploads` (where the Hetzner volume is mounted)
- **Container path**: `/app/uploads` (what the app sees inside Docker)

No changes needed to this mapping.
