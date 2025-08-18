# 🚀 Hetzner Deployment - Complete Guide

## Prerequisites
- Hetzner Cloud account
- Credit card or PayPal for payment
- Windows Terminal or Command Prompt

## Step-by-Step Process

### 1️⃣ Create Server in Hetzner Console
1. Login to https://console.hetzner.cloud
2. Click **"New Project"** → Name: `shop-management`
3. Click **"Add Server"**:
   - Location: **Nuremberg** (cheapest)
   - Image: **Ubuntu 22.04**
   - Type: **CX11** (€3.29/month)
   - Name: `shop-server`
4. Click **"Create & Buy Now"**
5. Copy the **Server IP** shown

### 2️⃣ Create SSH Key (First Time Only)
```cmd
deployment\create_ssh_key.bat
```
- Press Enter for default location
- Set a password (or leave empty)
- Copy the PUBLIC KEY shown
- Go back to Hetzner → Add this SSH key

### 3️⃣ Connect to Your Server
```cmd
deployment\connect_to_hetzner.bat
```
Enter your server IP when prompted

### 4️⃣ Setup Server (Run on Server)
Once connected to server, run:
```bash
# Download and run setup script
wget https://raw.githubusercontent.com/yourusername/shop-management/main/deployment/setup_server.sh
chmod +x setup_server.sh
./setup_server.sh
```

### 5️⃣ Upload Your Application
From your local machine:
```cmd
deployment\upload_to_hetzner.bat
```

### 6️⃣ Deploy Application (Run on Server)
```bash
cd /opt/shop-management
chmod +x deploy.sh
./deploy.sh
```

### 7️⃣ Access Your Application
Open browser and go to:
```
http://YOUR_SERVER_IP
```

## 🔧 Useful Commands

### Check Docker Status
```bash
docker ps
docker logs shop-backend
docker logs shop-frontend
```

### Restart Services
```bash
cd /opt/shop-management
docker-compose restart
```

### View Logs
```bash
docker logs -f shop-backend
docker logs -f shop-frontend
```

### Update Application
```bash
cd /opt/shop-management
git pull
docker-compose down
docker-compose up -d --build
```

## 🌐 Setup Custom Domain (Optional)

1. Point your domain to server IP in DNS settings
2. Run on server:
```bash
# Install SSL certificate
certbot --nginx -d yourdomain.com -d www.yourdomain.com
```

## 💰 Costs
- **Server**: €3.29/month (CX11)
- **Traffic**: 20TB included
- **Backup**: €0.60/month (optional)
- **Total**: ~€4/month

## 🆘 Troubleshooting

### Cannot connect via SSH
- Check firewall settings in Hetzner
- Verify SSH key is added correctly

### Docker not starting
```bash
systemctl status docker
systemctl restart docker
```

### Database connection issues
```bash
docker exec -it shop-postgres psql -U postgres
# Check tables: \dt
# Exit: \q
```

## 📞 Support
- Hetzner Support: https://console.hetzner.cloud/support
- Documentation: https://docs.hetzner.cloud/