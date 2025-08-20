# Image Storage Optimization for Hetzner

## Current Setup (FREE within VPS limits)
- Docker volume: `uploads_data`
- Location: VPS SSD storage
- Cost: Included in VPS price

## When to Upgrade Storage

### Small Business (FREE)
- **Images**: < 10GB
- **Solution**: Keep current setup
- **Cost**: €0 extra

### Medium Business (€3.20/month)
- **Images**: 10GB - 1TB  
- **Solution**: Add Storage Box
- **Cost**: €3.20/month for 1TB

### Large Business (€10.73/month)
- **Images**: 1TB - 5TB
- **Solution**: 5TB Storage Box  
- **Cost**: €10.73/month

## Setup Options

### Option 1: Current (FREE)
```bash
# Images stored in Docker volume
# Included in VPS disk space
# No additional cost
```

### Option 2: Storage Box Integration
```bash
# Mount Storage Box as additional volume
# Move older images to Storage Box
# Keep recent images on fast SSD
```

### Option 3: CDN + Storage Box
```bash
# Storage Box for bulk storage
# CloudFlare CDN for fast delivery
# Best performance + cost efficiency
```