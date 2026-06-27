// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Anchor",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "Anchor", targets: ["Anchor"])
    ],
    targets: [
        .executableTarget(
            name: "Anchor",
            path: "Anchor",
            exclude: ["Info.plist"]
        )
    ]
)
