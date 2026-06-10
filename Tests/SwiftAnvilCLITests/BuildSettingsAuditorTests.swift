// swiftlint:disable force_try
import Foundation
import Testing
@testable import SwiftAnvilCLI

struct BuildSettingsAuditorTests {
    private func makeTempDir() -> String {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp.path
    }

    private func writePackageSwift(
        at path: String,
        toolsVersion: String = "// swift-tools-version:6.0",
        content: String
    ) {
        let fullContent = """
        \(toolsVersion)
        import PackageDescription

        \(content)
        """
        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        try! fullContent.write(toFile: packagePath, atomically: true, encoding: .utf8)
    }

    @Test func auditPassesForCleanPackage() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        writePackageSwift(at: path, content: """
        let package = Package(
            name: "CleanPackage",
            platforms: [.iOS(.v18), .macOS(.v15)],
            products: [.library(name: "CleanPackage", targets: ["CleanPackage"])],
            targets: [.target(name: "CleanPackage")],
            swiftLanguageModes: [.v6]
        )
        """)

        let auditor = BuildSettingsAuditor(path: path)
        let findings = try await auditor.audit()
        #expect(findings.isEmpty)
    }

    @Test func auditDetectsOldToolsVersion() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        writePackageSwift(
            at: path,
            toolsVersion: "// swift-tools-version:5.9",
            content: """
            let package = Package(name: "OldPackage")
            """
        )

        let auditor = BuildSettingsAuditor(path: path)
        let findings = try await auditor.audit()
        let versionFindings = findings.filter { $0.category == "version" }
        #expect(versionFindings.count == 1)
        #expect(versionFindings.first?.severity == .warning)
    }

    @Test func auditDetectsMissingSwiftLanguageModes() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        writePackageSwift(at: path, content: """
        let package = Package(
            name: "NoLangMode",
            products: [.library(name: "NoLangMode", targets: ["NoLangMode"])],
            targets: [.target(name: "NoLangMode")]
        )
        """)

        let auditor = BuildSettingsAuditor(path: path)
        let findings = try await auditor.audit()
        let langFindings = findings.filter { $0.category == "language" }
        #expect(langFindings.count == 1)
    }

    @Test func auditDetectsDeprecatedStrictConcurrency() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        writePackageSwift(at: path, content: """
        let package = Package(
            name: "OldConcurrency",
            targets: [
                .target(
                    name: "OldConcurrency",
                    swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]
                )
            ]
        )
        """)

        let auditor = BuildSettingsAuditor(path: path)
        let findings = try await auditor.audit()
        let concurrencyFindings = findings.filter { $0.category == "concurrency" }
        #expect(concurrencyFindings.count == 1)
    }

    @Test func auditDetectsNonHTTPSBinaryTarget() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        writePackageSwift(at: path, content: """
        let package = Package(
            name: "BadBinary",
            targets: [
                .binaryTarget(name: "Framework", url: "http://example.com/framework.zip", checksum: "abc123")
            ]
        )
        """)

        let auditor = BuildSettingsAuditor(path: path)
        let findings = try await auditor.audit()
        let securityFindings = findings.filter { $0.category == "security" }
        #expect(securityFindings.count == 1)
        #expect(securityFindings.first?.severity == .error)
    }
}
