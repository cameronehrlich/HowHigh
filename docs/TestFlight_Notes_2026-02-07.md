# TestFlight Notes (2026-02-07)

## HowHigh

- [ ] UI sanity pass: confirm UI elements make sense on each screen (Barometer, Altimeter, Profile, History, Session Detail).
- [x] Calibrate / Zero button placement: move closer to the number being zeroed (Altimeter home).
- [x] Steady pressure arrow: remove confusing right-facing "navigation-looking" steady arrow; ensure Altimeter trend reflects altitude movement (not pressure).
- [x] WeatherKit "Could not fetch data": fix location authorization flow and improve error logging/messages.
- [x] Sea level pressure control: added NWS nearby station selection (US only) with graceful outside-US messaging.
- [ ] Widget: confirm whether a widget exists; if not, decide what it should show and implement.
- [x] Graph polish: smoother/nicer chart styling + make early-session small movements visible.
- [x] Sessions list: add swipe to delete + swipe to share (History + recent sessions on home).
- [~] Contact support: ensure the UI action works (mailto + fallback copy); still need to confirm the inbox actually receives emails.

## ColorCub

- [x] `@ColorCub/Preview/PreviewView.swift`: guard `imageAspectRatio` against division by zero when `image.size.height == 0` (both generated image path and constants fallback path).
