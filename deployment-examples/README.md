# Deployment Examples

This directory contains example configurations for deploying Spicy Claude in various environments.

## 📁 Files

### `docker-compose.yml`
Complete Docker Compose setup with backend and frontend services.

**Use for**:
- Quick deployment
- Isolated environments
- Easy scaling

**Start**: `docker-compose up -d`

---

### `systemd.service`
systemd service unit file for Linux systems.

**Use for**:
- Production Linux servers
- Ubuntu, Debian, CentOS, etc.
- Auto-start on boot

**Install**:
```bash
sudo cp systemd.service /etc/systemd/system/spicy-claude.service
sudo systemctl enable spicy-claude
sudo systemctl start spicy-claude
```

---

### `nginx.conf.example`
Nginx reverse proxy configuration with SSL and security headers.

**Use for**:
- Production deployments
- SSL/TLS encryption
- Authentication
- IP whitelisting

**Install**:
```bash
sudo cp nginx.conf.example /etc/nginx/sites-available/spicy-claude
sudo ln -s /etc/nginx/sites-available/spicy-claude /etc/nginx/sites-enabled/
sudo systemctl reload nginx
```

---

### `launchd.plist.example`
macOS LaunchAgent configuration.

**Use for**:
- macOS systems
- Local development
- Personal use

**Install**:
```bash
cp launchd.plist.example ~/Library/LaunchAgents/com.spicyclaude.service.plist
launchctl load ~/Library/LaunchAgents/com.spicyclaude.service.plist
```

---

## 🚀 Quick Start by Platform

### Docker
```bash
cd deployment-examples
docker-compose up -d
```

### Linux (systemd)
```bash
# 1. Update paths in systemd.service
# 2. Install service
sudo cp systemd.service /etc/systemd/system/spicy-claude.service
sudo systemctl daemon-reload
sudo systemctl enable --now spicy-claude
```

### macOS (LaunchAgent)
```bash
# 1. Update paths in launchd.plist.example
# 2. Copy to LaunchAgents
cp launchd.plist.example ~/Library/LaunchAgents/com.spicyclaude.service.plist
# 3. Load service
launchctl load ~/Library/LaunchAgents/com.spicyclaude.service.plist
```

### Production with Nginx
```bash
# 1. Setup backend service (systemd or docker)
# 2. Install nginx config
sudo cp nginx.conf.example /etc/nginx/sites-available/spicy-claude
sudo ln -s /etc/nginx/sites-available/spicy-claude /etc/nginx/sites-enabled/
# 3. Get SSL certificate
sudo certbot --nginx -d your-domain.com
# 4. Reload nginx
sudo systemctl reload nginx
```

---

## 📝 Customization Required

Before using these examples, you **must** customize:

1. **Paths**: Update all `/path/to/spicy-claude` references
2. **Usernames**: Replace `YOUR_USERNAME` with your actual username
3. **Domains**: Change `spicy-claude.example.com` to your domain
4. **Ports**: Adjust if 8080/3000 are already in use
5. **Node paths**: Verify node location with `which node`

---

## 🔒 Security Notes

### Dangerous Mode Warning
Spicy Claude's Dangerous Mode bypasses all permission prompts. Only use in:
- ✅ Isolated/sandboxed environments
- ✅ Trusted networks
- ✅ Personal development setups

**Never**:
- ❌ Expose to public internet
- ❌ Use in shared environments
- ❌ Use with untrusted code

### Production Deployment
For production, consider:
- SSL/TLS encryption (use nginx example)
- Basic authentication or OAuth
- IP whitelisting
- VPN access
- Firewall rules
- Regular updates

---

## 📚 Additional Resources

- [Deployment Guide](../docs/DEPLOYMENT-PUBLIC.md) - Complete deployment documentation
- [Contributing Guide](../docs/CONTRIBUTING.md) - How to contribute
- [Main README](../README.md) - Project overview

---

## 🆘 Troubleshooting

### Service won't start
```bash
# Check logs
# systemd:
sudo journalctl -u spicy-claude -f

# macOS LaunchAgent:
tail -f ~/Library/Logs/spicy-claude/stderr.log

# Docker:
docker-compose logs -f
```

### Port already in use
```bash
# Find what's using the port
lsof -i :8080

# Kill the process or change port in config
```

### Permission denied
```bash
# systemd: Check user/group in service file
# macOS: Check file permissions
chmod 644 ~/Library/LaunchAgents/com.spicyclaude.service.plist
```

### Claude CLI not found
```bash
# Install Claude CLI
npm install -g @anthropic-ai/claude-code

# Verify installation
which claude
claude --version

# Update PATH in service config
```

---

## 💡 Tips

- **Test locally first**: Run manually before setting up as service
- **Check logs**: Always check logs when troubleshooting
- **Security**: Use firewall and VPN for remote access
- **Monitoring**: Set up health checks and alerts
- **Backups**: Keep backups of working configurations

---

**Need help?** Open an issue at https://github.com/edwardhallam/spicy-claude/issues
