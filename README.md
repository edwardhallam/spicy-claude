# 🌶️ Spicy Claude

[![License](https://img.shields.io/github/license/edwardhallam/spicy-claude)](https://github.com/edwardhallam/spicy-claude/blob/main/LICENSE)
[![Version](https://img.shields.io/badge/version-1.0.0-blue)](https://github.com/edwardhallam/spicy-claude/releases)
[![Based on](https://img.shields.io/badge/based%20on-claude--code--webui%200.1.56-green)](https://github.com/sugyan/claude-code-webui)

> **Spicy Claude** - A web interface for Claude Code CLI with **dangerous mode** that bypasses all permission prompts

## ⚠️ **DANGER ZONE** ⚠️

This fork adds a **4th permission mode** called "Dangerous Mode" (☠️) that completely bypasses ALL permission checks. When enabled, Claude can:

- ✅ Execute ANY bash command without asking
- ✅ Read/write ANY file without prompting
- ✅ Install packages, modify system settings, delete files
- ⚠️ **DO THIS AT YOUR OWN RISK**

**Use Cases:**
- ✅ Trusted development environments
- ✅ Sandboxed containers
- ✅ Personal projects where speed > safety
- ❌ **NEVER use in production**
- ❌ **NEVER use with untrusted code**

**Based on:** [claude-code-webui v0.1.56](https://github.com/sugyan/claude-code-webui) by sugyan

[🎬 **View Demo**](https://github.com/user-attachments/assets/33e769b0-b17e-470b-8163-c71ef186b5af)

## 📱 Screenshots

<div align="center">

| Desktop Interface                                                                                                                                  | Mobile Experience                                                                                                                                |
| -------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------------------------------------------------------------------------------------ |
| <img src="https://github.com/sugyan/claude-code-webui/raw/main/docs/images/screenshot-desktop-basic-dark.png" alt="Desktop Interface" width="600"> | <img src="https://github.com/sugyan/claude-code-webui/raw/main/docs/images/screenshot-mobile-basic-dark.png" alt="Mobile Interface" width="250"> |
| _Chat-based coding interface with instant responses and ready input field_                                                                         | _Mobile-optimized chat experience with touch-friendly design_                                                                                    |

</div>

<details>
<summary><strong>💡 Light Theme Screenshots</strong></summary>

<div align="center">

| Desktop (Light)                                                                                                                                 | Mobile (Light)                                                                                                                                |
| ----------------------------------------------------------------------------------------------------------------------------------------------- | --------------------------------------------------------------------------------------------------------------------------------------------- |
| <img src="https://github.com/sugyan/claude-code-webui/raw/main/docs/images/screenshot-desktop-basic.png" alt="Desktop Light Theme" width="600"> | <img src="https://github.com/sugyan/claude-code-webui/raw/main/docs/images/screenshot-mobile-basic.png" alt="Mobile Light Theme" width="250"> |
| _Clean light interface for daytime coding sessions_                                                                                             | _iPhone SE optimized light theme interface_                                                                                                   |

</div>

</details>

<details>
<summary><strong>🔧 Advanced Features</strong></summary>

<div align="center">

| Desktop Permission Dialog                                                                                                                                   | Mobile Permission Dialog                                                                                                                                   |
| ----------------------------------------------------------------------------------------------------------------------------------------------------------- | ---------------------------------------------------------------------------------------------------------------------------------------------------------- |
| <img src="https://github.com/sugyan/claude-code-webui/raw/main/docs/images/screenshot-desktop-fileOperations-dark.png" alt="Permission Dialog" width="600"> | <img src="https://github.com/sugyan/claude-code-webui/raw/main/docs/images/screenshot-mobile-fileOperations-dark.png" alt="Mobile Permission" width="250"> |
| _Secure tool access with granular permission controls and clear approval workflow_                                                                          | _Touch-optimized permission interface for mobile devices_                                                                                                  |

</div>

</details>

---

## 📑 Table of Contents

- [✨ Why Claude Code Web UI?](#-why-claude-code-web-ui)
- [🚀 Quick Start](#-quick-start)
- [⚙️ CLI Options](#-cli-options)
- [🚨 Troubleshooting](#-troubleshooting)
- [🔧 Development](#-development)
- [🔒 Security Considerations](#-security-considerations)
- [📚 Documentation](#-documentation)
- [❓ FAQ](#-faq)
- [🤝 Contributing](#-contributing)
- [📄 License](#-license)

---

## ✨ Why Claude Code Web UI?

**Transform the way you interact with Claude Code**

Instead of being limited to command-line interactions, Claude Code Web UI brings you:

| CLI Experience                | Web UI Experience            |
| ----------------------------- | ---------------------------- |
| ⌨️ Terminal only              | 🌐 Any device with a browser |
| 📱 Desktop bound              | 📱 Mobile-friendly interface |
| 📝 Plain text output          | 🎨 Rich formatted responses  |
| 🗂️ Manual directory switching | 📁 Visual project selection  |

### 🎯 Key Features

- **☠️ DANGEROUS MODE** - 4th permission mode that bypasses ALL prompts (new in Spicy Claude!)
- **📋 Permission Mode Switching** - Toggle between normal, plan, accept edits, and dangerous modes
- **🔄 Real-time streaming responses** - Live Claude Code output in chat interface
- **📁 Project directory selection** - Visual project picker for context-aware sessions
- **💬 Conversation history** - Browse and restore previous chat sessions
- **🛠️ Tool permission management** - Granular control over Claude's tool access (or bypass entirely)
- **🎨 Dark/light theme support** - Automatic system preference detection
- **📱 Mobile-responsive design** - Touch-optimized interface including iOS Safari

---

## 🚀 Quick Start

Get up and running in under 2 minutes:

### Option 1: From Source (Recommended for Spicy Claude)

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

# Open browser to http://localhost:8080
```

### Option 2: Development Mode

```bash
# Backend (choose one)
cd backend && deno task dev    # Deno runtime
cd backend && npm run dev      # Node.js runtime

# Frontend (new terminal)
cd frontend && npm run dev

# Open browser to http://localhost:3000
```

### Prerequisites

- ✅ **Claude CLI** installed and authenticated ([Get it here](https://github.com/anthropics/claude-code))
- ✅ **Node.js >=20.0.0** (for npm installation) or **Deno** (for development)
- ✅ **Modern browser** (Chrome, Firefox, Safari, Edge)
- ✅ **dotenvx** (for development): [Install guide](https://dotenvx.com/docs/install)

---

## ☠️ How to Use Dangerous Mode

Dangerous Mode is the **primary feature** of Spicy Claude. Here's how to use it:

### Activating Dangerous Mode

**Method 1: Keyboard Shortcut** (Recommended)
1. Press `Ctrl+Shift+M` (or `Cmd+Shift+M` on Mac) **three times**
2. Mode cycles: 🔧 Normal → ⏸ Plan → ⏵⏵ Accept Edits → **☠️ DANGEROUS**

**Method 2: Click Mode Button**
1. Look for the mode button at the bottom of the chat input
2. Click **three times** to cycle to Dangerous Mode
3. Button text changes to: **"☠️ DANGEROUS MODE (bypass all)"**

### Visual Indicators

When Dangerous Mode is active, you'll see:

- ✅ **Red floating badge** in top-right: "🚨 DANGEROUS MODE - All permissions bypassed"
- ✅ **Red border** around message input box
- ✅ **Red text** on mode button
- ✅ **Console warning** (F12 Developer Tools): "⚠️ DANGEROUS MODE ENABLED"

### Deactivating Dangerous Mode

Press `Ctrl+Shift+M` once to cycle back to Normal Mode (🔧)

### What Dangerous Mode Does

When active, Claude will **execute ALL commands without asking**:

```
You: "Create a Python script that reads all files in /tmp and deletes .log files"

In Normal Mode:   ❓ Prompts: "Allow file read? Allow file delete?"
In Dangerous Mode: ✅ Executes immediately, no prompts
```

### Safety Recommendations

✅ **DO use in:**
- Personal development machines
- Sandboxed Docker containers
- Test environments
- Projects where you trust Claude completely

❌ **DON'T use in:**
- Production systems
- Shared computers
- When working with unfamiliar codebases
- When you're unsure what Claude will do

---

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

### Environment Variables

- `PORT` - Same as `--port`
- `DEBUG` - Same as `--debug`

### Examples

```bash
# Default (localhost:8080)
claude-code-webui

# Custom port
claude-code-webui --port 3000

# Bind to all interfaces (accessible from network)
claude-code-webui --host 0.0.0.0 --port 9000

# Enable debug mode
claude-code-webui --debug

# Custom Claude CLI path (for non-standard installations or aliases)
claude-code-webui --claude-path /path/to/claude

# Using environment variables
PORT=9000 DEBUG=true claude-code-webui
```

---

## 🚨 Troubleshooting

### Claude CLI Path Detection Issues

If you encounter "Claude Code process exited with code 1" or similar errors, this typically indicates Claude CLI path detection failure.

**Quick Solution:**

```bash
claude-code-webui --claude-path "$(which claude)"
```

**Common scenarios requiring explicit path specification:**

- **Node.js environment managers** (Volta, asdf, nvm, etc.)
- **Custom installation locations**
- **Shell aliases or wrapper scripts**

**Environment-specific commands:**

```bash
# For Volta users
claude-code-webui --claude-path "$(volta which claude)"

# For asdf users
claude-code-webui --claude-path "$(asdf which claude)"
```

**Native Binary Installation:**
Supported. Script path detection may fail and show warnings, but the application will work correctly as long as the Claude executable path is valid.

**Debug Mode:**
Use `--debug` flag for detailed error information:

```bash
claude-code-webui --debug
```

---

## 🔧 Development

### Setup

```bash
# Clone repository
git clone https://github.com/sugyan/claude-code-webui.git
cd claude-code-webui

# Install dotenvx (see prerequisites)

# Start backend (choose one)
cd backend
deno task dev    # Deno runtime
# OR
npm run dev      # Node.js runtime

# Start frontend (new terminal)
cd frontend
npm run dev
```

### Port Configuration

Create `.env` file in project root:

```bash
echo "PORT=9000" > .env
```

Run with dotenvx to use the `.env` file:

```bash
# Backend
cd backend
dotenvx run --env-file=../.env -- deno task dev    # Deno
dotenvx run --env-file=../.env -- npm run dev      # Node.js

# Frontend (uses Vite's built-in .env support)
cd frontend
npm run dev
```

Alternative: Set environment variables directly:

```bash
PORT=9000 deno task dev     # Deno
PORT=9000 npm run dev       # Node.js
```

---

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
claude-code-webui --port 8080

# Network access (trusted networks only)
claude-code-webui --port 8080 --host 0.0.0.0
```

**Never expose to public internet without proper security measures.**

---

## 📚 Documentation

For comprehensive technical documentation, see [CLAUDE.md](./CLAUDE.md) which covers:

- Architecture overview and design decisions
- Detailed development setup instructions
- API reference and message types

---

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
<summary><strong>Q: Can I deploy this to a server?</strong></summary>

While technically possible, it's designed for local use. If deploying remotely, ensure proper authentication and security measures.

</details>

<details>
<summary><strong>Q: How do I update?</strong></summary>

Download the latest binary from releases or pull the latest code for development mode.

</details>

<details>
<summary><strong>Q: What if Claude CLI isn't found or I get "process exited with code 1"?</strong></summary>

These errors typically indicate Claude CLI path detection issues. See the [Troubleshooting](#-troubleshooting) section for detailed solutions including environment manager workarounds and debug steps.

</details>

---

## 🔗 Related Projects

**Alternative Claude Code Web UIs:**

- **[siteboon/claudecodeui](https://github.com/siteboon/claudecodeui)**
  - A popular web-based Claude Code interface with mobile and remote management focus
  - Offers additional features for project and session management
  - Great alternative if you need more advanced remote access capabilities

Both projects aim to make Claude Code more accessible through web interfaces, each with their own strengths and approach.

---

## 🤝 Contributing

We welcome contributions! Please see our [development setup](#-development) and feel free to:

- 🐛 Report bugs
- ✨ Suggest features
- 📝 Improve documentation
- 🔧 Submit pull requests

**Fun fact**: This project is almost entirely written and committed by Claude Code itself! 🤖  
We'd love to see pull requests from your Claude Code sessions too :)

---

## 📄 License

MIT License - see [LICENSE](LICENSE) for details.

---

<div align="center">

**Made with ❤️ for the Claude Code community**

[⭐ Star this repo](https://github.com/sugyan/claude-code-webui) • [🐛 Report issues](https://github.com/sugyan/claude-code-webui/issues) • [💬 Discussions](https://github.com/sugyan/claude-code-webui/discussions)

</div>
