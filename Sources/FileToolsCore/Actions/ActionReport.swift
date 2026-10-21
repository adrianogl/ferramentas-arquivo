import Foundation

public struct ActionReport: Sendable, Equatable {
    public struct Output: Sendable, Equatable {
        public var url: URL
        public var isFolder: Bool
        public var sourceCount: Int
        public var originalBytes: Int
        public var finalBytes: Int
        public var pageCount: Int
        public var ocrPageCount: Int

        public init(
            url: URL, isFolder: Bool = false, sourceCount: Int = 0, originalBytes: Int = 0,
            finalBytes: Int = 0, pageCount: Int = 0, ocrPageCount: Int = 0
        ) {
            self.url = url
            self.isFolder = isFolder
            self.sourceCount = sourceCount
            self.originalBytes = originalBytes
            self.finalBytes = finalBytes
            self.pageCount = pageCount
            self.ocrPageCount = ocrPageCount
        }
    }

    public struct Untouched: Sendable, Equatable {
        public var url: URL
        public var bytes: Int

        public init(url: URL, bytes: Int) {
            self.url = url
            self.bytes = bytes
        }
    }

    public struct Failure: Sendable, Equatable {
        public var url: URL
        public var reason: ActionFailure

        public init(url: URL, reason: ActionFailure) {
            self.url = url
            self.reason = reason
        }
    }

    public var outputs: [Output]
    public var untouched: [Untouched]
    public var failures: [Failure]

    public init(outputs: [Output] = [], untouched: [Untouched] = [], failures: [Failure] = []) {
        self.outputs = outputs
        self.untouched = untouched
        self.failures = failures
    }
}
