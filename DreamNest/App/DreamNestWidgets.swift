#if canImport(WidgetKit)
import SwiftUI
import WidgetKit

struct DreamNestLauncherEntry: TimelineEntry {
    let date: Date
    let isActive: Bool
    let remainingText: String
}

struct DreamNestLauncherProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamNestLauncherEntry { .init(date: .now, isActive: false, remainingText: "Ready") }
    func getSnapshot(in context: Context, completion: @escaping (DreamNestLauncherEntry) -> Void) { completion(makeEntry()) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamNestLauncherEntry>) -> Void) {
        completion(Timeline(entries: [makeEntry()], policy: .after(.now.addingTimeInterval(60))))
    }

    private func makeEntry() -> DreamNestLauncherEntry {
        let store = UserDefaultsPlaybackSessionStore(defaults: .standard)
        if let session = store.load(), session.isStillActive {
            let remainingMinutes = max(1, Int(session.remainingDuration / 60))
            return .init(date: .now, isActive: true, remainingText: "\(remainingMinutes)m left")
        }
        return .init(date: .now, isActive: false, remainingText: "Ready")
    }
}

struct DreamNestLauncherWidgetView: View {
    let entry: DreamNestLauncherEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DreamNest")
                .font(.headline)
            Text(entry.isActive ? "Routine Active • \(entry.remainingText)" : "No active routine")
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack {
                Button(intent: StartBedtimeIntent()) { Label("Bedtime", systemImage: "bed.double.fill") }
                Button(intent: StartNapIntent()) { Label("Nap", systemImage: "moon.zzz") }
                Button(intent: StopPlaybackIntent()) { Image(systemName: "stop.fill") }
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
    }
}

struct DreamNestLauncherWidget: Widget {
    let kind: String = "DreamNestLauncherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DreamNestLauncherProvider()) { entry in
            DreamNestLauncherWidgetView(entry: entry)
        }
        .supportedFamilies([.systemSmall, .accessoryRectangular])
        .configurationDisplayName("DreamNest Quick Start")
        .description("Start nap, bedtime, or stop playback instantly.")
    }
}
#endif
