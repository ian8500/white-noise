# DreamNest

DreamNest is a SwiftUI iOS app for baby white-noise playback with an intentionally simple, reliable AVAudioPlayer path.

## Build and Run

1. Open `DreamNest.xcodeproj` in Xcode.
2. Select the `DreamNest` scheme.
3. Build and run (`⌘R`) on a simulator or real iPhone.

For the most accurate audio route and hardware behavior, validate playback on a real device.

## Implementation Notes

- Uses `AVAudioSession` category `.playback` (so playback works with the hardware silent switch).
- Activates audio session before playback starts.
- Uses `AVAudioPlayer` with:
  - `numberOfLoops = -1`
  - `prepareToPlay()`
- Fails loudly in logs when a required bundle asset is missing.

## Existing Repo Structure

```text
DreamNest/
├── App/
├── Core/
├── DesignSystem/
├── Features/
├── PreviewContent/
└── Resources/
    ├── Audio/
    │   └── README.md
    └── Info.plist
```
