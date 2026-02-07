# HowHigh Revival — Product Specification

## Vision & Objectives
- Relaunch HowHigh as the definitive mobile atmospheric toolkit that blends precise barometric readings with rich context, modern design, and sticky engagement loops.
- Preserve the existing bundle identifier to retain App Store ranking equity while rebuilding the experience in SwiftUI for long-term maintainability.
- Drive top-of-funnel growth through ASO-aligned features (barometer, altimeter, storm alerts) and retain users with progression-focused experiences.

## Success Metrics
- **Acquisition:** 30% lift in weekly organic installs within 3 months of relaunch; conversion rate from product page ≥ 5% in key locales (US, UK, CA, AU).
- **Engagement:** ≥ 40% of active users complete at least one altitude session per week; average session length ≥ 2.5 minutes.
- **Retention:** D7 retention ≥ 25%, D30 retention ≥ 12% after feature launch.
- **Revenue (optional phase):** Convert ≥ 3% of MAU to paid tier once monetization is enabled.

## Guiding Principles
1. **Trust the Sensor:** Provide transparent, explainable readings, including confidence indicators and calibration guidance.
2. **Celebrate Progress:** Turn raw data into achievements, streaks, and visuals that reward movement.
3. **Context Matters:** Blend atmospheric data with location, weather, and history to tell a story.
4. **One-Hand Friendly:** Design core interactions for quick glances; elevate deeper analysis via expandable surfaces.

## Target Personas & Jobs To Be Done
- **Trail Trekker Taylor (Primary):** Outdoor enthusiast who wants reliable elevation gain tracking for hikes, climbs, and ski runs. JTBD: “Track how much vertical gain I’ve logged today and compare it to past outings.”
- **Weather Watcher Will (Secondary):** Amateur meteorologist tracking pressure swings to anticipate storms or migraines. JTBD: “Spot pressure drops in time to prepare my family and log personal symptoms.”
- **Urban Commuter Casey (Tertiary):** City dweller curious about building heights and elevator rides. JTBD: “Capture fun micro-adventures and share quirky elevation facts.”

## Competitive Landscape & Differentiation
- Benchmark apps: Atmospheric Pressure Barometer (ID 1267360992), Barometer & Altimeter, My Altitude.
- Differentiation pillars: polished SwiftUI visuals, integrated insights (WeatherKit trends, Apple Watch support), gamified history, and delightfully shareable outputs.

## Feature Pillars
1. **Altitude Studio** – Real-time elevation display, session recorder, cumulative ascent/descent charts, optional GPS correction.
2. **Pressure Insights** – Live barometer, pressure trend arrows, customizable alerts, weather-adjusted readings, symptom logging.
3. **Engagement Layer** – Achievements, weekly goals, shareable cards, persistent history timeline.
4. **Platform Extensions** – Lock-screen & Home widgets, Apple Watch quick measure, Shortcuts integration, iCloud sync.

## MVP Scope (Launch Candidate)
- **SwiftUI Rebuild:** Universal (iPhone + iPad) app targeting iOS 16+. Use Swift Package Manager (SPM) for dependencies (Swift Charts, CombineSchedulers if needed).
- **Live Readouts:** CoreMotion/CMAltimeter-powered altitude, relative altitude, pressure, trend arrow; toggle between metric/imperial units.
- **Session Recorder:** Start/pause/stop controls, timeline graph (Swift Charts), stats summary (distance, duration, ascent, descent). Basic export to CSV.
- **History:** Local CoreData/iCloud store for the last 30 sessions, with detail view featuring charts and notes.
- **Widgets:** Lock Screen `Circular` and `Inline` complication plus Home Screen medium widget showing current altitude & trend.
- **Watch App (companion, minimal):** Instant altitude reading, haptic alert when threshold reached, sync sessions to phone when available.
- **Calibration & Help:** Onboarding flow to explain reliability, linking to Apple’s sensor guidelines; manual recalibration option.
- **ASO Foundation:** Updated app name/subtitle, new screenshots (phone + watch + widget), 30-second App Preview, localized keywords EN/FR/DE/ES.
- **Analytics & Crash Reporting:** Integrate Apple Analytics, custom telemetry via TelemetryDeck or Firebase (SPM). Track session starts, completions, widget installs.

## Post-MVP Enhancements (Backlog)
- Storm alerts with push notifications when pressure drops rapidly.
- WeatherKit integration for sea-level pressure normalization and forecast overlay.
- Achievement system with vertical mile badges, streak reminders, and shareable cards.
- Social sharing templates (PNG export) with gradient altitude graph.
- GPX import/export, Apple Health elevation metrics sync.
- Subscription tier (Pro) unlocking advanced graphs, unlimited history, weather overlays.

## Experience & UX Guidelines
- **Information Architecture:** Bottom tab bar with `Measure`, `History`, `Insights`, `Profile`. `Measure` opens instantly with live sensor data; `Insights` highlights pressure trends and alerts.
- **Visual Language:** Gradient backgrounds shifting with pressure trend (calm blues vs. storm oranges); use SF Symbols for clarity. Maintain high contrast for outdoors readability.
- **Interactions:** One-tap session start; swipe up sheet for detailed stats; haptics on key milestones (e.g., +100 ft gain). Provide voiceover labels and Dynamic Type support.
- **Content Strategy:** Plain-language explanations (“Pressure is dropping quickly—storm likely in 2-4 hours”), tooltips for advanced metrics, localized strings via `.stringsdict`.

## Technical Architecture
- **App Structure:** SwiftUI + MVVM; adopt Combine for sensor streams. Use `AltitudeService` (CoreMotion), `WeatherService` (WeatherKit stub for MVP), `SessionStore` (CoreData + CloudKit sync), `SettingsStore` (AppStorage/UserDefaults).
- **Local Persistence:** CoreData with lightweight schema migrations. CloudKit for optional syncing of sessions/achievements. Provide offline-first behavior—queue uploads when offline.
- **Device Support:** iPhone 8+ (A11) to current; degrade gracefully on devices lacking barometer (show limited mode). Apple Watch watchOS 9+ with `WCSession` syncing.
- **Testing Strategy:** Unit tests for services, snapshot tests for key SwiftUI views, integration tests using `XCTest` and `XCUITest`. Use preview providers for design iteration.
- **Build/CI:** Xcode Cloud or custom GitHub Actions using `xcodebuild test` + Fastlane for TestFlight deployment. Automate lint (SwiftLint via SPM plugin) and dependency checks.

## Data, Privacy & Security
- Minimal data collection; sessions stored locally and optionally in iCloud. No third-party analytics without consent; provide privacy toggle.
- Communicate sensor usage transparently; include privacy policy updates covering barometric data and health inferences.
- Secure cloud sync using Apple frameworks; avoid external servers initially to reduce compliance burden.

## Monetization & Pricing (Phase 2)
- Launch free; evaluate introducing a `HowHigh Pro` subscription (~$1.99/month or $12.99/year) after stable engagement.
- Pro perks: unlimited history, advanced weather layers, custom alerts, premium themes, cross-device sync.
- Offer 7-day free trial, family sharing, and promotional pricing for seasonal campaigns (ski season, hiking season).

## ASO & GTM Strategy
- **Title:** “HowHigh Altimeter · Barometer & Pressure Widget”.
- **Subtitle:** “Track elevation gain, pressure trends, storm alerts”.
- **Keyword Bank:** barometer, barometric pressure, altimeter, elevation tracker, storm alert, hiking altimeter, weather barometer, pressure trend, climb tracker.
- **Creative:** 5-7 screenshots showcasing live measure, session summary, pressure insights, achievements, widgets, Apple Watch. Include localized captions.
- **Launch Campaign:** Soft-launch TestFlight to existing install base (email list if available); gather testimonials for App Store reviews.
- **Retention:** Push notifications for streaks, pressure alerts, and new achievements. Optional newsletter + blog for atmospheric tips.

## Current Work Status (Feb 7, 2026)
- **MVP Release:** Shipped to App Store and initial ASO work completed. We have observed an early lift in downloads.
- **Localization:** Localized strings across all currently supported languages; metadata localized where supported.
- **ASO Updates:** Keyword updates applied across locales in fastlane metadata and uploaded to App Store Connect.
- **ASC Workflow:** `asc migrate import` exposed two issues that require fixes in the CLI:
  - Update requests must omit `locale` for existing localizations.
  - App info updates must target `PREPARE_FOR_SUBMISSION` appInfo, not `READY_FOR_SALE`.
- **Next Milestone:** Patch the asc CLI, verify `migrate import` end-to-end, and upstream the fix.

## Immediate Focus (Next 2-3 Weeks)
- **Distribution Infrastructure:** Fix `asc migrate import` and standardize metadata upload workflow for all locales.
- **ASO Iteration:** Run keyword experiments in 2-3 core locales; measure conversion per locale weekly.
- **Retention Baseline:** Add one low-risk “sticky” retention feature (lightweight streak or weekly summary) and verify D7 impact.
- **Product Page Conversion:** Improve screenshots and captions for high-traffic locales; A/B test if possible.

## Roadmap & Milestones
1. **Week 0-2 – Foundations:** Set up SwiftUI project, configure SPM dependencies, build `AltitudeService`, baseline UI skeleton. Deliverable: sensor data displayed in-app.
2. **Week 3-6 – MVP Feature Build:** Session recorder, history persistence, Swift Charts integration, widgets, calibration flow.
3. **Week 7-8 – Polish & QA:** Accessibility review, localization framework, analytics instrumentation, performance profiling.
4. **Week 9 – Beta & Soft Launch:** Internal TestFlight, collect qualitative feedback, iterate on ASO assets.
5. **Week 10 – App Store Submission:** Final metadata, App Review prep, marketing push.
6. **Post Launch (Month 2-3):** Add WeatherKit insights, achievements, storm alerts, evaluate monetization experiment.

## Risk & Mitigation
- **Sensor Variability:** Device-to-device discrepancies. Mitigation: calibration workflow, user education, optional GPS correction.
- **Battery Usage:** Continuous sensor polling can drain battery. Mitigation: throttle updates when screen off, offer low-power mode.
- **Adoption Drop-off:** Niche appeal. Mitigation: broaden use cases (storm alerts, health logging), seasonal campaigns.
- **Migration Complexity:** Rebuilding from Objective-C. Mitigation: start from clean Swift project; reuse only assets; maintain old app in branch for reference.

## QA & Operational Checklist
- Automated tests covering core services; manual regression on supported devices (mini, standard, Pro iPhones, Apple Watch).
- Sensor accuracy testing in varied environments (indoor, outdoor, altitude changes, weather changes).
- App Store compliance: update privacy policy, marketing metadata, screenshots, preview video.
- Post-launch monitoring: crash-free sessions ≥ 99.5%, sensor failure rate alerting via logging pipeline.

## Open Questions
- Do we integrate community features (leaderboards) in V1 or keep data private until retention stabilizes?
- Should monetization focus on subscription only or offer one-time lifetime unlock?
- Do we need Android parity eventually, or focus exclusively on iOS ecosystem advantages?
