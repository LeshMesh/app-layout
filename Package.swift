// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "AppLayoutCore",
    platforms: [.macOS("26.0")],
    products: [.library(name: "AppLayoutCore", targets: ["AppLayoutCore"])],
    targets: [
        .target(name: "AppLayoutCore", path: "Sources/Core"),
        .testTarget(name: "AppLayoutCoreTests", dependencies: ["AppLayoutCore"], path: "Tests/Core")
    ]
)
