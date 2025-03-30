// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MastodonProfileUI",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MastodonProfileUI",
            targets: ["MastodonProfileUI"]),
    ],
    dependencies: [
        .package(path: "SwiftUtilities"),
        .package(path: "UIKitUtilities"),
        .package(path: "FoundationUtilities"),
        .package(path: "MastodonCoreUI"),
        .package(path: "MastodonAccountsDomain"),
        .package(path: "MastodonSharedUI"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MastodonProfileUI",
            dependencies: [
                .byName(name: "SwiftUtilities"),
                .byName(name: "UIKitUtilities"),
                .byName(name: "FoundationUtilities"),
                .byName(name: "MastodonCoreUI"),
                .byName(name: "MastodonAccountsDomain"),
                .byName(name: "MastodonSharedUI"),
            ]
        ),
    ]
)
