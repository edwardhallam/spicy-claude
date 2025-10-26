# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Spicy Claude

A web-based interface for Claude Code CLI with a **Dangerous Mode** that bypasses all permission prompts. This is a fork of claude-code-webui v0.1.56 by sugyan.

## Code Quality

Automated quality checks ensure consistent code standards:

- **Lefthook**: Git hooks manager running `make check` before commits
- **Quality Commands**: `make check` runs all quality checks manually
- **CI/CD**: GitHub Actions runs quality checks on every push

### Setup for New Contributors

```bash
# Install Lefthook
brew install lefthook  # macOS
# Or download from https://github.com/evilmartians/lefthook/releases

# Install and verify hooks
lefthook install
lefthook run pre-commit
```

## Architecture

### Backend (Deno/Node.js)

- **Location**: `backend/` | **Port**: 8080 (configurable) | **Host**: 127.0.0.1 default, 0.0.0.0 in production
- **Technology**: TypeScript + Hono framework with runtime abstraction
- **Purpose**: Executes `claude` commands and streams JSON responses

**Key Features**: Runtime abstraction, modular architecture, structured logging, universal Claude CLI path detection, session continuity, single binary distribution, comprehensive testing.

**API Endpoints**:

- `GET /api/projects` - List available project directories
- `POST /api/chat` - Chat messages with streaming responses (`{ message, sessionId?, requestId, allowedTools?, workingDirectory? }`)
- `POST /api/abort/:requestId` - Abort ongoing requests
- `GET /api/projects/:encodedProjectName/histories` - Conversation histories
- `GET /api/projects/:encodedProjectName/histories/:sessionId` - Specific conversation history

### Frontend (React)

- **Location**: `frontend/` | **Port**: 3000 (configurable)
- **Technology**: Vite + React + SWC + TypeScript + TailwindCSS + React Router
- **Purpose**: Project selection and chat interface with streaming responses

**Key Features**: Project directory selection, routing system, conversation history, demo mode, real-time streaming, theme toggle, auto-scroll, accessibility features, modular hook architecture, request abort functionality, permission dialog handling, configurable Enter key behavior.

### Shared Types

**Location**: `shared/` - TypeScript type definitions shared between backend and frontend

**Key Types**: `StreamResponse`, `ChatRequest`, `AbortRequest`, `ProjectInfo`, `ConversationSummary`, `ConversationHistory`

## Dangerous Mode (Spicy Claude's Key Feature)

**4th permission mode** that completely bypasses ALL permission checks. When enabled, Claude executes ANY command without prompting.

**Activation**: Press `Ctrl+Shift+M` (or `Cmd+Shift+M` on Mac) **three times** to cycle to Dangerous Mode. Visual indicators include red floating badge, red border around input, red button text, and console warning.

**Implementation**:
- Frontend: `usePermissionMode` hook tracks mode state, `PlanPermissionInputPanel` component provides UI
- Backend: `allowedTools` parameter in chat requests - when set to `["*"]`, all tools are pre-allowed
- Session persistence: Mode state saved per conversation

**Use Cases**: Trusted development environments, sandboxed containers, personal projects. **Never use in production or with untrusted code.**

## Claude Command Integration

Backend uses Claude Code SDK executing commands with:

- `--output-format stream-json` - Streaming JSON responses
- `--verbose` - Detailed execution information
- `-p <message>` - Prompt mode with user message

**Message Types**: System (initialization), Assistant (response content), Result (execution summary)

### Claude CLI Path Detection

Universal detection supporting npm, pnpm, asdf, yarn installations:

1. Auto-discovery in system PATH
2. Script path tracing with temporary node wrapper
3. Version validation with `claude --version`
4. Fallback handling with logging

**Implementation**: `backend/cli/validation.ts` with `detectClaudeCliPath()`, `validateClaudeCli()`

## Session Continuity

Conversation continuity using Claude Code SDK's session management:

1. First message starts new Claude session
2. Frontend extracts `session_id` from SDK messages
3. Subsequent messages include `session_id` for context
4. Backend passes `session_id` to SDK via `options.resume`

## MCP Integration (Model Context Protocol)

Playwright MCP server integration for automated browser testing and demo verification.

### Configuration

```json
{
  "mcpServers": {
    "playwright": {
      "type": "stdio",
      "command": "npx",
      "args": ["@playwright/mcp@latest"]
    }
  }
}
```

### Usage

1. Say "**playwright mcp**" in requests for browser automation
2. Visible Chrome browser window opens for interaction
3. Manual authentication supported through browser window

**Available Tools**: Navigation, interaction, screenshots, content access, file operations, tab management, dialog handling

## Development

### Prerequisites

- Backend: Deno or Node.js (20.0.0+)
- Frontend: Node.js
- Claude CLI tool installed
- dotenvx: `npm install -g @dotenvx/dotenvx`

### Port Configuration

Create `.env` file in project root:

```bash
PORT=9000
```

### Running the Application

```bash
# Backend
cd backend
deno task dev        # Deno
npm run dev          # Node.js
# Add --debug for debug logging

# Frontend
cd frontend
npm run dev
```

**Access**: Frontend http://localhost:3000, Backend http://localhost:8080

### Project Structure

```
├── backend/              # Server with runtime abstraction
│   ├── cli/             # Entry points (deno.ts, node.ts, args.ts, validation.ts)
│   ├── runtime/         # Runtime abstraction (types.ts, deno.ts, node.ts)
│   ├── handlers/        # API handlers (chat.ts, projects.ts, histories.ts, etc.)
│   ├── history/         # History processing utilities
│   ├── middleware/      # Middleware modules
│   ├── utils/           # Utility modules (logger.ts)
│   └── scripts/         # Build and packaging scripts
├── frontend/            # React application
│   ├── src/
│   │   ├── config/      # API configuration
│   │   ├── utils/       # Utilities and constants
│   │   ├── hooks/       # Custom hooks (streaming, theme, chat state, etc.)
│   │   ├── components/  # UI components (chat, messages, dialogs, etc.)
│   │   ├── types/       # Type definitions
│   │   └── contexts/    # React contexts
├── shared/              # Shared TypeScript types
└── CLAUDE.md           # Technical documentation
```

## Key Design Decisions

1. **Runtime Abstraction**: Platform-agnostic business logic with minimal Runtime interface
2. **Universal CLI Detection**: Tracing-based approach for all package managers
3. **Raw JSON Streaming**: Unmodified Claude responses for frontend flexibility
4. **Modular Architecture**: Specialized hooks and components for maintainability
5. **TypeScript Throughout**: Consistent type safety across all components
6. **Project Directory Selection**: User-chosen working directories for contextual file access
7. **Network Accessibility**: Production configured for local network access (0.0.0.0) while development defaults to localhost for security

## Claude Code SDK Types Reference

**SDK Types**: `frontend/node_modules/@anthropic-ai/claude-code/sdk.d.ts`

```typescript
// Type extraction
const systemMsg = sdkMessage as Extract<SDKMessage, { type: "system" }>;
const assistantMsg = sdkMessage as Extract<SDKMessage, { type: "assistant" }>;

// Content access patterns
for (const item of assistantMsg.message.content) {
  if (item.type === "text") {
    const text = (item as { text: string }).text;
  }
}

// System message (direct access, no nesting)
console.log(systemMsg.cwd);
```

**Key Points**: System fields directly on object, Assistant content nested under `message.content`, Result has `subtype` field

## Testing and Deployment

### Automated Testing

**Frontend Unit Tests**: Vitest + Testing Library (`make test-frontend`)
**Backend Unit Tests**: Deno test runner (`make test-backend`)
**E2E UI Tests**: 20 Playwright tests covering permissions, bypass mode, chat functionality
  - Run all tests: `npm run test:ui` (~15 minutes)
  - Bypass mode only: `npm run test:bypass`
  - View report: `npm run test:report`
  - See `tests/README.md` and `tests/TESTING-STATUS.md` for details

**Unified**: `make test` runs both frontend and backend unit tests

### Production Deployment

**Target Environment**: macOS LaunchAgent (port 3002), accessible via local network, manual-only updates

**Key Scripts** (in `deployment/`):
- `install.sh` - Setup service with LaunchAgent configuration
- `start.sh` / `stop.sh` / `restart.sh` - Service management
- `status.sh` - Check service health

**Documentation**:
- `docs/DEPLOYMENT.md` - Installation and LaunchAgent setup
- `docs/OPERATIONS.md` - Day-to-day operations and troubleshooting
- `docs/MONITORING.md` - Prometheus alerts, Grafana dashboards, Slack notifications
- `docs/UPDATES.md` - Manual update procedures (no automation by design)

**Quick Status Check**:
```bash
cd deployment && ./status.sh
tail -f ~/Library/Logs/spicy-claude/stdout.log
```

## Single Binary Distribution

```bash
cd backend && deno task build  # Local building
```

**Automated**: Push git tags → GitHub Actions builds for Linux/macOS (x64/ARM64)

## Claude Code Dependency Management

**Policy**: Fixed versions (no caret `^`) for consistency across frontend/backend

**Update Procedure**:

1. Check versions: `grep "@anthropic-ai/claude-code" frontend/package.json backend/deno.json`
2. Update frontend package.json and `npm install`
3. Update backend deno.json imports and `rm deno.lock && deno cache cli/deno.ts`
4. Update backend package.json and `npm install`
5. Verify: `make check`

## Commands for Claude

### Unified Commands (from project root)

- `make format` - Format both frontend and backend
- `make lint` - Lint both
- `make typecheck` - Type check both
- `make test` - Test both
- `make check` - All quality checks
- `make format-files FILES="file1 file2"` - Format specific files

### Individual Commands

- Development: `make dev-backend` / `make dev-frontend`
- Testing: `make test-frontend` / `make test-backend`
- Build: `make build-backend` / `make build-frontend`

## Development Workflow

### Network Configuration

**Production**: Binds to `0.0.0.0:3002` (all interfaces) for local network access
**Development**: Binds to `127.0.0.1` by default (localhost only)

The `--host` parameter controls network binding:
- Backend supports `--host <address>` CLI argument
- Production LaunchAgent configured with `--host 0.0.0.0`
- Frontend uses relative API paths (works automatically)
- CORS set to `origin: "*"` for cross-origin access

To change network binding, edit the LaunchAgent plist and restart the service.

### Pull Request Process

1. Create feature branch: `git checkout -b feature/name`
2. Commit changes (Lefthook runs `make check`)
3. Push and create PR with appropriate labels:
   ```bash
   gh pr create --title "..." --body "..." --label "bug" --label "backend"
   ```
4. Include Type of Change checkboxes and description
5. Request review and merge after approval

### Labels

🐛 `bug`, ✨ `feature`, 💥 `breaking`, 📚 `documentation`, ⚡ `performance`, 🔨 `refactor`, 🧪 `test`, 🔧 `chore`, 🖥️ `backend`, 🎨 `frontend`

### Release Process (Automated with tagpr)

1. Feature PRs merged → tagpr creates release PR
2. Add version labels if needed (minor/major)
3. Merge release PR → automatic tag creation
4. GitHub Actions builds binaries automatically

### Viewing Copilot Review Comments

```bash
gh api repos/edwardhallam/spicy-claude/pulls/PR_NUMBER/comments
```

**Important**: Always run commands from project root. Use full paths for cd commands to avoid directory navigation issues.

## Project Distinguishing Features

This fork (Spicy Claude) differs from the upstream claude-code-webui in these key ways:

1. **Dangerous Mode**: 4th permission mode that bypasses all prompts - the primary feature
2. **Production Deployment**: LaunchAgent setup for macOS with comprehensive ops documentation
3. **Comprehensive E2E Testing**: 20 Playwright tests for UI verification including bypass mode
4. **Manual-Only Updates**: No automated updates by design for production stability
