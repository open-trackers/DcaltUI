// swift-tools-version: 5.7

import PackageDescription

let package = Package(name: "DcaltUI",
                      platforms: [.macOS(.v13), .iOS(.v16), .watchOS(.v9)],
                      products: [
                          .library(name: "DcaltUI",
                                   targets: ["DcaltUI"]),
                      ],
                      dependencies: [
                          .package(url: "https://github.com/openalloc/SwiftCompactor", from: "1.3.0"),
                          .package(url: "https://github.com/apple/swift-collections.git", from: "1.0.4"),
                          .package(url: "https://github.com/open-trackers/TrackerUI.git", from: "1.0.0"),
                          .package(url: "https://github.com/open-trackers/DcaltLib.git", from: "1.0.0"),
                          .package(path: "../SwiftNumberPad"),
                      ],
                      targets: [
                          .target(name: "DcaltUI",
                                  dependencies: [
                                      .product(name: "TrackerUI", package: "TrackerUI"),
                                      .product(name: "DcaltLib", package: "DcaltLib"),
                                      .product(name: "Compactor", package: "SwiftCompactor"),
                                      .product(name: "Collections", package: "swift-collections"),
                                      .product(name: "NumberPad", package: "SwiftNumberPad"),
                                  ],
                                  path: "Sources"),
                          .testTarget(name: "DcaltUITests",
                                      dependencies: ["DcaltUI"],
                                      path: "Tests"),
                      ])
