// swift-tools-version: 6.2
import PackageDescription

let package = Package(
    name: "NowCoiner",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v14)
    ],
    products: [
        .library(name: "NowCoinerCore", targets: ["NowCoinerCore"]),
        .executable(name: "NowCoinerApp", targets: ["NowCoinerApp"])
    ],
    targets: [
        .target(
            name: "NowCoinerCore"
        ),
        .executableTarget(
            name: "NowCoinerApp",
            dependencies: ["NowCoinerCore"],
            resources: [
                .process("Resources")
            ]
        ),
        .testTarget(
            name: "NowCoinerCoreTests",
            dependencies: ["NowCoinerCore"]
        )
    ]
)
