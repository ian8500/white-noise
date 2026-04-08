# DreamNest Mobile Privacy, Compliance, and App Review Readiness

_Date: April 8, 2026_

## 1) Key Risks

### A. Microphone and background-behavior review risk (Apple + Google)
- **High review sensitivity** any time an app requests microphone access, especially for features that can run while screen is off or app is backgrounded.
- Risk of rejection if permission text is vague (e.g., “for better experience”) or if app behavior appears broader than disclosed use.
- Risk increases if cry detection appears to imply continuous surveillance, safety guarantees, or medical monitoring.

### B. “Medical/safety claim” positioning risk
- Phrases like “detects distress,” “prevents hearing damage,” “sleep health monitoring,” or “keeps baby safe” can trigger medical-device or deceptive-claim scrutiny.
- “Safe listening limiter” can be viewed as a regulated/safety promise unless presented as a conservative user aid with clear limits.

### C. Child-directed/family policy risk
- App is for babies but purchased by adults: stores will still evaluate whether it is **child-directed** in design, imagery, language, and audience.
- If positioned as children/family content, stricter data handling and ad/SDK constraints apply.
- Any analytics/ads/profile tracking tied to child-directed positioning is higher risk.

### D. Subscription and dark-pattern risk
- Premium subscription requires transparent trial terms, billing cadence, renewal, cancellation route, and feature gating.
- Rejection risk if critical baby-related wording pressures urgent purchase (fear-based upsell).

### E. Data minimization risk
- Cry detection could unintentionally collect/store/transmit raw audio, derived sensitive inferences, or persistent identifiers.
- Storing audio snippets “for model improvement” without explicit opt-in creates major privacy and review risk.

### F. Background mode and battery behavior risk
- If app requests background audio/mic capabilities but user benefit is unclear, review may flag overbroad background execution.

---

## 2) Mitigation Steps

### A. Architect cry detection as on-device only by default
- Process audio stream locally in volatile memory.
- Do **not** store raw microphone audio unless user explicitly records a clip.
- Do **not** upload raw audio or cry-event features to servers by default.
- Keep event outputs minimal (e.g., “cry detected at 02:14 AM”) and user-deletable.

### B. Limit claims and add plain-language boundaries
- Describe as a **comfort feature** and **audio-pattern detection** only.
- Explicitly state: “Not a medical device; not a substitute for caregiver supervision.”

### C. Harden permissions and settings UX
- Ask for microphone only when user enables cry detection.
- Add just-in-time primer before system prompt.
- Provide “Not now” path and equivalent value from non-mic features.
- Add in-app toggle to disable cry detection and purge local cry history.

### D. Subscription compliance hygiene
- On paywall: price, period, trial length (if any), renewal behavior, cancellation instructions, and restoration path.
- Keep essential soothing playback usable without coercive paywall language.

### E. Child/family posture decision (pick one explicitly)
1. **Parent utility app (recommended):**
   - Market to caregivers, not children.
   - Avoid child-directed game-like UX and child-targeted ads.
2. **Family/child-directed listing:**
   - Remove behavioral ads/tracking SDKs.
   - Apply strictest data minimization and policy constraints.

### F. Internal controls
- Data map + retention table.
- SDK inventory with purpose tags.
- Privacy impact assessment for microphone feature before each major release.

---

## 3) Compliant UX Wording

### A. Pre-permission explainer (in-app)
**Title:** Enable cry detection (optional)

**Body:**
“DreamNest can listen for cry-like sound patterns on this device to trigger soothing actions. Audio is processed locally and is not recorded or uploaded by default.”

**Buttons:**
- “Continue”
- “Not now”

### B. iOS microphone usage description (Info.plist purpose string)
“Microphone access lets DreamNest detect cry-like sounds on your device and trigger soothing playback. Audio is processed locally and not uploaded by default.”

### C. Android runtime permission rationale
“Allow microphone so DreamNest can detect cry-like sounds on this device. Audio is processed locally for this feature.”

### D. Safety limiter copy
“Listening Limiter helps keep playback within your selected volume range. It is a guidance tool, not a guarantee of hearing safety.”

### E. Non-medical disclaimer (settings + onboarding + store listing)
“DreamNest is a comfort and sleep-audio app. It is not a medical device and does not provide medical or emergency monitoring.”

---

## 4) Store Listing Wording Do’s and Don’ts

### Do
- “Optional on-device cry detection.”
- “Microphone audio processed locally by default.”
- “Customizable timer fade-out and gentle white noise playback.”
- “Designed for caregiver convenience.”

### Don’t
- “Monitors your baby’s health.”
- “Prevents SIDS” / “prevents hearing loss.”
- “Guarantees safety while you sleep.”
- “AI baby monitor” (unless you truly provide compliant monitoring product claims and safeguards).

### Better phrasing examples
- Instead of “smart baby surveillance,” use “optional cry-sound detection to automate soothing playback.”
- Instead of “safe volume guaranteed,” use “set preferred maximum volume with built-in limiter controls.”

---

## 5) Privacy Checklist for Engineering

### Data that should never leave device (default posture)
- Raw microphone audio stream.
- Any buffered pre-cry/post-cry audio snippets.
- High-resolution acoustic embeddings/fingerprints that could reconstruct voice traits.
- Background audio transcripts.
- Fine-grained device sensor fusion for behavioral profiling.

### Local-only recommended data model
- Feature enabled flags (cry detection on/off, limiter on/off).
- Coarse event metadata (timestamp + event type), user-deletable.
- Local settings (volume cap, timer duration, selected sound).

### If cloud sync is offered (opt-in only)
- Sync only non-sensitive preferences.
- End-to-end encrypt sensitive sleep logs if synced.
- Separate account identifiers from usage telemetry where possible.

### Security and retention controls
- Encrypt at rest for any persisted event metadata.
- TTL auto-delete for event logs (e.g., 7/14/30 days configurable).
- One-tap “Delete all local data.”
- No third-party SDK access to mic-derived signals.

### Telemetry boundaries
- Aggregate product analytics only (feature toggles, crash, coarse performance).
- No ad personalization from cry-detection behavior.
- No sharing with data brokers.

---

## 6) Privacy Policy Outline

1. **Who the app is for** (caregivers/parents).
2. **What data is processed on-device** (microphone audio for cry detection, local processing statement).
3. **What data is stored** (settings, optional event timestamps).
4. **What data is not collected/transmitted** (raw audio by default).
5. **Optional cloud/account features** (if any) and legal basis/consent.
6. **Subscriptions and payment processors** (store-managed billing).
7. **Third-party services/SDK disclosures** (crash, analytics, payments).
8. **Retention schedule and deletion controls**.
9. **Children and family positioning statement**.
10. **Security safeguards**.
11. **Regional rights** (access, deletion, correction where applicable).
12. **Contact + policy update date**.

---

## 7) App Store Privacy Nutrition Label Considerations (Apple)

Prepare to classify data by:
- **Data used to track you**: ideally **none**.
- **Data linked to you**: account email (if account exists), purchase status, coarse diagnostics.
- **Data not linked to you**: aggregated usage metrics/crash data (if truly de-identified).

Potential categories to evaluate carefully:
- Contact info (if account/support).
- Identifiers (app instance/user ID).
- Usage data (feature interactions).
- Diagnostics (crash/performance).
- Sensitive data: avoid collecting audio content remotely unless absolutely required and separately consented.

If microphone audio is only on-device and never sent, ensure disclosures match exact behavior and SDK reality.

---

## 8) Play Data Safety Considerations (Google Play)

For each data type declare:
- Collected?
- Shared?
- Purpose (app functionality, analytics, fraud prevention, etc.)
- Optional/required
- In-transit encryption and deletion support

Recommended target posture:
- No audio data collection to server by default.
- No sharing of personal data with third parties for advertising.
- Clear deletion mechanism.
- Accurate declaration of subscription purchase data handled via Play billing.

If any diagnostics include device identifiers, ensure declaration aligns exactly with SDK output.

---

## 9) Child/Family Positioning Risks and Recommendation

### Risk profile
- Baby-themed branding can be interpreted as child-directed.
- If marked as family/children, policy expectations tighten around data practices and SDK use.

### Recommended positioning
- Position DreamNest as a **caregiver tool** for parents.
- Use caregiver-centric screenshots/copy.
- Avoid interactive child-directed elements and child-focused ad monetization.
- Add explicit statement: “Intended for use by parents/caregivers.”

---

## 10) Launch Gate Checklist

### Policy & legal
- [ ] Microphone purpose strings finalized and tested on-device.
- [ ] Non-medical disclaimer present in onboarding, settings, and listing.
- [ ] Privacy Policy published and versioned.
- [ ] Data Processing Addendum/vendor terms reviewed for all SDKs.

### Product & UX
- [ ] Just-in-time mic consent flow implemented.
- [ ] Feature works without mic permission (graceful degradation).
- [ ] In-app controls: disable cry detection, clear history, delete data.
- [ ] Subscription disclosures complete and legible pre-purchase.

### Engineering
- [ ] Confirm no raw mic audio leaves device (network inspection test).
- [ ] Confirm no raw mic audio persists to disk by default.
- [ ] Event logs retention + deletion tested.
- [ ] SDK audit confirms no hidden collection from mic feature.

### App review readiness
- [ ] Demo account / reviewer notes explain on-device cry detection behavior.
- [ ] Store metadata avoids medical/surveillance/safety guarantees.
- [ ] Child-directed signals reviewed (copy, visuals, category, ads).
