# Repository Guidelines

## Project Structure & Module Organization
- App sources live in `HowHigh/`, including `AppDelegate.m`, `ViewController.m`, `Base.lproj/`, and `Images.xcassets/`. Keep new UI code beside related controllers.
- Unit tests reside in `HowHighTests/HowHighTests.m`; mirror production class names with matching test categories for clarity.
- CocoaPods manifests (`Podfile`, `Podfile.lock`, `Pods/`) and the Xcode workspace/project sit at the repo root. Run toolchain commands from here.

## Build, Test, and Development Commands
- `pod install` — regenerate the workspace after dependency edits or first clone.
- `open HowHigh.xcworkspace` — launch Xcode with pods wired in; prefer the workspace over the project file.
- `xcodebuild -workspace HowHigh.xcworkspace -scheme HowHigh -configuration Debug clean build` — continuous integration-ready build.
- `xcodebuild test -workspace HowHigh.xcworkspace -scheme HowHighTests -destination 'platform=iOS Simulator,name=iPhone 15'` — run the XCTest suite on the default simulator.

## Coding Style & Naming Conventions
- Objective-C with four-space indentation; place method braces on the next line.
- Name methods descriptively with camelCase (`- (UIColor *)mainColor`). Group `@property` declarations by purpose and default to `nonatomic`.
- Import shared categories with angle brackets (e.g., `#import <UIView+Positioning.h>`). Keep assets in `Images.xcassets` and localized strings in `Base.lproj`.

## Testing Guidelines
- Extend `XCTestCase` in `HowHighTests/` and prefix tests with `test` (e.g., `testAltitudeFormatting`).
- Use `measureBlock` for performance-sensitive conversions and add assertions for UI visibility or picker configuration.
- Run the full suite before opening a pull request to keep main green.

## Commit & Pull Request Guidelines
- Write imperative, concise commit subjects like `Add banner shimmer cleanup` and squash WIP commits before sharing.
- PRs should describe functional changes, note pod updates, link relevant issues, include UI screenshots/GIFs, and document `xcodebuild test` results.

## Agent Workflow Tips
- Respect the existing workspace-write sandbox; avoid touching Pods unless dependencies change.
- Coordinate with maintainers before introducing new simulators or altering build destinations to keep automation aligned.
