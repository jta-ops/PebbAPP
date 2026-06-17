// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "PebbApp",
    platforms: [.iOS(.v17)],
    products: [
        .library(name: "PebbApp", targets: ["PebbApp"])
    ],
    targets: [
        .target(
            name: "PebbApp",
            path: "Sources/PebbApp",
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
