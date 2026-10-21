import Foundation

public struct PageSelection: Sendable, Equatable {
    public enum Gesture: Sendable {
        case single, toggle, extend
    }

    public private(set) var ids: Set<UUID> = []
    public private(set) var anchor: UUID?

    public init() {}

    public mutating func click(_ id: UUID, gesture: Gesture, order: [UUID]) {
        switch gesture {
        case .single:
            replace(with: id)
        case .toggle:
            if ids.contains(id) {
                ids.remove(id)
            } else {
                ids.insert(id)
            }
            anchor = id
        case .extend:
            guard let anchor, let from = order.firstIndex(of: anchor), let to = order.firstIndex(of: id) else {
                replace(with: id)
                return
            }
            ids = Set(order[min(from, to)...max(from, to)])
        }
    }

    public mutating func replace(with id: UUID) {
        ids = [id]
        anchor = id
    }

    public mutating func clear() {
        ids = []
        anchor = nil
    }

    public mutating func prune(to order: [UUID]) {
        let present = Set(order)
        ids.formIntersection(present)
        if let anchor, !present.contains(anchor) { self.anchor = nil }
    }
}
