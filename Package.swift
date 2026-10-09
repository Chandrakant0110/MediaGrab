// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "MediaGrab",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "MediaGrab",
            path: "Sources/MediaGrab",
            swiftSettings: [
                .swiftLanguageMode(.v5)
            ]
        )
    ]
)
