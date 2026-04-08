# DreamNest

Production-grade SwiftUI architecture scaffold for sleep-audio playback + local cry response.

## ✅ What was added to make this scaffold runnable in Xcode

- `DreamNest.xcodeproj` with:
  - iOS app target (`DreamNest`)
  - unit test target (`DreamNestTests`)
  - shared scheme (`DreamNest`)
- `DreamNest/Resources/Info.plist` with required microphone and background audio keys.

## Quick start (Xcode)

1. Open `DreamNest.xcodeproj` in Xcode 16+.
2. Select the `DreamNest` scheme.
3. Choose an iOS Simulator device.
4. Build + Run (`⌘R`).
5. Run tests (`⌘U`).

## Folder structure

- `DreamNest/App`: app entry and DI bootstrap
- `DreamNest/Core/Models`: domain entities and settings
- `DreamNest/Core/Protocols`: service contracts for dependency injection/testing
- `DreamNest/Core/Services`: catalog and application services
- `DreamNest/Core/Audio`: AVAudioSession / AVAudioPlayer playback engine
- `DreamNest/Core/CryDetection`: on-device cry detection heuristics + state machine
- `DreamNest/Core/Timer`: timer and fade curve logic
- `DreamNest/Core/Persistence`: UserDefaults-based persistence layer
- `DreamNest/Core/Safety`: max gain cap and exposure policy
- `DreamNest/Features`: SwiftUI screens + view models
- `DreamNest/DesignSystem`: visual tokens/theme
- `DreamNest/Resources`: Info.plist/capability requirements and implementation notes
- `DreamNestTests`: unit tests for fade/timer/cry state machine

## Project review: advice and fixes

### Fixes already implemented
- Added app metadata and permission declarations in Info.plist so the app can run and request mic access cleanly.
- Added a test target and linked existing test files so your timer/fade/cry logic is exercised from Xcode.

### High-impact next fixes I recommend
1. **Add bundled `.m4a` loop files** under app resources.
   - Today playback gracefully reports missing audio if files are absent.
2. **Add Assets.xcassets + AppIcon** to remove icon/build warnings.
3. **Persist timer state across app restarts** (`SleepTimerEngine.restoreIfNeeded` is currently minimal).
4. **Add lock-screen transport controls** with `MPRemoteCommandCenter` (you already have `MPNowPlayingInfoCenter`).
5. **Harden cry detection false-positive handling** by adding environment calibration and confidence smoothing.

See:
- `DreamNest/Resources/CONFIGURATION.md`
- `DreamNest/Resources/IMPLEMENTATION_NOTES.md`
