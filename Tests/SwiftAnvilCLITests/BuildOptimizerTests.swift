import Foundation
import Testing
@testable import SwiftAnvilCLI

@Suite("BuildOptimizer")
struct BuildOptimizerTests {
    @Test("detects no issues in minimal package")
    func minimalPackage() async throws {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let packageSwift = """
        // swift-tools-version: 6.0
        import PackageDescription
        let package = Package(
            name: "Minimal",
            products: [.library(name: "Minimal", targets: ["Minimal"])],
            targets: [
                .target(name: "Minimal"),
                .testTarget(name: "MinimalTests", dependencies: ["Minimal"])
            ]
        )
        """
        try packageSwift.write(to: tmpDir.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)

        let sourcesDir = tmpDir.appendingPathComponent("Sources/Minimal")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)
        try "// Minimal".write(
            to: sourcesDir.appendingPathComponent("Minimal.swift"),
            atomically: true,
            encoding: .utf8
        )

        let optimizer = BuildOptimizer(path: tmpDir.path)
        let results = try await optimizer.analyze()

        #expect(results.isEmpty)
    }

    @Test("detects large target for splitting suggestion")
    func largeTarget() async throws {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let packageSwift = """
        // swift-tools-version: 6.0
        import PackageDescription
        let package = Package(
            name: "BigLib",
            products: [.library(name: "BigLib", targets: ["BigLib"])],
            targets: [.target(name: "BigLib")]
        )
        """
        try packageSwift.write(to: tmpDir.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)

        let sourcesDir = tmpDir.appendingPathComponent("Sources/BigLib")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)
        for i in 1 ... 55 {
            try "// file \(i)".write(
                to: sourcesDir.appendingPathComponent("File\(i).swift"),
                atomically: true,
                encoding: .utf8
            )
        }

        let optimizer = BuildOptimizer(path: tmpDir.path)
        let results = try await optimizer.analyze()

        let splitting = results.filter { $0.category == "splitting" }
        #expect(splitting.count == 1)
        #expect(splitting.first?.severity == .warning)
        #expect(splitting.first?.message.contains("55") == true)
    }

    @Test("detects circular dependency")
    func circularDependency() async throws {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let packageSwift = """
        // swift-tools-version: 6.0
        import PackageDescription
        let package = Package(
            name: "Cycle",
            products: [],
            targets: [
                .target(name: "A", dependencies: ["B"]),
                .target(name: "B", dependencies: ["A"])
            ]
        )
        """
        try packageSwift.write(to: tmpDir.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)

        let optimizer = BuildOptimizer(path: tmpDir.path)
        let results = try await optimizer.analyze()

        let cycles = results.filter { $0.category == "graph" && $0.severity == .error }
        #expect(cycles.count >= 1)
    }

    @Test("recommends WMO for small leaf target")
    func wmoForLeaf() async throws {
        let tmpDir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: tmpDir, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: tmpDir) }

        let packageSwift = """
        // swift-tools-version: 6.0
        import PackageDescription
        let package = Package(
            name: "Leaf",
            products: [.library(name: "Leaf", targets: ["Leaf"])],
            targets: [.target(name: "Leaf")]
        )
        """
        try packageSwift.write(to: tmpDir.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)

        let sourcesDir = tmpDir.appendingPathComponent("Sources/Leaf")
        try FileManager.default.createDirectory(at: sourcesDir, withIntermediateDirectories: true)
        try "// Leaf".write(to: sourcesDir.appendingPathComponent("Leaf.swift"), atomically: true, encoding: .utf8)

        let optimizer = BuildOptimizer(path: tmpDir.path)
        let results = try await optimizer.analyze()

        let wmo = results.filter { $0.category == "wmo" }
        #expect(wmo.count >= 1)
        #expect(wmo.first?.message.contains("leaf") == true)
    }
}
