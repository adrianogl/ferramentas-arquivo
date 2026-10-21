import Foundation

public func naturalOrder(_ urls: [URL]) -> [URL] {
    urls.sorted { $0.lastPathComponent.localizedStandardCompare($1.lastPathComponent) == .orderedAscending }
}
