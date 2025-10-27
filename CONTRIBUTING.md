# Contributing to Spicy Claude

Thank you for your interest in contributing to Spicy Claude! This document provides guidelines and information for contributors.

## Table of Contents

- [Development Workflow](#development-workflow)
- [Pull Request Process](#pull-request-process)
- [Coding Standards](#coding-standards)
- [Testing Requirements](#testing-requirements)
- [GitHub Actions CI/CD](#github-actions-cicd)

## Development Workflow

### Getting Started

1. **Clone the repository**
   ```bash
   git clone https://github.com/edwardhallam/spicy-claude.git
   cd spicy-claude
   ```

2. **Install dependencies**
   ```bash
   cd frontend && npm install && cd ..
   cd backend && npm install && cd ..
   ```

3. **Install Lefthook** (pre-commit hooks)
   ```bash
   brew install lefthook  # macOS
   lefthook install
   ```

4. **Start development servers**
   ```bash
   make dev-backend    # Terminal 1
   make dev-frontend   # Terminal 2
   ```

### Branch Strategy

- **`main`** - Production-ready code, protected branch
- **Feature branches** - `feature/description` for new features
- **Bug fix branches** - `fix/description` for bug fixes

### Making Changes

1. **Create a feature branch**
   ```bash
   git checkout -b feature/your-feature-name
   ```

2. **Make your changes**
   - Write clean, documented code
   - Follow existing code style
   - Add tests for new functionality

3. **Run quality checks** (Lefthook runs these automatically on commit)
   ```bash
   make check  # Runs: format-check, lint, typecheck, tests
   ```

4. **Commit your changes**
   ```bash
   git add .
   git commit -m "feat: Add your feature description"
   ```

   **Commit Message Format**: Use [conventional commits](https://www.conventionalcommits.org/):
   - `feat:` - New features
   - `fix:` - Bug fixes
   - `docs:` - Documentation changes
   - `style:` - Code style changes (formatting, etc.)
   - `refactor:` - Code refactoring
   - `test:` - Adding or updating tests
   - `chore:` - Maintenance tasks

5. **Push your branch**
   ```bash
   git push -u origin feature/your-feature-name
   ```

## Pull Request Process

### 1. Create Pull Request

```bash
gh pr create --title "feat: Your feature title" --body "Description of changes"
```

Or use the GitHub web interface.

### 2. PR Requirements

**Before creating a PR, ensure:**
- ✅ All unit tests pass (`make test`)
- ✅ Code is properly formatted (`make format`)
- ✅ No linting errors (`make lint`)
- ✅ TypeScript compiles (`make typecheck`)
- ✅ Pre-commit hooks pass (Lefthook)

**Your PR must include:**
- Clear description of what changed and why
- Any relevant issue numbers (e.g., "Fixes #123")
- Screenshots/videos for UI changes
- Test coverage for new features

### 3. Automated CI Checks

When you create a PR, GitHub Actions automatically runs:

**PR Quality Checks** (~5 minutes):
- Prettier format check
- ESLint linting
- TypeScript type checking
- Frontend unit tests
- Backend unit tests

**Optional E2E Tests** (~15 minutes):
- Triggered manually via Actions tab
- Or add `e2e-test` label to your PR
- Runs full Playwright test suite

### 4. Review Process

- GitHub Actions must pass ✅
- Solo project: No approving review required (you merge your own PRs)
- Address any CI failures before merging
- Keep PRs focused and reasonably sized

### 5. Merging

Once all checks pass:

```bash
gh pr merge --squash
# Or use "Squash and merge" button on GitHub
```

**What happens after merge:**
1. Code merges to `main`
2. GitHub Actions automatically:
   - Builds production binaries (Linux/macOS x64/ARM64)
   - Creates a GitHub Release with version `v1.0.0-{short-sha}`
   - Uploads binaries as release assets
   - Generates changelog from commits

3. Deploy manually:
   ```bash
   # Download artifacts from GitHub Releases
   # Then run deployment scripts
   cd deployment && ./restart.sh
   ```

## Coding Standards

### TypeScript

- Use TypeScript for all code (frontend and backend)
- Avoid `any` types - use proper type definitions
- Export types from `shared/types.ts` for cross-component types

### Code Style

- **Formatting**: Prettier (automatic via Lefthook)
- **Linting**: ESLint with project configuration
- **Naming**:
  - Components: `PascalCase`
  - Functions/variables: `camelCase`
  - Constants: `UPPER_SNAKE_CASE`
  - Files: `kebab-case.ts` or `PascalCase.tsx` for components

### File Organization

```
frontend/src/
├── components/     # React components
├── hooks/          # Custom React hooks
├── contexts/       # React context providers
├── utils/          # Utility functions
└── types/          # TypeScript type definitions

backend/
├── handlers/       # API request handlers
├── middleware/     # Express/Hono middleware
├── utils/          # Utility functions
└── runtime/        # Runtime abstraction layer
```

## Testing Requirements

### Unit Tests

**Frontend** (Vitest + Testing Library):
```bash
cd frontend && npm test
```

**Backend** (Deno test / npm test):
```bash
cd backend && npm test
```

**Requirements**:
- Test all new functions and components
- Aim for >80% code coverage
- Mock external dependencies
- Test edge cases and error conditions

### E2E Tests

**Playwright**:
```bash
npm run test:ui                    # All tests
npm run test:bypass                # Bypass mode tests only
npm run test:ui -- tests/e2e/prototype/  # Prototype tests
```

**When to add E2E tests**:
- New user-facing features
- Critical user workflows
- Permission mode changes
- UI layout changes

**E2E Test Guidelines**:
- Use accessibility-first selectors (`getByRole`, `getByLabel`)
- Test keyboard navigation
- Include mobile viewports for responsive features
- Capture screenshots for visual regression

## GitHub Actions CI/CD

### Workflows

**1. PR Checks** (`.github/workflows/pr-checks.yml`)
- **Trigger**: Pull request opened/updated
- **Jobs**: Format, lint, typecheck, unit tests
- **Time**: ~3-5 minutes
- **Required**: Must pass before merge

**2. Release** (`.github/workflows/release.yml`)
- **Trigger**: Push to `main` branch
- **Jobs**: Build binaries, create release
- **Time**: ~10-15 minutes
- **Artifacts**: Linux/macOS binaries (x64/ARM64)

**3. E2E Tests** (`.github/workflows/e2e-tests.yml`)
- **Trigger**: Manual or `e2e-test` label
- **Jobs**: Full Playwright test suite
- **Time**: ~15-20 minutes
- **Optional**: Not required for all PRs

### Continuous Releases

Every merge to `main` creates a new release:

- **Version format**: `v1.0.0-{git-short-sha}`
- **Automated**: No manual intervention needed
- **Artifacts**: Binaries attached to release
- **Changelog**: Auto-generated from commit messages

### Deployment

Deployments are **manual** by design:

1. Go to [Releases](https://github.com/edwardhallam/spicy-claude/releases)
2. Download the latest artifacts for your platform
3. Follow [docs/DEPLOYMENT.md](docs/DEPLOYMENT.md) for installation
4. Use deployment scripts:
   ```bash
   cd deployment && ./restart.sh
   ```

## Questions?

- Check [CLAUDE.md](CLAUDE.md) for technical architecture details
- Review existing code for patterns and examples
- Open an issue for questions or suggestions

## License

By contributing, you agree that your contributions will be licensed under the MIT License.

---

**Happy coding! 🌶️**
