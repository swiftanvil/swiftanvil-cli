// ProjectVerificationPolicy.swift
// Centralized generated project verification requirements

import Foundation

struct ProjectVerificationPolicy: Sendable {
    let requiredFiles: [String]
    let requiredDirectories: [String]
    let packageManifestPath: String
    let ciWorkflowPath: String
    let documentationRegistryPath: String
    let requiredCheckoutAction: String
    let requiredSwiftLanguageMode: String

    static let current = ProjectVerificationPolicy(
        requiredFiles: [
            "Package.swift",
            ".github/workflows/ci.yml",
            "Documentation/Registry/index.yml",
            "AGENTS.md",
        ],
        requiredDirectories: [
            "Sources",
            "Tests",
        ],
        packageManifestPath: "Package.swift",
        ciWorkflowPath: ".github/workflows/ci.yml",
        documentationRegistryPath: "Documentation/Registry/index.yml",
        requiredCheckoutAction: "actions/checkout@v6",
        requiredSwiftLanguageMode: "swiftLanguageModes: [.v6]"
    )
}
