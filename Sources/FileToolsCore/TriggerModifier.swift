import CoreGraphics

public enum TriggerModifier: String, CaseIterable, Sendable {
    case option, command, shift

    public var title: String {
        switch self {
        case .option: "⌥ Option"
        case .command: "⌘ Command"
        case .shift: "⇧ Shift"
        }
    }

    public var glyph: String {
        switch self {
        case .option: "⌥"
        case .command: "⌘"
        case .shift: "⇧"
        }
    }

    public var cgFlag: CGEventFlags {
        switch self {
        case .option: .maskAlternate
        case .command: .maskCommand
        case .shift: .maskShift
        }
    }
}
