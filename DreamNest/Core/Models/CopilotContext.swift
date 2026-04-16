import Foundation

struct CopilotContext: Equatable, Sendable, Identifiable {
    enum EntryPoint: String, Sendable {
        case nightState
        case helpNow
        case resetCompletion
        case tonightAnchor
    }

    let entryPoint: EntryPoint
    let nightState: String?
    let timerMinutes: Int?
    let isLowStimulationMode: Bool
    var id: String { "\(entryPoint.rawValue)-\(nightState ?? "none")-\(timerMinutes ?? -1)-\(isLowStimulationMode)" }

    init(
        entryPoint: EntryPoint,
        nightState: String? = nil,
        timerMinutes: Int? = nil,
        isLowStimulationMode: Bool = false
    ) {
        self.entryPoint = entryPoint
        self.nightState = nightState
        self.timerMinutes = timerMinutes
        self.isLowStimulationMode = isLowStimulationMode
    }
}
