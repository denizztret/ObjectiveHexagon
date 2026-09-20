// swift-tools-version: 6.0

import PackageDescription

let package = Package(
  name: "HexagonKit",
  platforms: [
    .iOS(.v15),
    .macOS(.v12),
    .tvOS(.v15),
    .watchOS(.v8),
    .visionOS(.v1),
  ],
  products: [
    .library(name: "HexagonKit", targets: ["HexagonKit"]),
    .library(name: "HexagonKitUI", targets: ["HexagonKitUI"]),
  ],
  targets: [
    .target(name: "HexagonKit"),
    .target(name: "HexagonKitUI", dependencies: ["HexagonKit"]),
    .testTarget(name: "HexagonKitTests", dependencies: ["HexagonKit"]),
    .testTarget(name: "HexagonKitUITests", dependencies: ["HexagonKitUI"]),
  ]
)
