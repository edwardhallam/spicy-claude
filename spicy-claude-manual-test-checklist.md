# Spicy Claude - Manual Testing Checklist

**Server**: http://localhost:3456
**Test Date**: 2025-10-25

## Pre-Test Setup
- [x] Frontend dependencies installed
- [x] Backend dependencies installed
- [x] TypeScript compilation: ZERO errors
- [x] ESLint: PASSED
- [x] Frontend build: SUCCESS (289KB bundle)
- [x] Backend build: SUCCESS
- [x] Production server running on port 3456
- [x] Bundle contains dangerous mode code (verified)

## Visual Verification Tests

### Test 1: Page Load - Normal Mode (Default)
**Steps:**
1. Open http://localhost:3456 in browser
2. Observe initial state

**Expected:**
- [_] Page title shows "Spicy Claude" in browser tab
- [_] Header displays "Spicy Claude 🌶️" 
- [_] Mode button shows "🔧 normal mode" (NOT "Claude Code Web UI")
- [_] Message input has normal border (not red)
- [_] No red floating badge visible
- [_] No console warning

### Test 2: Plan Mode (⏸)
**Steps:**
1. Press `Ctrl+Shift+M` once (or click mode button once)
2. Observe changes

**Expected:**
- [_] Mode button changes to "⏸ plan mode"
- [_] Send button changes to "Plan" (instead of "Send")
- [_] No red border on input
- [_] No red floating badge
- [_] Type message: "What files are in the current directory?"
- [_] Click "Plan" button
- [_] Claude should plan WITHOUT executing any commands
- [_] Should see planning text only, no bash execution

### Test 3: Accept Edits Mode (⏵⏵)
**Steps:**
1. Press `Ctrl+Shift+M` again (or click mode button)
2. Observe changes

**Expected:**
- [_] Mode button changes to "⏵⏵ accept edits"
- [_] Send button shows "Send"
- [_] No red border on input
- [_] No red floating badge

### Test 4: Dangerous Mode (☠️) - CRITICAL TEST
**Steps:**
1. Press `Ctrl+Shift+M` again (third time, or click mode button)
2. **IMMEDIATELY observe all visual changes**

**Expected Visual Warnings (ALL must be present):**
- [_] **RED FLOATING BADGE** in top-right corner with text:
      "🚨 DANGEROUS MODE - All permissions bypassed"
- [_] **RED BORDER** around message input box (border-red-500 class)
- [_] **RED TEXT** on mode button: "☠️ DANGEROUS MODE (bypass all)"
- [_] **Console Warning** (press F12 to open DevTools):
      "⚠️ DANGEROUS MODE ENABLED" in red text
      "All permission checks are bypassed. Claude can execute ANY command without prompting."

**Expected Behavior:**
- [_] Type message: "Create a test file /tmp/spicy-test.txt with content 'dangerous mode works'"
- [_] Click "Send" button
- [_] Claude should execute WITHOUT showing permission prompt
- [_] File should be created
- [_] Verify with: `ls -la /tmp/spicy-test.txt`
- [_] Clean up: `rm /tmp/spicy-test.txt`

### Test 5: Mode Cycling
**Steps:**
1. From dangerous mode, press `Ctrl+Shift+M` again
2. Continue pressing (or clicking mode button)

**Expected:**
- [_] Cycles back to "🔧 normal mode"
- [_] RED border disappears
- [_] RED floating badge disappears
- [_] Press again → "⏸ plan mode"
- [_] Press again → "⏵⏵ accept edits"
- [_] Press again → "☠️ DANGEROUS MODE" (all red warnings return)
- [_] Verify cycling works smoothly

### Test 6: Branding Consistency
**Steps:**
1. Review all visible UI text

**Expected:**
- [_] NO references to "Claude Code Web UI" anywhere in UI
- [_] All branding shows "Spicy Claude" or "Spicy Claude 🌶️"
- [_] Page title: "Spicy Claude"
- [_] Header: "Spicy Claude 🌶️"

## iOS Safari Testing (CRITICAL - User will access from mobile)

### Environment
- Device: [iPhone/iPad model]
- iOS Version: [version]
- Safari Version: [version]
- Connection: http://[YOUR_MAC_IP]:3456

### Tests
- [_] Page loads correctly on iOS Safari
- [_] All 4 permission modes accessible via mode button tap
- [_] Dangerous mode visual warnings all display correctly:
  - [_] Red floating badge visible
  - [_] Red border on input
  - [_] Red text on mode button
- [_] Mode cycling works with touch interactions
- [_] Messages can be typed and sent
- [_] Layout responsive (no horizontal scroll)
- [_] All touch targets large enough for finger taps

**If iOS testing not available:**
- Document: "iOS Safari testing required - user must test on actual device"

## Error Testing

### TypeScript Compilation
```bash
cd /Users/edwardhallam/projects/spicy-claude/frontend
npm run typecheck
```
**Result:** [x] PASSED - 0 errors

### Linting
```bash
cd /Users/edwardhallam/projects/spicy-claude/frontend
npm run lint
```
**Result:** [x] PASSED - 0 errors

### Build Verification
```bash
cd /Users/edwardhallam/projects/spicy-claude/frontend
npm run build
```
**Result:** [x] SUCCESS - 289KB bundle, no errors

## Bundle Verification (Automated)

**Code Presence in Bundle:**
- [x] "DANGEROUS MODE" string: 4 occurrences
- [x] "☠️" emoji: 1 occurrence
- [x] "Spicy Claude" branding: 1 occurrence
- [x] "DANGEROUS MODE - All permissions bypassed": 1 occurrence
- [x] "border-red-500" styling: present
- [x] Console warning code: present

## Known Issues
[Document any issues found during testing]

## Overall Assessment
- Installation: ✅ PASSED
- TypeScript/Lint: ✅ PASSED
- Production Build: ✅ PASSED
- Bundle Contains Code: ✅ VERIFIED
- Manual UI Testing: ⚠️ REQUIRED (see checklist above)
- iOS Safari Testing: ⚠️ REQUIRED (user device needed)

## Next Steps
1. User should test all visual elements work correctly
2. User MUST test on iOS Safari (primary access method)
3. Verify dangerous mode actually bypasses permissions
4. If all tests pass → Ready for Phase 4 deployment
