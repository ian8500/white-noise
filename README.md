# DreamNest

DreamNest is a modern iOS sleep-audio companion for caregivers. It combines calming sound playback, safety-aware volume controls, configurable sleep timers, and on-device cry-response automation to support smoother naps, bedtimes, and overnight resettles.

Built with **SwiftUI** and **AVFoundation**, DreamNest is designed to feel soft, quiet, and trustworthy while still exposing advanced controls for families who want more automation.

---

## Table of Contents

- [What DreamNest Is](#what-dreamnest-is)
- [Core User Workflow](#core-user-workflow)
- [Feature Breakdown](#feature-breakdown)
- [App Experience and UI](#app-experience-and-ui)
- [Safety and Privacy](#safety-and-privacy)
- [Architecture at a Glance](#architecture-at-a-glance)
- [Project Layout](#project-layout)
- [Requirements](#requirements)
- [Build and Run](#build-and-run)
- [Testing](#testing)
- [Audio Assets and Catalog Notes](#audio-assets-and-catalog-notes)
- [Behavioral Notes](#behavioral-notes)
- [Reference Docs](#reference-docs)
- [Suggested Next Improvements](#suggested-next-improvements)

---

## What DreamNest Is

DreamNest helps caregivers quickly start consistent sleep routines with minimal taps:

- Start playback instantly from the main control.
- Choose a sleep duration and automatic fade-out.
- Enable cry-response behavior to detect distress and respond automatically.
- Use quick presets (Nap/Bedtime) for repeatable routines.
- Keep volume in a safer range with built-in hearing guidance and caps.

The app focuses on "calm by default" with optional advanced automation as confidence grows.

---

## Core User Workflow

A typical DreamNest session looks like this:

1. **Launch DreamNest** and land on the Home screen.
2. **Choose sound + duration**:
   - Tap sound summary to start default routine quickly.
   - Use timer chips and +/- controls to fine tune duration.
3. **Start routine**:
   - Tap the central sleep button for immediate playback.
   - Or trigger a preset card (Sleep/Nap) for saved configuration.
4. **Optional smart automation**:
   - Enable cry mode or smart resettle in preset configuration.
   - During active listening windows, DreamNest can auto-respond based on cry confidence and cooldown rules.
5. **Session completes safely**:
   - Timer fades audio down before stopping.
   - Playback can also stop manually or via App Intent/Widget shortcuts.

This workflow is optimized for sleepy, one-handed interactions during nighttime care.

---

## Feature Breakdown

### 1) Sleep Audio Playback
- Looping playback using AVAudioPlayer.
- Multiple sound categories (noise, nature, ambience, mechanical).
- Sound selection and quick switching from the main experience.
- Support for persistent favorites/recent sound context.

### 2) Sleep Timer and Fade Engine
- Quick time presets (e.g., 30m, 45m, 1h, 2h).
- Fine adjustments via increment/decrement minute controls.
- Smooth fade curve before stop for gentler transitions.
- Countdown-aware display during active playback.

### 3) Quick Presets for Repeatable Routines
- Built-in preset types for **Nap** and **Bedtime**.
- Per-preset configuration:
  - Sound choice
  - Duration
  - Cry mode enablement
  - Smart resettle policy
- Long-press customization flow in UI for parent-level control.

### 4) Cry Response + Smart Resettle
- On-device cry confidence stream integration.
- Configurable confidence threshold and cooldown behavior.
- Response coordination can:
  - Start playback when needed
  - Increase volume (within safety limits)
  - Extend timer duration
- Smart resettle sessions support listening windows, resettle durations, and max auto-resettles.

### 5) Safety Controls
- Noise protection policy clamps unsafe gain levels.
- In-app warning banner when user attempts levels above guidance.
- Exposure guidance screen with practical safe-listening recommendations.

### 6) Persistence and Continuity
- User defaults-backed settings for routine continuity.
- Stores timer preferences, cry-response settings, noise protection config, favorites, recents, and presets.
- Playback session persistence support for restoring relevant state.

### 7) Automation Surfaces
- App Intents for Nap, Bedtime, and Stop Playback actions.
- Widget launcher for quick start from Home/Lock Screen contexts.

### 8) Test Coverage
- Unit tests for:
  - Fade curve behavior
  - Sleep timer engine
  - Cry-detection state machine
  - Cry response coordinator
  - HomeViewModel timer/concurrency/cry workflows

---

## App Experience and UI

DreamNest’s interface is intentionally soothing and low-friction:

- Dark, gradient-based visual language suited for nighttime use.
- Large primary action target for reliable sleepy tapping.
- Soft haptics and subtle motion for feedback without overstimulation.
- Preset and status surfaces that communicate confidence and trust.
- Clear hierarchy between “quick start now” and “configure deeply.”

The design system is built around rounded typography, restrained contrast, and sleep-first interaction pacing.

---

## Safety and Privacy

- Cry-response logic is designed around local/on-device processing abstractions.
- Microphone access is required only for cry-response features.
- The app includes explicit guidance that it is **not** a medical device and does not provide certified hearing protection.
- Safety policy enforces configurable caps to reduce accidental overexposure risk.

---

## Architecture at a Glance

- **SwiftUI app layer** for experience, state presentation, and flow orchestration.
- **Service-driven core** for audio control, timers, cry detection, persistence, and safety.
- **ViewModel-centric composition** (`HomeViewModel`) coordinating playback lifecycle and automation.
- **Protocol-based design** to keep services testable and swappable.

---

## Project Layout

```text
DreamNest/
├── App/                    # App entry point, environment, intents, widget definitions
├── Core/
│   ├── Audio/              # AVAudioSession + AVAudioPlayer services
│   ├── CryDetection/       # Cry adapter, state machine, response coordinator
│   ├── Models/             # Settings, presets, sound definitions
│   ├── Persistence/        # UserDefaults-backed stores + session persistence
│   ├── Safety/             # Volume cap and warning policy
│   ├── Services/           # Sound catalog and related services
│   └── Timer/              # Timer engine + fade curve
├── DesignSystem/           # Tokens, palettes, and visual helpers
├── Features/
│   ├── Home/               # Main UI and interaction workflow
│   └── Exposure/           # Safety guidance UI
├── Resources/              # Audio assets + implementation/config docs
└── PreviewContent/         # SwiftUI preview support

DreamNestTests/             # XCTest target
```

---

## Requirements

- macOS with latest stable Xcode recommended
- iOS Simulator or physical iPhone
- Physical device recommended for microphone/cry-mode behavior validation

---

## Build and Run

1. Open `DreamNest.xcodeproj` in Xcode.
2. Select the `DreamNest` scheme.
3. Choose a simulator or connected iPhone.
4. Build and run with `⌘R`.

---

## Testing

```bash
xcodebuild -scheme DreamNest -destination 'platform=iOS Simulator,name=iPhone 16' test
```

If `iPhone 16` is unavailable locally, list installed simulators:

```bash
xcrun simctl list devices
```

---

## Audio Assets and Catalog Notes

The seeded sound catalog currently references more sound IDs than the checked-in `DreamNest/Resources/Audio` bundle contains. For reliable local playback:

- add corresponding files for all catalog entries (e.g., `noise_dark_loop`, `nature_waves_loop`, etc.), **or**
- temporarily trim the seeded catalog while prototyping.

Current checked-in examples include:

- `noise_white_loop.mp3`
- `noise_pink_loop.mp3` and `noise_pink_loop.wav`
- `nature_rain_loop.mp3`
- `nature_fire_loop.mp3`

---

## Behavioral Notes

- Audio session uses playback mode for normal operation.
- Cry mode transitions into play-and-record behavior for mic monitoring.
- Playback loops until stop conditions (manual stop, timer completion, interruption).
- Timer completion uses a fade curve before final stop.
- Cry response actions are constrained by safety policy and cooldown logic.

---

## Reference Docs

- `DreamNest/Resources/CONFIGURATION.md`
- `DreamNest/Resources/IMPLEMENTATION_NOTES.md`
- `DREAMNEST_PRODUCT_ARCHITECTURE.md`
- `DREAMNEST_EXECUTION_PLAN.md`
- `DREAMNEST_PRIVACY_COMPLIANCE_REVIEW.md`
- `DREAMNEST_AUDIO_CRY_SUBSYSTEM_DESIGN.md`
- `DREAMNEST_MOBILE_UX_UI_SPEC.md`

---

## Suggested Next Improvements

1. Add missing bundled audio files to fully match seeded catalog.
2. Add UI snapshot testing for Home and preset customization flows.
3. Add CI test plan for simulator matrix and reliability gates.
4. Expand caregiver-facing onboarding for cry mode confidence tuning.
5. Add privacy-preserving local analytics for false-positive iteration.

