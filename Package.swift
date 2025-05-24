// swift-tools-version:6.0

import PackageDescription
import CompilerPluginSupport

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
        .package(url: "https://github.com/swiftlang/swift-syntax", from: "509.0.0"),
    ],
    targets: [
        .target(
            name: "FlooidRequests",
            dependencies: [
                "FlooidRequestClientMacros"
            ],
            path: "Abstract"
        ),
        .target(
            name: "FlooidURLSession",
            dependencies: [
                .target(name: "FlooidRequests"),
            ],
            path: "URLSession"
        ),
        .macro(
            name: "FlooidRequestClientMacros",
            dependencies: [
                .product(name: "SwiftSyntaxMacros", package: "swift-syntax"),
                .product(name: "SwiftCompilerPlugin", package: "swift-syntax")
            ],
            path: "Macros"
        ),
    ],
    swiftLanguageVersions: [.v6]
)
