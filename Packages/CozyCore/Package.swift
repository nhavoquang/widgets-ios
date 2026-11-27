// swift-tools-version:5.10
import PackageDescription

let package = Package(
    name: "CozyCore",
    defaultLocalization: "vi",
    platforms: [.iOS(.v17), .macOS(.v14), .watchOS(.v10)],
    products: [
        .library(name: "CozyCore", targets: ["CozyCore"]),
    ],
    targets: [
        .target(name: "CozyCore"),
        .testTarget(name: "CozyCoreTests", dependencies: ["CozyCore"]),
    ]
)
