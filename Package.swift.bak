// swift-tools-version: 6.3
// iFoundation — Swift Project Scaffolding Tool
// Host-agnostic, LLM-era project infrastructure for Apple platforms

import PackageDescription

let package = Package(
    name: "SwiftAnvilCLI",
    platforms: [.macOS(.v15)],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.5.0"),
        .package(url: "https://github.com/stencilproject/Stencil.git", from: "0.15.0"),
        .package(url: "https://github.com/jpsim/Yams.git", from: "5.1.0")
    ],
    targets: [
        .executableTarget(
            name: "SwiftAnvilCLI",
            dependencies: [
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "Stencil", package: "Stencil"),
                .product(name: "Yams", package: "Yams")
            ]
        ),
        .testTarget(
            name: "SwiftAnvilCLITests",
            dependencies: ["SwiftAnvilCLI"]
        )
    ],
    swiftLanguageModes: [.v6]
)
