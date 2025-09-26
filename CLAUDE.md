# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview
HowHigh is an iOS application that uses the iPhone's built-in barometer (available on iPhone 6 and later) to measure vertical distance/height. The app displays height measurements in inches, feet, or yards using the device's altimeter data.

## Development Commands

### Building the Project
```bash
# Install CocoaPods dependencies
pod install

# Build the project using workspace (not xcodeproj)
xcodebuild -workspace HowHigh.xcworkspace -scheme HowHigh -configuration Debug build

# Clean build
xcodebuild -workspace HowHigh.xcworkspace -scheme HowHigh clean
```

### Running Tests
```bash
xcodebuild test -workspace HowHigh.xcworkspace -scheme HowHigh -destination 'platform=iOS Simulator,name=iPhone 15'
```

### Opening in Xcode
```bash
open HowHigh.xcworkspace
```

**Important**: Always use the `.xcworkspace` file, not the `.xcodeproj` file, since this project uses CocoaPods.

## Architecture

### Core Components

**ViewController** (`HowHigh/ViewController.m`)
- Main view controller that handles all app functionality
- Uses `CMAltimeter` to access barometer/altimeter data
- Manages UI state between idle and measuring modes
- Converts altitude measurements to user-selected units (inches/feet/yards)

### Key Dependencies (via CocoaPods)
- **ReactiveCocoa 2.3**: Reactive programming framework for handling asynchronous events
- **UIView+Positioning**: Helper methods for view positioning
- **UIColor+Hex**: Convenience methods for creating colors from hex values
- **UIView+Shimmer**: Animation effect for the Start button

### App Functionality Flow
1. App checks for barometer availability (`CMAltimeter.isRelativeAltitudeAvailable`)
2. User places device on starting surface and presses "Start"
3. App begins monitoring relative altitude changes using `startRelativeAltitudeUpdatesToQueue`
4. Real-time height displayed as user lifts device, converted to selected unit
5. "Reset" allows starting new measurement

### UI Architecture
- Uses programmatic UI creation (no Interface Builder for main UI)
- Visual blur effect applied to background image
- Motion effects (parallax) added to content view
- iAd banner integration (deprecated - consider removing)

## Hardware Requirements
- Requires iPhone 6 or later (devices with barometer/M8 motion coprocessor)
- App specifically checks for `CMAltimeter` availability and shows error message on unsupported devices