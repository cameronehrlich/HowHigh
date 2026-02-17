# HowHigh Release Plan (2026-02-17)

## Candidate Version
- Marketing version: `1.3.2`
- Build number: `2`
- Release type: patch / bug fix

## Customer Requests (Andy)

### 1) Keep screen on option
- Recommendation: **Ship now**.
- Status: Implemented and fixed for lifecycle reliability in this release.
- Reason: Direct regression report from a highly engaged user; clear impact during active use.

### 2) Hide graph / faster access to Zero
- Recommendation: **Do not add new work in this patch**.
- Status: Already implemented in current app.
- Verification needed in QA:
  - Settings > Display includes `Show Chart` toggle.
  - Zero/Calibrate action is visible directly in the main altitude card without scrolling.

### 3) User-adjustable font size and font style
- Recommendation: **Ship system Dynamic Type support now; no in-app font-size setting**.
- Status: Implemented in this release across primary measurement, lists, and settings layouts.
- Reason: Uses iOS-native accessibility behavior, lowers settings complexity, and covers Andy’s readability need without a separate custom control.

## App Store Release Notes (en-US / en-GB)
- Fixed an issue where Keep Screen On could still allow the display to sleep.
- Improved screen-awake reliability when switching tabs or returning to the app.
- Improved support for iOS Dynamic Type so text scales more gracefully across screens.

## QA Checklist Before Submission
- Keep Screen On = ON:
  - Altimeter tab stays awake for at least 3+ minutes.
  - Barometer tab stays awake for at least 3+ minutes.
  - Switch between tabs and verify screen stays awake.
  - Background app for 10+ seconds, reopen, verify screen still stays awake.
- Keep Screen On = OFF:
  - Confirm normal iOS auto-lock behavior returns.
- Display options:
  - Toggle chart visibility on/off and confirm layout.
  - Confirm Zero/Calibrate remains easy to access in altimeter mode.
- Dynamic Type:
  - Set iOS text size to at least one Accessibility size and verify core screens remain readable.
  - Confirm segmented controls gracefully switch to menu-style pickers where needed.
