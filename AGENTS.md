# Repository Guidelines

## Project Structure & Module Organization
The `HowHigh/` directory holds the iOS app's Objective-C sources such as `AppDelegate.m`, `ViewController.m`, and UI resources in `Base.lproj` and `Images.xcassets`. Tests live in `HowHighTests/` alongside `HowHighTests.m`. Project files (`HowHigh.xcodeproj`, `HowHigh.xcworkspace`) and CocoaPods manifests (`Podfile`, `Podfile.lock`, `Pods/`) sit at the repo root; regenerate Pods with `pod install` whenever dependencies change.

## Build, Test, and Development Commands
Run `pod install` after cloning to ensure the workspace links all pods. Open the workspace with `open HowHigh.xcworkspace` when working in Xcode. For automated builds, use `xcodebuild -workspace HowHigh.xcworkspace -scheme HowHigh -configuration Debug clean build`. Execute the XCTest suite locally with `xcodebuild test -workspace HowHigh.xcworkspace -scheme HowHighTests -destination 'platform=iOS Simulator,name=iPhone 15'`.

## Coding Style & Naming Conventions
Follow the existing Objective-C style: four-space indentation, brace on the next line for methods, and descriptive camelCase method names (`- (UIColor *)mainColor`). Group `@property` declarations by purpose and prefer `nonatomic` attributes unless thread-safety demands otherwise. Import shared categories (`UIView+Positioning`, `UIColor+Hex`, etc.) via angle brackets to match current headers. Keep assets and localized strings in `Images.xcassets` and `Base.lproj`.

## Testing Guidelines
Extend the `XCTestCase` classes in `HowHighTests/` for unit and UI logic. Name test methods with the `test` prefix plus the behavior under test (e.g., `testAltitudeFormatting`). Use `measureBlock` for performance-sensitive conversions. When adding new UI features, add simulator snapshots or assertions validating banner visibility and picker configuration.

## Commit & Pull Request Guidelines
Write concise, imperative commit subjects similar to `Add banner shimmer cleanup`. Squash work-in-progress commits before pushing. Each pull request should describe functional changes, note any pod updates, link to issues, and include screenshots or gif captures for UI-visible changes. Confirm `xcodebuild` test results in the PR description to keep the main branch green.
