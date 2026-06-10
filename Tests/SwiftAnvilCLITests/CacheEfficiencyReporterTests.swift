// swiftlint:disable force_try
import Foundation
import Testing
@testable import SwiftAnvilCLI

struct CacheEfficiencyReporterTests {
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
        let package = Package(name: "CacheTest")
        """.write(toFile: packagePath, atomically: true, encoding: .utf8)
    }

    @Test func analyzeReturnsHealthyForEmptyProject() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }
        writePackage(at: path)

        let reporter = CacheEfficiencyReporter(path: path)
        let report = try await reporter.analyze()
        #expect(report.buildDirSize == 0)
        #expect(report.moduleCount == 0)
        #expect(report.staleArtifactCount == 0)
        #expect(report.recommendations.contains(where: { $0.contains("healthy") }))
    }

    @Test func analyzeDetectsLargeBuildDir() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }
        writePackage(at: path)

        let buildPath = (path as NSString).appendingPathComponent(".build")
        try FileManager.default.createDirectory(atPath: buildPath, withIntermediateDirectories: true)
        let bigFile = (buildPath as NSString).appendingPathComponent("big.o")
        try Data(repeating: 0, count: 600_000_000).write(to: URL(fileURLWithPath: bigFile))

        let reporter = CacheEfficiencyReporter(path: path)
        let report = try await reporter.analyze()
        #expect(report.buildDirSize == 600_000_000)
        #expect(report.recommendations.contains(where: { $0.contains("exceeds 500 MB") }))
    }

    @Test func analyzeCountsModules() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }
        writePackage(at: path)

        let buildPath = (path as NSString).appendingPathComponent(".build")
        try FileManager.default.createDirectory(atPath: buildPath, withIntermediateDirectories: true)
        for i in 0 ..< 3 {
            let modPath = (buildPath as NSString).appendingPathComponent("Mod\(i).swiftmodule")
            try Data().write(to: URL(fileURLWithPath: modPath))
        }

        let reporter = CacheEfficiencyReporter(path: path)
        let report = try await reporter.analyze()
        #expect(report.moduleCount == 3)
    }
}
