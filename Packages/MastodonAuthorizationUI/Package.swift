// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "MastodonAuthorizationUI",
    platforms: [.iOS(.v15)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "AuthorizationUI",
            targets: ["AuthorizationUI"]
        ),
    ],
    dependencies: [
        .package(path: "UIKitFoundation"),
        .package(path: "UIKitUtilities"),
        .package(path: "SwiftUtilities"),
        .package(path: "MastodonAuthorizationDomain"),
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "AuthorizationUI",
            dependencies: [
                .byName(name: "UIKitFoundation"),
                .byName(name: "InstancesUI"),
                .product(name: "AuthorizationDomain", package: "MastodonAuthorizationDomain"),
            ]
        ),
        .target(
            name: "InstancesUI",
            dependencies: [
                .byName(name: "UIKitFoundation"),
                .byName(name: "UIKitUtilities"),
                .byName(name: "SwiftUtilities"),
                .product(name: "InstancesDomain", package: "MastodonAuthorizationDomain"),
            ]
        )
    ]
)
