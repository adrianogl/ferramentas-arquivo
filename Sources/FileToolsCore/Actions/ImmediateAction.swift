import Foundation

public protocol ImmediateAction: Sendable {
    var id: ActionID { get }
    func run(_ urls: [URL], limit: SizeLimit) -> ActionReport
}
