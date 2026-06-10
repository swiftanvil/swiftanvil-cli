// swiftlint:disable force_try
import Foundation
import Testing
@testable import SwiftAnvilCLI

struct BinarySizeAnalyzerTests {
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
        let package = Package(name: "SizeTest")
        """.write(toFile: packagePath, atomically: true, encoding: .utf8)
    }

    @Test func analyzeReturnsEmptyWhenNoBuildProducts() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }
        writePackage(at: path)

        let analyzer = BinarySizeAnalyzer(path: path)
        let breakdown = try await analyzer.analyze()
        #expect(breakdown.totalBytes == 0)
        #expect(breakdown.sections.isEmpty)
        #expect(!breakdown.recommendations.isEmpty)
    }

    @Test func analyzeDetectsDebugBinaries() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }
        writePackage(at: path)

        let debugPath = (path as NSString).appendingPathComponent(".build/debug")
        try FileManager.default.createDirectory(atPath: debugPath, withIntermediateDirectories: true)
        let binaryPath = (debugPath as NSString).appendingPathComponent("SizeTest")
        try Data(repeating: 0, count: 1024).write(to: URL(fileURLWithPath: binaryPath))

        let analyzer = BinarySizeAnalyzer(path: path)
        let breakdown = try await analyzer.analyze()
        #expect(breakdown.totalBytes == 1024)
        #expect(breakdown.sections.count == 1)
        #expect(breakdown.sections.first?.name.contains("SizeTest") == true)
    }

    @Test func analyzeDetectsLargeBinary() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }
        writePackage(at: path)

        let releasePath = (path as NSString).appendingPathComponent(".build/release")
        try FileManager.default.createDirectory(atPath: releasePath, withIntermediateDirectories: true)
        let binaryPath = (releasePath as NSString).appendingPathComponent("SizeTest")
        try Data(repeating: 0, count: 15_000_000).write(to: URL(fileURLWithPath: binaryPath))

        let analyzer = BinarySizeAnalyzer(path: path)
        let breakdown = try await analyzer.analyze()
        #expect(breakdown.totalBytes == 15_000_000)
        let hasLargeWarning = breakdown.recommendations.contains {
            $0.contains("exceeds 10 MB")
        }
        #expect(hasLargeWarning)
    }
}
