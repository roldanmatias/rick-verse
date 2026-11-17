// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "Core",
    // iOS is the real target. macOS 14 lets `swift test` run in Terminal/CI without a simulator.
    platforms: [.iOS(.v17), .macOS(.v14)],
    products: [
        .library(name: "Domain", targets: ["Domain"]),
        .library(name: "Networking", targets: ["Networking"]),
        .library(name: "DataREST", targets: ["DataREST"]),
        .library(name: "DataGraphQL", targets: ["DataGraphQL"]),
        .library(name: "Presentation", targets: ["Presentation"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apollographql/apollo-ios.git", from: "2.0.0"),
        // DocC → GitHub Pages (Phase 11). Build-time plugin only; it adds nothing to the app.
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.4.0"),
    ],
    targets: [
        .target(name: "Domain"),
        .target(name: "Networking"),
        .target(name: "DataREST", dependencies: ["Domain", "Networking"]),
        .target(name: "DataGraphQL", dependencies: [
            "Domain",
            "Networking",   // for NetworkLog (Phase 8). Apollo types never leave this module.
            .product(name: "Apollo", package: "apollo-ios"),
            .product(name: "ApolloAPI", package: "apollo-ios"),
        ]),
        .target(name: "Presentation", dependencies: ["Domain"]),

        // Shared test helpers (URLProtocolStub, fixture loading). A normal target used only by tests.
        .target(name: "TestSupport", path: "Tests/TestSupport"),

        .testTarget(name: "DomainTests", dependencies: ["Domain"]),
        .testTarget(name: "NetworkingTests", dependencies: ["Networking", "TestSupport"]),
        .testTarget(name: "DataRESTTests",
                    dependencies: ["DataREST", "Networking", "TestSupport"],
                    resources: [.process("Fixtures")]),
        .testTarget(name: "DataGraphQLTests",
                    dependencies: ["DataGraphQL", "TestSupport",
                                   .product(name: "Apollo", package: "apollo-ios")],
                    resources: [.process("Fixtures")]),
        .testTarget(name: "PresentationTests", dependencies: ["Presentation", "Domain"]),

        // Live tests against the real API. Skipped unless RUN_CONTRACT_TESTS=1 (nightly CI, Phase 11).
        .testTarget(name: "ContractTests",
                    dependencies: ["Domain", "Networking", "DataREST", "DataGraphQL"]),
    ]
)
