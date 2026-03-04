# Linux Commands - Essential for Server Management

## Navigation & Files

| Command | What it does | Example |
|---------|-------------|---------|
| `pwd` | Print current directory | `pwd` → `/opt/user-service` |
| `ls` | List files | `ls -la` (show all, with details) |
| `cd` | Change directory | `cd /opt/user-service` |
| `mkdir` | Create directory | `mkdir -p /opt/backups` (`-p` = create parents too) |
| `cp` | Copy file | `cp file.txt backup.txt` |
| `mv` | Move/rename file | `mv old.txt new.txt` |
| `rm` | Delete file | `rm file.txt` |
| `rm -rf` | Delete folder and everything inside | `rm -rf /opt/old-app` (DANGEROUS - no undo!) |
| `cat` | Show file contents | `cat /opt/user-service/.env` |
| `nano` | Edit file (simple editor) | `nano /etc/nginx/sites-available/user-api` |
| `head` | Show first N lines | `head -20 logfile.txt` |
| `tail` | Show last N lines | `tail -50 logfile.txt` |
| `tail -f` | Follow file (live updates) | `tail -f /var/log/nginx/error.log` |

> **nano shortcuts:**
> - `Ctrl+O` = Save
> - `Ctrl+X` = Exit
> - `Ctrl+W` = Search
> - `Ctrl+K` = Cut line
> - `Ctrl+U` = Paste line

---

## File Permissions

```bash
ls -la
# Output: -rwxr-xr-- 1 root root 1234 Jan 1 12:00 script.sh
#          ^^^
#          rwx = owner can read/write/execute
#             r-x = group can read/execute
#                r-- = others can only read
```

| Command | What it does | Example |
|---------|-------------|---------|
| `chmod +x` | Make file executable | `chmod +x backup.sh` |
| `chmod 755` | Owner: all, Others: read+execute | `chmod 755 /opt/user-service` |
| `chmod 600` | Owner only (private file) | `chmod 600 .env` (protect secrets!) |
| `chown` | Change file owner | `chown deploy:deploy /opt/user-service` |

---

## Searching

| Command | What it does | Example |
|---------|-------------|---------|
| `find` | Find files by name | `find / -name "pg_hba.conf"` |
| `grep` | Search text inside files | `grep "error" /var/log/nginx/error.log` |
| `grep -r` | Search recursively in folder | `grep -r "password" /opt/user-service/` |
| `grep -i` | Case-insensitive search | `grep -i "error" logfile.txt` |
| `which` | Find where a command is | `which nginx` → `/usr/sbin/nginx` |

---

## System Info

| Command | What it does | Example |
|---------|-------------|---------|
| `df -h` | Disk space usage | `df -h` (how full is the disk?) |
| `du -sh` | Folder size | `du -sh /opt/user-service` |
| `free -h` | RAM usage | `free -h` (how much memory used?) |
| `top` | Live process monitor | `top` (press `q` to quit) |
| `htop` | Better process monitor | `apt install htop && htop` |
| `uptime` | How long server is running | `uptime` → `up 5 days, 3:22` |
| `uname -a` | OS/kernel info | Shows Ubuntu version, architecture |
| `lsb_release -a` | Ubuntu version | `Ubuntu 24.04 LTS` |
| `whoami` | Current user | `whoami` → `root` |
| `hostname` | Server name | `hostname` |
| `ip addr` | Show IP addresses | `ip addr` or shorter: `ip a` |

---

## Process Management

| Command | What it does | Example |
|---------|-------------|---------|
| `ps aux` | List all running processes | `ps aux \| grep java` |
| `kill PID` | Stop a process gracefully | `kill 1234` |
| `kill -9 PID` | Force stop a process | `kill -9 1234` (last resort) |
| `lsof -i :8081` | What's using port 8081? | Shows which process uses a port |
| `ss -tlnp` | Show all listening ports | Like `netstat` but better |

> **Common use:** "My app won't start, port already in use"
> ```bash
> ss -tlnp | grep 8081     # Find what's using port 8081
> kill PID                  # Stop that process
> ```

---

## systemctl (Service Management)

`systemctl` controls services (programs that run in background).

| Command | What it does |
|---------|-------------|
| `systemctl start nginx` | Start Nginx now |
| `systemctl stop nginx` | Stop Nginx now |
| `systemctl restart nginx` | Stop + Start |
| `systemctl status nginx` | Check if running (shows logs too) |
| `systemctl enable nginx` | Auto-start on boot |
| `systemctl disable nginx` | Don't auto-start on boot |
| `systemctl is-enabled nginx` | Check if auto-start is set |
| `systemctl list-timers` | Show scheduled tasks (like Certbot renewal) |

> **Key insight:** `start` = run now. `enable` = run on boot. You usually need BOTH:
> ```bash
> systemctl start postgresql    # Start now
> systemctl enable postgresql   # Also start on every reboot
> ```

---

## Docker Commands

| Command | What it does |
|---------|-------------|
| `docker ps` | List running containers |
| `docker ps -a` | List ALL containers (including stopped) |
| `docker logs user-service` | Show container logs |
| `docker logs -f user-service` | Follow logs (live) |
| `docker logs --tail 100 user-service` | Last 100 lines |
| `docker stop user-service` | Stop container |
| `docker start user-service` | Start stopped container |
| `docker restart user-service` | Restart container |
| `docker rm -f user-service` | Force remove container |
| `docker build -t name .` | Build image from Dockerfile |
| `docker images` | List all images |
| `docker rmi image-name` | Delete an image |
| `docker exec -it user-service bash` | Open shell inside container |
| `docker stats` | Live resource usage (CPU, RAM) |
| `docker system prune -a` | Delete unused images/containers (frees disk) |

> **Common workflow (redeploy):**
> ```bash
> docker build --no-cache -t user-service .
> docker rm -f user-service
> docker run -d --name user-service ... user-service
> docker logs -f user-service    # Watch it start
> ```

---

## Networking

| Command | What it does | Example |
|---------|-------------|---------|
| `curl` | Make HTTP request | `curl http://localhost:8081/api/version` |
| `curl -I` | Show only headers | `curl -I https://user-api.nammaoorudelivary.in` |
| `ping` | Check if host is reachable | `ping google.com` |
| `ss -tlnp` | Show listening ports | See what's running on which port |
| `ip addr` | Show IP addresses | `ip addr show eth0` |
| `traceroute` | Show network path | `traceroute google.com` |

---

## User Management

| Command | What it does | Example |
|---------|-------------|---------|
| `adduser deploy` | Create new user | Interactive - asks for password |
| `usermod -aG sudo deploy` | Add user to sudo group | Can use `sudo` for admin commands |
| `su - deploy` | Switch to user | `su - deploy` |
| `passwd deploy` | Change user's password | Interactive |
| `id deploy` | Show user's groups | `uid=1001(deploy) gid=1001(deploy) groups=...` |

---

## SSH & File Transfer

| Command | What it does | Example |
|---------|-------------|---------|
| `ssh user@ip` | Connect to server | `ssh root@YOUR_SERVER_IP` |
| `scp file user@ip:/path` | Copy file TO server | `scp app.jar root@YOUR_SERVER_IP:/opt/` |
| `scp user@ip:/path file` | Copy file FROM server | `scp root@YOUR_SERVER_IP:/opt/backup.sql .` |
| `scp -r folder user@ip:/path` | Copy folder to server | `scp -r user-service/ root@IP:/opt/` |

> **Note:** `scp -r` does NOT copy hidden files (`.env`, `.gitignore`).
> Create those manually on the server.

---

## Logs & Troubleshooting

| Log File | What it contains |
|----------|-----------------|
| `/var/log/nginx/access.log` | All HTTP requests to Nginx |
| `/var/log/nginx/error.log` | Nginx errors |
| `/var/log/auth.log` | SSH login attempts (fail2ban watches this) |
| `/var/log/syslog` | General system logs |
| `/var/log/postgresql/` | Database logs |

```bash
# Live watch Nginx errors
tail -f /var/log/nginx/error.log

# Search for errors in syslog
grep "error" /var/log/syslog | tail -20

# Check failed SSH logins
grep "Failed password" /var/log/auth.log | tail -10

# Docker container logs
docker logs --tail 200 user-service
```

---

## Pipes & Redirection

| Symbol | What it does | Example |
|--------|-------------|---------|
| `\|` | Send output to next command | `ps aux \| grep java` |
| `>` | Write output to file (overwrite) | `echo "hello" > file.txt` |
| `>>` | Append output to file | `echo "line2" >> file.txt` |
| `2>/dev/null` | Hide error messages | `find / -name "x" 2>/dev/null` |
| `&&` | Run next command only if first succeeds | `apt update && apt upgrade` |
| `\|\|` | Run next command only if first fails | `docker stop app \|\| echo "not running"` |

---

## Cron (Scheduled Tasks)

```bash
crontab -e      # Edit cron jobs
crontab -l      # List cron jobs
```

**Cron format:**
```
┌───────── minute (0-59)
│ ┌─────── hour (0-23)
│ │ ┌───── day of month (1-31)
│ │ │ ┌─── month (1-12)
│ │ │ │ ┌─ day of week (0-6, Sun=0)
│ │ │ │ │
* * * * * command
```

**Examples:**
```bash
0 2 * * *    /opt/backups/backup-db.sh     # Daily at 2:00 AM
*/5 * * * *  curl http://localhost:8081/api/version  # Every 5 minutes
0 0 * * 0    docker system prune -af       # Weekly Sunday midnight (cleanup)
```

---

## Package Management (apt)

| Command | What it does |
|---------|-------------|
| `apt update` | Refresh package list (always run first) |
| `apt upgrade -y` | Update all installed packages |
| `apt install -y nginx` | Install a package |
| `apt remove nginx` | Remove a package |
| `apt autoremove` | Remove unused dependencies |
| `apt list --installed` | List all installed packages |

> **Always run `apt update` before `apt install`** to get latest versions.

---

## Most Used Combos for Your Server

```bash
# "Is my app running?"
docker ps && curl -s http://localhost:8081/api/version

# "What's using my RAM?"
free -h && docker stats --no-stream

# "Why did my app crash?"
docker logs --tail 100 user-service

# "Is anyone trying to hack my server?"
fail2ban-client status sshd
grep "Failed password" /var/log/auth.log | wc -l

# "How full is my disk?"
df -h

# "Clean up old Docker stuff"
docker system prune -a

# "Restart everything"
systemctl restart nginx
systemctl restart postgresql
docker restart user-service

# "Check everything is OK"
systemctl status nginx postgresql
docker ps
ufw status
fail2ban-client status sshd
```
