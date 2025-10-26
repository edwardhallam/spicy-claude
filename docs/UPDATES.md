# Spicy Claude - Update Documentation

**UPDATE**: Spicy Claude now has **automated updates** with safety features and rollback protection.

## Update Policy

✅ **Automated Updates Enabled** ✅

Spicy Claude uses a hybrid automation system to keep the fork synchronized with upstream and deploy updates safely:

### Automation System

1. **Upstream Sync** (GitHub Actions)
   - Runs daily at 2 AM UTC
   - Auto-merges changes from sugyan/claude-code-webui
   - Skips on conflicts, creates issue, notifies via Slack

2. **Auto-Deployment** (LaunchAgent)
   - Checks for updates every 10 minutes
   - Runs full test suite (20 tests)
   - Auto-deploys if tests pass
   - Auto-rollback if tests fail

3. **Slack Notifications**
   - All automation events sent to #homelab-updates
   - Before update, after success, on failures

**See**: [AUTOMATION.md](AUTOMATION.md) for complete automation documentation

### Safety Features

- ✅ Rate limiting (max 1 update per hour)
- ✅ Full test suite before deployment
- ✅ Automatic rollback on test failures
- ✅ Backup branches (keeps last 5)
- ✅ Health checks after deployment
- ✅ Lock files prevent concurrent updates

### Manual Override

You can still perform manual updates when needed (see below).

## Manual Update Process

### Step 1: Stop Service
```bash
cd /Users/edwardhallam/projects/spicy-claude/deployment
./stop.sh
```

### Step 2: Backup Current Version
```bash
cd /Users/edwardhallam/projects/spicy-claude
git stash  # Save any local changes
git branch backup-$(date +%Y%m%d)  # Create backup branch
```

### Step 3: Pull Latest Changes
```bash
git pull origin main
```

If there are merge conflicts with local modifications, resolve them carefully.

### Step 4: Rebuild Backend
```bash
cd backend
npm install
npm run build
```

### Step 5: Verify Build
```bash
ls -la dist/cli/node.js  # Should exist
```

### Step 6: Run Tests
```bash
cd /Users/edwardhallam/projects/spicy-claude
npm run test:ui
```

**Expected**: All 20 tests passing (100%)

### Step 7: Start Service
```bash
cd deployment
./start.sh
```

### Step 8: Verify Deployment
```bash
# Check service status
./status.sh

# Check HTTP endpoint
curl -I http://localhost:3002

# Check monitoring
curl -s "http://localhost:9090/api/v1/query?query=probe_success{job=\"claudecodeui\"}" | grep value
```

### Step 9: Monitor for Issues
Watch logs for the first 10 minutes:
```bash
tail -f ~/Library/Logs/spicy-claude/stdout.log
```

Check Slack #homelab-updates for any alerts.

## Rollback Procedure

If the update causes issues:

### Step 1: Stop Service
```bash
cd /Users/edwardhallam/projects/spicy-claude/deployment
./stop.sh
```

### Step 2: Restore Previous Version
```bash
cd /Users/edwardhallam/projects/spicy-claude
git checkout backup-YYYYMMDD  # Use backup branch from Step 2 above
```

### Step 3: Rebuild
```bash
cd backend
npm install
npm run build
```

### Step 4: Restart Service
```bash
cd ../deployment
./start.sh
```

### Step 5: Verify
```bash
./status.sh
npm run test:ui
```

## Monitoring During Updates

During updates, Prometheus will detect the service as down:

**Expected Alerts**:
- ClaudeCodeUIDown (after 5 minutes downtime)
- ClaudeCodeUICritical (after 15 minutes downtime)

**To prevent false alerts**:
1. **Silence alerts before update**: http://localhost:9093 → Silences → New Silence
2. **Matcher**: `service=claudecodeui`
3. **Duration**: 30 minutes (or expected update time)
4. **Comment**: "Manual update in progress"

## Update Frequency

**Recommended**: Check for updates monthly

**Update triggers**:
1. Security vulnerabilities reported
2. Critical bugs affecting functionality
3. Desired new features from upstream
4. Dependency updates (Node.js, npm packages)

**Not recommended to update**:
- Minor upstream changes
- Cosmetic improvements
- Features that don't add value

## Upstream Compatibility

Spicy Claude is based on:
- **Upstream**: claude-code-webui v0.1.56
- **Fork Date**: 2025-10-24
- **Custom Modifications**: Bypass permissions mode (4th permission option)

**Upstream Changes**:
Monitor https://github.com/siteboon/claude-code-webui for updates, but **do not auto-merge** - always review changes for compatibility with bypass permissions mode.

## Dependency Updates

### Node.js
Current version: v24.10.0 (v20.11.0+ required)

**To update Node.js**:
```bash
brew upgrade node
node --version
```

After updating Node.js, rebuild and restart:
```bash
cd /Users/edwardhallam/projects/spicy-claude/backend
npm install
npm run build
cd ../deployment
./restart.sh
```

### npm Packages

**Check for outdated packages**:
```bash
cd backend
npm outdated
```

**Update packages**:
```bash
npm update  # Update within semver ranges
# OR
npm install package@latest  # Update specific package to latest
```

**After package updates**:
```bash
npm run build
cd ../deployment
./restart.sh
npm run test:ui  # Validate functionality
```

## Testing After Updates

**Minimal Test Suite**:
```bash
cd /Users/edwardhallam/projects/spicy-claude

# Quick smoke test
npm run test:bypass  # Bypass permissions tests (BP-W1, BP-W2, BP-B1)
```

**Full Test Suite**:
```bash
# Complete validation
npm run test:ui  # All 20 tests (15-20 minutes)
```

**Manual Testing Checklist**:
- [ ] Service starts without errors
- [ ] Web UI loads at http://localhost:3002
- [ ] Can create new conversation
- [ ] Can switch to bypass permissions mode
- [ ] File operations work in bypass mode (no prompts)
- [ ] Bash operations work in bypass mode (no prompts)
- [ ] Monitoring shows service up in Prometheus
- [ ] No alerts firing in Alertmanager

## Migration History

**2025-10-26**: Migrated from old claude-code-webui to Spicy Claude
- Removed old auto-update system
- Deployed Spicy Claude on port 3002
- Documented manual-only update policy

**2025-01-26**: Implemented new automation system
- Added GitHub Actions upstream sync
- Added LaunchAgent auto-deployment
- Added Slack notifications
- Added automatic rollback on test failures
- Comprehensive safety features

## Questions About Updates?

**Why automated updates now?**
- Previous manual-only approach replaced with safer automation
- Full test suite runs before every deployment
- Automatic rollback protects against breaking changes
- Preserves Dangerous Mode functionality with test gates
- Better upstream sync keeps fork current

**How does it protect Dangerous Mode?**
- 20 Playwright tests must pass before deployment
- Includes specific bypass mode tests (BP-W1, BP-W2, BP-B1)
- Automatic rollback if tests fail
- Conflicts trigger manual review via GitHub issues

**How do I monitor updates?**
- Slack #homelab-updates for all automation events
- GitHub Actions logs for upstream sync
- LaunchAgent logs at `~/Library/Logs/spicy-claude-updater/`
- Service logs at `~/Library/Logs/spicy-claude/`

**Can I still update manually?**
- Yes! Follow the "Manual Update Process" section above
- Disable automation temporarily if needed
- Useful for testing specific changes

## Related Documentation

- [AUTOMATION.md](AUTOMATION.md) - **Complete automation system documentation**
- [DEPLOYMENT.md](DEPLOYMENT.md) - Deployment procedures
- [TESTING.md](../tests/README.md) - Test suite documentation
- [MONITORING.md](MONITORING.md) - Monitoring and alerts
- [OPERATIONS.md](OPERATIONS.md) - Day-to-day operations

## Automation Control

### Check Automation Status

```bash
# Check if auto-updater is running
launchctl list | grep spicy-claude-updater

# View recent logs
tail -50 ~/Library/Logs/spicy-claude-updater/stdout.log

# Check last update time
cat .last-auto-update
date -r $(cat .last-auto-update)
```

### Disable Automation

```bash
# Emergency disable (with notification)
./deployment/emergency-disable.sh "Reason for disabling"

# Or manually unload LaunchAgent
launchctl unload ~/Library/LaunchAgents/com.homelab.spicy-claude-updater.plist
```

### Re-enable Automation

```bash
launchctl load ~/Library/LaunchAgents/com.homelab.spicy-claude-updater.plist
```

### Monitor Automation

- **Slack**: Check #homelab-updates channel for all automation events
- **Logs**: `tail -f ~/Library/Logs/spicy-claude-updater/stdout.log`
- **GitHub**: Check Actions tab for upstream sync status

## Upstream Sync

Spicy Claude automatically merges changes from upstream (sugyan/claude-code-webui):

### Automatic Sync

- Runs daily at 2 AM UTC via GitHub Actions
- Skips if conflicts detected
- Creates GitHub issue if manual resolution needed
- Sends Slack notification

### Manual Upstream Sync

```bash
# Fetch and merge upstream
git fetch upstream main
git merge upstream/main

# If conflicts, resolve carefully (preserve Dangerous Mode!)
# Test thoroughly
npm run test:ui

# Push
git push origin main
```

---

**Last Updated**: 2025-01-26
**Update Policy**: Automated (with safety features)
**Automation**: GitHub Actions + LaunchAgent
**Test Suite**: 20 Playwright tests (100% passing)
**Rollback**: Automatic on test failures
**Full Documentation**: [AUTOMATION.md](AUTOMATION.md)
