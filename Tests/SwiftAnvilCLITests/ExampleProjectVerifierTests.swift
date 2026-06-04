import Foundation
import Testing
@testable import SwiftAnvilCLI

@Suite("ExampleProjectVerifier")
struct ExampleProjectVerifierTests {

    @Test("passes valid example project")
    func passesValidExample() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        try fm.createDirectory(at: tempDir.appendingPathComponent("Sources/MyLib"), withIntermediateDirectories: true)
        try fm.createDirectory(at: tempDir.appendingPathComponent("Tests/MyLibTests"), withIntermediateDirectories: true)
        try "// swift-tools-version: 6.0\nimport PackageDescription".write(to: tempDir.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        try "# MyLib\n\n## Build\n\n```bash\nswift build\n```\n\n## Test\n\n```bash\nswift test\n```".write(to: tempDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try "*.xcodeproj\n".write(to: tempDir.appendingPathComponent(".gitignore"), atomically: true, encoding: .utf8)

        let verifier = ExampleProjectVerifier()
        let report = verifier.verify(path: tempDir.path)

        #expect(report.passed == true)
        #expect(report.errors.isEmpty)
    }

    @Test("fails when Package.swift is missing")
    func failsMissingPackageSwift() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        try fm.createDirectory(at: tempDir.appendingPathComponent("Sources"), withIntermediateDirectories: true)
        try fm.createDirectory(at: tempDir.appendingPathComponent("Tests"), withIntermediateDirectories: true)
        try "# README".write(to: tempDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try "".write(to: tempDir.appendingPathComponent(".gitignore"), atomically: true, encoding: .utf8)

        let verifier = ExampleProjectVerifier()
        let report = verifier.verify(path: tempDir.path)

        #expect(report.passed == false)
        #expect(report.errors.contains { $0.check == "required-file" && $0.path == "Package.swift" })
    }

    @Test("fails when Sources directory is missing")
    func failsMissingSources() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        try fm.createDirectory(at: tempDir.appendingPathComponent("Tests"), withIntermediateDirectories: true)
        try "// swift-tools-version: 6.0".write(to: tempDir.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        try "# README".write(to: tempDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try "".write(to: tempDir.appendingPathComponent(".gitignore"), atomically: true, encoding: .utf8)

        let verifier = ExampleProjectVerifier()
        let report = verifier.verify(path: tempDir.path)

        #expect(report.passed == false)
        #expect(report.errors.contains { $0.check == "required-directory" && $0.path == "Sources" })
    }

    @Test("warns when Package.swift lacks Swift 6 mode")
    func warnsNoSwift6() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        try fm.createDirectory(at: tempDir.appendingPathComponent("Sources/MyLib"), withIntermediateDirectories: true)
        try fm.createDirectory(at: tempDir.appendingPathComponent("Tests/MyLibTests"), withIntermediateDirectories: true)
        try "// swift-tools-version: 5.9\nimport PackageDescription".write(to: tempDir.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        try "# README\n\n## Build\n\n## Test".write(to: tempDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try "".write(to: tempDir.appendingPathComponent(".gitignore"), atomically: true, encoding: .utf8)

        let verifier = ExampleProjectVerifier()
        let report = verifier.verify(path: tempDir.path)

        #expect(report.warnings.contains { $0.check == "package-swift-6" })
    }

    @Test("warns when README lacks build/test instructions")
    func warnsNoBuildTestInstructions() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        try fm.createDirectory(at: tempDir.appendingPathComponent("Sources/MyLib"), withIntermediateDirectories: true)
        try fm.createDirectory(at: tempDir.appendingPathComponent("Tests/MyLibTests"), withIntermediateDirectories: true)
        try "// swift-tools-version: 6.0\nimport PackageDescription\nlet package = Package(name: \"MyLib\", targets: [.target(name: \"MyLib\"), .testTarget(name: \"MyLibTests\", dependencies: [\"MyLib\"])])".write(to: tempDir.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)
        try "# README".write(to: tempDir.appendingPathComponent("README.md"), atomically: true, encoding: .utf8)
        try "".write(to: tempDir.appendingPathComponent(".gitignore"), atomically: true, encoding: .utf8)

        let verifier = ExampleProjectVerifier()
        let report = verifier.verify(path: tempDir.path)

        #expect(report.warnings.contains { $0.check == "readme-build-test" })
    }
}
