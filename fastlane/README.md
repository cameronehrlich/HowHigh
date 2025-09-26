# Fastlane Setup

This repository includes a minimal [fastlane](https://fastlane.tools/) configuration so you can download the current App Store Connect metadata into source control.

## Prerequisites

1. Install Ruby 3+ (rbenv, asdf, or system Ruby).
2. Install bundler if it is not already available:
   ```bash
   gem install bundler
   ```
3. From the repo root, install the pinned toolchain:
   ```bash
   bundle install
   ```
4. Authenticate with App Store Connect. You can use either:
   - **Apple ID / App-Specific Password** (`FASTLANE_USER`, `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`), or
   - **App Store Connect API Key** (`Appfile` `api_key_path` or environment variables `APP_STORE_CONNECT_API_KEY_PATH` etc.).

## Configure credentials

- Update `fastlane/Appfile` with your `app_identifier`, `team_id`, and either an Apple ID or API key information. Using environment variables is strongly recommended so secrets never land in git.
- The defaults assume `com.LuckyBunny.HowHigh` and team `842K77RHSG`. Override them with `APP_IDENTIFIER`, `APP_STORE_TEAM_ID`, or `ITC_TEAM_ID` environment variables if needed.
- If you use an API key, run `fastlane spaceauth -u your@email` once or create a JSON key from App Store Connect and reference it via `FASTLANE_CONNECT_API_KEY_PATH`.
- Copy `fastlane/.env.sample` to `fastlane/.env`, fill in the secrets (notably `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`), and `source fastlane/.env` (or export the values another way) before running commands.

## Download metadata

From the repo root:

```bash
bundle exec fastlane download_metadata
```

This will populate `fastlane/metadata/` with the localized `*.txt` files and keep screenshots in `fastlane/screenshots/`. By default screenshots are skipped. To fetch screenshots too:

```bash
bundle exec fastlane download_metadata screenshots:true
```

If you only need specific locales, pass a comma-separated list:

```bash
bundle exec fastlane download_metadata languages:"en-US,es-ES"
```

If you prefer to call `deliver` directly (e.g., to target a specific App Store version), run:

```bash
bundle exec fastlane deliver download_metadata --skip-screenshots --app_version 1.2.3
```

The `--skip-screenshots` flag mirrors the default lane behaviour; drop it if you need the images as well.

## Screenshot automation

1. Capture fresh screenshots:
   ```bash
   ./capture_screenshots.sh
   ```
   This runs the UITest suite on iPhone 14 Plus (6.5" class) and iPad Pro (12.9-inch) (6th generation) so the output matches App Store Connect’s supported dimensions (6.5" phone + 13" tablet), and writes the `.xcresult` bundles to the repo root.
2. Export the attachments into Fastlane’s directory layout:
   ```bash
   python3 scripts/export_screenshots.py ScreenshotResults.xcresult ScreenshotResults_iPad.xcresult --clean
   ```
   The helper examines each attachment name (`<locale>-<device>-<label>`) and saves the PNGs under `fastlane/screenshots/<locale>/` with consistent numbering.

## Output structure

```
fastlane/
  metadata/
    en-US/
      description.txt
      keywords.txt
      ...
    es-ES/
      ...
    es-MX/
      ...
  screenshots/
    en-US/
    es-ES/
    es-MX/
    ...
```

Add this folder to git so changes to the App Store listing can be reviewed like any other PR.

## Helpful tips

- To avoid two-factor prompts on every run, prefer API key auth.
- For automation, set `FASTLANE_SESSION` or API key environment variables inside your CI system.
