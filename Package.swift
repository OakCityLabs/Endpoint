// swift-tools-version:5.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

//
//  Package.swift
//  Endpoint
//
//  Created by Jay Lyerly on 10/30/19.
//  Copyright © 2019 Oak City Labs. All rights reserved.
//

import PackageDescription

let package = Package(
    name: "Endpoint",
    platforms: [
        .iOS(.v11)
    ],
    products: [
        // Products define the executables and libraries produced by a package,
        // and make them visible to other packages.
        .library(
            name: "Endpoint",
            targets: ["Endpoint"])
    ],
    dependencies: [
        // Dependencies declare other packages that this package depends on.
        // .package(url: /* package url */, from: "1.0.0"),
    ],
    targets: [
        // Targets are the basic building blocks of a package. A target can define a module or a test suite.
        // Targets can depend on other targets in this package, and on products in packages which this package depends
        .target(
            name: "Endpoint",
            dependencies: []),
        .testTarget(
            name: "EndpointTests",
            dependencies: ["Endpoint"])
    ]
)
