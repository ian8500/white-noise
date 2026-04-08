# DreamNest Audio + Cry Detection Subsystem Design Review

This document reviews the current implementation and proposes an MVP-to-v2 design that meets:
- premium seamless loops
- natural fades
- overnight battery efficiency
- robust local-only cry detection
- in-app safe volume limiting
- portable architecture for iOS and Android

## Current-state review (what to keep vs improve)

### Keep
- `AudioPlaybackService` already supports background category configuration, crossfade when switching tracks, and interruption handling, which is a strong baseline for reliability.
- `FadeCurve` already uses a psychoacoustically sensible eased curve shape.
- `CryDetectionStateMachine` already includes persistence and cooldown, which are the right anti-noise primitives.

### Improve
- Current playback uses `AVAudioPlayer` with whole-file loop (`numberOfLoops = -1`); this is not sufficient for sample-accurate seam control for all assets.
- Current cry feature extraction uses RMS + ZCR proxy only; add explicit band-energy envelopes and temporal modulation for better infant-cry specificity.
- Current safety policy is static clamping only; add look-ahead safety limiter and explicit gain staging contract.

---

## 1) Recommended audio engine architecture

## Core principle
Use a **graph-based engine** with deterministic control-rate automation and explicit gain stages.

### Logical modules (cross-platform)
- `AudioSessionController` (route, interruptions, ducking policy)
- `LoopPlaybackEngine` (single/multi-layer looping, sample-accurate seeks)
- `EnvelopeEngine` (fade in/out and crossfades)
- `MasterGainStage` (user gain + policy cap + safety limiter)
- `CryDetectionPipeline` (frame extraction -> feature extraction -> heuristics classifier)
- `AutomationOrchestrator` (cry event -> ramp/extend/switch actions)
- `MetricsEmitter` (privacy-safe counters only)

### Threading model
- Audio render thread: only real-time safe operations, no allocations, no locks.
- Analysis thread: frame features, ring buffers, lightweight state machine.
- Main/UI thread: control changes and visualization at low update rate.

### Platform mapping
- iOS: `AVAudioEngine` with `AVAudioPlayerNode` + mixer + optional custom `AVAudioUnitEffect` limiter.
- Android: ExoPlayer for simple playback, but for premium gapless + precise envelopes prefer **Oboe/AAudio** (or AudioTrack) based engine node graph.

---

## 2) Loop handling strategy to avoid clicks/gaps

### Asset prep pipeline (offline)
1. Trim to zero-crossings near intended loop points.
2. Remove DC offset.
3. Match loop-start/loop-end spectral profile.
4. Bake micro-crossfade metadata (`loopCrossfadeMs`, typically 8-30 ms for ambience).
5. Store per-asset metadata: `loopStartSample`, `loopEndSample`, `suggestedCrossfadeMs`, `integratedLufs`, `truePeakDbtp`.

### Runtime loop strategy
- Use sample-indexed loop region (not full file by default).
- Run two playheads near seam:
  - A: outgoing tail
  - B: incoming head (from loopStart)
- Equal-power seam crossfade over configured overlap window.

### Click prevention rules
- Always ramp gain over at least 64-128 samples for any abrupt state changes.
- Never perform instantaneous gain jumps in render callback.
- When resuming from interruption, apply short fade-in (20-50 ms).

---

## 3) Fade curve recommendations

### User-visible fades (seconds)
- Use **equal-power cosine/sine** pair for crossfades.
- For timer fade-out, use perceptual exponential-ish curve (slow early, faster late) to feel natural.

### Suggested formulas
- Crossfade in: `g_in = sin(0.5*pi*t)`
- Crossfade out: `g_out = cos(0.5*pi*t)`
- Timer fade: `g = pow(t, 1.6)` mapped from remaining fraction (or equivalent eased sigmoid).

### Durations
- Start/stop fades: 250-800 ms
- Track switch crossfade: 400-1200 ms
- Timer fade: 1-10 minutes (already product-configurable)

---

## 4) Audio normalization strategy across all assets

Normalize assets offline, not in real time.

### Recommended targets
- Integrated loudness: **-24 LUFS** for sleep ambience library baseline.
- True peak ceiling: **<= -2 dBTP** after normalization.
- Keep crest-factor diversity (avoid heavy limiting at asset-master stage).

### Per-asset metadata
Store:
- `integratedLufs`
- `lra`
- `truePeakDbtp`
- `loopStartSample` / `loopEndSample`
- `recommendedDefaultGain`

Use this metadata to set initial layer trim so different sounds feel consistent at equal slider positions.

---

## 5) Gain staging rules

Define a deterministic gain stack:

`sample -> assetTrim -> layerGain -> masterUserGain -> safetyCap -> safetyLimiter -> output`

### Rules
- `assetTrim`: static compensation from loudness metadata.
- `layerGain`: user slider per layer (log-tapered UI mapping, not linear).
- `masterUserGain`: global user intent.
- `safetyCap`: hard upper bound from policy.
- `safetyLimiter`: final protection against transient stacking.

### Numeric guidance
- Internal float headroom target: at least 6 dB.
- Two-layer sum should keep nominal bus level around -12 dBFS before limiter.

---

## 6) In-app safety limiter design

### MVP limiter (practical)
- Single-band look-ahead peak limiter
- Look-ahead: 3-5 ms
- Attack: 1-3 ms
- Release: 80-200 ms
- Ceiling: policy-driven (e.g., -6 dBFS equivalent app-domain cap)

### UX contract
- Limiter should be mostly transparent.
- If limiter engages >X% of frames in a 10 s window, show soft guidance: “Volume may be high for infant sleep.”

### Important
- App cannot fully control hardware output SPL; present this as in-app gain safety and placement guidance, not absolute dB guarantee.

---

## 7) Cry detection MVP based on DSP heuristics

## Design intent
Detect **probable infant cry episodes** (not every impulse/event) fully on-device with low CPU.

### Frame/window settings
- Sample rate for analysis: 16 kHz mono
- Frame length: 25 ms (400 samples)
- Hop: 10 ms (160 samples)
- Window: Hann

### Features per frame
1. Broadband RMS (dBFS)
2. Band energies (IIR/FFT bins):
   - Low: 150-400 Hz
   - Mid: 400-1200 Hz
   - High: 1200-3500 Hz
3. Spectral centroid / rolloff
4. Temporal modulation proxy:
   - Envelope over 1-4 s window
   - Modulation energy around ~1-5 Hz (cry rhythm)
5. Voicedness proxy / harmonicity (optional MVP-lite)

### Episode logic
- `amplitude persistence`: require N of last M frames above RMS + band ratio thresholds.
- `shape constraint`: rising/falling envelope pattern consistent with cry bursts.
- `confidence score`: weighted sum of normalized feature scores + persistence bonus.
- `cooldown`: post-trigger suppression (e.g., 90-180 s) with optional decay override for sustained episodes.

### MVP confidence example
`confidence = 0.30*rms + 0.30*bandPattern + 0.20*modulation + 0.20*persistence`

Trigger if:
- `confidence >= 0.78` for `>= K` consecutive hops, or
- `rollingMean(confidence, 2s) >= 0.72` and persistence passes.

---

## 8) Migration path to ML-based cry detection

### Phase A (current -> strong heuristics)
- Implement richer DSP features and episode detector.
- Log feature statistics + decisions (no audio).
- Build labeled evaluation set and confusion matrix.

### Phase B (hybrid)
- Add tiny on-device classifier (e.g., TFLite/Core ML) operating on mel patches.
- Gate ML with heuristic prefilter to reduce duty cycle and battery.
- Final decision = calibrated blend of heuristic + ML probability.

### Phase C (ML primary with guardrails)
- ML drives detection probability continuously.
- Heuristic state machine still handles cooldown/hysteresis and explainability.
- Keep fully local inference and local model updates via app releases.

---

## 9) False-positive mitigation strategy

Use a **multi-layer gate**:
1. **VAD gate**: ignore near-silence/background floor.
2. **Band-pattern gate**: reject broadband impacts and low-frequency hum.
3. **Temporal gate**: require persistence and modulation rhythm.
4. **Context gate**: if playback itself dominates mic input (self-audio leakage), raise threshold.
5. **Cooldown and refractory period**: suppress duplicate alerts.
6. **Action ramping**: when confidence is marginal, apply smaller response first (e.g., +10% volume, not full jump).

Also expose user sensitivity presets: `Low FP`, `Balanced` (default), `High sensitivity`.

---

## 10) Battery/performance optimization strategy

### Audio path
- Keep render graph static overnight (avoid node churn).
- Preload and reuse buffers; no allocations in render callback.
- Use moderate analysis sample rate (16 kHz) separate from playback sample rate.

### Cry analysis duty cycling
- Analyze continuously but with lightweight features each hop.
- Compute heavier features (modulation windows) every 100-200 ms.
- Suspend cry pipeline when user disables cry mode or phone battery saver policy dictates.

### System integration
- iOS: category `.playback` + optional `.mixWithOthers` only when needed.
- Android: foreground service for long-running playback; use wake policies sparingly.

---

## 11) Test methodology using recorded sample sets

## Dataset composition (local test assets)
- Positive: infant cry clips across ages, distances, room types, device positions.
- Hard negatives: adult speech, TV, vacuum, door slam, dog bark, toy sounds, pink/white noise playback leakage.
- Mixed scenes: low SNR, reverb, overlapping household sounds.

### Evaluation protocol
- Frame-level and episode-level labels.
- Metrics:
  - Episode precision/recall/F1
  - False triggers per night-hour
  - Mean detection latency to cry onset
  - Battery drain per 8-hour session

### Acceptance targets (MVP suggestion)
- Recall >= 85% on curated positive set
- False triggers <= 1 per 8-hour mixed-scene run (balanced mode)
- Median latency <= 2.0 s from onset

### Regression testing
- Fixed golden feature vectors for deterministic unit tests.
- State-machine property tests for persistence/cooldown edges.
- Long soak tests (8-10 h) for memory and audio continuity.

---

## 12) Telemetry suggestions (no raw microphone storage)

Emit only aggregate, non-content events:
- `cry_detection_started/stopped`
- `cry_candidate_count`
- `cry_trigger_count`
- `cry_trigger_confidence_bucket` (e.g., 0.7-0.8)
- `false_positive_user_feedback` (thumbs-down)
- `action_taken_on_trigger` (volume ramp/timer extend/switch preset)
- `limiter_engagement_ratio_bucket`
- `session_battery_delta_bucket`

### Privacy constraints
- No raw audio upload.
- No feature vectors that enable reconstruction.
- Round timestamps to coarse buckets.
- Keep per-session IDs ephemeral/rotating.

---

## Algorithm pseudocode (MVP heuristics)

```pseudo
init config:
  frame_ms = 25
  hop_ms = 10
  sr = 16000
  cooldown_s = 120
  persist_N = 18          # ~180 ms at 10 ms hops
  window_M = 30           # 300 ms

state:
  last_trigger_time = -inf
  conf_ring = RingBuffer(seconds=4)
  amp_flags = RingBuffer(length=window_M)
  env_ring = RingBuffer(seconds=4)

for each hop frame x:
  xw = hann(x)
  rms_db = 20*log10(rms(xw) + eps)

  E_low  = band_energy(xw, 150, 400)
  E_mid  = band_energy(xw, 400, 1200)
  E_high = band_energy(xw, 1200, 3500)

  band_pattern = sigmoid(a1*log(E_mid/E_low) + a2*log(E_high/E_low))

  env = envelope(rms_db)
  env_ring.push(env)
  modulation = modulation_score(env_ring, band_hz=1..5)

  amp_ok = rms_db > adaptive_noise_floor_db + amp_margin_db
  amp_flags.push(amp_ok)
  persistence = count_true(amp_flags)/window_M

  conf = clamp01(0.30*norm_rms(rms_db)
               + 0.30*band_pattern
               + 0.20*modulation
               + 0.20*persistence)
  conf_ring.push(conf)

  if now - last_trigger_time < cooldown_s:
    emit(detected=false, confidence=conf, reason="cooldown")
    continue

  consecutive_high = consecutive(conf_ring, threshold=0.78)
  rolling_mean = mean_last(conf_ring, 2s)

  if (consecutive_high >= persist_N) or
     (rolling_mean >= 0.72 and persistence >= 0.60):
       emit(detected=true, confidence=max(conf, rolling_mean))
       last_trigger_time = now
       reset_short_term_state()
  else:
       emit(detected=false, confidence=conf)
```

---

## Platform-specific implementation advice

## iOS
- Replace `AVAudioPlayer` loop core with `AVAudioEngine + AVAudioPlayerNode` for seam-safe loop regions.
- Use `installTap` only for analysis; keep buffer size aligned with hop cadence.
- Prefer `AVAudioSession` category `.playback`; avoid unnecessary options that may increase route churn.
- For limiter, start with software limiter in engine graph; profile on older devices.

## Android
- For robust overnight playback and precise looping, prefer native audio path (Oboe/AAudio or tuned AudioTrack) over generic MediaPlayer.
- Keep cry detection in a foreground service only when enabled and user informed.
- Use `AudioRecord` at 16 kHz mono for analysis path.
- Implement identical state-machine parameters to iOS for parity and shared QA vectors.

---

## Concrete fixes to apply next in this repo

1. Migrate `AudioPlaybackService` from `AVAudioPlayer` to `AVAudioEngine` node graph.
2. Expand `CryHeuristicFrame` to include low/mid/high band energies and modulation score.
3. Update `LocalCryDetectionService.extractFeatures` to compute explicit band energies.
4. Extend `CryDetectionStateMachine` confidence model with temporal modulation and adaptive noise floor.
5. Replace static `NoiseSafetyPolicy` clamp with limiter engagement monitoring API.
6. Add long-run soak tests and false-positive benchmark harness using offline sample bundles.

