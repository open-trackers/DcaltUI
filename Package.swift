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
//                          .package(url: "https://github.com/buh/CompactSlider.git", from: "1.1.3"),
                          // .package(url: "https://github.com/Pyroh/SlidingRuler", .upToNextMajor(from: "0.1.0")),
                          // .package(url: "https://github.com/gym-routine-tracker/DcaltLib.git", from: "1.1.0"),
                          .package(name: "TrackerUI", path: "../TrackerUI"),
                          .package(name: "DcaltLib", path: "../DcaltLib"),
                          // .package(name: "ColorThemeLib", path: "../ColorThemeLib"),
                      ],
                      targets: [
                          .target(name: "DcaltUI",
                                  dependencies: [
                                      .product(name: "TrackerUI", package: "TrackerUI"),
                                      .product(name: "DcaltLib", package: "DcaltLib"),
                                      .product(name: "Compactor", package: "SwiftCompactor"),
//                                      .product(name: "CompactSlider", package: "CompactSlider"),
                                      // .product(name: "SlidingRuler", package: "SlidingRuler"),
                                      .product(name: "Collections", package: "swift-collections"),
                                      // .product(name: "ColorThemeLib", package: "ColorThemeLib"),
                                  ],
                                  path: "Sources"),
                          .testTarget(name: "DcaltUITests",
                                      dependencies: ["DcaltUI"],
                                      path: "Tests"),
                      ])
