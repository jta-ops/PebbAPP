// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PebbApp",
    platforms: [.iOS(.v17)],
    targets: [
        .executableTarget(
            name: "PebbApp",
            path: "Sources/PebbApp",
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
