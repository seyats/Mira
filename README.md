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
- Open this folder in Xcode as an app project source set, then add the files to an iOS app target if needed.
