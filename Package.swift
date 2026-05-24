// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "Blink",
    platforms: [.macOS(.v14)],
    products: [
        .executable(name: "Blink", targets: ["BlinkApp"]),
        .library(name: "BlinkCore", targets: ["BlinkCore"])
    ],
    dependencies: [
        .package(url: "https://github.com/groue/GRDB.swift.git", from: "6.29.0"),
        .package(url: "https://github.com/sindresorhus/KeyboardShortcuts.git", from: "2.3.0")
    ],
    targets: [
        .executableTarget(
            name: "BlinkApp",
            dependencies: [
                "BlinkCore",
                .product(name: "KeyboardShortcuts", package: "KeyboardShortcuts")
            ],
            path: "Sources/BlinkApp"
        ),
        .target(
            name: "BlinkCore",
            dependencies: [
                .product(name: "GRDB", package: "GRDB.swift")
            ],
            path: "Sources/BlinkCore"
        ),
        .testTarget(
            name: "BlinkCoreTests",
            dependencies: ["BlinkCore"],
            path: "Tests/BlinkCoreTests"
        ),
        .testTarget(
            name: "BlinkAppTests",
            dependencies: ["BlinkApp", "BlinkCore"],
            path: "Tests/BlinkAppTests"
        )
    ]
)
