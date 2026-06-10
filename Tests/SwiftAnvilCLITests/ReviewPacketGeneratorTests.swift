// swiftlint:disable force_try
import Foundation
import Testing
@testable import SwiftAnvilCLI

struct ReviewPacketGeneratorTests {
    private func makeGitRepo(at path: String) async {
        let runner = ShellRunner()
        _ = try! await runner.run("git init '\(path)'")
        _ = try! await runner.run("git -C '\(path)' config user.email 'test@test.com'")
        _ = try! await runner.run("git -C '\(path)' config user.name 'Test'")
    }

    private func makeTempDir() -> String {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp.path
    }

    @Test func generateCreatesPacket() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }
        await makeGitRepo(at: path)

        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        try """
        // swift-tools-version:6.0
        import PackageDescription
        let package = Package(name: "ReviewTest")
        """.write(toFile: packagePath, atomically: true, encoding: .utf8)

        let runner = ShellRunner()
        try await runner.run("git -C '\(path)' add -A")
        try await runner.run("git -C '\(path)' commit -m 'initial'")

        // Make a change
        let readmePath = (path as NSString).appendingPathComponent("README.md")
        try "# ReviewTest".write(toFile: readmePath, atomically: true, encoding: .utf8)
        try await runner.run("git -C '\(path)' add -A")
        try await runner.run("git -C '\(path)' commit -m 'add readme'")

        let generator = ReviewPacketGenerator(path: path)
        let packet = try await generator.generate()

        #expect(!packet.diff.isEmpty)
        #expect(!packet.architectureNotes.isEmpty)
        #expect(packet.policyChecks.contains { $0.name == "README Present" })
    }

    @Test func formatMarkdownProducesValidOutput() {
        let packet = ReviewPacket(
            diff: "+ added line",
            testSummary: "10 tests passed",
            architectureNotes: "Single module",
            policyChecks: [
                ReviewPacket.PolicyCheck(name: "Tests", passed: true, details: "All pass")
            ]
        )
        let generator = ReviewPacketGenerator(path: "/tmp")
        let markdown = generator.formatMarkdown(packet)
        #expect(markdown.contains("# Review Packet"))
        #expect(markdown.contains("✅"))
        #expect(markdown.contains("+ added line"))
    }
}
