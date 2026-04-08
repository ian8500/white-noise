# DreamNest

DreamNest is a production-oriented iOS SwiftUI repository for a premium baby white noise experience with local cry-aware response, hearing safety controls, and extensible modular architecture.

## Tech Stack

- Swift 6-compatible code style
- SwiftUI + Combine
- AVFoundation audio + microphone pipeline
- UserDefaults persistence (replaceable via protocol)
- Unit tests with XCTest

## Repository Structure

```text
DreamNest/
├── App/
│   ├── AppEnvironment.swift
│   └── DreamNestApp.swift
├── Core/
│   ├── Audio/
│   │   └── AudioPlaybackService.swift
│   ├── CryDetection/
│   │   ├── CryDetectionStateMachine.swift
│   │   ├── CryResponseCoordinator.swift
│   │   └── LocalCryDetectionService.swift
│   ├── Models/
│   │   ├── AppSettings.swift
│   │   ├── EQProfile.swift
│   │   └── SoundDefinition.swift
│   ├── Persistence/
│   │   └── UserDefaultsSettingsStore.swift
│   ├── Protocols/
│   │   └── ServiceProtocols.swift
│   ├── Safety/
│   │   └── NoiseSafetyPolicy.swift
│   ├── Services/
│   │   └── SoundCatalogService.swift
│   └── Timer/
│       ├── FadeCurve.swift
│       └── SleepTimerEngine.swift
├── DesignSystem/
│   └── DreamNestTheme.swift
├── Features/
│   ├── Exposure/
│   │   └── ExposureGuidanceView.swift
│   └── Home/
│       ├── HomeView.swift
│       └── HomeViewModel.swift
├── PreviewContent/
│   └── PreviewData.swift
└── Resources/
    ├── ASSET_CATALOG_PLAN.md
    ├── CONFIGURATION.md
    ├── IMPLEMENTATION_NOTES.md
    └── Info.plist

DreamNestTests/
├── CryDetectionStateMachineTests.swift
├── CryResponseCoordinatorTests.swift
├── FadeCurveTests.swift
└── SleepTimerEngineTests.swift
```

## Feature Coverage

### ✅ SwiftUI App
`DreamNestApp` bootstraps from `AppEnvironment` into a premium-themed `HomeView` with accessibility labels and voice-friendly controls.

### ✅ Modular Architecture
Core behaviors are separated by domain module folders (`Audio`, `Timer`, `CryDetection`, `Safety`, `Persistence`) and composed using protocol-driven dependency injection.

### ✅ Audio Playback Engine
`AudioPlaybackService` handles:
- session configuration
- looped playback
- crossfade between sounds
- interruption handling
- volume ramping
- now playing metadata

### ✅ Bundled Sound Catalog
`SoundCatalogService` and `SoundDefinition.seededCatalog` define bundled local sounds. Audio files are loaded from `Bundle.main` as `.m4a` resources.

### ✅ Timer + Fade Out
`SleepTimerEngine` manages running/cancel/extend lifecycle and `FadeCurve` applies smooth equal-power tapering near timer completion.

### ✅ Settings Persistence
`UserDefaultsSettingsStore` stores `AppSettings` and cry event history with backward compatibility for older saved keys.

### ✅ Cry Detection Abstraction
`CryDetectionControlling` defines the interface and `LocalCryDetectionService` provides on-device microphone analysis.

### ✅ MVP Heuristic Cry Detector
`CryDetectionStateMachine` computes confidence from amplitude + centroid proxy + band energy ratio with persistence and cooldown debouncing.

### ✅ Noise Protection Settings
`NoiseProtectionSettings` + `NoiseSafetyPolicy` enforce gain caps and warning thresholds.

### ✅ Polished Premium Bedtime UI
Deep gradient background, soft cards, concise controls, large quick start CTA, and curated sound list.

### ✅ Accessibility Support
Primary controls include accessibility labels/hints/values and combine related semantic content.

### ✅ Unit Tests
Coverage includes:
- timer behavior (`SleepTimerEngineTests`)
- fade curve behavior (`FadeCurveTests`)
- cry trigger heuristics (`CryDetectionStateMachineTests`)
- cry response output/cooldown (`CryResponseCoordinatorTests`)

## Asset Catalog Plan

See `DreamNest/Resources/ASSET_CATALOG_PLAN.md` for detailed names, sizes, and organization.

## Setup Instructions

1. Open `DreamNest.xcodeproj` in Xcode 16+.
2. Select the `DreamNest` scheme.
3. Pick an iOS Simulator target.
4. Build and run (`⌘R`).
5. Run unit tests (`⌘U`).
6. Add bundled `.m4a` files matching `SoundDefinition.seededCatalog` IDs.

## Configuration Notes

- `Info.plist` includes microphone privacy copy for local cry detection.
- The app is fully on-device and does not require network to run baseline features.
- Cry detection should be calibrated against real-world nursery noise before release.

## Next Implementation Steps

1. Replace heuristic detector with Core ML classifier + confidence calibration.
2. Add lock screen transport controls (`MPRemoteCommandCenter`).
3. Add real premium entitlement flow (StoreKit 2) and gated catalog sections.
4. Add data export + parental insights dashboard from cry event history.
5. Add snapshot tests and UI automation for core bedtime flow.
6. Add audio session recovery tests and long-run stability soak testing.

## Existing Product Docs

- `DREAMNEST_PRODUCT_ARCHITECTURE.md`
- `DREAMNEST_AUDIO_CRY_SUBSYSTEM_DESIGN.md`
- `DREAMNEST_MOBILE_UX_UI_SPEC.md`
- `DREAMNEST_PRIVACY_COMPLIANCE_REVIEW.md`
- `DREAMNEST_EXECUTION_PLAN.md`
