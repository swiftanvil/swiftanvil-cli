// swiftlint:disable force_try
import Foundation
import Testing
@testable import SwiftAnvilCLI

struct AgentContextPackGeneratorTests {
    private func makeTempDir() -> String {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp.path
    }

    @Test func generateReadsPackageName() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        try """
        // swift-tools-version:6.0
        import PackageDescription
        let package = Package(name: "AgentTest")
        """.write(toFile: packagePath, atomically: true, encoding: .utf8)

        let generator = AgentContextPackGenerator(path: path)
        let pack = try await generator.generate()
        #expect(pack.projectName == "AgentTest")
    }

    @Test func generateDetectsDependencies() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        try """
        // swift-tools-version:6.0
        import PackageDescription
        let package = Package(
            name: "AgentTest",
            dependencies: [
                .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0")
            ]
        )
        """.write(toFile: packagePath, atomically: true, encoding: .utf8)

        let generator = AgentContextPackGenerator(path: path)
        let pack = try await generator.generate()
        #expect(pack.dependencies.contains("swift-argument-parser"))
    }

    @Test func formatProducesMarkdown() {
        let pack = AgentContextPack(
            projectName: "Test",
            architecture: "Single module.",
            recentChanges: ["abc123 feat: add thing"],
            testPolicy: "Run swift test.",
            dependencies: ["Dep1"],
            conventions: ["Use Swift 6"]
        )
        let generator = AgentContextPackGenerator(path: "/tmp")
        let markdown = generator.format(pack)
        #expect(markdown.contains("# Agent Context Pack: Test"))
        #expect(markdown.contains("Dep1"))
        #expect(markdown.contains("abc123"))
    }
}
