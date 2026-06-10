// ProjectVerifierTests.swift
// Unit tests for generated project verification

import Foundation
import Testing
@testable import SwiftAnvilCLI

struct ProjectVerifierTests {
    @Test func validGeneratedProjectContractPasses() {
        let fileSystem = InMemoryProjectVerificationFileSystem.validProject()
        let report = ProjectVerifier(fileSystem: fileSystem).verify(path: "/GeneratedApp")

        #expect(report.passed)
        #expect(report.issues.isEmpty)
    }

    @Test func missingRequiredStructureFails() {
        let fileSystem = InMemoryProjectVerificationFileSystem(files: [:], directories: [])
        let report = ProjectVerifier(fileSystem: fileSystem).verify(path: "/GeneratedApp")

        #expect(!report.passed)
        #expect(report.errors.contains { $0.check == "required-file" && $0.path == "Package.swift" })
        #expect(report.errors.contains { $0.check == "required-directory" && $0.path == "Sources" })
        #expect(report.errors.contains { $0.check == "required-directory" && $0.path == "Tests" })
    }

    @Test func staleCheckoutVersionFails() {
        var fileSystem = InMemoryProjectVerificationFileSystem.validProject()
        fileSystem.files["/GeneratedApp/.github/workflows/ci.yml"] = """
        name: CI
        jobs:
          test:
            steps:
              - uses: actions/checkout@v4
              - run: swift build
              - run: swift test
        """

        let report = ProjectVerifier(fileSystem: fileSystem).verify(path: "/GeneratedApp")

        #expect(!report.passed)
        #expect(report.errors.contains { $0.check == "ci-checkout-version" })
    }

    @Test func missingTestTargetFails() {
        var fileSystem = InMemoryProjectVerificationFileSystem.validProject()
        fileSystem.files["/GeneratedApp/Package.swift"] = """
        // swift-tools-version: 6.0
        import PackageDescription
        let package = Package(
            name: "GeneratedApp",
            targets: [
                .target(name: "GeneratedApp")
            ],
            swiftLanguageModes: [.v6]
        )
        """

        let report = ProjectVerifier(fileSystem: fileSystem).verify(path: "/GeneratedApp")

        #expect(!report.passed)
        #expect(report.errors.contains { $0.check == "package-test-target" })
    }

    @Test func missingRegistrySourcesFails() {
        var fileSystem = InMemoryProjectVerificationFileSystem.validProject()
        fileSystem.files["/GeneratedApp/Documentation/Registry/index.yml"] = """
        documents:
          readme:
            path: README.md
        """

        let report = ProjectVerifier(fileSystem: fileSystem).verify(path: "/GeneratedApp")

        #expect(!report.passed)
        #expect(report.errors.contains { $0.check == "registry-sources" })
    }
}

private struct InMemoryProjectVerificationFileSystem: ProjectVerificationFileSystem {
    var files: [String: String]
    var directories: Set<String>

    func fileExists(atPath path: String) -> Bool {
        files.keys.contains(normalize(path))
    }

    func directoryExists(atPath path: String) -> Bool {
        directories.contains(normalize(path))
    }

    func readFile(atPath path: String) throws -> String {
        guard let contents = files[normalize(path)] else {
            throw CocoaError(.fileReadNoSuchFile)
        }
        return contents
    }

    static func validProject() -> Self {
        InMemoryProjectVerificationFileSystem(
            files: [
                "/GeneratedApp/Package.swift": """
                // swift-tools-version: 6.0
                import PackageDescription
                let package = Package(
                    name: "GeneratedApp",
                    targets: [
                        .target(name: "GeneratedApp"),
                        .testTarget(name: "GeneratedAppTests", dependencies: ["GeneratedApp"])
                    ],
                    swiftLanguageModes: [.v6]
                )
                """,
                "/GeneratedApp/.github/workflows/ci.yml": """
                name: CI
                jobs:
                  test:
                    steps:
                      - uses: actions/checkout@v6
                      - run: swift build
                      - run: swift test
                """,
                "/GeneratedApp/Documentation/Registry/index.yml": """
                documents:
                  readme:
                    path: README.md
                    sources: []
                """,
                "/GeneratedApp/AGENTS.md": "# GeneratedApp Agent Guidelines\n"
            ],
            directories: [
                "/GeneratedApp/Sources",
                "/GeneratedApp/Tests"
            ]
        )
    }

    private func normalize(_ path: String) -> String {
        URL(fileURLWithPath: path).standardizedFileURL.path
    }
}
