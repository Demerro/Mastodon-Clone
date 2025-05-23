// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MastodonApplicationUI",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "MastodonApplicationUI",
            targets: ["MastodonApplicationUI"]),
    ],
    dependencies: [
        .package(path: "UIKitFoundation"),
        .package(path: "MastodonAuthorizationUI"),
        .package(path: "MastodonMainUI"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "MastodonApplicationUI",
            dependencies: [
                .byName(name: "UIKitFoundation"),
                .byName(name: "MastodonAuthorizationUI"),
                .byName(name: "MastodonMainUI"),
            ]
        ),
    ]
)
