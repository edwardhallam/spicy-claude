# Spicy Claude - Automation Documentation

**PRIVATE DOCUMENTATION** - This file contains personal automation setup and is excluded from the public repository.

## Overview

Spicy Claude uses a hybrid automation system for keeping the fork synchronized with upstream and automatically deploying updates.

**Architecture**:
- **GitHub Actions**: Syncs upstream changes from sugyan/claude-code-webui daily
- **Local LaunchAgent**: Monitors origin/main for changes and auto-deploys every 10 minutes
- **Slack Integration**: Sends notifications for all automation events

## System Components

### 1. GitHub Actions - Upstream Sync

**File**: `.github/workflows/upstream-sync.yml`

**Purpose**: Automatically merges changes from upstream repository

**Trigger**: Daily at 2 AM UTC (cron schedule)

**Workflow**:
1. Fetch upstream changes from sugyan/claude-code-webui
2. Check for new commits
3. Attempt automatic merge
4. **If successful**: Push to main, send Slack notification
5. **If conflicts**: Skip merge, create GitHub issue, send Slack alert

**Manual trigger**:
```bash
# Via GitHub UI: Actions → Upstream Sync → Run workflow
# Or via gh CLI:
gh workflow run upstream-sync.yml
```

**Configuration**:
- Requires `SLACK_WEBHOOK_URL` secret in GitHub repository settings
- Requires `GITHUB_TOKEN` (automatically provided)

### 2. Local Auto-Updater

**Files**:
- `deployment/auto-updater.sh` - Main update script
- `deployment/launchd/com.homelab.spicy-claude-updater.plist` - LaunchAgent configuration

**Purpose**: Monitors origin/main and deploys updates automatically

**Schedule**: Every 10 minutes (StartInterval: 600)

**Workflow**:
1. Fetch from origin/main
2. Check for new commits
3. Create backup branch
4. Pull latest changes
5. Run full test suite (20 Playwright tests)
6. **If tests pass**: Deploy and restart service
7. **If tests fail**: Automatically rollback to backup branch
8. Send Slack notifications for all stages

**Installation**:
```bash
# Load LaunchAgent
launchctl load ~/Library/LaunchAgents/com.homelab.spicy-claude-updater.plist

# Check status
launchctl list | grep spicy-claude-updater

# View logs
tail -f ~/Library/Logs/spicy-claude-updater/stdout.log
tail -f ~/Library/Logs/spicy-claude-updater/stderr.log
```

**Disable/Enable**:
```bash
# Disable
./deployment/emergency-disable.sh "Reason for disabling"

# Enable
launchctl load ~/Library/LaunchAgents/com.homelab.spicy-claude-updater.plist
```

### 3. Slack Notifications

**File**: `deployment/slack-notify.sh`

**Purpose**: Reusable script for sending formatted Slack messages

**Configuration**: Set `SLACK_WEBHOOK_URL` in `.env` file

**Message Types**:
- `checking` - Checking for updates
- `upstream-detected` - New upstream commits found
- `upstream-merged` - Successfully merged upstream
- `upstream-conflict` - Merge conflicts detected
- `deployment-start` - Starting deployment
- `deployment-success` - Deployment completed
- `tests-running` - Running test suite
- `tests-passed` - Tests passed
- `tests-failed` - Tests failed, rolling back
- `rollback` - Rollback initiated
- `rollback-success` - Rollback completed
- `rollback-failed` - Critical: rollback failed
- `automation-disabled` - Auto-updates disabled
- `error` - General error

**Usage**:
```bash
./deployment/slack-notify.sh <message_type> [details]

# Examples:
./deployment/slack-notify.sh checking
./deployment/slack-notify.sh deployment-success "v1.0.1"
./deployment/slack-notify.sh error "Build failed"
```

### 4. Enhanced Rollback System

**File**: `deployment/rollback.sh`

**Purpose**: Rollback to previous version with automatic backup detection

**Features**:
- Finds most recent backup branch automatically
- Stops service before rollback
- Rebuilds from backup
- Restarts service and verifies health
- Cleans up old backups (keeps last 5)

**Usage**:
```bash
# Auto-detect backup
./deployment/rollback.sh

# Specific backup branch
./deployment/rollback.sh backup-20250126-103000
```

### 5. Emergency Disable

**File**: `deployment/emergency-disable.sh`

**Purpose**: Quickly stop auto-updates in case of issues

**Usage**:
```bash
./deployment/emergency-disable.sh "Critical bug discovered"
```

**Actions**:
- Stops LaunchAgent immediately
- Removes lock files
- Sends Slack notification

## Configuration

### Environment Variables (.env)

Create `.env` file in project root:

```bash
# Required
SLACK_WEBHOOK_URL=https://hooks.slack.com/services/YOUR/WEBHOOK/URL

# Optional
AUTO_ROLLBACK_ENABLED=true
UPDATE_CHECK_INTERVAL=600
PORT=3002
HOST=0.0.0.0
```

### GitHub Secrets

Required in GitHub repository settings (Settings → Secrets and variables → Actions):

1. **SLACK_WEBHOOK_URL**: Slack webhook for notifications
2. **PUBLIC_REPO_TOKEN**: GitHub personal access token for pushing to public repo
3. **GITHUB_TOKEN**: Automatically provided by GitHub Actions

### Slack Webhook Setup

1. Go to Slack workspace → Apps → Incoming Webhooks
2. Create new webhook for #homelab-updates channel
3. Copy webhook URL
4. Add to `.env` and GitHub secrets

## Monitoring

### Check Auto-Updater Status

```bash
# Check if LaunchAgent is running
launchctl list | grep spicy-claude-updater

# View recent logs
tail -50 ~/Library/Logs/spicy-claude-updater/stdout.log

# Check for errors
tail -50 ~/Library/Logs/spicy-claude-updater/stderr.log

# Check last update time
cat .last-auto-update
date -r $(cat .last-auto-update) '+%Y-%m-%d %H:%M:%S'
```

### Check Main Service Status

```bash
# Service status
./deployment/status.sh

# Service logs
tail -f ~/Library/Logs/spicy-claude/stdout.log

# Health check
curl -I http://localhost:3002/
```

### GitHub Actions Status

```bash
# List recent workflow runs
gh run list --workflow=upstream-sync.yml

# View specific run
gh run view RUN_ID

# Watch live run
gh run watch
```

## Troubleshooting

### Auto-Updater Not Running

```bash
# Check LaunchAgent status
launchctl list | grep spicy-claude-updater

# If not listed, load it
launchctl load ~/Library/LaunchAgents/com.homelab.spicy-claude-updater.plist

# Check for errors in plist
plutil -lint ~/Library/LaunchAgents/com.homelab.spicy-claude-updater.plist

# Check logs
tail -50 ~/Library/Logs/spicy-claude-updater/stderr.log
```

### Updates Not Being Applied

```bash
# Check if lock file is stuck
ls -la .auto-updater.lock
rm .auto-updater.lock  # Remove if stuck

# Check rate limiting
cat .last-auto-update
# Updates max once per hour

# Manually trigger update
./deployment/auto-updater.sh
```

### Slack Notifications Not Working

```bash
# Test Slack webhook
./deployment/slack-notify.sh checking

# Check environment variables
grep SLACK_WEBHOOK_URL .env

# Verify webhook URL is valid
curl -X POST $SLACK_WEBHOOK_URL \
  -H 'Content-Type: application/json' \
  -d '{"text":"Test message"}'
```

### Rollback Failures

```bash
# List available backup branches
git branch | grep backup-

# Check git status
git status

# Manual rollback steps:
./deployment/stop.sh
git checkout backup-YYYYMMDD-HHMMSS
cd backend && npm install && npm run build
cd ../deployment && ./start.sh
```

### Upstream Merge Conflicts

When GitHub Actions detects conflicts:

1. Check GitHub issues for auto-created conflict report
2. Check Slack for notification with conflicting files
3. Manually resolve:

```bash
git fetch upstream main
git merge upstream/main

# Resolve conflicts in affected files
# Priority: Preserve Dangerous Mode functionality

git add .
git commit
git push origin main

# Verify Dangerous Mode still works
npm run test:bypass
```

## Safety Features

### Rate Limiting
- Maximum 1 auto-update per hour
- Prevents update loops
- Can be overridden manually

### Lock Files
- Prevents concurrent updates
- Automatically cleaned on completion
- Stale locks removed (if process dead)

### Backup Retention
- Keeps last 5 backup branches
- Older backups automatically deleted
- Manual backups preserved

### Test Gate
- All 20 Playwright tests must pass
- Deployment blocked if tests fail
- Automatic rollback on failure

### Health Checks
- Service health verified after deployment
- 10 retries over 20 seconds
- Rollback triggered if unhealthy

## Manual Operations

### Manual Update

```bash
# Stop auto-updater temporarily
./deployment/emergency-disable.sh "Manual update"

# Pull and deploy
git pull origin main
cd backend && npm install && npm run build
./deployment/restart.sh

# Verify
./deployment/status.sh
npm run test:bypass

# Re-enable auto-updater
launchctl load ~/Library/LaunchAgents/com.homelab.spicy-claude-updater.plist
```

### Manual Upstream Sync

```bash
git fetch upstream main
git merge upstream/main

# If conflicts, resolve them
# Test thoroughly!
npm run test:ui

# Push
git push origin main
```

### Force Deploy Without Tests

**⚠️ Use only in emergencies!**

```bash
# Set environment variable to skip tests
AUTO_ROLLBACK_ENABLED=false ./deployment/auto-updater.sh

# Or deploy manually
cd backend && npm run build
./deployment/restart.sh
```

## Logs and Audit Trail

### Log Locations

```bash
# Auto-updater logs
~/Library/Logs/spicy-claude-updater/stdout.log
~/Library/Logs/spicy-claude-updater/stderr.log

# Main service logs
~/Library/Logs/spicy-claude/stdout.log
~/Library/Logs/spicy-claude/stderr.log

# LaunchAgent logs
/var/log/system.log  # Search for "spicy-claude"
```

### Audit Information

- Git commit history tracks all changes
- Backup branches preserve previous versions
- Slack notifications provide timeline
- GitHub Actions logs available for 90 days
- LaunchAgent logs retained indefinitely

## Best Practices

1. **Monitor Slack**: Check #homelab-updates regularly
2. **Test in staging**: Use a test branch for risky changes
3. **Manual verification**: Periodically test Dangerous Mode
4. **Keep backups**: Don't delete backup branches immediately
5. **Update gradually**: Let automation run, don't force updates
6. **Document changes**: Add notes to commits for automation context

## Recovery Procedures

### Complete System Failure

```bash
# 1. Stop everything
./deployment/stop.sh
./deployment/emergency-disable.sh "System recovery"

# 2. Find last known good version
git log --oneline -20
git branch | grep backup-

# 3. Checkout known good version
git checkout <commit-hash>

# 4. Rebuild
cd backend && npm install && npm run build

# 5. Start service
cd ../deployment && ./start.sh

# 6. Verify
./status.sh
curl -I http://localhost:3002/

# 7. When stable, re-enable automation
launchctl load ~/Library/LaunchAgents/com.homelab.spicy-claude-updater.plist
```

## Future Improvements

Potential enhancements to automation system:

- [ ] Email notifications in addition to Slack
- [ ] Canary deployments (gradual rollout)
- [ ] Automatic upstream conflict resolution
- [ ] Performance monitoring integration
- [ ] Automated security scanning
- [ ] Multi-environment support (dev/staging/prod)

---

**Last Updated**: 2025-01-26
**Automation Version**: 1.0
**Status**: Active
