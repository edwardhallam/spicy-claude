# Contributing to Spicy Claude

Thank you for your interest in contributing to Spicy Claude! This guide will help you get started.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Making Changes](#making-changes)
- [Testing](#testing)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Project Structure](#project-structure)

## Code of Conduct

- Be respectful and inclusive
- Focus on constructive feedback
- Help others learn and grow
- Remember: Dangerous Mode is powerful - always prioritize safety

## Getting Started

### Prerequisites

- Node.js v20.0.0+
- npm latest version
- Claude CLI installed
- Git

### Fork and Clone

```bash
# Fork the repository on GitHub, then:
git clone https://github.com/YOUR_USERNAME/spicy-claude.git
cd spicy-claude

# Add upstream remote
git remote add upstream https://github.com/edwardhallam/spicy-claude.git
```

## Development Setup

### Backend Setup

```bash
cd backend
npm install

# Run in development mode
npm run dev

# Or build and run
npm run build
node dist/cli/node.js --port 8080
```

### Frontend Setup

```bash
cd frontend
npm install

# Run development server
npm run dev
```

### Running Tests

```bash
# Frontend unit tests
cd frontend
npm test

# Backend tests
cd backend
npm test

# E2E UI tests (requires backend and frontend running)
cd ..
npm run test:ui

# Bypass mode tests only (faster)
npm run test:bypass
```

## Making Changes

### Create a Feature Branch

```bash
git checkout -b feature/your-feature-name
```

Branch naming conventions:
- `feature/` - New features
- `fix/` - Bug fixes
- `docs/` - Documentation updates
- `refactor/` - Code refactoring
- `test/` - Test additions/updates

### Commit Messages

Follow conventional commits format:

```
<type>: <description>

[optional body]

[optional footer]
```

**Types**:
- `feat` - New feature
- `fix` - Bug fix
- `docs` - Documentation
- `refactor` - Code refactoring
- `test` - Tests
- `chore` - Maintenance

**Examples**:
```bash
git commit -m "feat: Add new keyboard shortcut for Dangerous Mode"
git commit -m "fix: Resolve permission dialog not showing on mobile"
git commit -m "docs: Update deployment guide with Docker instructions"
```

## Testing

### Before Submitting

1. **Run all tests**: `npm run test:ui`
2. **Test Dangerous Mode**: Ensure bypass functionality works
3. **Test on mobile**: Verify responsive design
4. **Check for console errors**: Clean browser console

### Writing Tests

#### Frontend Unit Tests (Vitest)

```typescript
// frontend/src/components/__tests__/YourComponent.test.tsx
import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import YourComponent from '../YourComponent';

describe('YourComponent', () => {
  it('should render correctly', () => {
    render(<YourComponent />);
    expect(screen.getByText('Expected Text')).toBeInTheDocument();
  });
});
```

#### E2E Tests (Playwright)

```typescript
// tests/e2e/feature/your-test.spec.ts
import { test, expect } from '@playwright/test';

test('should perform action', async ({ page }) => {
  await page.goto('http://localhost:3000');
  await page.click('[data-testid="button"]');
  await expect(page.locator('.result')).toBeVisible();
});
```

### Test Coverage

- Aim for >80% coverage on new code
- Always test Dangerous Mode related changes
- Include both happy path and error cases

## Pull Request Process

### 1. Update Your Branch

```bash
git fetch upstream
git rebase upstream/main
```

### 2. Run Quality Checks

```bash
# Format code
npm run format

# Lint
npm run lint

# Type check
npm run typecheck

# Run all tests
npm run test:ui
```

### 3. Push Your Changes

```bash
git push origin feature/your-feature-name
```

### 4. Create Pull Request

1. Go to GitHub and create a Pull Request
2. Fill in the PR template:
   - Description of changes
   - Testing performed
   - Screenshots (if UI changes)
   - Breaking changes (if any)

### 5. PR Checklist

- [ ] Tests pass locally
- [ ] Code follows project conventions
- [ ] Documentation updated (if needed)
- [ ] Dangerous Mode tested (if applicable)
- [ ] No console errors
- [ ] Mobile tested (if UI changes)

### 6. Review Process

- Maintainers will review your PR
- Address any requested changes
- Once approved, PR will be merged

## Coding Standards

### TypeScript

- Use TypeScript for all new code
- Avoid `any` types
- Export types for reusability

```typescript
// Good
interface UserData {
  name: string;
  age: number;
}

// Avoid
const data: any = { name: "John", age: 30 };
```

### React Components

- Use functional components with hooks
- Extract complex logic into custom hooks
- Keep components focused and small

```typescript
// Good
export function ChatInput({ onSubmit }: ChatInputProps) {
  const [message, setMessage] = useState('');

  return (
    <form onSubmit={handleSubmit}>
      <input value={message} onChange={e => setMessage(e.target.value)} />
    </form>
  );
}
```

### Naming Conventions

- Components: `PascalCase` (e.g., `ChatInput.tsx`)
- Hooks: `camelCase` with `use` prefix (e.g., `usePermissionMode.ts`)
- Utils: `camelCase` (e.g., `formatMessage.ts`)
- Constants: `UPPER_SNAKE_CASE` (e.g., `DEFAULT_PORT`)

### File Organization

```
frontend/src/
├── components/     # React components
├── hooks/          # Custom React hooks
├── utils/          # Utility functions
├── types/          # TypeScript types
└── config/         # Configuration
```

## Project Structure

### Key Directories

```
spicy-claude/
├── backend/              # Backend server (Hono + Node/Deno)
│   ├── cli/             # Entry points
│   ├── handlers/        # API handlers
│   ├── runtime/         # Runtime abstraction
│   └── utils/           # Utilities
├── frontend/            # Frontend (React + Vite)
│   ├── src/
│   │   ├── components/  # React components
│   │   ├── hooks/       # Custom hooks
│   │   └── utils/       # Utilities
├── shared/              # Shared TypeScript types
├── tests/               # E2E tests (Playwright)
└── docs/                # Documentation
```

### Dangerous Mode Architecture

Dangerous Mode is Spicy Claude's key differentiator:

**Frontend**:
- `usePermissionMode` hook tracks permission mode state
- `PlanPermissionInputPanel` provides UI controls
- Keyboard shortcut: Ctrl+Shift+M (3x to reach Dangerous Mode)

**Backend**:
- `allowedTools` parameter in chat requests
- When set to `["*"]`, all tools are pre-allowed
- No permission prompts sent to frontend

**Testing**:
- Bypass mode tests in `tests/e2e/bypass/`
- Comparison tests verify mode differences

## Areas for Contribution

### High Priority

- 🐛 Bug fixes for Dangerous Mode
- 📱 Mobile UI improvements
- 🧪 Additional E2E tests
- 🌐 Internationalization (i18n)
- ♿ Accessibility improvements

### Features

- 🔐 Optional authentication layer
- 📊 Usage analytics dashboard
- 🎨 Theme customization
- ⌨️ Additional keyboard shortcuts
- 📝 Conversation export

### Documentation

- 📚 Tutorial videos
- 🎯 Use case examples
- 🔧 Advanced configuration guides
- 🌍 Translations

## Questions?

- 💬 [GitHub Discussions](https://github.com/edwardhallam/spicy-claude/discussions)
- 🐛 [GitHub Issues](https://github.com/edwardhallam/spicy-claude/issues)
- 📧 Email maintainers (see README)

## License

By contributing, you agree that your contributions will be licensed under the same license as the project (see LICENSE file).

---

**Thank you for contributing to Spicy Claude!** 🌶️
