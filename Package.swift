// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "BleScan",
  platforms: [
    .macOS(.v13)
  ],
  dependencies: [
    .package(url: "https://github.com/realm/SwiftLint", from: "0.58.2"),
    .package(url: "https://github.com/apple/swift-async-algorithms", from: "1.0.3"),
  ],
  targets: [
    .executableTarget(
      name: "BleScan",
      dependencies: [
        .product(name: "AsyncAlgorithms", package: "swift-async-algorithms")
      ]
    )
  ]
)
