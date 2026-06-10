// swiftlint:disable force_try
import Foundation
import Testing
@testable import SwiftAnvilCLI

struct AgentInstructionsGeneratorTests {
    private func makeTempDir() -> String {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp.path
    }

    @Test func generateIncludesBuildCommands() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        try """
        // swift-tools-version:6.0
        import PackageDescription
        let package = Package(name: "InstrTest")
        """.write(toFile: packagePath, atomically: true, encoding: .utf8)

        let generator = AgentInstructionsGenerator(path: path)
        let instructions = try await generator.generate()
        #expect(instructions.contains("swift build"))
        #expect(instructions.contains("swift test"))
    }

    @Test func generateDetectsSwiftFormat() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        try """
        // swift-tools-version:6.0
        import PackageDescription
        let package = Package(name: "InstrTest")
        """.write(toFile: packagePath, atomically: true, encoding: .utf8)

        let formatPath = (path as NSString).appendingPathComponent(".swiftformat")
        try "".write(toFile: formatPath, atomically: true, encoding: .utf8)

        let generator = AgentInstructionsGenerator(path: path)
        let instructions = try await generator.generate()
        #expect(instructions.contains("swiftformat"))
    }
}
