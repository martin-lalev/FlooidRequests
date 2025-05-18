// swift-tools-version:6.0

import PackageDescription

let package = Package(
    name: "FlooidRequests",
    platforms: [.iOS(.v16), .macOS(.v10_15)],
    products: [
        .library(
            name: "FlooidRequests",
            targets: ["FlooidRequests"]
        ),
        .library(
            name: "FlooidURLSession",
            targets: ["FlooidURLSession"]
        ),
    ],
    dependencies: [
    ],
    targets: [
        .target(
            name: "FlooidRequests",
            dependencies: [],
            path: "Abstract"
        ),
        .target(
            name: "FlooidURLSession",
            dependencies: [
                .target(name: "FlooidRequests"),
            ],
            path: "URLSession"
        ),
    ],
    swiftLanguageVersions: [.v6]
)
