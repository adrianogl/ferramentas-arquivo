// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "FerramentasArquivo",
    platforms: [.macOS(.v26)],
    targets: [
        .target(name: "FileToolsCore"),
        .executableTarget(name: "FileToolsApp", dependencies: ["FileToolsCore"]),
        .testTarget(name: "FileToolsCoreTests", dependencies: ["FileToolsCore"]),
    ],
    swiftLanguageModes: [.v6]
)
