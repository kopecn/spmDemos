// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "variousDemos",
    platforms: [
        .macOS(.v14)  // Minimum macOS version
    ],
    dependencies: [
        .package(url: "git@github.com:kopecn/spmFoundationTools.git", branch: "dev"),
        .package(url: "https://github.com/daikimat/depermaid.git", from: "1.1.0"),
        .package(url: "https://github.com/stackotter/swift-cross-ui", branch: "main"),
        .package(url: "https://github.com/kopecn/spmMathTools.git", branch: "dev"),
    ],
    targets: [
        .executableTarget(
            name: "TransactionDemo",
            dependencies: [
                "FoundationUITools",
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui"),
            ],
            path: "spm/Sources/TransactionDemo"
        ),
        .executableTarget(
            name: "OTGUIDemo",
            dependencies: [
                "FoundationUITools",
                .product(name: "spmMathTools", package: "spmMathTools"),
                .product(name: "FoundationTypes", package: "spmFoundationTools"),
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui"),
            ],
            path: "spm/Sources/OTGUIDemo",
            exclude: []
        ),
    ]
)
