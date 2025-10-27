# 🌶️ Spicy Claude

[![License](https://img.shields.io/github/license/edwardhallam/spicy-claude)](https://github.com/edwardhallam/spicy-claude/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/edwardhallam/spicy-claude/releases)

> **Spicy Claude** - A web interface for Claude Code CLI with a redesigned chat-like interface

**Initial version based on [claude-code-webui v0.1.56](https://github.com/sugyan/claude-code-webui) by sugyan**

## ⚡ What Makes Spicy Claude Different

### 🎯 Key Features

- **🎨 Redesigned UI** - New chat-like interface in development (access via `/prototype` route)
- **🔄 Dual Interface** - Toggle between classic and redesigned UI
- **📱 Mobile-Responsive** - Touch-optimized interface for all devices
- **🌐 Local Network Access** - Accessible from any device on your network
- **🛠️ Production Ready** - LaunchAgent deployment with comprehensive monitoring
- **✅ Well-Tested** - 20+ Playwright E2E tests ensuring reliability

## 🚀 Quick Start

### Prerequisites

- ✅ **Claude CLI** installed and authenticated ([Get it here](https://github.com/anthropics/claude-code))
- ✅ **Node.js >=20.0.0**
- ✅ **Modern browser** (Chrome, Firefox, Safari, Edge)

### Installation

```bash
# Clone the repository
git clone https://github.com/edwardhallam/spicy-claude.git
cd spicy-claude

# Install dependencies
cd frontend && npm install && cd ..
cd backend && npm install && cd ..

# Build production version
cd frontend && npm run build && cd ..
cd backend && npm run build && cd ..

# Start the server
cd backend && node dist/cli/node.js

# Access the application:
# - From the host machine: http://localhost:8080
# - From other devices on your network: http://<host-ip>:8080
```

### Development Mode

```bash
# Backend (choose one)
cd backend && npm run dev      # Node.js runtime
cd backend && deno task dev    # Deno runtime

# Frontend (new terminal)
cd frontend && npm run dev

# Access: http://localhost:3000
```

## 🎨 Redesigned UI (In Development)

Spicy Claude includes a redesigned chat-like interface accessible at `/prototype` (development mode only).

**Current Status**: Foundation implemented (Story #1 complete)
- Basic route and navigation
- Theme support (light/dark)
- Settings integration
- Responsive design

**Roadmap**: See [PROTOTYPE-BACKLOG.md](docs/PROTOTYPE-BACKLOG.md) for upcoming features:
- Project management sidebar
- Session/chat management
- Streaming responses in new UI
- Advanced session features (pin, archive, search)

**Access**: http://localhost:3000/prototype (development builds only)

**Toggle**: Use "Back to Classic" link in prototype or navigate to `/` for classic interface

## 📚 Documentation

### Production Deployment

- **[Deployment Guide](docs/DEPLOYMENT.md)** - Installation, service management, LaunchAgent configuration
- **[Operations Guide](docs/OPERATIONS.md)** - Day-to-day tasks, troubleshooting, maintenance
- **[Monitoring](docs/MONITORING.md)** - Prometheus alerts, Grafana dashboards, Slack notifications
- **[Updates](docs/UPDATES.md)** - Manual-only update policy and procedures

### Development

- **[CLAUDE.md](CLAUDE.md)** - Comprehensive technical documentation
- **[Testing Guide](tests/README.md)** - Full test suite documentation (20+ E2E tests)
- **[Test Status](tests/TESTING-STATUS.md)** - Current testing status and quick reference

### Quick Commands

```bash
# Service Management (Production)
cd deployment && ./status.sh   # Check service status
cd deployment && ./restart.sh  # Restart service

# Development
make dev-backend               # Start backend
make dev-frontend             # Start frontend
make check                    # Run all quality checks

# Testing
npm run test:ui               # Run all E2E tests (~15 min)
npm run test:report           # View HTML test report
make test                     # Run unit tests (frontend + backend)

# Logs (Production)
tail -f ~/Library/Logs/spicy-claude/stdout.log
```

## ⚙️ CLI Options

The backend server supports the following command-line options:

| Option                 | Description                                               | Default     |
| ---------------------- | --------------------------------------------------------- | ----------- |
| `-p, --port <port>`    | Port to listen on                                         | 8080        |
| `--host <host>`        | Host address to bind to (use 0.0.0.0 for all interfaces)  | 127.0.0.1   |
| `--claude-path <path>` | Path to claude executable (overrides automatic detection) | Auto-detect |
| `-d, --debug`          | Enable debug mode                                         | false       |
| `-h, --help`           | Show help message                                         | -           |
| `-v, --version`        | Show version                                              | -           |

### Examples

```bash
# Default (localhost:8080)
node dist/cli/node.js

# Custom port
node dist/cli/node.js --port 3000

# Bind to all interfaces (accessible from network)
node dist/cli/node.js --host 0.0.0.0 --port 9000

# Enable debug mode
node dist/cli/node.js --debug

# Custom Claude CLI path
node dist/cli/node.js --claude-path /path/to/claude
```

## 🌐 Network Access

By default, Spicy Claude is configured to be accessible from any device on your local network.

### Accessing the Application

- **From the host machine**: http://localhost:3002
- **From other devices**: http://<host-machine-ip>:3002
  - To find your machine's IP: `ifconfig | grep "inet " | grep -v 127.0.0.1`
  - Example: http://192.168.1.50:3002

### Security Considerations

- Any device on your local network can access the application
- NOT accessible from the internet (with standard home network setup)
- No authentication is currently implemented
- Intended for trusted local network use only

To restrict access to localhost only:
1. Edit the plist: `~/Library/LaunchAgents/com.homelab.spicy-claude.plist`
2. Change `<string>0.0.0.0</string>` to `<string>127.0.0.1</string>`
3. Restart: `cd deployment && ./restart.sh`

## 🔧 Development

### Setup

```bash
# Clone repository
git clone https://github.com/edwardhallam/spicy-claude.git
cd spicy-claude

# Install dependencies
cd frontend && npm install && cd ..
cd backend && npm install && cd ..

# Start development servers
make dev-backend    # Terminal 1
make dev-frontend   # Terminal 2
```

### Port Configuration

Create `.env` file in project root:

```bash
PORT=9000
```

### Network Configuration

The backend supports a `--host` parameter to control network binding:
- `--host 127.0.0.1` - Localhost only (development default)
- `--host 0.0.0.0` - All interfaces (production default)

Development mode binds to localhost by default. To test network access during development:
```bash
cd backend
npm run dev -- --host 0.0.0.0
```

### Quality Checks

```bash
make check         # Run all checks (lint, typecheck, format, tests)
make format        # Format code with Prettier
make lint          # Lint code with ESLint
make typecheck     # Check TypeScript types
make test          # Run unit tests
```

### Pre-commit Hooks

Spicy Claude uses Lefthook to run quality checks before every commit:

```bash
# Install Lefthook
brew install lefthook  # macOS

# Install hooks
lefthook install

# Verify installation
lefthook run pre-commit
```

## 🧪 Testing

### E2E Tests (Playwright)

20+ comprehensive E2E tests covering:
- Permission dialogs and modes
- Chat interface and streaming
- Settings and theme switching
- Responsive design and mobile
- Keyboard accessibility

```bash
# Run all E2E tests
npm run test:ui

# Run specific test suite
npm run test:ui -- tests/e2e/prototype/  # Prototype tests

# View test report
npm run test:report
```

### Unit Tests

```bash
# Frontend unit tests
cd frontend && npm test

# Backend unit tests
cd backend && npm test

# Both (via Makefile)
make test
```

## 🔒 Security Considerations

**Important**: This tool executes Claude CLI locally and provides web access to it.

### ✅ Safe Usage Patterns

- **🏠 Local development**: Default localhost access
- **📱 Personal network**: LAN access from your own devices

### ⚠️ Security Notes

- **No authentication**: Currently no built-in auth mechanism
- **System access**: Claude can read/write files in selected projects
- **Network exposure**: Configurable but requires careful consideration

### 🛡️ Best Practices

```bash
# Local only (recommended)
node dist/cli/node.js --port 8080

# Network access (trusted networks only)
node dist/cli/node.js --port 8080 --host 0.0.0.0
```

**Never expose to public internet without proper security measures.**

## 🤝 Contributing

We welcome contributions! Please see our [development setup](#-development) and feel free to:

- 🐛 Report bugs
- ✨ Suggest features
- 📝 Improve documentation
- 🔧 Submit pull requests

**Workflow**:
1. Create feature branch: `git checkout -b feature/name`
2. Make changes (Lefthook runs checks on commit)
3. Push and create PR
4. GitHub Actions runs quality checks
5. Merge when checks pass

For detailed contribution guidelines, see [CLAUDE.md](CLAUDE.md).

## ❓ FAQ

<details>
<summary><strong>Q: Do I need Claude API access?</strong></summary>

Yes, you need the Claude CLI tool installed and authenticated. The web UI is a frontend for the existing Claude CLI.

</details>

<details>
<summary><strong>Q: Can I use this on mobile?</strong></summary>

Yes! The web interface is fully responsive and works great on mobile devices when connected to your local network.

</details>

<details>
<summary><strong>Q: Is my code safe?</strong></summary>

Yes, everything runs locally. No data is sent to external servers except Claude's normal API calls through the CLI.

</details>

<details>
<summary><strong>Q: How do I update?</strong></summary>

Pull the latest code from the repository:

```bash
git pull origin main
cd frontend && npm install && npm run build && cd ..
cd backend && npm install && npm run build && cd ..
cd deployment && ./restart.sh
```

See [docs/UPDATES.md](docs/UPDATES.md) for detailed update procedures.

</details>

<details>
<summary><strong>Q: What's the difference between this and claude-code-webui?</strong></summary>

Spicy Claude adds:
- Redesigned chat-like interface (in development)
- Production deployment setup (LaunchAgent)
- Comprehensive E2E test suite (20+ tests)
- Enhanced documentation and monitoring

</details>

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

## 🙏 Acknowledgments

Initial version based on [claude-code-webui v0.1.56](https://github.com/sugyan/claude-code-webui) by [@sugyan](https://github.com/sugyan).

---

<div align="center">

**Made with ❤️ for the Claude Code community**

[⭐ Star this repo](https://github.com/edwardhallam/spicy-claude) • [🐛 Report issues](https://github.com/edwardhallam/spicy-claude/issues) • [💬 Discussions](https://github.com/edwardhallam/spicy-claude/discussions)

</div>
