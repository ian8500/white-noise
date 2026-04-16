import Combine
import Foundation
import OSLog
#if os(iOS)
import UIKit
#endif

private let homeLogger = Logger(subsystem: "com.dreamnest.app", category: "Home")

@MainActor
final class HomeViewModel: ObservableObject {
    enum SessionMode: Equatable {
        case mainProgramme
        case sleepPreset
        case napPreset
        case autoResettling
    }


    struct TonightAnchor {
        let prompt: String
        let supportingLine: String
        let ctaTitle: String
        let action: () -> Void
    }

    struct NightReplay {
        let headline: String
        let toolsUsed: String
        let mostUsed: String
        let fastestSettle: String
    }

    private static let cryTriggeredSoundID = "white-noise"
    private static let defaultRoutineDuration: TimeInterval = 30 * 60

    @Published var selectedSound: SoundDefinition
    @Published var volume: Float
    @Published var timerRemaining: TimeInterval = 0
    @Published var isPlaying = false
    @Published var warningBanner: String?
    @Published var cryModeEnabled: Bool
    @Published var cryDetectionThreshold: Float
    @Published var cryComfortMode: CryComfortMode
    @Published var showCryOnboarding = false
    @Published private(set) var isCryMonitoringActive = false
    @Published private(set) var lastCryDetectionTime: Date?
    @Published private(set) var lastCryConfidence: Float?
    @Published private(set) var lastCryActionSummary = "No cry events yet"
    @Published private(set) var cryCooldownRemaining: TimeInterval = 0
    @Published private(set) var recentCryEvents: [CryEventRow] = []
    @Published private(set) var smartResettleSession: SmartResettleSession?
    @Published private(set) var smartResettleStatusLabel = "Ready for rest"
    @Published private(set) var activeQuickPreset: PlaybackPreset?
    @Published private(set) var favoriteSoundIDs: Set<String>
    @Published private(set) var recentSoundIDs: [String]
    @Published private(set) var routinePresets: [RoutinePreset]
    @Published private(set) var defaultRoutinePresetID: UUID?
    @Published private(set) var timerDurationMinutes: Int
    @Published private(set) var activeSessionMode: SessionMode?

    let catalog: [SoundDefinition]

    private var settings: AppSettings
    private let audio: AudioPlaybackControlling
    private let timer: SleepTimerScheduling
    private let store: SettingsStoring
    private let cryService: CryDetectionControlling
    private let systemVolume: SystemVolumeControlling
    private let playbackSessionStore: PlaybackSessionStoring
    private let safetyPolicy: NoiseSafetyPolicy
    private let cryResponseCoordinator: CryResponseCoordinator
    private let dateProvider: () -> Date
    private var cancellables = Set<AnyCancellable>()
    private var playbackTask: Task<Void, Never>?
    private var cryMonitoringTask: Task<Void, Never>?
    private var playbackGeneration: Int = 0
    private var wasTimerRunning = false
    private var recentCryConfidenceHits: [Date] = []
    private var consecutiveDetectedSignals = 0
    private var lastDetectedSignalAt: Date?

    init(
        catalogService: SoundCatalogProviding,
        audio: AudioPlaybackControlling,
        timer: SleepTimerScheduling,
        store: SettingsStoring,
        cryService: CryDetectionControlling,
        systemVolume: SystemVolumeControlling? = nil,
        playbackSessionStore: PlaybackSessionStoring,
        safetyPolicy: NoiseSafetyPolicy,
        cryResponseCoordinator: CryResponseCoordinator,
        dateProvider: @escaping () -> Date = Date.init
    ) {
        self.catalog = catalogService.sounds
        self.audio = audio
        self.timer = timer
        self.store = store
        self.cryService = cryService
        self.systemVolume = systemVolume ?? NoOpSystemVolumeController()
        self.playbackSessionStore = playbackSessionStore
        self.safetyPolicy = safetyPolicy
        self.cryResponseCoordinator = cryResponseCoordinator
        self.dateProvider = dateProvider

        settings = store.load()
        settings.timer.duration = Self.defaultRoutineDuration
        store.save(settings)

        let fallbackCatalog = self.catalog.isEmpty ? SoundDefinition.seededCatalog : self.catalog
        selectedSound = catalogService.sound(id: settings.lastSoundID)
            ?? fallbackCatalog.first
            ?? SoundDefinition.seededCatalog[0]
        volume = safetyPolicy.clamped(volume: self.systemVolume.currentVolume)
        cryModeEnabled = settings.cryResponse.enabled
        cryDetectionThreshold = settings.cryResponse.detectionThreshold
        cryComfortMode = settings.cryResponse.comfortMode
        favoriteSoundIDs = settings.favoriteSoundIDs
        recentSoundIDs = settings.recentSoundIDs
        recentCryEvents = store.loadCryEvents(limit: 200).map(CryEventRow.init)

        if settings.routinePresets.isEmpty {
            settings.routinePresets = RoutinePreset.seededDefaults(using: settings)
            settings.defaultRoutinePresetID = settings.routinePresets.first?.id
            store.save(settings)
        }

        routinePresets = settings.routinePresets
        defaultRoutinePresetID = settings.defaultRoutinePresetID
        timerDurationMinutes = Self.minutes(from: settings.timer.duration)
        activeSessionMode = nil

        bind()
        cryService.updateDetectionThreshold(settings.cryResponse.detectionThreshold)
        cryService.updateCooldown(settings.cryResponse.cooldown)
        restorePlaybackSessionIfNeeded()
        startCryMonitoringIfNeeded()
        refreshCooldownState()
    }

    deinit {
        playbackTask?.cancel()
        cryMonitoringTask?.cancel()
    }

    func quickStart() {
        activeQuickPreset = nil
        smartResettleSession = nil
        updateSmartResettleStatus()
        startRoutine(
            sound: selectedSound,
            volume: volume,
            timerDuration: settings.timer.duration,
            cryModeEnabled: cryModeEnabled,
            sessionMode: .mainProgramme
        )
    }

    func startDefaultRoutine() {
        quickStart()
    }

    func startPreset(_ preset: PlaybackPreset) async {
        let config = quickPresetConfiguration(for: preset)
        let presetSound = quickPresetSound(for: preset)
        let sessionStart = dateProvider()
        setTimerDuration(seconds: config.duration)
        selectSound(presetSound)
        let effectiveCryMode = config.cryModeEnabled || config.smartResettleEnabled
        toggleCryMode(effectiveCryMode)
        activeQuickPreset = preset
        smartResettleSession = config.smartResettleEnabled
            ? SmartResettleSession(
                preset: preset,
                sound: presetSound,
                presetDuration: config.duration,
                sessionStartTime: sessionStart,
                scheduledTimerEnd: sessionStart.addingTimeInterval(config.duration),
                cryDetectionEnabled: effectiveCryMode,
                configuration: .init(
                    listeningWindow: config.listeningWindow,
                    resettleDuration: config.resettleDuration,
                    maxAutoResettles: config.maxAutoResettles
                )
            )
            : nil
        updateSmartResettleStatus()
        store.save(settings)
        await startPlayback(
            sound: presetSound,
            duration: settings.timer.duration,
            micModeEnabled: effectiveCryMode,
            sessionMode: .playingPreset
        )
        if isPlaying {
            activeSessionMode = preset == .bedtime ? .sleepPreset : .napPreset
        }
    }

    func quickPresetConfiguration(for preset: PlaybackPreset) -> QuickStartPresetSettings {
        settings.quickStartPresets[preset.rawValue] ?? .default(for: preset)
    }

    func updateQuickPreset(
        _ preset: PlaybackPreset,
        durationMinutes: Int? = nil,
        cryModeEnabled: Bool? = nil,
        soundID: String? = nil,
        smartResettleEnabled: Bool? = nil,
        listeningWindowMinutes: Int? = nil,
        resettleDurationMinutes: Int? = nil,
        maxAutoResettles: Int? = nil
    ) {
        var config = quickPresetConfiguration(for: preset)
        if let durationMinutes {
            config.duration = TimeInterval(max(1, durationMinutes) * 60)
        }
        if let cryModeEnabled {
            config.cryModeEnabled = cryModeEnabled
        }
        if let soundID {
            config.soundID = soundID
        }
        if let smartResettleEnabled {
            config.smartResettleEnabled = smartResettleEnabled
        }
        if let listeningWindowMinutes {
            config.listeningWindow = TimeInterval(max(15, listeningWindowMinutes) * 60)
        }
        if let resettleDurationMinutes {
            config.resettleDuration = TimeInterval(max(3, resettleDurationMinutes) * 60)
        }
        if let maxAutoResettles {
            config.maxAutoResettles = max(1, min(maxAutoResettles, 3))
        }
        settings.quickStartPresets[preset.rawValue] = config
        store.save(settings)
    }


    func quickPresetSound(for preset: PlaybackPreset) -> SoundDefinition {
        let config = quickPresetConfiguration(for: preset)
        if let soundID = config.soundID,
           let sound = catalog.first(where: { $0.id == soundID }) {
            return sound
        }
        return selectedSound
    }

    func clearCryEvents() {
        store.clearCryEvents()
        recentCryEvents = []
        lastCryActionSummary = "No cry events yet"
    }

    func loadCryEventRows(limit: Int = 200) -> [CryEventRow] {
        store.loadCryEvents(limit: limit).map(CryEventRow.init)
    }




    var tonightAnchor: TonightAnchor {
        if mainButtonIsActive {
            return TonightAnchor(
                prompt: "Your anchor is running. Keep the room quiet and let your body coast.",
                supportingLine: "You are already in progress—no extra steps needed.",
                ctaTitle: "Stop session",
                action: { [weak self] in self?.handleMainSleepButtonTap() }
            )
        }

        if let lastEvent = recentCryEvents.first {
            return TonightAnchor(
                prompt: "Return to your last helpful reset.",
                supportingLine: "\(lastEvent.actionDescription) worked recently. Repeating familiar support often settles faster.",
                ctaTitle: "Restart gentle reset",
                action: { [weak self] in
                    self?.applyTimerPreset(minutes: 2)
                    self?.startDefaultRoutine()
                }
            )
        }

        if timerDurationMinutes <= 2 {
            return TonightAnchor(
                prompt: "Start your usual 2-minute settle.",
                supportingLine: "A brief, predictable beginning can quiet decision fatigue.",
                ctaTitle: "Begin 2-minute settle",
                action: { [weak self] in
                    self?.applyTimerPreset(minutes: 2)
                    self?.startDefaultRoutine()
                }
            )
        }

        return TonightAnchor(
            prompt: "Keep it simple tonight: breathe, then rest.",
            supportingLine: "One calm sound and one short timer is enough.",
            ctaTitle: "Start tonight's anchor",
            action: { [weak self] in
                self?.applyTimerPreset(minutes: 10)
                self?.startDefaultRoutine()
            }
        )
    }

    var nightReplay: NightReplay {
        if recentCryEvents.isEmpty {
            return NightReplay(
                headline: "Last night was quiet and steady.",
                toolsUsed: "Anchor routine",
                mostUsed: "2-minute settle",
                fastestSettle: "Breathing guide"
            )
        }

        let actionCounts = Dictionary(grouping: recentCryEvents, by: { $0.actionDescription })
            .mapValues(\.count)
        let topAction = actionCounts.max(by: { $0.value < $1.value })?.key ?? "Anchor routine"
        let tools = Set(recentCryEvents.map { $0.actionDescription }).sorted().prefix(3).joined(separator: ", ")

        return NightReplay(
            headline: "You kept showing up for yourself in small, steady ways.",
            toolsUsed: tools,
            mostUsed: topAction,
            fastestSettle: timerDurationMinutes <= 2 ? "60-second reset" : "2-minute settle"
        )
    }

    var defaultRoutinePreset: RoutinePreset? {
        guard let defaultRoutinePresetID else { return nil }
        return routinePresets.first(where: { $0.id == defaultRoutinePresetID })
    }

    func startRoutine(preset: RoutinePreset) {
        applyPreset(preset)
        activeQuickPreset = nil
        smartResettleSession = nil
        updateSmartResettleStatus()
        startRoutine(
            sound: selectedSound,
            volume: volume,
            timerDuration: settings.timer.duration,
            cryModeEnabled: cryModeEnabled,
            sessionMode: .mainProgramme
        )
    }

    func saveCurrentAsPreset(named name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let preset = RoutinePreset(
            name: trimmed,
            soundID: selectedSound.id,
            volume: volume,
            timerDuration: settings.timer.duration,
            cryModeEnabled: cryModeEnabled
        )
        settings.routinePresets.append(preset)
        if settings.defaultRoutinePresetID == nil {
            settings.defaultRoutinePresetID = preset.id
        }
        syncRoutineSettings()
    }

    func renamePreset(id: UUID, name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty,
              let index = settings.routinePresets.firstIndex(where: { $0.id == id })
        else { return }
        settings.routinePresets[index].name = trimmed
        syncRoutineSettings()
    }

    func movePresets(from source: IndexSet, to destination: Int) {
        let moving = source.sorted().map { settings.routinePresets[$0] }
        for index in source.sorted(by: >) {
            settings.routinePresets.remove(at: index)
        }
        var insertAt = destination
        for index in source where index < destination {
            insertAt -= 1
        }
        settings.routinePresets.insert(contentsOf: moving, at: max(0, min(insertAt, settings.routinePresets.count)))
        syncRoutineSettings()
    }

    func setDefaultPreset(id: UUID) {
        guard settings.routinePresets.contains(where: { $0.id == id }) else { return }
        settings.defaultRoutinePresetID = id
        syncRoutineSettings()
    }

    func applyPreset(_ preset: RoutinePreset) {
        guard catalog.contains(where: { $0.id == preset.soundID }) else { return }
        if let sound = catalog.first(where: { $0.id == preset.soundID }) {
            selectSound(sound)
        }
        setVolume(preset.volume)
        setTimerDuration(seconds: preset.timerDuration)
        toggleCryMode(preset.cryModeEnabled)
        store.save(settings)
    }

    func stopPlayback() {
        Task { await stopPlaybackFromAutomation() }
    }

    func stopPlaybackFromAutomation() async {
        if let session = smartResettleSession {
            appendSmartResettleEvent(
                .sessionManuallyStopped,
                preset: session.preset,
                sound: session.sound,
                confidence: 0,
                duration: session.resettleEndTime?.timeIntervalSince(session.lastAutoResettleAt ?? session.sessionStartTime)
            )
        }
        timer.cancel()
        playbackSessionStore.clear()
        await audio.stop(fadeDuration: 0.3)
        isPlaying = false
        activeSessionMode = nil
        smartResettleSession = nil
        activeQuickPreset = nil
        updateSmartResettleStatus()
    }

    func setVolume(_ value: Float) {
        let clamped = safetyPolicy.clamped(volume: value)
        if safetyPolicy.shouldWarn(for: value) {
            warningBanner = "Volume capped for hearing safety guidance."
        }
        volume = clamped
        systemVolume.setSystemVolume(clamped)
        audio.updateVolume(clamped, rampDuration: 0.25)
        settings.lastVolume = clamped
        store.save(settings)
        persistPlaybackSnapshotIfNeeded()
    }

    func selectSound(_ sound: SoundDefinition) {
        let previousSoundID = selectedSound.id
        if previousSoundID == sound.id {
            return
        }

        selectedSound = sound
        settings.lastSoundID = sound.id
        settings.recentSoundIDs.removeAll(where: { $0 == sound.id })
        settings.recentSoundIDs.insert(sound.id, at: 0)
        settings.recentSoundIDs = Array(settings.recentSoundIDs.prefix(5))
        recentSoundIDs = settings.recentSoundIDs
        store.save(settings)

        guard isPlaying else { return }

        if var session = smartResettleSession {
            session.sound = sound
            smartResettleSession = session
        }

        Task { [weak self] in
            guard let self else { return }
            do {
                try self.audio.configureSession(micModeEnabled: self.cryModeEnabled)
                try await self.audio.play(
                    sound: sound,
                    volume: self.safetyPolicy.clamped(volume: self.volume)
                )
                self.persistPlaybackSnapshotIfNeeded()
            } catch {
                self.warningBanner = "Couldn't switch sound: \(error.localizedDescription)"
                homeLogger.error("sound switch failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    func toggleFavorite(_ sound: SoundDefinition) {
        if settings.favoriteSoundIDs.contains(sound.id) {
            settings.favoriteSoundIDs.remove(sound.id)
        } else {
            settings.favoriteSoundIDs.insert(sound.id)
        }
        favoriteSoundIDs = settings.favoriteSoundIDs
        store.save(settings)
    }

    func isFavorite(_ sound: SoundDefinition) -> Bool {
        favoriteSoundIDs.contains(sound.id)
    }

    var recentSounds: [SoundDefinition] {
        recentSoundIDs.compactMap { id in
            catalog.first(where: { $0.id == id })
        }
    }

    func applyTimerPreset(minutes: Int) {
        setTimerDuration(minutes: minutes)
    }

    func adjustTimerDuration(minutesDelta: Int) {
        setTimerDuration(minutes: timerDurationMinutes + minutesDelta)
    }

    var formattedTimerRemaining: String {
        Self.formatAsMinutesAndSeconds(timerRemaining)
    }

    var formattedTimerDuration: String {
        Self.formatAsMinutesAndSeconds(settings.timer.duration)
    }

    var configuredTimerDuration: TimeInterval {
        settings.timer.duration
    }

    var selectedTimerPresetMinutes: Int? {
        let presets = [30, 45, 60, 120]
        return presets.contains(timerDurationMinutes) ? timerDurationMinutes : nil
    }

    var timerCountdownTitle: String {
        if isPlaying, timerRemaining > 0 {
            return "\(timerDurationFriendlyLabel) left"
        }
        return "Ready: \(timerDurationFriendlyLabel)"
    }

    var timerCountdownSubtitle: String {
        if isPlaying, timerRemaining > 0 {
            return "Playback stops automatically when countdown reaches 00:00."
        }
        return "Starts from \(formattedTimerDuration) when you begin a sleep session."
    }

    var timerDurationFriendlyLabel: String {
        let seconds = (isPlaying && timerRemaining > 0) ? timerRemaining : settings.timer.duration
        return friendlyDuration(seconds)
    }

    var cryMonitoringStatusLabel: String {
        if !cryModeEnabled { return "Off" }
        return isCryMonitoringActive ? "On" : "Unavailable"
    }

    var mainButtonIsActive: Bool {
        isPlaying && activeSessionMode == .mainProgramme
    }

    var mainButtonTitle: String {
        mainButtonIsActive ? "Sleeping…" : "Start Sleep"
    }

    func isPresetActive(_ preset: PlaybackPreset) -> Bool {
        guard isPlaying else { return false }
        switch (preset, activeSessionMode) {
        case (.bedtime, .sleepPreset), (.nap, .napPreset):
            return true
        default:
            return false
        }
    }

    func presetButtonTitle(for preset: PlaybackPreset) -> String {
        guard isPresetActive(preset) else { return preset.title }
        return preset == .bedtime ? "Sleeping…" : "Napping…"
    }

    func handleMainSleepButtonTap() {
        if mainButtonIsActive {
            stopPlayback()
            return
        }
        startDefaultRoutine()
    }

    func handlePresetButtonTap(_ preset: PlaybackPreset) async {
        if isPresetActive(preset) {
            stopPlayback()
            return
        }
        await startPreset(preset)
    }

    var cryCooldownStatusLabel: String {
        guard cryModeEnabled else { return "Monitoring off" }
        if cryCooldownRemaining <= 0 { return "Ready" }
        return "Cooling down (\(Int(cryCooldownRemaining.rounded(.up)))s)"
    }

    func toggleCryMode(_ enabled: Bool) {
        cryModeEnabled = enabled
        settings.cryResponse.enabled = enabled
        store.save(settings)

        cryMonitoringTask?.cancel()
        cryMonitoringTask = Task { [weak self] in
            guard let self else { return }
            if enabled {
                await requestPermissionAndStartCryService()
            } else {
                cryService.stop()
                isCryMonitoringActive = false
                lastCryActionSummary = "Monitoring turned off"
            }
        }
    }

    func setCryDetectionThreshold(_ value: Float) {
        let clamped = max(0.4, min(value, 0.95))
        cryDetectionThreshold = clamped
        settings.cryResponse.detectionThreshold = clamped
        cryService.updateDetectionThreshold(clamped)
        store.save(settings)
    }

    func setCryComfortMode(_ mode: CryComfortMode) {
        cryComfortMode = mode
        settings.cryResponse.comfortMode = mode
        setCryDetectionThreshold(mode.threshold)
    }

    func prepareCryModeEnablement() {
        if settings.cryResponse.hasSeenOnboarding {
            toggleCryMode(true)
        } else {
            showCryOnboarding = true
        }
    }

    func completeCryOnboarding(enableNow: Bool, mode: CryComfortMode) {
        settings.cryResponse.hasSeenOnboarding = true
        settings.cryResponse.comfortMode = mode
        cryComfortMode = mode
        showCryOnboarding = false
        setCryDetectionThreshold(mode.threshold)
        if enableNow {
            toggleCryMode(true)
        }
        store.save(settings)
    }

    func runSmartResettleTest() {
        guard let sound = catalog.first else { return }
        Task {
            appendSmartResettleEvent(.autoResettleStarted, preset: .nap, sound: sound, confidence: 0.85, duration: 60)
            await startPlayback(sound: sound, duration: 60, micModeEnabled: true, sessionMode: .autoResettling)
            appendSmartResettleEvent(.autoResettleEnded, preset: .nap, sound: sound, confidence: 0, duration: 60)
        }
    }

    func clearSmartResettleHistory() {
        clearCryEvents()
    }

    private func syncRoutineSettings() {
        routinePresets = settings.routinePresets
        defaultRoutinePresetID = settings.defaultRoutinePresetID
        store.save(settings)
    }

    private func startRoutine(sound: SoundDefinition, volume: Float, timerDuration: TimeInterval, cryModeEnabled: Bool) {
        startRoutine(
            sound: sound,
            volume: volume,
            timerDuration: timerDuration,
            cryModeEnabled: cryModeEnabled,
            sessionMode: .mainProgramme
        )
    }

    private func startRoutine(
        sound: SoundDefinition,
        volume: Float,
        timerDuration: TimeInterval,
        cryModeEnabled: Bool,
        sessionMode: SessionMode
    ) {
        Task {
            do {
                try audio.configureSession(micModeEnabled: cryModeEnabled)
                try await audio.play(sound: sound, volume: safetyPolicy.clamped(volume: volume))
                timer.start(duration: timerDuration, fadeDuration: settings.timer.fadeDuration)
                isPlaying = true
                activeSessionMode = sessionMode
                if var session = smartResettleSession {
                    session.mode = .playingPreset
                    smartResettleSession = session
                }
                updateSmartResettleStatus()
            } catch {
                isPlaying = false
                activeSessionMode = nil
                warningBanner = "Playback failed: \(error.localizedDescription)"
                homeLogger.error("quickStart failed: \(error.localizedDescription, privacy: .public)")
            }
        }
    }

    private func bind() {
        timer.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                guard let self else { return }
                self.timerRemaining = state.remaining
                let didTimerComplete = self.wasTimerRunning && !state.isRunning
                self.wasTimerRunning = state.isRunning

                if didTimerComplete {
                    _ = self.advancePlaybackGeneration()
                    self.isPlaying = false
                    self.activeSessionMode = nil
                    self.playbackSessionStore.clear()
                    if self.smartResettleSession != nil {
                        Task { await self.handlePresetTimerCompletion() }
                    } else {
                        Task { await self.audio.stop(fadeDuration: 0.3) }
                    }
                }

                let fadeGain = FadeCurve.gain(remaining: state.remaining, fadeDuration: state.fadeDuration)
                if state.isRunning {
                    self.audio.updateVolume(self.volume * fadeGain, rampDuration: 0.5)
                    self.persistPlaybackSnapshotIfNeeded()
                }
            }
            .store(in: &cancellables)

        cryService.detectionPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] signal in
                guard let self else { return }

                self.lastCryDetectionTime = signal.date
                self.lastCryConfidence = signal.confidence
                self.processSmartResettleSignal(signal)

                guard let action = self.cryResponseCoordinator.handle(
                          signal: signal,
                          isEnabled: self.settings.cryResponse.enabled,
                          settings: self.settings.cryResponse,
                          currentVolume: self.volume,
                          safetyPolicy: self.safetyPolicy
                      )
                else { return }
                var actions: [CryDetectionEvent.Action] = [.increasedVolume]

                self.setVolume(action.targetVolume)
                if self.isPlaying {
                    self.timer.extend(by: action.timerExtension)
                    actions.append(.extendedTimer)
                    self.lastCryActionSummary = "Increased volume and extended timer"
                } else {
                    self.startCryTriggeredPlayback()
                    actions.append(.startedPlayback)
                    self.lastCryActionSummary = "Started playback and increased volume"
                }
                if action.shouldRecordEvent {
                    self.store.appendCryEvent(.init(timestamp: signal.date, confidence: signal.confidence, actions: actions))
                    self.recentCryEvents = self.store.loadCryEvents(limit: 200).map(CryEventRow.init)
                }
                self.refreshCooldownState()
            }
            .store(in: &cancellables)

        systemVolume.volumePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] systemValue in
                guard let self else { return }
                let clamped = self.safetyPolicy.clamped(volume: systemValue)
                self.volume = clamped
                self.audio.updateVolume(clamped, rampDuration: 0.1)
                self.settings.lastVolume = clamped
                self.store.save(self.settings)
            }
            .store(in: &cancellables)

        Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.refreshCooldownState()
            }
            .store(in: &cancellables)
    }

    private static func formatAsMinutesAndSeconds(_ seconds: TimeInterval) -> String {
        let totalSeconds = max(0, Int(seconds.rounded()))
        let minutes = totalSeconds / 60
        let remainingSeconds = totalSeconds % 60
        return String(format: "%02d:%02d", minutes, remainingSeconds)
    }

    private func setTimerDuration(minutes: Int) {
        let clampedMinutes = Self.clampTimerMinutes(minutes)
        timerDurationMinutes = clampedMinutes
        settings.timer.duration = TimeInterval(clampedMinutes * 60)
        store.save(settings)
        updateRunningTimerForDurationChange(targetDuration: settings.timer.duration)
    }

    private func setTimerDuration(seconds: TimeInterval) {
        setTimerDuration(minutes: Self.minutes(from: seconds))
    }

    private static func clampTimerMinutes(_ minutes: Int) -> Int {
        min(max(1, minutes), 24 * 60)
    }

    private static func minutes(from duration: TimeInterval) -> Int {
        clampTimerMinutes(Int(duration / 60))
    }

    private func friendlyDuration(_ seconds: TimeInterval) -> String {
        let totalMinutes = max(1, Int(seconds.rounded() / 60))
        let hours = totalMinutes / 60
        let minutes = totalMinutes % 60

        if hours > 0, minutes > 0 {
            return "\(hours)h \(minutes)m"
        }
        if hours > 0 {
            return "\(hours)h"
        }
        return "\(totalMinutes) min"
    }

    private func updateRunningTimerForDurationChange(targetDuration: TimeInterval) {
        guard isPlaying else { return }

        if timerRemaining <= 0 {
            timer.start(duration: targetDuration, fadeDuration: settings.timer.fadeDuration)
            return
        }

        let delta = targetDuration - timerRemaining
        if delta >= 0 {
            timer.extend(by: delta)
            return
        }

        let maxReduction = timerRemaining - 60
        let clampedReduction = max(delta, -maxReduction)
        timer.extend(by: clampedReduction)
    }

    private func startCryMonitoringIfNeeded() {
        guard settings.cryResponse.enabled else { return }
        cryMonitoringTask?.cancel()
        cryMonitoringTask = Task { [weak self] in
            await self?.requestPermissionAndStartCryService()
        }
    }

    private func requestPermissionAndStartCryService() async {
        let granted = await cryService.requestPermission()
        guard granted else {
            cryModeEnabled = false
            settings.cryResponse.enabled = false
            isCryMonitoringActive = false
            warningBanner = "Microphone access is off. Enable it in Settings > Privacy & Security > Microphone to use Cry Response Mode."
            store.save(settings)
            return
        }

        do {
            try audio.configureSession(micModeEnabled: true)
            cryService.updateDetectionThreshold(settings.cryResponse.detectionThreshold)
            cryService.updateCooldown(settings.cryResponse.cooldown)
            try cryService.start()
            isCryMonitoringActive = true
            lastCryActionSummary = "Monitoring and waiting for cry patterns"
        } catch {
            cryModeEnabled = false
            settings.cryResponse.enabled = false
            isCryMonitoringActive = false
            warningBanner = "Cry monitoring couldn’t start. Confirm microphone availability and try again. Error: \(error.localizedDescription)"
            store.save(settings)
        }
    }

    private func startCryTriggeredPlayback() {
        let targetSound = catalog.first(where: { $0.id == Self.cryTriggeredSoundID }) ?? selectedSound
        Task {
                    await startPlayback(
                        sound: targetSound,
                        duration: 5 * 60,
                        micModeEnabled: true,
                        sessionMode: .autoResettling
                    )
        }
    }

    private func startPlayback(
        sound: SoundDefinition,
        duration: TimeInterval,
        micModeEnabled: Bool,
        sessionMode: SmartResettleMode? = nil
    ) async {
        do {
            try audio.configureSession(micModeEnabled: micModeEnabled)
            let targetVolume = safetyPolicy.clamped(volume: volume)
            try await audio.play(sound: sound, volume: max(0.05, targetVolume * 0.35))
            audio.updateVolume(targetVolume, rampDuration: 0.9)
            timer.start(duration: duration, fadeDuration: settings.timer.fadeDuration)
            isPlaying = true
            if let sessionMode {
                switch sessionMode {
                case .playingPreset:
                    if let activeQuickPreset {
                        activeSessionMode = activeQuickPreset == .bedtime ? .sleepPreset : .napPreset
                    }
                case .autoResettling:
                    if activeSessionMode == nil {
                        activeSessionMode = .autoResettling
                    }
                default:
                    break
                }
            }
            if var session = smartResettleSession, let sessionMode {
                session.mode = sessionMode
                smartResettleSession = session
            }
            updateSmartResettleStatus()
            persistPlaybackSnapshotIfNeeded()
        } catch {
            isPlaying = false
            activeSessionMode = nil
            warningBanner = "Playback failed: \(error.localizedDescription)"
            homeLogger.error("playback failed: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func handlePresetTimerCompletion() async {
        await audio.stop(fadeDuration: 1.2)
        guard var session = smartResettleSession else { return }
        session.resettleEndTime = nil
        if session.isInListeningWindow(at: dateProvider()) {
            session.mode = .listeningForResettle
            smartResettleSession = session
        } else {
            session.mode = .completed
            smartResettleSession = session
            appendSmartResettleEvent(.listeningWindowExpired, preset: session.preset, sound: session.sound, confidence: 0, duration: nil)
        }
        updateSmartResettleStatus()
    }

    private func processSmartResettleSignal(_ signal: CryDetectionSignal) {
        guard var session = smartResettleSession else { return }
        guard session.mode == .listeningForResettle else { return }
        let now = signal.date
        guard session.isInListeningWindow(at: now), session.hasResettleCapacity, !session.isCoolingDown(at: now) else { return }

        if signal.confidence >= max(0.7, settings.cryResponse.detectionThreshold) {
            recentCryConfidenceHits.append(now)
        }
        recentCryConfidenceHits.removeAll { now.timeIntervalSince($0) > 10 }

        if signal.detected {
            if let lastDetectedSignalAt, now.timeIntervalSince(lastDetectedSignalAt) <= 1.5 {
                consecutiveDetectedSignals += 1
            } else {
                consecutiveDetectedSignals = 1
            }
            lastDetectedSignalAt = now
        }

        let hasRepeatedHits = recentCryConfidenceHits.count >= 3
        let hasSustainedPattern = consecutiveDetectedSignals >= 2
        guard hasRepeatedHits || hasSustainedPattern else { return }

        appendSmartResettleEvent(.cryDetected, preset: session.preset, sound: session.sound, confidence: signal.confidence, duration: nil)
        session.autoResettleCount += 1
        session.lastAutoResettleAt = now
        session.resettleEndTime = now.addingTimeInterval(session.configuration.resettleDuration)
        session.mode = .autoResettling
        smartResettleSession = session
        updateSmartResettleStatus()
        gentleResettleHaptic()
        appendSmartResettleEvent(.autoResettleStarted, preset: session.preset, sound: session.sound, confidence: signal.confidence, duration: session.configuration.resettleDuration)

        Task { [weak self] in
            guard let self else { return }
            await startPlayback(
                sound: session.sound,
                duration: session.configuration.resettleDuration,
                micModeEnabled: true,
                sessionMode: .autoResettling
            )
            appendSmartResettleEvent(.autoResettleEnded, preset: session.preset, sound: session.sound, confidence: 0, duration: session.configuration.resettleDuration)
            guard var updated = smartResettleSession else { return }
            updated.resettleEndTime = nil
            if updated.isInListeningWindow(at: dateProvider()), updated.hasResettleCapacity {
                updated.mode = .listeningForResettle
            } else {
                updated.mode = .completed
                appendSmartResettleEvent(.listeningWindowExpired, preset: updated.preset, sound: updated.sound, confidence: 0, duration: nil)
            }
            smartResettleSession = updated
            recentCryConfidenceHits.removeAll()
            consecutiveDetectedSignals = 0
            updateSmartResettleStatus()
        }
    }

    private func appendSmartResettleEvent(
        _ eventType: CryDetectionEvent.EventType,
        preset: PlaybackPreset,
        sound: SoundDefinition,
        confidence: Float,
        duration: TimeInterval?
    ) {
        store.appendCryEvent(
            .init(
                timestamp: dateProvider(),
                confidence: confidence,
                eventType: eventType,
                presetName: preset.title,
                soundID: sound.id,
                soundTitle: sound.title,
                resettleDuration: duration
            )
        )
        recentCryEvents = store.loadCryEvents(limit: 200).map(CryEventRow.init)
    }

    private func updateSmartResettleStatus() {
        guard let session = smartResettleSession else {
            smartResettleStatusLabel = isPlaying ? "Sleep active" : "Ready for rest"
            return
        }

        switch session.mode {
        case .idle:
            smartResettleStatusLabel = "Ready for rest"
        case .playingPreset:
            smartResettleStatusLabel = "Sleep active"
        case .listeningForResettle:
            smartResettleStatusLabel = "Listening for resettle"
        case .autoResettling:
            let remaining = max(0, Int((session.resettleEndTime?.timeIntervalSince(dateProvider()) ?? 0).rounded(.up) / 60))
            let suffix = remaining > 0 ? " • \(remaining) min left" : ""
            smartResettleStatusLabel = "Resettling with \(session.sound.title)\(suffix)"
        case .completed:
            smartResettleStatusLabel = "Smart Resettle complete"
        }
    }

    private func gentleResettleHaptic() {
#if os(iOS)
        let generator = UIImpactFeedbackGenerator(style: .soft)
        generator.impactOccurred(intensity: 0.6)
#endif
    }

    private func persistPlaybackSnapshotIfNeeded() {
        guard isPlaying, timerRemaining > 0 else { return }

        let snapshot = PlaybackSessionSnapshot(
            soundID: selectedSound.id,
            targetVolume: safetyPolicy.clamped(volume: volume),
            expectedEndDate: Date().addingTimeInterval(timerRemaining),
            micModeEnabled: cryModeEnabled
        )
        playbackSessionStore.save(snapshot)
    }

    private func restorePlaybackSessionIfNeeded() {
        guard let snapshot = playbackSessionStore.load() else { return }
        guard snapshot.isStillActive else {
            playbackSessionStore.clear()
            return
        }
        guard let sound = catalog.first(where: { $0.id == snapshot.soundID }) else {
            playbackSessionStore.clear()
            return
        }

        selectedSound = sound
        volume = safetyPolicy.clamped(volume: snapshot.targetVolume)
        startPlaybackSession(
            sound: sound,
            micModeEnabled: snapshot.micModeEnabled,
            duration: snapshot.remainingDuration,
            failurePrefix: "Couldn't restore previous playback session"
        )
    }

    private func startPlaybackSession(
        sound: SoundDefinition,
        micModeEnabled: Bool,
        duration: TimeInterval,
        failurePrefix: String
    ) {
        playbackTask?.cancel()
        let generation = advancePlaybackGeneration()
        playbackTask = Task { [weak self] in
            guard let self else { return }
            do {
                try audio.configureSession(micModeEnabled: micModeEnabled)
                try await audio.play(sound: sound, volume: volume)
                timer.start(duration: duration, fadeDuration: settings.timer.fadeDuration)
                isPlaying = true
                activeSessionMode = .mainProgramme
                persistPlaybackSnapshotIfNeeded()
            } catch {
                guard !Task.isCancelled, generation == playbackGeneration else { return }
                isPlaying = false
                activeSessionMode = nil
                warningBanner = "\(failurePrefix): \(error.localizedDescription)"
            }
        }
    }

    private func advancePlaybackGeneration() -> Int {
        playbackGeneration += 1
        return playbackGeneration
    }

    private func refreshCooldownState() {
        cryCooldownRemaining = cryResponseCoordinator.cooldownRemaining(
            at: dateProvider(),
            settings: settings.cryResponse
        )
        if var session = smartResettleSession,
           session.mode == .listeningForResettle,
           !session.isInListeningWindow(at: dateProvider()) {
            session.mode = .completed
            smartResettleSession = session
            appendSmartResettleEvent(
                .listeningWindowExpired,
                preset: session.preset,
                sound: session.sound,
                confidence: 0,
                duration: nil
            )
        }
        updateSmartResettleStatus()
    }
}

extension HomeViewModel {
    struct CryEventRow: Identifiable, Equatable {
        let id: UUID
        let timestamp: Date
        let confidence: Float
        let actionDescription: String
        let detailDescription: String

        init(event: CryDetectionEvent) {
            id = event.id
            timestamp = event.timestamp
            confidence = event.confidence
            actionDescription = event.eventType.displayLabel
            detailDescription = event.eventType.detail(
                presetName: event.presetName,
                soundTitle: event.soundTitle,
                duration: event.resettleDuration,
                actions: event.actions
            )
        }
    }
}

private extension CryDetectionEvent.Action {
    var label: String {
        switch self {
        case .startedPlayback:
            return "Started playback"
        case .increasedVolume:
            return "Increased volume"
        case .extendedTimer:
            return "Extended timer"
        }
    }
}

private extension CryDetectionEvent.EventType {
    var displayLabel: String {
        switch self {
        case .cryDetected: return "Cry detected"
        case .autoResettleStarted: return "Auto-resettle started"
        case .autoResettleEnded: return "Auto-resettle ended"
        case .listeningWindowExpired: return "Listening window expired"
        case .sessionManuallyStopped: return "Session stopped"
        case .legacyCryResponse: return "Cry response action"
        }
    }

    func detail(
        presetName: String?,
        soundTitle: String?,
        duration: TimeInterval?,
        actions: [CryDetectionEvent.Action]
    ) -> String {
        switch self {
        case .legacyCryResponse:
            let legacy = actions.map(\.label).joined(separator: " • ")
            return legacy.isEmpty ? "Action recorded" : legacy
        case .cryDetected:
            return "\(presetName ?? "Session") • \(soundTitle ?? "Current sound")"
        case .autoResettleStarted:
            let minutes = Int((duration ?? 0) / 60)
            return "\(presetName ?? "Session") • \(soundTitle ?? "Sound") • \(minutes) min"
        case .autoResettleEnded:
            return "\(presetName ?? "Session") • \(soundTitle ?? "Sound")"
        case .listeningWindowExpired:
            return "\(presetName ?? "Session") finished"
        case .sessionManuallyStopped:
            return "\(presetName ?? "Session") manually stopped"
        }
    }
}

@MainActor
private final class NoOpSystemVolumeController: SystemVolumeControlling {
    var volumePublisher: AnyPublisher<Float, Never> { Empty().eraseToAnyPublisher() }
    var currentVolume: Float { 0.35 }
    func setSystemVolume(_ value: Float) {}
}
