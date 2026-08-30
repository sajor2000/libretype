// swift-tools-version: 5.9

import PackageDescription

let package = Package(
    name: "ModelRuntime",
    platforms: [.macOS(.v14)],
    products: [
        .library(name: "ModelRuntime", targets: ["ModelRuntime"]),
        .library(name: "LlamaModelRuntime", targets: ["LlamaModelRuntime"])
    ],
    dependencies: [
        .package(path: "../AutocompleteCore"),
        .package(path: "../TokenProfiles")
    ],
    targets: [
        .target(
            name: "ModelRuntime",
            dependencies: [
                .product(name: "AutocompleteCore", package: "AutocompleteCore")
            ]
        ),
        // llama.cpp xcframework via Libretype-mirrored URL+checksum (ADR-007 preferred form;
        // ADR-134). Local-path override under Vendor/ is for llama.cpp development only —
        // see CONTRIBUTING.md. Pin bumps require a new ADR and U7 baseline re-run.
        .binaryTarget(
            name: "llama",
            url: "https://github.com/sajor2000/libretype/releases/download/llama-b9402/llama-b9402-xcframework.zip",
            checksum: "ac9adcabf4638eced651010ff8280df98b9bb094d2ba882d89823bbd3c63b895"
        ),
        .target(
            name: "LlamaModelRuntime",
            dependencies: [
                .product(name: "AutocompleteCore", package: "AutocompleteCore"),
                .product(name: "TokenProfiles", package: "TokenProfiles"),
                "ModelRuntime",
                "llama"
            ]
        ),
        .testTarget(
            name: "ModelRuntimeTests",
            dependencies: [
                "ModelRuntime",
                "LlamaModelRuntime"
            ]
        )
    ]
)
