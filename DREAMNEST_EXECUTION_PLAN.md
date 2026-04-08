# DreamNest Production Execution Plan (iOS-first)

## 0) Context from Current Repository (Review + Advice)

This repository already has a strong technical scaffold:
- Core audio playback, timer/fade, safety policy, cry detection service/state machine, and unit tests are present.
- Existing docs define architecture and privacy direction.

Immediate high-leverage fixes before/alongside delivery:
1. Add production audio asset pipeline (licensed loops, loudness-normalized masters, asset hashing/versioning).
2. Implement robust background + interruption handling (calls, Siri, route changes, low power).
3. Expand privacy UX (clear “on-device only” cry detection onboarding + consent logs).
4. Add telemetry + experiments from day 1 to avoid blind launches.
5. Add CI quality gates (tests, lint, static analysis, privacy manifest checks).

---

## 1) Product Vision

### Vision statement
DreamNest helps exhausted parents protect and improve infant sleep with trustworthy, science-informed sound routines that are calming, safe, and private by design.

### Product principles
- **Sleep-first reliability:** playback must be stable for long overnight sessions.
- **Safety by default:** guardrails for sound exposure and caregiver education.
- **Privacy by architecture:** cry detection is fully on-device, no cloud audio upload.
- **Low cognitive load:** one-handed, night-friendly UX in sleep-deprived contexts.
- **Premium emotional design:** soft visuals, confidence cues, reassuring copy.

### Target users
- New parents (0–18 months infant age).
- Caregivers needing quick setup and predictable routines.
- Privacy-conscious families avoiding “always streaming” baby monitors.

### Value proposition
- High-quality looping noise + bedtime timers.
- Automatic local cry response that recovers sleep environment.
- Exposure-aware controls to reduce unsafe listening patterns.

### North-star metric
- **Weekly Restored Sleep Sessions (WRSS):** sessions >30 min where app stayed active and parent did not manually intervene after cry response.

---

## 2) Technical Architecture

### App architecture
- **UI:** SwiftUI feature modules with state-driven view models.
- **Domain:** use-case services (Playback, Timer, Cry Response, Safety).
- **Infrastructure:** AVFoundation, CoreAudio metering, local persistence, analytics client.
- **Pattern:** Clean-ish layered architecture + protocol-driven dependency injection.

### Core subsystems
1. **Playback Engine**
   - Gapless looping, fade in/out envelopes, category/session management.
   - Supports route changes (Bluetooth disconnect, speaker changes).
2. **Sleep Timer + Fade-out**
   - Deterministic countdown engine with configurable fade curves.
   - Resilient restore on app relaunch.
3. **Noise Safety Limiter**
   - Max output cap and “safe range” guidance.
   - Per-session exposure estimate and warning thresholds.
4. **Local Cry Detection**
   - On-device microphone analysis and lightweight classifier/heuristics.
   - Confidence smoothing + debounce to avoid false triggers.
   - Action policy: temporary volume boost + timer extension.
5. **Premium UX Layer**
   - Dark-safe theme, large controls, haptic-confirmed key actions.
6. **Data & Analytics**
   - Event schema, funnel tracking, reliability metrics, experiment flags.

### Non-functional requirements
- Startup to play <= 2 sec on mid-tier devices.
- Overnight crash-free session reliability >= 99.7%.
- Cry response trigger latency <= 1.5 sec (target).
- Background audio continuity across lock screen and app switching.
- Battery overhead under defined threshold for overnight runs.

### Privacy & compliance stance
- No raw audio leaves device.
- Transparent permissions, purpose strings, and in-app privacy education.
- Data minimization: only aggregate/product telemetry.

---

## 3) Backlog by Epics and Stories

## Epic A — Core Sleep Experience

### Story A1: Browse and play looping sounds
- **User story:** As a parent, I can start a sound in one tap so I can settle my baby quickly.
- **Acceptance criteria:**
  - Sound list loads instantly with preview metadata.
  - Selected sound loops seamlessly for at least 8 hours.
  - Play/pause/volume controls respond within 150 ms perceived latency.
- **Technical notes:**
  - Preload audio buffers, use loop-safe file boundaries.
  - Handle AVAudioSession interruptions and route changes.
- **Dependencies:** Licensed sound library, playback service.
- **Definition of done:** Unit tests + manual overnight run + analytics events emitted.

### Story A2: Favorites and recent sounds
- **User story:** As a parent, I can quickly return to the sounds that work best for my child.
- **Acceptance criteria:** favorite toggle, recent list, persistence across app relaunch.
- **Technical notes:** local persistence via settings store.
- **Dependencies:** A1.
- **Definition of done:** Persistence tests + UX review sign-off.

### Story A3: Start from lock screen controls
- **User story:** As a parent, I can control playback without unlocking my phone.
- **Acceptance criteria:** play/pause/next obey lock screen and control center commands.
- **Technical notes:** MPNowPlayingInfoCenter + MPRemoteCommandCenter wiring.
- **Dependencies:** A1.
- **Definition of done:** tested with locked device and headset controls.

## Epic B — Timer & Fade Intelligence

### Story B1: Sleep timer presets
- **User story:** As a parent, I can choose 15/30/45/60/custom timer lengths.
- **Acceptance criteria:** timer starts/stops reliably and state is visible at all times.
- **Technical notes:** timer domain model + view model binding.
- **Dependencies:** A1.
- **Definition of done:** unit + UI tests for timer state transitions.

### Story B2: Fade-out engine
- **User story:** As a parent, audio fades out smoothly instead of abruptly stopping.
- **Acceptance criteria:** configurable fade duration, no pops/clicks, deterministic curve.
- **Technical notes:** reuse/extend FadeCurve, sample-safe gain ramping.
- **Dependencies:** B1.
- **Definition of done:** audio QA pass on multiple devices.

### Story B3: Timer restore after relaunch
- **User story:** If the app is interrupted, timer and playback recover gracefully.
- **Acceptance criteria:** resume policy documented and consistent in background/foreground transitions.
- **Technical notes:** persist timestamped timer checkpoints.
- **Dependencies:** B1/B2.
- **Definition of done:** interruption scenario test suite passes.

## Epic C — Safety & Hearing Protection

### Story C1: Safe listening limiter
- **User story:** As a parent, I cannot accidentally exceed unsafe volume levels.
- **Acceptance criteria:** hard cap configurable by policy; cap applies during all volume changes.
- **Technical notes:** central policy enforcement in playback pipeline.
- **Dependencies:** A1.
- **Definition of done:** cap cannot be bypassed via UI or cry-response logic.

### Story C2: Exposure guidance UI
- **User story:** I can understand safe placement and volume recommendations.
- **Acceptance criteria:** clear guidance shown on first run + in settings; acknowledges once.
- **Technical notes:** dedicated guidance view and localization-ready copy.
- **Dependencies:** C1.
- **Definition of done:** legal/compliance copy sign-off.

### Story C3: Safety override with friction
- **User story:** If needed, I can override cap briefly with clear warning.
- **Acceptance criteria:** override requires explicit confirmation and auto-resets after session.
- **Technical notes:** feature flaggable by region/compliance policy.
- **Dependencies:** C1/C2.
- **Definition of done:** telemetry on override usage added.

## Epic D — Local Cry Detection & Adaptive Response

### Story D1: On-device cry detection pipeline
- **User story:** As a parent, the app detects likely crying without sending audio to cloud.
- **Acceptance criteria:** on-device processing only; confidence score available every analysis window.
- **Technical notes:** short-window feature extraction + smoothing/debounce.
- **Dependencies:** mic permission flow, audio session coordination.
- **Definition of done:** privacy review + benchmark report.

### Story D2: Adaptive response actions
- **User story:** When crying is detected, volume increases safely and timer extends automatically.
- **Acceptance criteria:** policy-configurable boost and extension; limiter still enforced.
- **Technical notes:** response orchestrator with cooldown window.
- **Dependencies:** B1/B2, C1, D1.
- **Definition of done:** integration tests for trigger/cooldown/rollback.

### Story D3: False-positive controls
- **User story:** I can tune sensitivity to reduce unwanted triggers.
- **Acceptance criteria:** low/medium/high modes with explanatory copy.
- **Technical notes:** map UI sensitivity levels to detection thresholds.
- **Dependencies:** D1.
- **Definition of done:** QA field test in noisy-home scenarios.

## Epic E — Premium Product Experience

### Story E1: Premium visual system
- **User story:** The app feels calming and trustworthy at night.
- **Acceptance criteria:** accessible contrast, dark mode optimized, large tap targets.
- **Technical notes:** design tokens and reusable components.
- **Dependencies:** design system foundation.
- **Definition of done:** design QA checklist pass.

### Story E2: Onboarding and trust narrative
- **User story:** I understand exactly what the app does and how privacy works.
- **Acceptance criteria:** 4-screen onboarding with clear outcomes and permissions rationale.
- **Technical notes:** progressive disclosure and permission pre-prompts.
- **Dependencies:** C2, D1.
- **Definition of done:** onboarding completion tracking live.

### Story E3: Subscription/paywall foundations
- **User story:** I can try core value quickly and upgrade when convinced.
- **Acceptance criteria:** free tier limits + premium unlock flows + restore purchases.
- **Technical notes:** StoreKit 2, remote-config paywall experiments.
- **Dependencies:** analytics + feature flags.
- **Definition of done:** sandbox purchase and restore tested.

## Epic F — Platform Reliability, QA, and Ops

### Story F1: CI/CD and test automation
- **User story:** Team ships safely with confidence.
- **Acceptance criteria:** CI runs unit/UI/lint on every PR.
- **Technical notes:** GitHub Actions/Xcode Cloud pipeline.
- **Dependencies:** stable test suite.
- **Definition of done:** branch protection enabled.

### Story F2: Observability and crash triage
- **User story:** Team can detect and fix production issues quickly.
- **Acceptance criteria:** crash reporting, breadcrumb logs, release health dashboard.
- **Technical notes:** structured logs for playback/timer/cry transitions.
- **Dependencies:** analytics SDK.
- **Definition of done:** on-call runbook published.

### Story F3: Release operations playbook
- **User story:** Launches are repeatable and low risk.
- **Acceptance criteria:** checklist for beta, phased release, rollback.
- **Technical notes:** versioning, feature flags, kill-switches.
- **Dependencies:** F1/F2.
- **Definition of done:** dry-run conducted before GA.

---

## 4) 12-Week Delivery Plan

### Weeks 1–2: Foundation hardening
- Finalize product requirements, event taxonomy, privacy guardrails.
- Build CI baseline, test harness, feature flag infrastructure.
- Complete sound pipeline + metadata schema.

### Weeks 3–4: Core playback and timer MVP
- Ship A1, B1, B2 initial versions.
- Add lock screen controls prototype (A3).
- Internal dogfood on overnight reliability.

### Weeks 5–6: Safety and cry detection alpha
- Deliver C1/C2 and D1 alpha.
- Integrate D2 adaptive response with caps and cooldowns.
- Start battery/performance profiling.

### Weeks 7–8: UX polish + onboarding + analytics
- Deliver E1/E2 and analytics dashboards.
- Improve false positive handling (D3).
- Run closed beta with 30–50 parents.

### Weeks 9–10: Monetization + stabilization
- Deliver E3 StoreKit flows.
- Fix reliability bugs from beta, improve interruptions handling.
- App Store assets, legal copy, support macros.

### Weeks 11–12: Launch readiness
- Regression sweep and launch checklist execution.
- Phased rollout (1% → 10% → 50% → 100%) with guardrail monitoring.
- Post-launch iteration backlog lock-in.

---

## 5) iOS-first File/Folder Structure

```
DreamNest/
  App/
    DreamNestApp.swift
    AppEnvironment.swift
    AppRouter.swift
  DesignSystem/
    Theme/
    Components/
    Tokens/
  Core/
    Audio/
      AudioPlaybackService.swift
      AudioSessionCoordinator.swift
      LoopEngine.swift
    Timer/
      SleepTimerEngine.swift
      FadeCurve.swift
      TimerStateStore.swift
    CryDetection/
      LocalCryDetectionService.swift
      CryFeatureExtractor.swift
      CryDetectionStateMachine.swift
      CryResponseOrchestrator.swift
    Safety/
      NoiseSafetyPolicy.swift
      ExposureEstimator.swift
    Models/
    Protocols/
    Persistence/
      UserDefaultsSettingsStore.swift
      EventStore.swift
    Analytics/
      AnalyticsClient.swift
      EventSchema.swift
  Features/
    Onboarding/
    Home/
    Timer/
    Safety/
    CryDetection/
    Settings/
    Paywall/
  Resources/
    Sounds/
    Localizations/
    PrivacyInfo.xcprivacy
    Info.plist
  Support/
    FeatureFlags/
    Logging/
    BuildConfig/
DreamNestTests/
  Unit/
  Integration/
DreamNestUITests/
  Flows/
Scripts/
  ci/
  release/
Docs/
  product/
  qa/
  launch/
```

---

## 6) UX Copy Deck (Initial)

### Onboarding
1. **Title:** Better sleep starts with steady sound.
   - Body: “DreamNest plays smooth, premium sleep sounds designed for all-night comfort.”
2. **Title:** Safety comes first.
   - Body: “Built-in volume limits help protect little ears with parent-friendly guidance.”
3. **Title:** Cry response, on your device.
   - Body: “DreamNest listens locally and reacts to crying—no cloud audio storage.”
4. **Title:** Ready for tonight?
   - CTA: “Start Sleep Session”

### Permission pre-prompts
- **Microphone:** “Microphone access enables local cry detection. Audio never leaves your phone.”
- **Notifications:** “Optional alerts help when sessions end or attention is needed.”

### Core UI microcopy
- Timer label: “Sound stops in {{time_remaining}}”
- Fade toggle: “Gentle fade-out”
- Cry sensitivity: “Cry response sensitivity”
- Safety cap note: “Volume is capped for safer listening.”

### Premium paywall
- Headline: “Sleep support that works while you rest.”
- Bullets:
  - “Unlimited premium sounds”
  - “Adaptive cry response controls”
  - “Advanced sleep session insights”
- CTA: “Try DreamNest Premium”

---

## 7) QA Matrix

### Functional
- Playback controls, loop integrity, timer transitions, fade behavior, cry trigger actions.

### Device/OS
- iPhone SE (latest supported) through Pro Max; latest iOS and previous major.
- Wired/Bluetooth/phone speaker routes.

### Reliability
- 8-hour playback soak tests.
- Background/foreground, lock/unlock, call interruption, low battery mode.

### Safety
- Volume cap enforcement in all flows.
- Cry response cannot exceed configured max gain.

### Privacy
- No network calls containing raw audio payloads.
- Permission denial and revocation paths behave gracefully.

### Accessibility
- VoiceOver labels, dynamic type, contrast, reduced motion, one-hand operation.

### Regression gates
- Must-pass suites: unit, integration, smoke UI flows, release checklist.

---

## 8) Analytics Plan

### Event taxonomy (examples)
- `session_started`, `session_ended`
- `sound_selected`, `favorite_toggled`
- `timer_set`, `timer_extended`, `fade_completed`
- `cry_detected`, `cry_response_applied`, `cry_response_dismissed`
- `safety_cap_reached`, `safety_override_used`
- `paywall_viewed`, `trial_started`, `subscription_started`

### Key funnels
1. Onboarding completion → first session start.
2. First session → 7-day retained active parent.
3. Cry detection enabled → successful auto-response sessions.
4. Paywall viewed → trial/purchase conversion.

### Guardrail metrics
- Crash-free users/sessions.
- Playback interruption rate.
- Cry false-positive complaint rate.
- Battery impact percentile.

### Experimentation
- Timer default preset tests.
- Paywall copy/package tests.
- Cry sensitivity defaults by infant age profile.

---

## 9) Launch Checklist

### Product
- All launch-blocker stories complete and signed off.
- App Store screenshots, metadata, privacy nutrition labels finalized.

### Engineering
- Release candidate tagged, reproducible build, symbol upload verified.
- Feature flags and kill-switches validated in production config.

### QA
- Full regression + 72-hour launch soak completed.
- Known issues triaged with severity and owner.

### Legal/Privacy
- Terms, privacy policy, in-app disclosures reviewed.
- Data retention/deletion policy documented.

### GTM
- Positioning, pricing, FAQ, support macros, launch email/social assets ready.
- Phased rollout monitoring dashboard staffed.

### Support/Ops
- On-call rotation and incident playbook active.
- Day 1 / Day 3 / Day 7 KPI checkpoints scheduled.

---

## 10) Post-launch Roadmap (Quarter +)

### 0–30 days
- Stabilize top crashes and playback edge cases.
- Tune cry detection thresholds based on telemetry and feedback.
- Improve onboarding drop-off points.

### 31–60 days
- Add routines (bedtime automations, schedule templates).
- Introduce richer insight cards (session consistency, interruptions).
- Expand premium sound catalog.

### 61–90 days
- Apple Watch companion quick controls (if validated).
- Family sharing and caregiver handoff features.
- Localization for top non-English markets.

### Future bets
- Personalized adaptive soundscapes by sleep phase.
- Pediatric advisory content partnerships.
- Cross-platform expansion after iOS PMF signals.

---

## Operating Cadence (Recommended)
- Weekly: product/eng/design/QA launch readiness sync.
- Twice weekly: bug triage and reliability review.
- Daily during beta/launch: KPI + incident standup.

## Team Shape (Lean startup)
- 1 iOS lead + 1 iOS engineer
- 1 ML/audio engineer (part-time acceptable initially)
- 1 product manager
- 1 product designer
- 1 QA automation + manual hybrid
- fractional growth/marketing + support

This plan is production-grade but intentionally sequenced for a lean startup team shipping high trust features quickly.
