// DocsCommandTests.swift
// Tests for docs generate and preview commands

import ArgumentParser
import Foundation
import Testing
@testable import iFoundation

// MARK: - DocCGenerator Tests

@Suite("DocCGenerator")
struct DocCGeneratorTests {

    @Test("result is codable and equatable")
    func resultIsCodableAndEquatable() throws {
        let result = DocCGenerator.Result(
            success: true,
            catalogName: "MyPackage.docc",
            pageCount: 42,
            outputPath: "/tmp/docs",
            errorMessage: nil
        )

        let encoder = JSONEncoder()
        let data = try encoder.encode(result)
        let decoded = try JSONDecoder().decode(DocCGenerator.Result.self, from: data)

        #expect(decoded == result)
    }

    @Test("result equality respects all fields")
    func resultEquality() {
        let a = DocCGenerator.Result(success: true, catalogName: "A", pageCount: 1, outputPath: "/a", errorMessage: nil)
        let b = DocCGenerator.Result(success: true, catalogName: "A", pageCount: 1, outputPath: "/a", errorMessage: nil)
        let c = DocCGenerator.Result(success: false, catalogName: "A", pageCount: 1, outputPath: "/a", errorMessage: nil)

        #expect(a == b)
        #expect(a != c)
    }

    @Test("generate returns success when docc catalog exists")
    func generateReturnsSuccessWithCatalog() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        // Create a fake package with a .docc catalog
        let packageDir = tempDir.appendingPathComponent("MyPackage", isDirectory: true)
        let sourcesDir = packageDir.appendingPathComponent("Sources", isDirectory: true)
        let doccDir = sourcesDir.appendingPathComponent("MyPackage.docc", isDirectory: true)
        try fm.createDirectory(at: doccDir, withIntermediateDirectories: true)
        try "# Hello".write(to: doccDir.appendingPathComponent("Hello.md"), atomically: true, encoding: .utf8)

        // Create a fake output dir with HTML files to simulate successful generation
        let outputDir = tempDir.appendingPathComponent("docs", isDirectory: true)
        try fm.createDirectory(at: outputDir, withIntermediateDirectories: true)
        try "<html></html>".write(to: outputDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)
        try "<html></html>".write(to: outputDir.appendingPathComponent("page2.html"), atomically: true, encoding: .utf8)

        let generator = DocCGenerator()
        let result = try await generator.generate(
            path: packageDir.path,
            output: outputDir.path,
            hostingBasePath: nil,
            target: nil
        )

        #expect(result.catalogName == "MyPackage.docc")
        #expect(result.outputPath == outputDir.path)
    }

    @Test("generate returns failure when no catalog found")
    func generateReturnsFailureWithoutCatalog() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        let packageDir = tempDir.appendingPathComponent("NoDocsPackage", isDirectory: true)
        try fm.createDirectory(at: packageDir, withIntermediateDirectories: true)
        try "// no docs".write(to: packageDir.appendingPathComponent("Package.swift"), atomically: true, encoding: .utf8)

        let outputDir = tempDir.appendingPathComponent("docs", isDirectory: true)
        try fm.createDirectory(at: outputDir, withIntermediateDirectories: true)

        let generator = DocCGenerator()
        let result = try await generator.generate(
            path: packageDir.path,
            output: outputDir.path,
            hostingBasePath: nil,
            target: nil
        )

        #expect(result.success == false)
        #expect(result.catalogName == nil)
        #expect(result.errorMessage != nil)
    }

    @Test("generate respects hosting base path option")
    func generateRespectsHostingBasePath() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        let packageDir = tempDir.appendingPathComponent("Pkg", isDirectory: true)
        let doccDir = packageDir.appendingPathComponent("Sources/Pkg.docc", isDirectory: true)
        try fm.createDirectory(at: doccDir, withIntermediateDirectories: true)
        try "# Doc".write(to: doccDir.appendingPathComponent("Doc.md"), atomically: true, encoding: .utf8)

        let outputDir = tempDir.appendingPathComponent("docs", isDirectory: true)
        try fm.createDirectory(at: outputDir, withIntermediateDirectories: true)
        try "<html></html>".write(to: outputDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)

        let generator = DocCGenerator()
        let result = try await generator.generate(
            path: packageDir.path,
            output: outputDir.path,
            hostingBasePath: "my-package",
            target: nil
        )

        #expect(result.catalogName == "Pkg.docc")
    }

    @Test("generate respects target option")
    func generateRespectsTargetOption() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        let packageDir = tempDir.appendingPathComponent("MultiTarget", isDirectory: true)
        let doccDir = packageDir.appendingPathComponent("Sources/Core.docc", isDirectory: true)
        try fm.createDirectory(at: doccDir, withIntermediateDirectories: true)
        try "# Core".write(to: doccDir.appendingPathComponent("Core.md"), atomically: true, encoding: .utf8)

        let outputDir = tempDir.appendingPathComponent("docs", isDirectory: true)
        try fm.createDirectory(at: outputDir, withIntermediateDirectories: true)
        try "<html></html>".write(to: outputDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)

        let generator = DocCGenerator()
        let result = try await generator.generate(
            path: packageDir.path,
            output: outputDir.path,
            hostingBasePath: nil,
            target: "Core"
        )

        #expect(result.catalogName == "Core.docc")
    }
}

// MARK: - DocC Previewer Tests

@Suite("DocCPreviewer")
struct DocCPreviewerTests {

    @Test("serve fails when docs directory does not exist")
    func serveFailsWhenDocsMissing() async throws {
        let previewer = DocCPreviewer()

        await #expect(throws: ExitCode.failure) {
            try await previewer.serve(
                docsPath: "/nonexistent/path/to/docs",
                port: 9999,
                sourcePath: "."
            )
        }
    }

    @Test("serve fails when no index.html found")
    func serveFailsWhenNoIndex() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        let docsDir = tempDir.appendingPathComponent("no-index", isDirectory: true)
        try fm.createDirectory(at: docsDir, withIntermediateDirectories: true)
        try "other".write(to: docsDir.appendingPathComponent("other.html"), atomically: true, encoding: .utf8)

        let previewer = DocCPreviewer()

        await #expect(throws: ExitCode.failure) {
            try await previewer.serve(
                docsPath: docsDir.path,
                port: 9998,
                sourcePath: "."
            )
        }
    }
}

// MARK: - DocsCommand Integration Tests

@Suite("DocsCommand.Generate")
struct DocsGenerateCommandTests {

    @Test("generate command produces result with correct defaults")
    func generateCommandDefaults() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        let packageDir = tempDir.appendingPathComponent("TestPkg", isDirectory: true)
        let doccDir = packageDir.appendingPathComponent("Sources/TestPkg.docc", isDirectory: true)
        try fm.createDirectory(at: doccDir, withIntermediateDirectories: true)
        try "# Doc".write(to: doccDir.appendingPathComponent("Doc.md"), atomically: true, encoding: .utf8)

        let outputDir = tempDir.appendingPathComponent("output", isDirectory: true)
        try fm.createDirectory(at: outputDir, withIntermediateDirectories: true)
        try "<html></html>".write(to: outputDir.appendingPathComponent("index.html"), atomically: true, encoding: .utf8)

        let generator = DocCGenerator()
        let result = try await generator.generate(
            path: packageDir.path,
            output: outputDir.path,
            hostingBasePath: nil,
            target: nil
        )

        #expect(result.catalogName == "TestPkg.docc")
        #expect(result.outputPath == outputDir.path)
    }
}
