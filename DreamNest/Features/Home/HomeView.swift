import Combine
import SwiftUI

struct HomeView: View {
    @StateObject var viewModel: HomeViewModel
    @State private var isShowingSoundPicker = false
    @State private var isShowingSettings = false
    @State private var editingPreset: PlaybackPreset?

    var body: some View {
        ZStack {
            DreamNestTheme.background
                .ignoresSafeArea()

            ScrollView(showsIndicators: false) {
                VStack(spacing: 28) {
                    header
                    presetSection
                    nowPlayingSection
                    timerSection
                    smartResettleStatus

                    if let warning = viewModel.warningBanner {
                        warningMessage(warning)
                    }

                    footer
                }
                .padding(.horizontal, 22)
                .padding(.top, 18)
                .padding(.bottom, 34)
                .frame(maxWidth: 620)
                .frame(maxWidth: .infinity)
            }
        }
        .sheet(isPresented: $isShowingSoundPicker) {
            SoundPickerSheet(
                sounds: viewModel.catalog.filter(viewModel.isSoundUnlocked),
                selectedSoundID: viewModel.selectedSound.id,
                title: "Choose a sound",
                applyButtonTitle: "Done",
                isSoundUnlocked: { _ in true },
                onSelect: viewModel.selectSound,
                onLockedSelect: { _ in },
                onApply: {}
            )
            .presentationDetents([.medium, .large])
        }
        .sheet(item: $editingPreset) { preset in
            PresetEditorSheet(preset: preset, viewModel: viewModel)
        }
        .sheet(isPresented: $isShowingSettings) {
            DreamNestSettingsSheet(viewModel: viewModel)
        }
    }

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 3) {
                Text("DreamNest")
                    .font(.system(size: 30, weight: .semibold, design: .rounded))
                    .foregroundStyle(DreamNestTheme.primaryText)

                Text("A quieter way to settle.")
                    .font(.subheadline)
                    .foregroundStyle(DreamNestTheme.secondaryText)
            }

            Spacer()

            Button {
                isShowingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundStyle(DreamNestTheme.primaryText)
                    .frame(width: 44, height: 44)
                    .background(Circle().fill(DreamNestTheme.surface))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Settings")
        }
    }

    private var presetSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("One-tap routines")
                .font(.caption.weight(.semibold))
                .foregroundStyle(DreamNestTheme.tertiaryText)
                .textCase(.uppercase)
                .tracking(0.8)

            HStack(spacing: 12) {
                presetButton(.bedtime, icon: "moon.fill")
                presetButton(.nap, icon: "sun.haze.fill")
            }
        }
    }

    private func presetButton(_ preset: PlaybackPreset, icon: String) -> some View {
        let configuration = viewModel.quickPresetConfiguration(for: preset)
        let sound = viewModel.quickPresetSound(for: preset)
        let isActive = viewModel.isPresetActive(preset)

        return VStack(alignment: .leading, spacing: 0) {
            Button {
                Task { await viewModel.handlePresetButtonTap(preset) }
            } label: {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Image(systemName: icon)
                            .font(.system(size: 19, weight: .semibold))
                        Spacer()
                        if isActive {
                            Circle()
                                .fill(DreamNestTheme.accent)
                                .frame(width: 8, height: 8)
                        }
                    }

                    Text(viewModel.presetButtonTitle(for: preset))
                        .font(.title3.weight(.semibold))

                    Text("\(sound.title) • \(Int(configuration.duration / 60)) min")
                        .font(.footnote)
                        .foregroundStyle(DreamNestTheme.secondaryText)
                        .lineLimit(1)
                }
                .foregroundStyle(DreamNestTheme.primaryText)
                .frame(maxWidth: .infinity, minHeight: 108, alignment: .leading)
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(isActive ? DreamNestTheme.surfaceElevated : DreamNestTheme.surface)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .stroke(isActive ? DreamNestTheme.accent.opacity(0.7) : Color.white.opacity(0.06), lineWidth: 1)
                )
            }
            .buttonStyle(.plain)
            .simultaneousGesture(
                LongPressGesture(minimumDuration: 0.45)
                    .onEnded { _ in editingPreset = preset }
            )

            Button {
                editingPreset = preset
            } label: {
                Label("Edit", systemImage: "slider.horizontal.3")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DreamNestTheme.secondaryText)
                    .padding(.top, 8)
                    .padding(.horizontal, 4)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Edit \(preset.title) routine")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var nowPlayingSection: some View {
        VStack(spacing: 18) {
            Button {
                isShowingSoundPicker = true
            } label: {
                HStack(spacing: 14) {
                    Image(systemName: soundIcon(for: viewModel.selectedSound))
                        .font(.system(size: 24, weight: .medium))
                        .foregroundStyle(DreamNestTheme.accent)
                        .frame(width: 50, height: 50)
                        .background(Circle().fill(DreamNestTheme.accent.opacity(0.12)))

                    VStack(alignment: .leading, spacing: 3) {
                        Text(viewModel.isPlaying ? "Playing" : "Sound")
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(DreamNestTheme.tertiaryText)
                            .textCase(.uppercase)
                        Text(viewModel.selectedSound.title)
                            .font(.title3.weight(.semibold))
                            .foregroundStyle(DreamNestTheme.primaryText)
                    }

                    Spacer()

                    Text("Change")
                        .font(.subheadline.weight(.semibold))
                        .foregroundStyle(DreamNestTheme.accentSoft)
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)

            Button {
                if viewModel.isPlaying {
                    viewModel.stopPlayback()
                } else {
                    viewModel.startDefaultRoutine()
                }
            } label: {
                HStack(spacing: 10) {
                    Image(systemName: viewModel.isPlaying ? "pause.fill" : "play.fill")
                    Text(viewModel.isPlaying ? "Stop" : "Start")
                }
                .font(.headline.weight(.semibold))
                .foregroundStyle(Color(hex: "111317"))
                .frame(maxWidth: .infinity)
                .frame(height: 58)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(DreamNestTheme.accentSoft)
                )
            }
            .buttonStyle(.plain)
            .accessibilityHint(viewModel.isPlaying ? "Stops the current sleep sound" : "Starts the selected sound")
        }
    }

    private var timerSection: some View {
        VStack(spacing: 14) {
            VStack(spacing: 3) {
                Text(viewModel.isPlaying ? "Time remaining" : "Timer")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(DreamNestTheme.tertiaryText)
                    .textCase(.uppercase)

                Text(viewModel.isPlaying ? viewModel.formattedTimerRemaining : viewModel.formattedTimerDuration)
                    .font(.system(size: 42, weight: .medium, design: .rounded))
                    .monospacedDigit()
                    .foregroundStyle(DreamNestTheme.primaryText)
                    .contentTransition(.numericText())
            }

            HStack(spacing: 10) {
                timerButton("-10", delta: -10)
                timerButton("-5", delta: -5)
                timerButton("+5", delta: 5)
                timerButton("+10", delta: 10)
            }
        }
        .padding(.vertical, 4)
    }

    private func timerButton(_ title: String, delta: Int) -> some View {
        Button {
            viewModel.adjustTimerDuration(minutesDelta: delta)
        } label: {
            Text(title)
                .font(.subheadline.weight(.semibold))
                .foregroundStyle(DreamNestTheme.primaryText)
                .frame(maxWidth: .infinity)
                .frame(height: 44)
                .background(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(DreamNestTheme.surface)
                )
        }
        .buttonStyle(.plain)
        .accessibilityLabel("\(delta > 0 ? "Add" : "Remove") \(abs(delta)) minutes")
    }

    private var smartResettleStatus: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: "moon.zzz")
                .font(.system(size: 18, weight: .medium))
                .foregroundStyle(DreamNestTheme.accent)

            VStack(alignment: .leading, spacing: 3) {
                Text("Smart Resettle")
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(DreamNestTheme.primaryText)

                Text(smartResettleDetail)
                    .font(.footnote)
                    .foregroundStyle(DreamNestTheme.secondaryText)
            }

            Spacer()

            Button("History") {
                isShowingSettings = true
            }
            .font(.footnote.weight(.semibold))
            .foregroundStyle(DreamNestTheme.accentSoft)
        }
        .padding(.top, 2)
    }

    private var smartResettleDetail: String {
        if let _ = viewModel.smartResettleSession {
            return viewModel.smartResettleStatusLabel
        }
        return viewModel.isPlaying ? "Off for this session" : "Set it for Sleep or Nap"
    }

    private func warningMessage(_ message: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "exclamationmark.circle")
                .foregroundStyle(DreamNestTheme.accent)
            Text(message)
                .font(.footnote)
                .foregroundStyle(DreamNestTheme.secondaryText)
                .frame(maxWidth: .infinity, alignment: .leading)
            Button {
                viewModel.warningBanner = nil
            } label: {
                Image(systemName: "xmark")
                    .foregroundStyle(DreamNestTheme.tertiaryText)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Dismiss message")
        }
        .padding(14)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(DreamNestTheme.surface)
        )
    }

    private var footer: some View {
        Text("No account needed. Your sleep sounds work offline.")
            .font(.caption)
            .foregroundStyle(DreamNestTheme.tertiaryText)
            .frame(maxWidth: .infinity, alignment: .center)
            .padding(.top, 2)
    }

    private func soundIcon(for sound: SoundDefinition) -> String {
        let id = sound.id.lowercased()
        if id.contains("rain") { return "cloud.rain.fill" }
        if id.contains("wave") { return "water.waves" }
        if id.contains("fire") { return "flame.fill" }
        if id.contains("fan") { return "fan.fill" }
        if id.contains("forest") { return "leaf.fill" }
        if id.contains("heart") { return "heart.fill" }
        return "waveform"
    }
}

private struct PresetEditorSheet: View {
    let preset: PlaybackPreset
    @ObservedObject var viewModel: HomeViewModel

    @Environment(\.dismiss) private var dismiss
    @State private var selectedSoundID: String
    @State private var durationMinutes: Int
    @State private var smartResettleEnabled: Bool

    init(preset: PlaybackPreset, viewModel: HomeViewModel) {
        self.preset = preset
        self.viewModel = viewModel

        let configuration = viewModel.quickPresetConfiguration(for: preset)
        _selectedSoundID = State(initialValue: configuration.soundID ?? viewModel.quickPresetSound(for: preset).id)
        _durationMinutes = State(initialValue: max(5, Int(configuration.duration / 60)))
        _smartResettleEnabled = State(initialValue: configuration.smartResettleEnabled)
    }

    var body: some View {
        NavigationStack {
            ZStack {
                DreamNestTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 26) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Edit \(preset.title)")
                                .font(.largeTitle.weight(.semibold))
                                .foregroundStyle(DreamNestTheme.primaryText)
                            Text("Keep the routine familiar and easy to start.")
                                .font(.subheadline)
                                .foregroundStyle(DreamNestTheme.secondaryText)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Sound")
                                .font(.headline)
                                .foregroundStyle(DreamNestTheme.primaryText)

                            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 10) {
                                ForEach(viewModel.catalog.filter(viewModel.isSoundUnlocked), id: \.id) { sound in
                                    Button {
                                        selectedSoundID = sound.id
                                    } label: {
                                        HStack(spacing: 8) {
                                            Image(systemName: selectedSoundID == sound.id ? "checkmark.circle.fill" : "circle")
                                            Text(sound.title)
                                                .lineLimit(1)
                                        }
                                        .font(.subheadline.weight(.semibold))
                                        .foregroundStyle(DreamNestTheme.primaryText)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(12)
                                        .background(
                                            RoundedRectangle(cornerRadius: 14, style: .continuous)
                                                .fill(selectedSoundID == sound.id ? DreamNestTheme.surfaceElevated : DreamNestTheme.surface)
                                        )
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            Text("Duration")
                                .font(.headline)
                                .foregroundStyle(DreamNestTheme.primaryText)

                            HStack {
                                Button {
                                    durationMinutes = max(5, durationMinutes - 5)
                                } label: {
                                    Image(systemName: "minus")
                                        .frame(width: 44, height: 44)
                                        .background(Circle().fill(DreamNestTheme.surface))
                                }

                                Spacer()

                                Text("\(durationMinutes) min")
                                    .font(.title2.weight(.semibold))
                                    .monospacedDigit()
                                    .foregroundStyle(DreamNestTheme.primaryText)

                                Spacer()

                                Button {
                                    durationMinutes = min(240, durationMinutes + 5)
                                } label: {
                                    Image(systemName: "plus")
                                        .frame(width: 44, height: 44)
                                        .background(Circle().fill(DreamNestTheme.surface))
                                }
                            }
                            .foregroundStyle(DreamNestTheme.primaryText)
                            .buttonStyle(.plain)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Toggle(isOn: $smartResettleEnabled) {
                                VStack(alignment: .leading, spacing: 4) {
                                    Text("Smart Resettle")
                                        .font(.headline)
                                        .foregroundStyle(DreamNestTheme.primaryText)
                                    Text("If they wake after the timer ends, DreamNest can gently restart this sound for 5 minutes.")
                                        .font(.footnote)
                                        .foregroundStyle(DreamNestTheme.secondaryText)
                                }
                            }
                            .tint(DreamNestTheme.accent)
                        }

                        Button {
                            viewModel.updateQuickPreset(
                                preset,
                                durationMinutes: durationMinutes,
                                cryModeEnabled: smartResettleEnabled,
                                soundID: selectedSoundID,
                                smartResettleEnabled: smartResettleEnabled,
                                resettleDurationMinutes: 5
                            )
                            dismiss()
                        } label: {
                            Text("Save \(preset.title)")
                                .font(.headline)
                                .foregroundStyle(Color(hex: "111317"))
                                .frame(maxWidth: .infinity)
                                .frame(height: 56)
                                .background(
                                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                                        .fill(DreamNestTheme.accentSoft)
                                )
                        }
                        .buttonStyle(.plain)
                    }
                    .padding(22)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Close") { dismiss() }
                        .foregroundStyle(DreamNestTheme.accentSoft)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

private struct DreamNestSettingsSheet: View {
    @ObservedObject var viewModel: HomeViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ZStack {
                DreamNestTheme.background.ignoresSafeArea()

                ScrollView(showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 28) {
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Settings")
                                .font(.largeTitle.weight(.semibold))
                                .foregroundStyle(DreamNestTheme.primaryText)
                            Text("Only the things you might actually need at night.")
                                .font(.subheadline)
                                .foregroundStyle(DreamNestTheme.secondaryText)
                        }

                        VStack(alignment: .leading, spacing: 10) {
                            Text("Smart Resettle")
                                .font(.headline)
                                .foregroundStyle(DreamNestTheme.primaryText)
                            Text("Turn it on from a Sleep or Nap routine. Microphone access is only needed while listening for crying.")
                                .font(.subheadline)
                                .foregroundStyle(DreamNestTheme.secondaryText)
                        }

                        VStack(alignment: .leading, spacing: 12) {
                            HStack {
                                Text("Recent resettles")
                                    .font(.headline)
                                    .foregroundStyle(DreamNestTheme.primaryText)
                                Spacer()
                                if !viewModel.recentCryEvents.isEmpty {
                                    Button("Clear") {
                                        viewModel.clearSmartResettleHistory()
                                    }
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(DreamNestTheme.accentSoft)
                                }
                            }

                            if viewModel.recentCryEvents.isEmpty {
                                Text("Nothing recorded yet.")
                                    .font(.subheadline)
                                    .foregroundStyle(DreamNestTheme.tertiaryText)
                            } else {
                                ForEach(viewModel.recentCryEvents.prefix(8)) { row in
                                    VStack(alignment: .leading, spacing: 3) {
                                        Text(row.actionDescription)
                                            .font(.subheadline.weight(.semibold))
                                            .foregroundStyle(DreamNestTheme.primaryText)
                                        Text(row.detailDescription)
                                            .font(.footnote)
                                            .foregroundStyle(DreamNestTheme.secondaryText)
                                        Text(row.timestamp, style: .time)
                                            .font(.caption)
                                            .foregroundStyle(DreamNestTheme.tertiaryText)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                        }

                        Divider().overlay(Color.white.opacity(0.08))

                        VStack(alignment: .leading, spacing: 8) {
                            Text("Privacy")
                                .font(.headline)
                                .foregroundStyle(DreamNestTheme.primaryText)
                            Text("Sleep audio works offline. Smart Resettle uses microphone access for on-device cry detection; DreamNest does not need an account for its core features.")
                                .font(.subheadline)
                                .foregroundStyle(DreamNestTheme.secondaryText)
                        }

                        Text("DreamNest 1.0")
                            .font(.caption)
                            .foregroundStyle(DreamNestTheme.tertiaryText)
                    }
                    .padding(22)
                }
            }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(DreamNestTheme.accentSoft)
                }
            }
            .toolbarBackground(.hidden, for: .navigationBar)
        }
    }
}

private extension Color {
    init(hex: String) {
        let cleaned = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: cleaned).scanHexInt64(&int)
        let r, g, b: UInt64
        switch cleaned.count {
        case 6:
            (r, g, b) = (int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (r, g, b) = (245, 247, 250)
        }
        self.init(.sRGB, red: Double(r) / 255, green: Double(g) / 255, blue: Double(b) / 255, opacity: 1)
    }
}
