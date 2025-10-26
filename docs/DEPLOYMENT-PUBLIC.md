# Spicy Claude - Deployment Guide

Complete guide for deploying Spicy Claude in production environments.

## 📋 Table of Contents

- [Quick Start](#quick-start)
- [Prerequisites](#prerequisites)
- [Deployment Options](#deployment-options)
  - [Docker Deployment](#docker-deployment)
  - [systemd (Linux)](#systemd-linux)
  - [LaunchAgent (macOS)](#launchagent-macos)
  - [PM2 (Node.js)](#pm2-nodejs)
- [Network Configuration](#network-configuration)
- [Monitoring](#monitoring)
- [Security Considerations](#security-considerations)
- [Troubleshooting](#troubleshooting)

## Quick Start

```bash
# Clone the repository
git clone https://github.com/edwardhallam/spicy-claude.git
cd spicy-claude

# Build backend
cd backend
npm install
npm run build

# Start backend (port 8080)
node dist/cli/node.js --port 8080

# In another terminal, start frontend (port 3000)
cd frontend
npm install
npm run dev
```

Access the application at http://localhost:3000

## Prerequisites

- **Node.js**: v20.0.0 or higher
- **npm**: Latest version
- **Claude CLI**: Installed and configured (`npm install -g @anthropic-ai/claude-code`)
- **Git**: For cloning and updates

### Verify Prerequisites

```bash
node --version  # Should be v20+
npm --version
claude --version  # Should show Claude Code CLI version
```

## Deployment Options

### Docker Deployment

The easiest way to deploy Spicy Claude with all dependencies included.

**See**: `deployment-examples/docker-compose.yml` for complete Docker setup

```bash
# Using docker-compose
docker-compose up -d

# Or build custom image
docker build -t spicy-claude .
docker run -p 3000:3000 -p 8080:8080 spicy-claude
```

**Benefits**:
- ✅ Isolated environment
- ✅ Easy scaling
- ✅ Consistent deployments
- ✅ Built-in health checks

### systemd (Linux)

For production Linux servers using systemd.

**See**: `deployment-examples/systemd.service` for complete systemd configuration

```bash
# 1. Copy service file
sudo cp deployment-examples/systemd.service /etc/systemd/system/spicy-claude.service

# 2. Edit paths in service file
sudo nano /etc/systemd/system/spicy-claude.service

# 3. Enable and start
sudo systemctl enable spicy-claude
sudo systemctl start spicy-claude
sudo systemctl status spicy-claude
```

**Management Commands**:
```bash
# Start/Stop/Restart
sudo systemctl start spicy-claude
sudo systemctl stop spicy-claude
sudo systemctl restart spicy-claude

# View logs
sudo journalctl -u spicy-claude -f

# Check status
sudo systemctl status spicy-claude
```

### LaunchAgent (macOS)

For macOS systems using LaunchAgent.

**See**: `deployment-examples/launchd.plist.example` for complete plist configuration

```bash
# 1. Copy and customize plist
cp deployment-examples/launchd.plist.example ~/Library/LaunchAgents/com.spicyclaude.plist

# 2. Edit paths in plist
nano ~/Library/LaunchAgents/com.spicyclaude.plist

# 3. Load LaunchAgent
launchctl load ~/Library/LaunchAgents/com.spicyclaude.plist

# 4. Check status
launchctl list | grep spicyclaude
```

**Management Commands**:
```bash
# Start/Stop
launchctl load ~/Library/LaunchAgents/com.spicyclaude.plist
launchctl unload ~/Library/LaunchAgents/com.spicyclaude.plist

# View logs (update path to your log location)
tail -f ~/Library/Logs/spicy-claude/stdout.log
tail -f ~/Library/Logs/spicy-claude/stderr.log
```

### PM2 (Node.js)

For Node.js-based deployments using PM2 process manager.

```bash
# Install PM2
npm install -g pm2

# Start Spicy Claude
pm2 start backend/dist/cli/node.js --name spicy-claude -- --port 8080

# Save PM2 configuration
pm2 save

# Setup PM2 to start on boot
pm2 startup
```

**Management Commands**:
```bash
# Status
pm2 list
pm2 show spicy-claude

# Logs
pm2 logs spicy-claude

# Restart
pm2 restart spicy-claude

# Stop
pm2 stop spicy-claude
```

## Network Configuration

### Local Access Only

Bind to localhost for security:

```bash
node dist/cli/node.js --port 8080 --host 127.0.0.1
```

Access: http://localhost:8080

### Local Network Access

Bind to all interfaces to allow access from other devices:

```bash
node dist/cli/node.js --port 8080 --host 0.0.0.0
```

Access from any device: http://YOUR_IP:8080

**Security Notes**:
- ⚠️ No authentication is built-in
- ⚠️ Only use on trusted networks
- ⚠️ Consider adding reverse proxy with authentication

### Reverse Proxy (nginx)

For production deployments with SSL and authentication.

**See**: `deployment-examples/nginx.conf.example` for complete nginx configuration

```nginx
server {
    listen 80;
    server_name spicy-claude.example.com;

    location / {
        proxy_pass http://localhost:8080;
        proxy_http_version 1.1;
        proxy_set_header Upgrade $http_upgrade;
        proxy_set_header Connection 'upgrade';
        proxy_set_header Host $host;
        proxy_cache_bypass $http_upgrade;
    }
}
```

**Add SSL with Let's Encrypt**:
```bash
sudo apt install certbot python3-certbot-nginx
sudo certbot --nginx -d spicy-claude.example.com
```

## Monitoring

### Health Checks

```bash
# Simple health check
curl -I http://localhost:8080/

# Expected: HTTP 200 OK
```

### Prometheus Monitoring

Example Prometheus scrape configuration:

```yaml
scrape_configs:
  - job_name: 'spicy-claude'
    static_configs:
      - targets: ['localhost:8080']
```

### Log Monitoring

**systemd logs**:
```bash
sudo journalctl -u spicy-claude -f
```

**LaunchAgent logs**:
```bash
tail -f ~/Library/Logs/spicy-claude/stdout.log
```

**PM2 logs**:
```bash
pm2 logs spicy-claude
```

## Security Considerations

### ⚠️ Dangerous Mode Warning

Spicy Claude includes a **Dangerous Mode** that bypasses ALL permission prompts. This is extremely powerful but potentially dangerous.

**Recommendations**:
1. ✅ Use in sandboxed/containerized environments
2. ✅ Deploy on isolated networks
3. ✅ Never expose to public internet
4. ❌ Never use with untrusted code
5. ❌ Never use in shared environments

### Network Security

- **Firewall**: Restrict access to trusted IPs
- **VPN**: Access through VPN for remote access
- **Authentication**: Add authentication via reverse proxy
- **SSL/TLS**: Use HTTPS in production

### Environment Variables

Store sensitive configuration in environment variables:

```bash
# Create .env file
cp .env.example .env

# Edit with your values
nano .env
```

**Never commit `.env` to version control!**

## Troubleshooting

### Service Won't Start

```bash
# Check if port is already in use
lsof -i :8080

# Check logs
# systemd:
sudo journalctl -u spicy-claude -n 50

# LaunchAgent:
tail -50 ~/Library/Logs/spicy-claude/stderr.log

# PM2:
pm2 logs spicy-claude --lines 50
```

### Build Failures

```bash
# Clean install
cd backend
rm -rf node_modules package-lock.json
npm install
npm run build
```

### Permission Denied Errors

```bash
# Make sure Claude CLI is accessible
which claude
claude --version

# Check PATH in service configuration
# systemd: Check Environment= in service file
# LaunchAgent: Check EnvironmentVariables in plist
# PM2: Check PATH in pm2 env
```

### Can't Access from Other Devices

```bash
# Verify binding to 0.0.0.0
ps aux | grep node

# Check firewall
# Linux:
sudo ufw status
sudo ufw allow 8080

# macOS:
# System Settings → Network → Firewall
```

### High Memory Usage

Claude Code can use significant memory. Increase limits if needed:

```bash
# PM2: Increase max memory
pm2 start backend/dist/cli/node.js --max-memory-restart 2G

# systemd: Add to service file
[Service]
MemoryLimit=2G
```

## Updates

### Manual Update

```bash
# Stop service
sudo systemctl stop spicy-claude  # Or your service manager

# Pull latest changes
git pull origin main

# Rebuild
cd backend
npm install
npm run build

# Start service
sudo systemctl start spicy-claude
```

### Automated Updates

For automated updates, consider:
- GitHub Actions for CI/CD
- Watchtower for Docker deployments
- Custom scripts with proper testing

**Recommendation**: Always test updates in a staging environment first!

## Performance Tuning

### Backend Optimization

```bash
# Increase Node.js memory
node --max-old-space-size=4096 dist/cli/node.js

# Enable production mode
NODE_ENV=production node dist/cli/node.js
```

### Frontend Optimization

```bash
# Build optimized production bundle
cd frontend
npm run build

# Serve with nginx or apache
```

## Getting Help

- 📚 [README.md](../README.md) - Main documentation
- 🐛 [GitHub Issues](https://github.com/edwardhallam/spicy-claude/issues)
- 💬 [Discussions](https://github.com/edwardhallam/spicy-claude/discussions)

---

**Remember**: Spicy Claude's Dangerous Mode is powerful. Use responsibly and only in secure, controlled environments.
