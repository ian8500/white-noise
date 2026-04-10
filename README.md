# DreamNest

DreamNest is an iOS app (SwiftUI + AVFoundation) for bedtime sound playback, sleep timers, and on-device cry-response automation.

## What the app currently includes

- **Looping sound playback** using `AVAudioPlayer` and `AVAudioSession` configuration suitable for bedtime playback.
- **Sleep timer** with quick presets, incremental adjustments, and fade-out behavior.
- **Cry response mode** with local microphone permission flow, confidence threshold tuning, cooldown handling, and timer extension logic.
- **Safety controls** via a configurable noise cap policy that clamps unsafe volume levels.
- **State persistence** for recent sounds, favorites, timer settings, cry settings, and noise protection settings via `UserDefaults`.
- **Unit tests** for timer fade curve behavior, state-machine logic, cry response coordination, and key `HomeViewModel` flows.

## Project layout

```text
DreamNest/
├── App/                    # App entry point and dependency graph
├── Core/
│   ├── Audio/              # AVAudioSession + AVAudioPlayer services
│   ├── CryDetection/       # Cry detection adapter + state machine + response coordinator
│   ├── Models/             # App settings, sound definitions, EQ profiles
│   ├── Persistence/        # UserDefaults-backed settings store
│   ├── Safety/             # Volume clamping / warning policy
│   ├── Services/           # Catalog and supporting services
│   └── Timer/              # Sleep timer engine + fade curve
├── DesignSystem/           # Colors and visual tokens
├── Features/
│   ├── Home/               # Main UI + view model
│   └── Exposure/           # Safety guidance UI
├── Resources/              # Audio files and app configuration docs
└── PreviewContent/         # SwiftUI preview data

DreamNestTests/             # XCTest target
```

## Requirements

- **macOS with Xcode** (latest stable recommended)
- iOS Simulator or physical iPhone for runtime testing
- iOS microphone permission testing should be done on a physical device for best behavior validation

## Build and run

1. Open `DreamNest.xcodeproj` in Xcode.
2. Select the `DreamNest` scheme.
3. Choose an iOS Simulator or connected iPhone.
4. Build and run (`⌘R`).

## Test

From terminal (on a machine with Xcode CLI tools installed):

```bash
xcodebuild -scheme DreamNest -destination 'platform=iOS Simulator,name=iPhone 16' test
```

If that simulator name is unavailable on your machine, replace it with an installed simulator from:

```bash
xcrun simctl list devices
```

## Audio assets (important)

The default sound catalog currently references more sound IDs than the checked-in `Resources/Audio` folder provides.
For reliable playback during local runs, ensure each catalog entry has a matching bundled file (for example `noise_dark_loop.mp3`, `nature_waves_loop.mp3`, etc.) or temporarily trim the catalog while prototyping.

Current checked-in examples include:

- `noise_white_loop.mp3`
- `noise_pink_loop.mp3` and `.wav`
- `nature_rain_loop.mp3`
- `nature_fire_loop.mp3`

## Behavioral notes

- The app sets `AVAudioSession` to `.playback` normally, and `.playAndRecord` when cry mode is active.
- Playback loops indefinitely until user stop, timer completion, or interruption.
- Timer fade uses a ramped volume curve before stop.
- Cry response logic can raise volume (within safety cap), extend timer, and optionally auto-start playback.

## Configuration and design docs

The repository includes additional product and implementation docs:

- `DreamNest/Resources/CONFIGURATION.md`
- `DreamNest/Resources/IMPLEMENTATION_NOTES.md`
- `DREAMNEST_PRODUCT_ARCHITECTURE.md`
- `DREAMNEST_EXECUTION_PLAN.md`
- `DREAMNEST_PRIVACY_COMPLIANCE_REVIEW.md`

## Suggested next cleanup items

1. Align seeded sound catalog entries with bundled assets (or add a content manifest validation step in CI).
2. Add an Xcode test plan + CI workflow to run `DreamNestTests` automatically on push.
3. Add snapshot/UI tests for the Home and Settings flows.
4. Add structured in-app analytics hooks for cry-response false-positive tuning (privacy-preserving, on-device first).

