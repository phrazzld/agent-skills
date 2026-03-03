# fastlane config

## Snapfile (iOS snapshot)
Key knobs: `devices`, `languages`, `scheme`, `output_directory`, `launch_arguments`.

```ruby
# fastlane/Snapfile
devices(["iPhone 15 Pro Max", "iPhone 15 Pro"])
languages(["en-US", "es-ES"])
scheme("App")
output_directory("screenshots/ios")
clear_previous_screenshots(true)
skip_open_summary(true)
launch_arguments(["-uiTesting", "1", "-route", "paywall"])
```

Route strategy: drive app state via launch args or a deep link router in UI tests.

Android note: fastlane uses `screengrab` + `fastlane/metadata/android/...`.

## Framefile (frameit)
Use one `default(...)` block, then device overrides only when needed.

```ruby
# fastlane/Framefile
default(
  keyword: "your-app",
  title: { color: "#FFFFFF", size: 96, font: "SF Pro Display" },
  padding: 48,
)
```

Frame backgrounds: drop assets in `fastlane/` and reference relative paths.

## CI/CD patterns
- Install fastlane early; prefer `bundle exec fastlane ...` when Gemfile exists.
- Preinstall simulators/emulators; snapshot fails hard when devices missing.
- Cache derived data and Gradle where possible; speeds up screenshot runs.
- Archive outputs as CI artifacts: `screenshots/**`.

## Troubleshooting
- "scheme not shared": share scheme in Xcode and commit it.
- "device not found": open Simulator once or install runtimes.
- Empty output: UI tests not navigating; verify route args / helpers.
- Frameit font errors: use system fonts available on the runner.
- Android frameit path: ensure `fastlane/metadata/android/<locale>/images/*`.

