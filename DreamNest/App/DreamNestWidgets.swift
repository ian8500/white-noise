#if canImport(WidgetKit)
import SwiftUI
import WidgetKit

struct DreamNestLauncherEntry: TimelineEntry {
    let date: Date
}

struct DreamNestLauncherProvider: TimelineProvider {
    func placeholder(in context: Context) -> DreamNestLauncherEntry { .init(date: .now) }
    func getSnapshot(in context: Context, completion: @escaping (DreamNestLauncherEntry) -> Void) { completion(.init(date: .now)) }
    func getTimeline(in context: Context, completion: @escaping (Timeline<DreamNestLauncherEntry>) -> Void) {
        completion(Timeline(entries: [.init(date: .now)], policy: .never))
    }
}

struct DreamNestLauncherWidgetView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("DreamNest")
                .font(.headline)
            Button(intent: StartBedtimeIntent()) {
                Label("Start Bedtime", systemImage: "bed.double.fill")
            }
            .buttonStyle(.borderedProminent)

            Button(intent: StartNapIntent()) {
                Label("Start Nap", systemImage: "moon.zzz")
            }
            .buttonStyle(.bordered)
        }
        .padding(12)
    }
}

struct DreamNestLauncherWidget: Widget {
    let kind: String = "DreamNestLauncherWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: DreamNestLauncherProvider()) { _ in
            DreamNestLauncherWidgetView()
        }
        .supportedFamilies([.systemSmall, .accessoryRectangular])
        .configurationDisplayName("DreamNest Quick Start")
        .description("Start nap or bedtime sound from Home Screen or Lock Screen.")
    }
}
#endif
