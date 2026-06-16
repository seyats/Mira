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
- For free signing, open the generated project in Xcode on a Mac, select your Apple ID team, keep `Automatic` signing, and run on a device.
- For AltStore, build a signed app from Xcode with your Apple ID, then install that build using AltStore/AltServer.
