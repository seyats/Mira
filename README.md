# Mira

SwiftUI iOS app source that recreates the referenced dark glass UI and uses the supplied blue glow video as the animated background.

## Files

- `AuroraChatApp.swift`
- `ContentView.swift`
- `Models.swift`
- `LoopingVideoBackground.swift`
- `Resources/blue_glow_background.mp4`

## Notes

- The app is designed for iPhone.
- Glass styling is applied through `glassEffect()` when available on iOS 18, with a visual fallback on older versions.
- `project.yml` is intended for XcodeGen.
- GitHub Actions expects these secrets for full `.ipa` export:
  - `IOS_DISTRIBUTION_P12_BASE64`
  - `IOS_DISTRIBUTION_P12_PASSWORD`
  - `IOS_PROVISIONING_PROFILE_BASE64`
  - `IOS_SIGNING_IDENTITY`
  - `IOS_TEAM_ID`
