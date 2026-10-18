// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "EdgeGuard",
    platforms: [.macOS(.v13)],
    products: [
        .library(name: "EdgeGuardCore", targets: ["EdgeGuardCore"]),
        .executable(name: "edgeguard-cli", targets: ["edgeguard-cli"]),
        .executable(name: "edgeguard-eval", targets: ["edgeguard-eval"]),
        .executable(name: "EdgeGuardMenuBar", targets: ["EdgeGuardMenuBar"])
    ],
    targets: [
        .target(name: "EdgeGuardCore"),
        .executableTarget(name: "edgeguard-cli", dependencies: ["EdgeGuardCore"]),
        .executableTarget(name: "edgeguard-eval", dependencies: ["EdgeGuardCore"]),
        .executableTarget(name: "EdgeGuardMenuBar", dependencies: ["EdgeGuardCore"]),
        .testTarget(name: "EdgeGuardCoreTests", dependencies: ["EdgeGuardCore"])
    ]
)
