// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "TickerPad",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "TickerPadCore", targets: ["TickerPadCore"]),
        .executable(name: "TickerPadApp", targets: ["TickerPadApp"])
    ],
    targets: [
        .target(
            name: "TickerPadCore"
        ),
        .executableTarget(
            name: "TickerPadApp",
            dependencies: ["TickerPadCore"]
        ),
        .testTarget(
            name: "TickerPadCoreTests",
            dependencies: ["TickerPadCore"]
        )
    ]
)
