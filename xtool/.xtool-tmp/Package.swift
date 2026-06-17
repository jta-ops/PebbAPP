// swift-tools-version: 6.0
import PackageDescription
let package = Package(
    name: "PebbApp-Builder",
    platforms: [
        .iOS("17.0"),
    ],
    dependencies: [
        .package(name: "RootPackage", path: "../.."),
    ],
    targets: [
        .executableTarget(
    name: "PebbApp-App",
    dependencies: [
        .product(name: "PebbApp", package: "RootPackage"),
    ],
    linkerSettings: [
    .unsafeFlags([
        "-Xlinker", "-rpath", "-Xlinker", "@executable_path/Frameworks",
    ]),
]
)
    ]
)
