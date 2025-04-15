// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MastodonFeedUI",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MastodonFeedUI",
            targets: ["MastodonFeedUI"]),
    ],
    dependencies: [
        .package(path: "MastodonUtilities"),
        .package(path: "MastodonSharedUI"),
        .package(path: "MastodonKit"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MastodonFeedUI",
            dependencies: [
                "MastodonUtilities",
                "MastodonSharedUI",
                "MastodonKit"
            ]
        ),
    ],
    swiftLanguageModes: [.v5]
)
