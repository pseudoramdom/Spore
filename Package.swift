// swift-tools-version: 5.7
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Spore",
    platforms: [
        .iOS(.v14),
        .macOS(.v11),
    ],
    products: [
        // Products define the executables and libraries a package produces, and make them visible to other packages.
        .library(
            name: "Spore",
            targets: ["Spore"]),
        .executable(name: "spore-cli", targets: ["spore-cli"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        .package(url: "https://github.com/GigaBitcoin/secp256k1.swift",
                 exact: .init(stringLiteral: "0.8.1")),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages this package depends on.
        .target(
            name: "Spore",
            dependencies: [
                .product(name: "secp256k1", package: "secp256k1.swift"),
            ]),
        .testTarget(
            name: "SporeTests",
            dependencies: ["Spore"]),
        .executableTarget(name: "spore-cli", dependencies: [
            .target(name: "Spore"),
            .product(name: "ArgumentParser", package: "swift-argument-parser"),
        ])
    ]
)

#if swift(>=5.6)
    // Add the documentation compiler plugin if possible
    package.dependencies.append(
        .package(url: "https://github.com/apple/swift-docc-plugin", from: "1.0.0")
    )
#endif
