# DreamNest (Working Title) — Product & Technical Blueprint

## 1) Executive summary

DreamNest is a premium, parent-first mobile app for infant sleep support through continuous soothing audio, optional layered mixing, and privacy-preserving cry response automation. The product is intentionally optimized for low-light, one-handed operation at 2am with a calming aesthetic and minimal interaction complexity.

**Core value proposition**
- Reliable high-quality soothing sound loops that work **offline** and in background mode.
- Premium intelligent automation (cry response) that remains fully **on-device**.
- Safety-forward controls (volume limiter + guidance) designed for real-world bedtime setups.

**Positioning**
- "Premium sleep sound companion for parents" — not a medical monitor, diagnosis tool, or emergency system.
- Distinct from generic white noise apps via seamless loops, dual-layer mixing, cry-triggered automations, and a deeply night-optimized UX.

**Success criteria (12 months)**
- D1 retention >= 45%, D7 >= 25% (for new parents cohort).
- Free-to-trial conversion >= 8–12%.
- Night session reliability >= 99.5% (no unexpected playback stop while locked/overnight).
- <2% sessions with safety warning ignored repeatedly (indicates guidance efficacy).

---

## 2) Recommended stack

## Recommendation: **iOS native first (SwiftUI + AVFoundation), with cross-platform-ready domain architecture**

Given your constraints (premium feel, advanced audio, background stability, energy efficiency, cry detection on-device), iOS-native-first is the strongest path to production quality and risk reduction.

### Why SwiftUI native first
1. **Audio/session reliability**: AVAudioEngine + AVAudioSession are mature and give precise control over looping, fades, ducking, interruptions, lock screen controls.
2. **Battery tuning**: Lower abstraction overhead and better profiling/control for overnight playback + on-device ML audio inference.
3. **Cry detection integration**: Easier use of Core ML / SoundAnalysis / AudioKit-level integrations with deterministic behavior.
4. **Premium UI polish**: SwiftUI with selective UIKit bridges provides fast path to high-fidelity interactions.

### Cross-platform readiness strategy
Use a **clean architecture** and keep core domain logic platform-agnostic:
- Shared product specification and state machine docs.
- Audio behavior contracts (JSON/test vectors) shared across platforms.
- Same event taxonomy and feature flags on iOS/Android.

Then implement Android natively (Kotlin + ExoPlayer/AAudio/Oboe stack where needed) once product-market fit is validated.

### Honest cross-platform tradeoffs
If using Flutter/React Native from day one:
- Pros: faster dual-platform UI delivery.
- Cons: complex audio edge cases (gapless looping, background controls, mixing precision, interruptions, low-latency cry pipeline) often require substantial native modules anyway.
- Bottom line: You may still end up writing native-heavy audio infrastructure, reducing cross-platform speed gains.

**Verdict**: SwiftUI native first for iOS launch; architect business/domain layers for eventual Kotlin-native Android parity.

---

## 3) PRD

## Product goals
- Help parents start and maintain baby sleep with calming ambient sounds.
- Reduce nighttime manual intervention through optional intelligent cry response.
- Provide safe-use controls and guidance without making medical claims.

## Non-goals
- Medical monitoring, SIDS prevention, diagnosis, or emergency alerting.
- Two-way baby monitor streaming.
- Cloud storage of raw audio.

## Target users
- Primary: parents/caregivers of newborns to toddlers.
- Secondary: prenatal users preparing nursery sleep routines.

## Core feature requirements

### A) Sound playback (MVP)
**Must-have sounds**
- White noise
- Dark noise
- Pink noise
- Brown noise
- Rain
- Ocean waves
- Crackling fire
- Gentle fan
- Soft forest ambience
- Womb-like heartbeat ambience

**Functional requirements**
- Play one selected sound continuously.
- Seamless looping (no perceptible click/gap).
- High-quality fade-in/fade-out.
- Background playback support.
- Lock screen/notification controls (play/pause/stop, preset).
- Offline operation once assets are bundled/downloaded.

### B) Premium dual-layer mixer (V1/Premium)
- Mix up to 2 simultaneous sounds.
- Independent volume sliders per layer.
- Save/reuse favorite blends as presets.

### C) Sleep timer (MVP)
- Presets: 15/30/45/60/90/120 min.
- Custom duration picker.
- Fade-out in final 1/3/5/10 min.
- Optional auto-extend via cry response.

### D) Cry response mode (Premium)
- Explicit mic permission with clear disclosure.
- Local cry event detection only (on-device inference).
- Trigger actions on detected cry:
  - Smooth increase to configured max volume.
  - Extend timer by configured amount.
  - Optionally switch to designated calming preset.
- No cloud upload of audio clips.

### E) Noise protection and safety UX (MVP)
- Parent-configurable safety limiter (% in-app gain cap).
- Warning UI if device output likely exceeds recommended level.
- Soft cap mode to prevent in-app gain beyond configured threshold.
- Bedtime guidance page for speaker/phone placement and safe listening habits.

### F) Parent-focused UX (MVP)
- Warm, soft premium visual system.
- Dark mode optimized for low-light use.
- One-handed night interactions with large tap targets.
- Minimal decision overhead at launch.

## Feature phasing

### MVP (launch)
- Single sound playback (all required library sounds).
- Seamless loops + fade in/out.
- Background playback + lock screen controls.
- Timer presets/custom + fade-out options.
- Volume safety limiter + warning + bedtime guidance.
- Offline asset support.
- Basic onboarding + permission education.

### V1 (post-launch)
- Preset management (favorites/routines).
- Improved onboarding personalization (baby age/sleep context).
- Local notifications for timer end/session summary.
- Better interruption recovery (calls, alarms, Bluetooth transitions).

### Premium roadmap
- Dual-layer mix with independent volumes.
- Cry response automation.
- Adaptive routines (time-of-night suggestions, entirely local rules).
- Cross-device sync of presets/settings (without audio upload).

## User flows

### Flow 1: First-time setup
1. Open app -> calming onboarding.
2. Select quick goal: "Fall asleep now".
3. Choose starter sound.
4. Set timer preset.
5. Optional: enable safety limiter.
6. Start playback.

### Flow 2: Night quick-start returning user
1. Open app.
2. Tap last-used preset card (single primary CTA).
3. Playback starts instantly.
4. Optional one-tap timer adjust.

### Flow 3: Premium cry response setup
1. Open Automations.
2. Explain privacy + on-device processing.
3. Ask microphone permission.
4. Configure response actions:
   - Max ramp volume.
   - Timer extension.
   - Preset switch optional.
5. Save as nighttime profile.

### Flow 4: Safety warning path
1. Playback starts with high system/device output.
2. Non-blocking warning banner + explanation.
3. CTA: "Reduce volume" and "Learn safe placement".

## Information architecture
- Home (Now Playing)
- Library (sounds + categories)
- Mixer (premium)
- Timer
- Automations (cry response)
- Safety
- Presets
- Settings (audio behavior, permissions, battery mode, legal)

Top-level nav recommendation: 4 tabs
- Home
- Library
- Automations
- Settings

Timer and Mixer presented as bottom sheets from Home for faster one-thumb use.

---

## 4) Architecture

## High-level system architecture

### Client modules (iOS)
1. **Presentation Layer**
   - SwiftUI views, design system, accessibility tokens.
2. **Application Layer**
   - Use-cases: StartPlayback, SetTimer, ApplyFade, HandleCryEvent.
3. **Domain Layer**
   - Entities: SoundAsset, MixLayer, TimerConfig, SafetyPolicy, CryResponsePolicy.
   - State machine for session lifecycle.
4. **Infrastructure Layer**
   - Audio engine adapter (AVAudioEngine).
   - Cry detection adapter (Core ML/SoundAnalysis).
   - Persistence adapter (SQLite/CoreData/UserDefaults blend).
   - Analytics + remote config adapter.

### Runtime pipelines

#### Audio pipeline
- Preprocessed assets (loop-aligned, normalized LUFS targets).
- Player nodes per layer (max 2 in premium).
- Master bus with safety limiter & fade envelope control.
- Background audio session category: `.playback` with proper interruption handling.

#### Cry detection pipeline
- Mic input frame buffer -> feature extraction -> on-device classifier.
- Hysteresis/debounce logic to reduce false positives.
- Emit CryDetected event -> Automation engine applies configured actions.

### Suggested data model (simplified)
- `SoundAsset(id, name, category, duration, loopStart, loopEnd, loudnessTarget)`
- `Preset(id, name, layerA, layerB?, timerDefault, fadeDefault, safetyProfileId)`
- `Session(id, startedAt, activePresetId, timerEndAt, cryModeEnabled)`
- `SafetyProfile(id, maxInAppGain, warningThreshold, softCapEnabled)`
- `CryPolicy(id, enabled, maxRampGain, rampDuration, timerExtendMinutes, presetOnCry?)`

### Performance/efficiency requirements
- Overnight session CPU target: low single-digit average.
- Memory budget for audio buffers bounded and predictable.
- Avoid continuous high-frequency UI refresh while screen locked.
- Cry inference duty-cycle tuned for battery (windowed analysis).

### Offline strategy
- Bundle core sounds in app package.
- Optional high-fidelity pack downloads with checksum validation and local encryption-at-rest if desired.
- Graceful fallback when storage low.

### Observability
- Structured local logs (rotating).
- Crash reporting (no raw audio artifacts).
- Playback reliability metrics and interruption-resume success.

---

## 5) Data/privacy model

## Permissions approach
- **Microphone**: requested only when enabling cry response; clear purpose string.
- **Notifications** (optional): timer completion/session reminders.
- No location/contacts/photos permissions needed.

## Privacy guarantees
- Cry detection runs on-device only.
- No raw microphone audio upload or retention by default.
- Minimal telemetry: events, settings states, performance counters.
- User-facing privacy center with clear toggles and data export/delete pathways.

## Compliance and policy posture
- Avoid medical claims in copy/screenshots/metadata.
- Include disclaimer: "Not a medical device. Not an emergency monitoring service."
- COPPA/GDPR/CCPA checks via legal review (parents are users, but infant-related context still sensitive in perception).

## Data retention
- Session analytics aggregated and de-identified.
- Local logs auto-pruned (e.g., 7–14 days).
- User account optional; allow anonymous local-only mode.

---

## 6) Monetization

## Recommended model
- **Freemium + trialed subscription** (monthly/yearly).

### Free tier
- Full single-sound playback library.
- Timer presets + custom timer.
- Basic safety controls.

### Premium tier
- Two-sound mixer.
- Cry response automations.
- Advanced presets/routines.
- Optional expanded sound packs.

### Pricing strategy
- 7-day trial then subscription.
- Annual plan emphasized with clear savings.
- Family sharing support recommended for trust/value.

### Conversion UX principles
- Demonstrate premium in context (e.g., when user attempts mixer/cry mode).
- Avoid aggressive nighttime paywalls.
- Offer post-cry-response insight preview to showcase value.

### Anti-churn
- Cancel flow with pause/downgrade options.
- In-app reminder of offline reliability and safety features.

---

## 7) QA and release plan

## QA strategy

### Test pyramid
1. **Unit tests**
   - Timer math, fade envelopes, safety caps, cry action rules.
2. **Integration tests**
   - AVAudio session transitions, lock screen controls, interruption recovery.
3. **End-to-end tests**
   - Overnight simulation with background playback and timer completion.
4. **Manual exploratory**
   - 2am UX audit in dark mode with one-hand tasks.

### Critical test matrices
- Device states: locked/unlocked/low power mode.
- Audio routes: speaker, wired, Bluetooth.
- Interruptions: call, alarm, Siri, other media app.
- Battery levels and thermal states.
- Airplane mode/offline usage.

### Quality gates before release
- Zero P0/P1 playback bugs.
- >99% automated pass on timer and session-state modules.
- Crash-free sessions >= 99.8% in beta.
- App startup to playback <= 2 seconds median on target devices.

### Release plan
1. Internal dogfood.
2. TestFlight closed beta with parents cohort.
3. Staged rollout with feature flags (cry mode initially limited).
4. Monitor analytics + crash + store feedback, then scale.

### Analytics events (recommended taxonomy)
- `onboarding_started`, `onboarding_completed`
- `sound_play_started`, `sound_play_stopped`
- `timer_set`, `timer_completed`, `timer_extended`
- `fade_mode_selected`
- `mix_enabled`, `mix_layer_changed`
- `cry_mode_enabled`, `cry_detected`, `cry_action_executed`
- `safety_warning_shown`, `safety_cap_adjusted`
- `paywall_viewed`, `trial_started`, `subscription_started`, `subscription_canceled`

Include dimensions: app version, device model, OS version, battery state, audio route, subscription status.

### App Store / Play Store review risk controls
- Avoid wording like "detects dangerous events" or "protects from SIDS."
- Clear mic disclosure and privacy statement.
- Explain cry detection is optional and local.
- Provide easy toggle to disable mic features.
- Ensure background audio behavior aligns with declared app purpose.

---

## 8) Technical risk register

| Risk | Impact | Likelihood | Mitigation |
|---|---:|---:|---|
| Perceptible loop seams/clicks | High | Medium | Preprocess assets with loop-point QA + crossfade; automated audio artifact tests |
| Background playback interruption failures | High | Medium | Robust AVAudioSession handling + integration tests across interruption scenarios |
| Cry false positives in noisy homes | High | Medium-High | Confidence thresholds, hysteresis, calibration mode, user-tunable sensitivity |
| Battery drain overnight | High | Medium | Optimize inference cadence, use lightweight model, profile on real devices |
| Device volume too high despite in-app cap | Medium-High | Medium | Strong warning UX + bedtime safety education + soft cap defaults |
| App review rejection for medical implication | High | Medium | Legal copy review, strict non-medical messaging in app/store listing |
| Cross-platform parity drift (future Android) | Medium | Medium | Shared product contracts + conformance tests + aligned analytics schema |
| Subscription backlash | Medium | Medium | Generous free tier + clear premium value + family sharing |

## Engineering implementation advice (practical fixes)

1. **Treat audio asset prep as a first-class pipeline** (not manual edits). Build a repeatable script/process to normalize loudness, verify loop points, and export metadata.
2. **Build a deterministic session state machine early** to avoid playback/timer edge-case regressions.
3. **Do not couple cry detection directly to UI layer**. Use event bus/application service so automations remain testable.
4. **Run nightly endurance tests** (4–8 hour sessions) before every release candidate.
5. **Design the paywall flow after night UX** so monetization never blocks immediate soothing actions.

