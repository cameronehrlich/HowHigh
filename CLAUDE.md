# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
HowHigh is an iOS barometer and altimeter app rebuilt in SwiftUI. It provides live pressure and altitude readings, session recording with interactive Swift Charts, and optional WeatherKit sea-level calibration. Targets iOS 16+, universal (iPhone + iPad).

- **Bundle ID:** `com.LuckyBunny.HowHigh`
- **App Store ID:** `921339656`

## Development Commands

### Building
```bash
xcodebuild build -project HowHigh/HowHigh.xcodeproj -scheme HowHigh -destination 'generic/platform=iOS' -configuration Debug
```

### Running Tests
```bash
xcodebuild test -project HowHigh/HowHigh.xcodeproj -scheme HowHigh -destination 'platform=iOS Simulator,name=iPhone 17 Pro' -only-testing:HowHighTests
```

### Opening in Xcode
```bash
open HowHigh/HowHigh.xcodeproj
```

**Important**: This project uses the `.xcodeproj` directly (no CocoaPods, no workspace). The old ObjC codebase is archived in `HowHighOG.zip`.

## Architecture

### SwiftUI + MVVM + Combine

- **RootView** — TabView with Barometer, Altimeter, and Profile tabs
- **MeasureView / MeasureViewModel** — Live readings, session recording, chart display, confidence indicator
- **ProfileView** — Settings (units, pressure unit, sea-level calibration, WeatherKit toggle)
- **InsightsView / InsightsViewModel** — Weather-based insight cards via AtmosphereStore

### Core Services
- **AltitudeService** — Wraps `CMAltimeter` for live pressure/altitude via Combine publisher. Supports sea-level pressure freeze during recording to prevent mid-session calibration jumps.
- **AtmosphereStore** — Fetches WeatherKit observations for sea-level pressure calibration
- **SessionStore** — CoreData persistence for recorded sessions
- **SettingsStore** — UserDefaults-backed preferences (units, pressure unit, display mode, WeatherKit auto-calibration)

### Key Models
- **SensorConfidence / SensorConfidenceEstimator** — Linear regression over 8-second reading window to estimate measurement jitter (good/poor/warming up/calibrating/unavailable)
- **AltitudeSession / AltitudeSample** — Session recording with ascent/descent/net tracking
- **AltitudeDisplayMode** — Gain vs Net elevation display

### Localization
All UI strings use `Localizable.xcstrings` with 12 locales: en-US, en-GB, ar-SA, de-DE, es-ES, es-MX, fr-FR, ja, ko, pt-BR, ru, zh-Hans.

## CI/CD
- **Xcode Cloud:** "Deploy to Production" workflow triggers on push to `master`
- **Fastlane:** Metadata management only (no build/deploy lanes)
- **ASC CLI (`asc`):** Used for App Store Connect operations (builds, versions, submissions, metadata)

### Release Workflow
1. Merge feature branch to `master` and push
2. Xcode Cloud builds automatically
3. Attach build to ASC version: `asc versions attach-build --version-id VERSION --build BUILD`
4. Submit: `asc submit create --app 921339656 --version-id VERSION --build BUILD --confirm`

## ASC Notes
- App has two `appInfo` records (READY_FOR_SALE + PREPARE_FOR_SUBMISSION). When querying app-info localizations, use `--app-info` flag to target the correct one.
- `asc migrate import` has known bugs with locale in PATCH payloads and appInfo selection. Use individual `asc` commands as workaround.
