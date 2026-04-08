# DreamNest

Production-grade SwiftUI architecture scaffold for sleep-audio playback + local cry response.

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

See:
- `DreamNest/Resources/CONFIGURATION.md`
- `DreamNest/Resources/IMPLEMENTATION_NOTES.md`
