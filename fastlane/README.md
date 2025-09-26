# Fastlane Setup

This repository includes a minimal [fastlane](https://fastlane.tools/) configuration so you can download the current App Store Connect metadata into source control.

## Prerequisites

1. Install Ruby 3+ (rbenv, asdf, or system Ruby).
2. Install bundler and fastlane:
   ```bash
   gem install bundler
   gem install fastlane
   ```
   *or* add fastlane to your `Gemfile` and run `bundle install`.
3. Authenticate with App Store Connect. You can use either:
   - **Apple ID / App-Specific Password** (`FASTLANE_USER`, `FASTLANE_APPLE_APPLICATION_SPECIFIC_PASSWORD`), or
   - **App Store Connect API Key** (`Appfile` `api_key_path` or environment variables `APP_STORE_CONNECT_API_KEY_PATH` etc.).

## Configure credentials

- Update `fastlane/Appfile` with your `app_identifier`, `team_id`, and either an Apple ID or API key information. Using environment variables is strongly recommended so secrets never land in git.
- If you use an API key, run `fastlane spaceauth -u your@email` once or create a JSON key from App Store Connect and reference it via `FASTLANE_CONNECT_API_KEY_PATH`.

## Download metadata

From the repo root:

```bash
bundle exec fastlane download_metadata
```

This will populate `fastlane/metadata/` with the localized `*.txt` files and keep screenshots in `fastlane/metadata/screenshots/`. By default screenshots are skipped. To fetch screenshots too:

```bash
bundle exec fastlane download_metadata screenshots:true
```

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
    screenshots/
      ... (if downloaded)
```

Add this folder to git so changes to the App Store listing can be reviewed like any other PR.

## Helpful tips

- To avoid two-factor prompts on every run, prefer API key auth.
- If you only need specific locales, pass `languages:"en-US,es-ES"` to `deliver()` inside the lane.
- For automation, set `FASTLANE_SESSION` or API key environment variables inside your CI system.
