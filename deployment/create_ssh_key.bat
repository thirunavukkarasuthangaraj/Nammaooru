@echo off
echo Creating SSH Key for Hetzner...
echo.

REM Check if .ssh directory exists
if not exist "%USERPROFILE%\.ssh" (
    mkdir "%USERPROFILE%\.ssh"
    echo Created .ssh directory
)

REM Generate SSH key
ssh-keygen -t rsa -b 4096 -f "%USERPROFILE%\.ssh\hetzner_key" -C "your-email@example.com"

echo.
echo SSH Key created successfully!
echo.
echo Your PUBLIC key (copy this to Hetzner):
type "%USERPROFILE%\.ssh\hetzner_key.pub"
echo.
echo Your PRIVATE key location: %USERPROFILE%\.ssh\hetzner_key
echo Keep this private key safe!
pause