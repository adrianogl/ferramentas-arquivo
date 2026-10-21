public struct ActionDescriptor: Sendable {
    public let id: ActionID
    public let title: String
    public let shortLabel: String
    public let symbol: String
    public let colorHex: String
    public let slot: Int
    public let interaction: ActionInteraction
    public let progressTitle: String

    public init(
        id: ActionID, title: String, shortLabel: String, symbol: String, colorHex: String,
        slot: Int, interaction: ActionInteraction, progressTitle: String
    ) {
        self.id = id
        self.title = title
        self.shortLabel = shortLabel
        self.symbol = symbol
        self.colorHex = colorHex
        self.slot = slot
        self.interaction = interaction
        self.progressTitle = progressTitle
    }
}
