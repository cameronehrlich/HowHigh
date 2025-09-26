#!/bin/bash
set -euo pipefail

# Runs screenshot UI tests for iPhone and iPad. Optional arg = base result bundle name.
BASE_RESULT=${1:-ScreenshotResults}
PROJECT_PATH="HowHigh/HowHigh.xcodeproj"
SCHEME="HowHighUITests"

if [[ ! -f "$PROJECT_PATH/project.pbxproj" ]]; then
  echo "error: $PROJECT_PATH not found. Run this script from /Users/cameronehrlich/HowHigh/HowHighCodex." >&2
  exit 1
fi

# Clean existing bundles to avoid xcodebuild errors.
rm -rf "$BASE_RESULT" "$BASE_RESULT.xcresult" "${BASE_RESULT}_iPad" "${BASE_RESULT}_iPad.xcresult"

run_tests() {
  local destination=$1
  local bundle=$2
  local fallback=${3:-}

  echo "\nRunning screenshots on $destination → $bundle.xcresult"
  if ! xcodebuild test \
      -project "$PROJECT_PATH" \
      -scheme "$SCHEME" \
      -destination "$destination" \
      -only-testing:HowHighUITests/ScreenshotUITests/testCaptureLocalizedScreenshots \
      -resultBundlePath "$bundle"; then
    if [[ -n "$fallback" ]]; then
      echo "Destination $destination unavailable. Retrying with $fallback"
      rm -rf "$bundle" "$bundle.xcresult"
      xcodebuild test \
        -project "$PROJECT_PATH" \
        -scheme "$SCHEME" \
        -destination "$fallback" \
        -only-testing:HowHighUITests/ScreenshotUITests/testCaptureLocalizedScreenshots \
        -resultBundlePath "$bundle"
    else
      exit 1
    fi
  fi
}

run_tests 'platform=iOS Simulator,name=iPhone 17 Pro' "$BASE_RESULT" 'platform=iOS Simulator,name=iPhone 17'
run_tests 'platform=iOS Simulator,name=iPad Pro 13-inch (M4),OS=26.0' "${BASE_RESULT}_iPad"

cat <<MSG
\nDone! Result bundles:
  $(pwd)/$BASE_RESULT.xcresult
  $(pwd)/${BASE_RESULT}_iPad.xcresult
Open them in Finder or Xcode to export the PNG attachments.
MSG
