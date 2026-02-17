# TestFlight Notes (2026-02-17)

## HowHigh 1.3.2 (Build 2)

### Focus
- Fix reliability of `Keep Screen On`.
- Improve Dynamic Type support (system text-size scaling).

### Verify
- [ ] Keep Screen On ON: screen remains awake on Altimeter tab during active viewing.
- [ ] Keep Screen On ON: screen remains awake on Barometer tab during active viewing.
- [ ] Keep Screen On ON: still works after switching tabs repeatedly.
- [ ] Keep Screen On ON: still works after app goes background -> foreground.
- [ ] Keep Screen On OFF: iOS auto-lock behavior is normal.

### Secondary checks
- [ ] `Show Chart` toggle still works and layout remains stable.
- [ ] Zero/Calibrate control remains immediately reachable in Altimeter view.
- [ ] At an Accessibility text size, Barometer, Altimeter, History, Session Detail, and Settings remain readable and navigable.
- [ ] Unit/pressure pickers in Settings remain usable at larger text sizes.
