# DreamNest Implementation Notes

## Architecture
- MVVM at feature layer (`HomeViewModel` + `HomeView`).
- Service protocols in `Core/Protocols` for DI/testability.
- AVFoundation isolated inside `AudioPlaybackService` and `LocalCryDetectionService`.
- Timer/fade/cry state machine in pure Swift modules for focused unit tests.

## Timer + fade behavior
- `SleepTimerEngine` emits remaining time every second.
- `FadeCurve.gain` applies equal-power style easing during tail fade.
- Timer can extend when cry event fires.

## Cry detection pipeline (MVP)
- Frame features:
  - RMS amplitude
  - zero-crossing derived centroid proxy
  - high/low band energy proxy via first-order difference energy
- Temporal persistence + cooldown handled by `CryDetectionStateMachine`.
- Architecture permits replacing heuristics with Core ML by swapping feature extractor/state machine pair.

## Background + interruptions
- `AudioPlaybackService` sets `.playback` category.
- Handles interruption and route change notifications.
- Updates lock-screen metadata via `MPNowPlayingInfoCenter`.

## Next-step checklist
1. ✅ Add remote transport controls with `MPRemoteCommandCenter` (play/pause handlers are now wired in playback service).
2. ✅ Add favorites + recent sounds persistence for faster repeat bedtime setup.
3. Add real EQ pipeline using `AVAudioEngine` + `AVAudioUnitEQ`.
4. Add layered mixer abstraction (`Track`, `MixerGraph`) for multi-sound scenes.
5. Move persistence to SwiftData/CoreData if event history grows.
6. Add analytics only after privacy review and explicit opt-in.
7. Add XCTest UI snapshots for dark-mode accessibility validation.

## Platform automation scaffolding (April 2026)

This repository now includes code scaffolding for:
- App Intents + Siri/App Shortcuts (`Start Nap`, `Start Bedtime`, `Stop Playback`)
- Interactive Widget UI intended for Home Screen + Lock Screen launch actions
- Playback session snapshots for restoration after relaunch

### Manual Xcode configuration still required
1. **Add widget extension target** and move `DreamNest/App/DreamNestWidgets.swift` into that target's membership.
2. **Enable App Intents discovery** by confirming the app target embeds `PlaybackAppIntents.swift` and rebuilding so shortcuts are indexed.
3. **App Group (recommended for widget->app shared state)**:
   - Add an App Group capability to app + widget targets (for example `group.com.yourcompany.dreamnest`).
   - Update persistence stores to use `UserDefaults(suiteName:)` for shared reads/writes.
4. **Background modes**: keep `audio` background mode enabled for reliable lock-screen control behavior.
5. **If choosing Live Activities later**: add ActivityKit entitlement and push settings, then layer a `PlaybackActivityController` on top of the same session snapshot model.
