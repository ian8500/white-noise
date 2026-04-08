# DreamNest iOS Configuration

## Asset naming convention
- Audio loops: `<domain>_<name>_loop.m4a` (e.g., `noise_white_loop.m4a`, `nature_rain_loop.m4a`)
- Artwork: `artwork_<sound_id>` image set in Assets.xcassets
- Keep sample rate consistent (44.1kHz AAC or ALAC) to minimize route-change artifacts.

## Info.plist requirements
Add the following keys:
- `NSMicrophoneUsageDescription`: "DreamNest listens locally on your device to detect crying and adjust playback. Audio is never uploaded."
- `UIBackgroundModes`:
  - `audio` for sleep sound playback and lock-screen controls
- `UIApplicationSupportsIndirectInputEvents`: `YES` (optional for iPad keyboard/remote support)

## Xcode Capabilities / Entitlements
Enable:
1. **Background Modes** → check **Audio, AirPlay, and Picture in Picture**.
2. (Optional, if using premium sync later) **iCloud**.

No network upload is used by cry detection in MVP.

## App Store review callouts
- Clearly disclose microphone use in onboarding/settings.
- State that cry analysis runs **fully on-device** and data stays local.
- Do not market as medical device or certified hearing protection.
- If background audio is active without user initiation, review risk increases; keep explicit user-triggered playback.
