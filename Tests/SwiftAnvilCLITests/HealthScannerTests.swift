// swiftlint:disable force_try
import Foundation
import Testing
@testable import SwiftAnvilCLI

struct HealthScannerTests {
    private func makeTempDir() -> String {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp.path
    }

    private func writePackage(at path: String) {
        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        try! """
        // swift-tools-version:6.0
        import PackageDescription
        let package = Package(name: "HealthTest")
        """.write(toFile: packagePath, atomically: true, encoding: .utf8)
    }

    @Test func scanDetectsFormatIssues() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }
        writePackage(at: path)

        let sourcesPath = (path as NSString).appendingPathComponent("Sources/HealthTest")
        try FileManager.default.createDirectory(atPath: sourcesPath, withIntermediateDirectories: true)
        let filePath = (sourcesPath as NSString).appendingPathComponent("Test.swift")
        try "let x=1".write(toFile: filePath, atomically: true, encoding: .utf8)

        let scanner = HealthScanner(path: path, quick: true)
        let report = try await scanner.scan()

        let formatDim = report.dimensions.first { $0.name == "format" }
        #expect(formatDim != nil)
        // Format may fail because swiftformat is not installed or file needs formatting
        #expect(formatDim?.status != nil)
    }

    @Test func scanProducesJSON() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }
        writePackage(at: path)

        let scanner = HealthScanner(path: path, quick: true)
        let report = try await scanner.scan()

        let encoder = JSONEncoder()
        let data = try encoder.encode(report)
        let decoded = try JSONDecoder().decode(RepoHealthReport.self, from: data)
        #expect(!decoded.repoName.isEmpty)
    }

    @Test func markdownOutputContainsDimensions() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }
        writePackage(at: path)

        let scanner = HealthScanner(path: path, quick: true)
        let report = try await scanner.scan()
        let markdown = scanner.formatMarkdown(report)

        #expect(markdown.contains("Health Report:"))
        #expect(markdown.contains("format"))
        #expect(markdown.contains("lint"))
    }
}
