# DreamNest — Mobile UX/UI Design Spec (Developer Handoff)

## 0) Project review summary (advice + fixes)

Based on the current product architecture and privacy review documents, DreamNest has a strong technical foundation, especially around offline reliability, on-device cry detection, and safety posture. This UX/UI spec tightens the product experience around exhausted-parent behavior in low-light contexts.

### What is already strong
- Parent-first positioning and premium tone are clear.
- Night reliability and background playback are correctly treated as critical.
- Safety and privacy messaging are product-level concerns, not afterthoughts.

### Recommended UX/product fixes to prioritize
1. **Reduce first-session setup friction to < 20 seconds**
   - Introduce a one-tap “Start Tonight” path before account/paywall complexity.
2. **Permission trust gap fix**
   - Add pre-permission education cards before OS prompts (microphone + notifications).
3. **Core action prominence fix**
   - On Home/Now Playing, ensure only one dominant CTA at any time: Play/Pause.
4. **Safety comprehension fix**
   - Add clear in-context “why this matters” copy in timer fade, max volume cap, and safe placement screens.
5. **Premium value clarity fix**
   - Tie premium upsell to nighttime outcomes (“fewer wakeups, less manual intervention”) rather than feature list only.
6. **At-a-glance state confidence fix**
   - Persistent status row: active sound, timer remaining, automation state, volume cap state.

---

## 1) Product UX north star

### Experience principles
1. **Calm under pressure**: every screen should lower cognitive load within 2 seconds.
2. **One-thumb in darkness**: frequent actions sit in lower 60% of the screen.
3. **Trust by transparency**: plain-language privacy/safety explanations next to controls.
4. **Luxurious restraint**: fewer elements, richer spacing, subtle depth.
5. **Parent-first utility**: practical outcomes over cute visuals.

### Primary user context
- One hand occupied (holding baby).
- Dim lighting / sleep deprivation.
- High need for certainty and quick action.

---

## 2) Design system

## 2.1 Color tokens (moonlight/dusk palette)
Use semantic tokens in code; avoid hardcoded hex in components.

### Core surfaces
- `color.bg.base` = `#0F1220` (deep dusk navy)
- `color.bg.elevated` = `#171B2E`
- `color.bg.card` = `#1D2238`
- `color.bg.overlay` = `rgba(8,10,18,0.62)`

### Gradients
- `gradient.hero.night` = `#1A1F36 -> #2A3155 -> #3D4A72`
- `gradient.cta.softMoon` = `#9AA8D6 -> #B9C6EA`
- `gradient.accent.warmCloud` = `#C6B7A8 -> #E2D6CA`

### Text
- `color.text.primary` = `#F6F7FB`
- `color.text.secondary` = `#C7CCDB`
- `color.text.tertiary` = `#9EA6BD`
- `color.text.inverse` = `#0E1120`

### Accent/feedback
- `color.accent.primary` = `#B7C4EE`
- `color.accent.secondary` = `#D7C7B8`
- `color.state.success` = `#79C4A3`
- `color.state.warning` = `#F2C27B`
- `color.state.error` = `#EE8F9B`
- `color.state.info` = `#91B7FF`

### Safety highlighting
- `color.safety.cap` = `#88D0B4`
- `color.safety.alert` = `#F0BA7C`

## 2.2 Typography system
Use dynamic type-compatible scale, high readability, generous line height.

- `type.display.l` — 34/40, semibold (hero onboarding)
- `type.display.m` — 28/34, semibold
- `type.title.l` — 24/30, semibold
- `type.title.m` — 20/26, semibold
- `type.body.l` — 17/24, regular
- `type.body.m` — 15/22, regular
- `type.label.l` — 15/20, medium
- `type.label.m` — 13/18, medium
- `type.caption` — 12/16, regular
- `type.numeric.timer` — 32/36, medium (tabular numerals)

## 2.3 Spacing tokens (4-pt base)
- `space.1`=4, `space.2`=8, `space.3`=12, `space.4`=16, `space.5`=20, `space.6`=24, `space.8`=32, `space.10`=40, `space.12`=48.
- Screen horizontal padding: 20.
- Minimum vertical rhythm between sections: 24.

## 2.4 Corner radius system
- `radius.xs`=8 (chips)
- `radius.s`=12 (inputs)
- `radius.m`=16 (cards)
- `radius.l`=22 (bottom sheets)
- `radius.xl`=28 (hero cards)
- `radius.pill`=999 (primary CTA)

## 2.5 Elevation/depth
- `elevation.0` flat (background)
- `elevation.1` card soft shadow 8% black, y=4, blur=16
- `elevation.2` active card 12% black, y=8, blur=24
- `elevation.glow` accent outer glow 20% primary accent, blur=18 (sparingly)

## 2.6 Icon style
- 2px stroke, rounded caps/joins.
- Optical size aligned to 24dp base.
- No playful/cartoon metaphors.
- Prefer abstract calm symbols (moon, waveform, shield, timer, heart-shield).

## 2.7 Core components
- Primary pill button (56h min tap target).
- Secondary ghost button.
- Segmented control.
- Sound card (art + tags + quick actions).
- Volume/timer slider with enlarged thumb and haptic snap points.
- Toggle rows with explanation text.
- Inline status banner (non-blocking warning/info).
- Modal bottom sheet (large drag handle + 3 snap points).

---

## 3) Interaction principles

1. **Single dominant action per screen state.**
2. **Predictable gestures:** swipe down to dismiss sheets, never hidden destructive gestures.
3. **Progressive disclosure:** advanced controls hidden behind “Advanced”.
4. **Low-light comfort:** avoid pure black/white contrast spikes and high-frequency animation.
5. **Haptics:** light impact for start/stop, selection haptics for timer presets.
6. **Recovery-first errors:** always give immediate fallback (“Continue with basic playback”).

---

## 4) Accessibility standards

- WCAG 2.2 AA contrast minimum (4.5:1 text, 3:1 large text/icons).
- Dynamic Type support through at least iOS Accessibility XXL.
- VoiceOver labels for every icon-only control.
- 44x44pt minimum touch targets (56pt recommended for nighttime core actions).
- Motion reduction: respect “Reduce Motion” with crossfade-only transitions.
- Color is never sole meaning carrier (icons + labels on warnings/safety state).
- Left/right thumb reach accommodations: allow bottom action rail to mirror in settings.

---

## 5) Screen-by-screen spec

## 5.1 Onboarding

### Content hierarchy
1. Brand reassurance headline.
2. Outcome-focused value props (sleep continuity, safety, privacy).
3. “Start Tonight” primary CTA.
4. Optional personalization (baby age, sleep goal).

### Layout rationale
- 3-card carousel max (no long tutorials).
- Bottom-anchored CTA for one-hand reach.
- Skip available but visually secondary.

### Components
- Full-width gradient hero.
- Progress dots.
- Primary CTA: “Start Tonight”.
- Secondary text button: “Customize first”.

### Microcopy
- Headline: “A calmer night, in one tap.”
- Subtext: “Premium soothing sounds designed for exhausted parents.”
- Privacy line: “Cry response is processed on your device.”

### Motion guidance
- Slow 350ms fade/slide between cards.
- Parallax max 6dp equivalent.

### States
- Empty: N/A.
- Loading: shimmer on hero artwork if remote config present.
- Error: if onboarding config fails, fallback to default static 3-card flow.

### Accessibility notes
- Disable auto-advance.
- VoiceOver reads card position (“Card 1 of 3”).

---

## 5.2 Permission education screens

### Content hierarchy
1. Why permission helps tonight.
2. Privacy commitment.
3. CTA to continue to OS prompt.

### Layout rationale
- One permission per screen (Microphone, Notifications).
- Avoid stacked prompts.

### Components
- Permission icon badge.
- Plain-language explanation card.
- Primary CTA: “Allow Microphone” / “Allow Notifications”.
- Secondary CTA: “Not now”.

### Microcopy
- Mic title: “Hear cries, without sending audio anywhere.”
- Mic body: “DreamNest listens on-device only to trigger your chosen response.”
- Notifications body: “We’ll only notify for timer end or important safety reminders.”

### Motion guidance
- OS handoff transition 200ms.

### States
- Denied state: show recovery steps and deep-link to Settings.
- Limited functionality state: explain what remains available.

### Accessibility notes
- Ensure CTA labels include action + destination (“Open system permission dialog”).

---

## 5.3 Home / Now Playing

### Content hierarchy
1. Current session status (sound, timer, automation, cap).
2. Large Play/Pause control.
3. Quick adjustments (volume, timer, sound switch).
4. Contextual safety banner (if needed).

### Layout rationale
- Thumb zone at bottom: play/pause and timer shortcuts.
- Session summary at top for confidence glance.

### Components
- Hero sound art + subtle animated waveform ring.
- Play/Pause primary pill (min 64h).
- Timer chip row (15/30/60/∞).
- Volume slider with safety cap marker.
- Bottom sheet triggers: “Library”, “Timer”, “Automations”.

### Microcopy
- Status line: “Brown Noise • 42 min left.”
- Safety banner: “Volume is above your cap recommendation.” + CTA “Lower now”.

### Motion guidance
- Waveform breath animation 4s loop, opacity only.
- Play/Pause morph 180ms.

### States
- Empty (no preset): “Pick a sound to begin tonight.”
- Loading: skeleton for artwork + metadata.
- Error playback: “Playback interrupted.” CTA “Resume in 1 tap”.

### Accessibility notes
- Slider supports step increments via VoiceOver rotor.
- Timer remaining announced every significant change threshold.

---

## 5.4 Sound Library

### Content hierarchy
1. Search.
2. Recommended for tonight.
3. Categories.
4. Full library list.

### Layout rationale
- Category chips pinned top.
- Cards large enough for quick recognition in low light.

### Components
- Search field with recent terms.
- Category chips: Noise, Nature, Rhythmic, Ventilation.
- Sound cards (name, preview, favorite, premium badge).
- “Play instantly” quick action.

### Microcopy
- Empty search: “No exact match. Try ‘rain’ or ‘fan’.”
- Premium badge: “Premium Mix Ready”.

### Motion guidance
- Card press depth transition 120ms.
- Mini preview crossfade 150ms.

### States
- Empty favorites category.
- Loading list skeleton.
- Error state: retry + offline indicator.

### Accessibility notes
- Do not autoplay previews with VoiceOver on.
- Provide explicit “Preview” and “Play now” controls.

---

## 5.5 Timer setup

### Content hierarchy
1. Quick presets.
2. Custom duration.
3. Fade-out behavior.
4. Apply CTA.

### Layout rationale
- Bottom sheet from Home for speed.
- Presets as large segmented pills.

### Components
- Preset chips 15/30/45/60/90/120/∞.
- Wheel picker or stepper for custom time.
- Fade selector (1/3/5/10 min).
- Save as default toggle.

### Microcopy
- Assistive line: “Fade-out helps avoid abrupt silence.”
- CTA: “Set Timer”.

### Motion guidance
- Haptic snap on preset selection.

### States
- Invalid custom time (below 5m): inline validation.
- Persist failure: non-blocking toast “Couldn’t save default, timer still set.”

### Accessibility notes
- Time picker must be fully screen-reader operable.

---

## 5.6 Cry response settings (Premium)

### Content hierarchy
1. Master toggle.
2. Trigger sensitivity.
3. Response actions.
4. Privacy explainer.

### Layout rationale
- Reassurance copy directly under each control.
- Advanced options collapsed by default.

### Components
- Toggle: Enable Cry Response.
- Sensitivity slider (Low/Medium/High with labels).
- Action rows: volume ramp max, timer extension, preset switch.
- “Test response” simulation button.

### Microcopy
- “Audio never leaves your phone.”
- “Recommended: Medium sensitivity to reduce false triggers.”

### Motion guidance
- Simulated event animation (subtle pulse + progress).

### States
- Mic denied: inline blocker with “Open Settings”.
- Premium locked: compact upgrade card.
- Error processing: “Cry detection paused. Playback continues normally.”

### Accessibility notes
- Sensitivity labels read with numeric mapping for screen readers.

---

## 5.7 Noise protection settings

### Content hierarchy
1. Max playback cap.
2. Safe-use reminders.
3. Alert behavior.
4. Learn more link.

### Layout rationale
- Keep safety controls simple; avoid technical jargon/dB overload.

### Components
- Slider with recommended zone tint.
- Toggle: “Warn me above recommended level”.
- Toggle: “Auto-limit in app”.
- Info card: safe placement rules.

### Microcopy
- “Set a comfort cap to prevent accidental loud starts.”
- “Place phone at least an arm’s length from baby.”

### Motion guidance
- Cap marker animates into place on first setup.

### States
- No output route data: “We can’t read connected speaker level. Cap still applies in-app.”

### Accessibility notes
- Avoid red-only warnings; pair icon + text + haptic warning.

---

## 5.8 Presets / Favorites

### Content hierarchy
1. Tonight presets.
2. Favorites.
3. Recent sessions.
4. Create new preset.

### Layout rationale
- Grid/list toggle; default list for readability.
- Reorder via drag handle with clear mode.

### Components
- Preset card (name, layers, timer, automation badge).
- Favorite toggle.
- Duplicate/edit/delete actions.
- “Quick Start” pinned preset option.

### Microcopy
- Empty: “Save your first preset to start nights faster.”
- CTA: “Create Preset”.

### Motion guidance
- Reorder with spring 220ms.

### States
- Empty state illustration (abstract moon/cloud).
- Sync/loading state for premium cloud backup.
- Error: failed save with retry.

### Accessibility notes
- Provide non-drag alternative reorder controls.

---

## 5.9 Premium upsell

### Content hierarchy
1. Outcome promise.
2. 3 key premium benefits.
3. Plan options and trial terms.
4. Primary subscribe CTA.
5. Restore/manage links.

### Layout rationale
- Full-screen modal with trust-first framing.
- Benefits mapped to moments (“when baby cries”, “when you’re exhausted”).

### Components
- Hero benefit card.
- Benefit bullets with icons.
- Plan selector (monthly/yearly).
- Primary CTA “Start 7-Day Free Trial”.
- Secondary: “Continue with Free”.

### Microcopy
- Header: “Get more sleep with less intervention.”
- Trust note: “Cancel anytime in App Store settings.”

### Motion guidance
- Content reveal stagger 50ms steps, total < 250ms.

### States
- Billing unavailable: graceful fallback and retry.
- Restore failure: clear instructions with support link.

### Accessibility notes
- Trial terms always visible without extra tap.

---

## 5.10 Bedtime guidance / safe use page

### Content hierarchy
1. Safe setup checklist.
2. Volume and distance best practices.
3. Sleep environment tips.
4. Disclaimer + emergency boundary.

### Layout rationale
- Scannable checklist format with icon bullets.
- Sticky “Got it” CTA.

### Components
- Checklist cards.
- Expandable FAQ rows.
- “Apply recommended safety settings” shortcut.

### Microcopy
- “DreamNest supports sleep routines; it is not a medical monitor.”
- “If your baby seems unwell, seek professional care.”

### Motion guidance
- FAQ expansion 180ms.

### States
- Offline content always available (bundle local copy).

### Accessibility notes
- Keep reading level around 6th–8th grade.

---

## 6) Premium subscription placement rules

1. **Never interrupt first playback start.**
2. Upsell at naturally high-intent moments only:
   - enabling cry response,
   - saving >1 preset,
   - attempting dual-layer mix.
3. Always provide visible “Continue Free” path.
4. Frequency cap: max 1 full-screen upsell per 48 hours unless user triggers premium feature directly.
5. Reinforce trust in paywall footer: privacy + cancellation transparency.
6. Suppress upsell for 7 days after explicit decline unless user initiates locked feature.

---

## 7) Developer implementation notes

- Build tokens as centralized constants (`ColorToken`, `SpaceToken`, `RadiusToken`, `TypeToken`).
- Home screen should render within 1 frame using cached last session state.
- Use state machine to enforce one dominant CTA and prevent conflicting controls.
- All critical controls must be reachable within lower 2/3 viewport on iPhone mini-size devices.
- Preload last-used sound artwork + metadata at app launch.
- Persist permission education dismissal state separately from OS permission status.

---

## 8) QA checklist (UX acceptance)

1. Parent can start playback from cold launch in <= 2 taps.
2. No required permission gate before first successful playback.
3. All primary controls meet touch target and dynamic type requirements.
4. VoiceOver can complete onboarding, start playback, set timer, and toggle cry response.
5. Premium upsell rules respect frequency cap and never block emergency use.
6. Safety warning is visible but non-blocking and actionable in one tap.

---

## 9) Suggested next design deliverables

1. High-fidelity dark-mode component library in Figma using tokens above.
2. Interactive prototype for 3 critical night flows:
   - first-night quick start,
   - timer adjustment mid-session,
   - cry-response trigger and reassurance state.
3. Copy deck with localization-ready strings and character limits.
4. Usability test script for sleep-deprived-parent simulation (dim light + one hand).
