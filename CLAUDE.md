# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

# Spicy Claude

A web-based interface for Claude Code CLI with a **Bypass Permissions Mode** that bypasses all permission prompts. Initial version based on claude-code-webui v0.1.56 by sugyan.

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

## Specialized Agents

Spicy Claude includes a team of specialized AI agents configured in `.claude/agents/`. Each agent is optimized for specific tasks and can be invoked individually or in parallel for maximum efficiency.

### Available Agents

#### documentation-writer
**Purpose**: Technical documentation, PRDs, API docs, and user guides

**Use when:**
- Starting a new feature (create lean PRD for MVP)
- Documenting APIs or system architecture
- Writing user-facing guides
- Creating technical specifications
- Updating project documentation (README, CONTRIBUTING, etc.)
- Creating operational runbooks

**Examples:**
```
@documentation-writer Create a lean PRD for adding chat export functionality
@documentation-writer Update the API documentation for the new /api/sessions endpoint
@documentation-writer Write a troubleshooting guide for common deployment issues
```

#### devops-engineer
**Purpose**: CI/CD pipelines, deployment automation, monitoring, and infrastructure

**Use when:**
- Setting up or modifying CI/CD pipelines
- Deploying services or applications
- Creating monitoring and alerting systems
- Building auto-update mechanisms
- Writing deployment scripts
- Setting up health checks and status endpoints
- Troubleshooting production issues

**Examples:**
```
@devops-engineer Add a health check endpoint for the backend service
@devops-engineer Set up Prometheus alerts for high memory usage
@devops-engineer Create a deployment script for the staging environment
```

#### test-engineer
**Purpose**: Test strategy, test automation, quality assurance, and TDD validation

**Use when:**
- Starting a new feature (define tests first - TDD approach)
- After writing any code (create/run tests immediately)
- Before deployment (validation and smoke tests)
- Setting up CI/CD test automation
- Debugging issues (create reproduction tests)
- Reviewing test coverage and quality metrics

**Examples:**
```
@test-engineer Write Playwright tests for the new chat export feature
@test-engineer Create unit tests for the session management hook
@test-engineer Review test coverage for the backend handlers
```

#### fullstack-developer
**Purpose**: Complete vertical-slice feature development from UI to API to database

**Use when:**
- Building new features that span frontend and backend
- Implementing complete user workflows
- Creating vertical slices (UI → API → DB)
- Integrating frontend and backend components
- Refactoring features across the stack

**Examples:**
```
@fullstack-developer Implement chat export as a complete vertical slice
@fullstack-developer Add session persistence with frontend UI and backend API
@fullstack-developer Refactor the permission mode system for better maintainability
```

#### code-reviewer
**Purpose**: Code quality, best practices, security review, and architecture feedback

**Use when:**
- Reviewing pull requests or code changes
- Refactoring existing code
- Evaluating architecture decisions
- Identifying security issues
- Optimizing performance
- Ensuring TypeScript best practices
- Before merging significant changes

**Examples:**
```
@code-reviewer Review the new authentication middleware for security issues
@code-reviewer Analyze the streaming implementation for performance bottlenecks
@code-reviewer Suggest refactoring for the chat state management code
```

### Parallel Agent Execution

Multiple agents can work simultaneously for maximum efficiency. This is especially powerful for complex tasks that span multiple domains.

**Pattern: Feature Development Pipeline**
```
# Phase 1: Planning & Design (parallel)
@documentation-writer Create lean PRD for chat export feature
@test-engineer Define test strategy for chat export

# Phase 2: Implementation (parallel after planning)
@fullstack-developer Implement the chat export feature
@test-engineer Write tests for chat export (can start as soon as PRD is ready)

# Phase 3: Quality & Deployment (parallel)
@code-reviewer Review the chat export implementation
@devops-engineer Prepare deployment checklist for chat export
@test-engineer Run full test suite and report results
```

**Pattern: Production Issue Response**
```
# Parallel investigation and response
@devops-engineer Check production logs and metrics for the reported issue
@test-engineer Create reproduction tests for the bug
@code-reviewer Analyze the affected code for potential root causes
@documentation-writer Document the incident and workarounds
```

**Pattern: Release Preparation**
```
# Parallel release tasks
@test-engineer Run full regression test suite
@code-reviewer Final code quality review of all changes
@devops-engineer Prepare deployment scripts and rollback plan
@documentation-writer Update CHANGELOG and release notes
```

### Best Practices for Agent Usage

1. **Be Specific**: Provide clear context and expected outcomes
   - Good: "@test-engineer Write Playwright tests for the bypass permissions mode toggle including edge cases"
   - Bad: "@test-engineer Add tests"

2. **Use Parallel Execution**: Invoke multiple agents when tasks are independent
   ```
   @test-engineer Write unit tests for the new API endpoint
   @documentation-writer Document the API endpoint specification
   ```

3. **Respect Dependencies**: Some tasks require sequential execution
   ```
   # Sequential: PRD → Implementation → Tests
   @documentation-writer Create PRD for feature X
   # Wait for PRD, then:
   @fullstack-developer Implement feature X based on PRD
   # Wait for implementation, then:
   @test-engineer Validate feature X implementation
   ```

4. **Leverage Specialization**: Use the right agent for the job
   - Don't ask test-engineer to write production code
   - Don't ask fullstack-developer to design monitoring dashboards
   - Don't ask documentation-writer to implement features

5. **Coordinate for Complex Features**: Use multiple agents in phases
   ```
   # Phase 1: Design
   @documentation-writer + @code-reviewer + @test-engineer

   # Phase 2: Build
   @fullstack-developer + @test-engineer

   # Phase 3: Deploy
   @devops-engineer + @test-engineer + @documentation-writer
   ```

### Agent Communication Patterns

**Handoff Pattern**: One agent completes work, next agent takes over
```
@documentation-writer Create PRD for user authentication
# Output: PRD saved to docs/PRD-authentication.md

@fullstack-developer Implement user authentication based on docs/PRD-authentication.md
# Output: Feature implemented

@test-engineer Validate authentication implementation
# Output: Tests pass
```

**Parallel Pattern**: Multiple agents work simultaneously on independent tasks
```
@test-engineer Write E2E tests for checkout flow
@documentation-writer Document checkout API endpoints
@devops-engineer Set up monitoring for checkout performance
# All three can run simultaneously
```

**Review Pattern**: One agent produces, another reviews
```
@fullstack-developer Refactor the session management module
# Wait for completion, then:
@code-reviewer Review the session management refactoring for issues
```

**Iterative Pattern**: Agents work in cycles for continuous improvement
```
# Iteration 1
@fullstack-developer Add basic export functionality
@test-engineer Test basic export
@code-reviewer Review basic export

# Iteration 2
@fullstack-developer Add export format options based on feedback
@test-engineer Test format options
# Continue iterating...
```

### Verification and Tools

**List Available Agents:**
```bash
cd /Users/edwardhallam/projects/spicy-claude
claude
# In Claude Code:
/agents
```

**Agent Definitions Location:**
`.claude/agents/` contains the markdown files defining each agent's capabilities and context.

**Team Setup Documentation:**
See `.claude/TEAM-SETUP.md` for team structure and iterative development workflow.

### Integration with Automation

Agents work seamlessly with automated systems documented in `docs/AUTOMATION.md`:

**Automated Detection → Agent Response:**
1. GitHub Actions / LaunchAgent / Monitoring detects issue
2. Slack notification sent automatically
3. Invoke agents for parallel investigation and resolution
4. Automation validates the fix (CI/CD, health checks)

**Example Workflow:**
```bash
# Auto-updater fails and rolls back (automated)
# Slack notification received
# Parallel agent response:
@devops-engineer Analyze auto-updater logs
@test-engineer Identify failing test
@code-reviewer Review recent changes
```

**See Also:**
- `docs/AUTOMATION.md` - Complete automation system documentation with agent workflow patterns
- `.claude/TEAM-SETUP.md` - Agent team structure and coordination strategies

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

## Bypass Permissions Mode (Spicy Claude's Key Feature)

**4th permission mode** that completely bypasses ALL permission checks. When enabled, Claude executes ANY command without prompting.

**Activation**: Press `Ctrl+Shift+M` (or `Cmd+Shift+M` on Mac) **three times** to cycle to Bypass Mode. Visual indicators include red floating badge, red border around input, red button text, and console warning.

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
├── .claude/             # AI agent definitions and configuration
│   ├── agents/          # Specialized agent definitions
│   │   ├── documentation-writer.md
│   │   ├── devops-engineer.md
│   │   ├── test-engineer.md
│   │   ├── fullstack-developer.md
│   │   └── code-reviewer.md
│   ├── settings.json    # Agent configuration
│   └── TEAM-SETUP.md    # Team structure and workflow
└── CLAUDE.md           # Technical documentation (this file)
```

## Key Design Decisions

1. **Runtime Abstraction**: Platform-agnostic business logic with minimal Runtime interface
2. **Universal CLI Detection**: Tracing-based approach for all package managers
3. **Raw JSON Streaming**: Unmodified Claude responses for frontend flexibility
4. **Modular Architecture**: Specialized hooks and components for maintainability
5. **TypeScript Throughout**: Consistent type safety across all components
6. **Project Directory Selection**: User-chosen working directories for contextual file access
7. **Network Accessibility**: Production configured for local network access (0.0.0.0) while development defaults to localhost for security
8. **Specialized Agents**: Domain-specific AI agents for parallel task execution and workflow optimization

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

Initial version based on claude-code-webui v0.1.56 by sugyan. Key differentiators:

1. **Bypass Permissions Mode**: 4th permission mode that bypasses all prompts - the primary feature
2. **Redesigned UI**: Chat-like interface in development (accessible via /prototype route)
3. **Production Deployment**: LaunchAgent setup for macOS with comprehensive ops documentation
4. **Comprehensive E2E Testing**: 20 Playwright tests for UI verification including bypass mode
5. **Specialized AI Agents**: Team of domain-specific agents for parallel workflow execution
