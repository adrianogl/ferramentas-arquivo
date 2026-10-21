import FileToolsCore
import Foundation
import Observation

@MainActor
@Observable
final class RadialMenuModel {
    enum Phase: Equatable {
        case choosing
        case running(ActionID)
    }

    let urls: [URL]
    let limit: SizeLimit
    private(set) var targets: [TargetInfo]
    private(set) var availability: [ActionID: Availability] = [:]
    private var pageCountsKnown = false
    var hoveredSlot: Int?
    var phase: Phase = .choosing
    var isShown = false

    init(urls: [URL], targets: [TargetInfo], limit: SizeLimit) {
        self.urls = urls
        self.targets = targets
        self.limit = limit
        evaluate()
    }

    func updatePageCounts(_ counts: [Int?]) {
        guard counts.count == targets.count else { return }
        targets = zip(targets, counts).map { target, count in
            TargetInfo(name: target.name, bytes: target.bytes, pageCount: count, kind: target.kind)
        }
        pageCountsKnown = true
        evaluate()
    }

    var hoveredAction: ActionID? {
        guard let hoveredSlot else { return nil }
        return action(at: hoveredSlot)
    }

    var runningAction: ActionID? {
        if case .running(let id) = phase { return id }
        return nil
    }

    func action(at slot: Int) -> ActionID? {
        Constants.actions.first { $0.slot == slot }?.id
    }

    func isAvailable(_ id: ActionID) -> Bool {
        availability[id] == .available
    }

    var coreText: RadialCoreText {
        let hovered = hoveredAction
        return RadialCoreText.make(
            hovered: hovered,
            availability: hovered.flatMap { availability[$0] } ?? .available,
            targets: targets,
            limit: limit,
            running: runningAction)
    }

    private func evaluate() {
        let pages = Dictionary(zip(urls, targets.map(\.pageCount)), uniquingKeysWith: { first, _ in first })
        let assumeMultiPage = !pageCountsKnown
        var result: [ActionID: Availability] = [:]
        for id in ActionID.allCases {
            result[id] = ActionAvailability.availability(of: id, for: urls) { url in
                assumeMultiPage ? Int.max : pages[url] ?? nil
            }
        }
        availability = result
    }
}
