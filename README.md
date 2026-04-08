# DreamNest

DreamNest is a SwiftUI iOS app for baby white-noise playback with an intentionally simple, reliable AVAudioPlayer path.

## Quick Audio Smoke Test (First Working Build)

### 1) Place the required test file
Add this file to the repo:

- `DreamNest/Resources/Audio/test_white_noise.mp3`

The app's temporary smoke-test buttons expect exactly that filename.

### 2) Verify target membership in Xcode
1. Open `DreamNest.xcodeproj`.
2. In the Project navigator, click `DreamNest/Resources/Audio/test_white_noise.mp3`.
3. Open the File Inspector (right panel).
4. Under **Target Membership**, check **DreamNest**.
5. In **Build Phases** for target **DreamNest**, verify the file appears in **Copy Bundle Resources**.

### 3) Build/run order
- **First preference:** test on a **real iPhone** (best for reliable audio route/silent switch behavior).
- Simulator can work for basic verification, but real hardware is the source of truth.

### 4) Run and hear audio
1. Build and run (`⌘R`).
2. On Home, tap **Play Test Sound**.
3. Confirm Xcode console logs:
   - audio session setup success/failure
   - file URL resolution
   - player initialization
   - playback start/failure
4. Tap **Stop Sound** to end playback.

## Implementation Notes

- Uses `AVAudioSession` category `.playback` (so playback works with the hardware silent switch).
- Activates audio session before playback starts.
- Uses `AVAudioPlayer` with:
  - `numberOfLoops = -1`
  - `prepareToPlay()`
  - default playback volume of `0.5` for the smoke test.
- Fails loudly in logs when the bundle asset is missing.

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
    │   ├── README.md
    │   └── test_white_noise.mp3   <- add this file
    └── Info.plist
```
