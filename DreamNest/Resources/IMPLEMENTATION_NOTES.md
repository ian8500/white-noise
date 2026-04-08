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
