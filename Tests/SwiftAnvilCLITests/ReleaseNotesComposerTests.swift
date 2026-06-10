// swiftlint:disable force_try
import Foundation
import Testing
@testable import SwiftAnvilCLI

struct ReleaseNotesComposerTests {
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

    @Test func composeReturnsEmptyForNoCommits() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }
        await makeGitRepo(at: path)

        let composer = ReleaseNotesComposer(path: path)
        let notes = try await composer.compose()
        #expect(notes.sections.isEmpty)
    }

    @Test func composeCategorizesCommits() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }
        await makeGitRepo(at: path)

        let runner = ShellRunner()
        try await runner.run("git -C '\(path)' commit --allow-empty -m 'initial'")
        try await runner.run("git -C '\(path)' tag v0.1.0")
        try await runner.run("git -C '\(path)' commit --allow-empty -m 'feat: add login'")
        try await runner.run("git -C '\(path)' commit --allow-empty -m 'fix: resolve crash'")
        try await runner.run("git -C '\(path)' commit --allow-empty -m 'docs: update README'")

        let composer = ReleaseNotesComposer(path: path)
        let notes = try await composer.compose()

        let featureSection = notes.sections.first { $0.title.contains("Features") }
        let fixSection = notes.sections.first { $0.title.contains("Bug Fixes") }
        let docsSection = notes.sections.first { $0.title.contains("Documentation") }

        #expect(featureSection != nil)
        #expect(fixSection != nil)
        #expect(docsSection != nil)
    }

    @Test func formatMarkdownProducesValidOutput() {
        let notes = ReleaseNotes(
            version: "1.2.0",
            sections: [
                ReleaseNotes.Section(title: "Features", items: ["Add login", "Add signup"])
            ]
        )
        let composer = ReleaseNotesComposer(path: "/tmp")
        let markdown = composer.formatMarkdown(notes)
        #expect(markdown.contains("## 1.2.0"))
        #expect(markdown.contains("- Add login"))
        #expect(markdown.contains("- Add signup"))
    }
}
