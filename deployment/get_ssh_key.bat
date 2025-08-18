@echo off
echo ==========================================
echo  Get SSH Private Key for GitHub Secrets
echo ==========================================
echo.

echo Your SSH Private Key (copy this to GitHub):
echo ==========================================
type "%USERPROFILE%\.ssh\hetzner_key"
echo ==========================================
echo.
echo Instructions:
echo 1. Copy the ENTIRE content above (including -----BEGIN/END-----)
echo 2. Go to GitHub → Your Repo → Settings → Secrets and Variables → Actions
echo 3. Add New Secret:
echo    - Name: HETZNER_SSH_KEY
echo    - Value: Paste the key content
echo.
echo Also add these secrets:
echo - HETZNER_HOST: 65.21.4.236  
echo - HETZNER_USER: root
echo.
pause