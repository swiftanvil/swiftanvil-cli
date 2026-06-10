// DocsCommand.swift
// Documentation commands: registry compose/validate + DocC generate/preview
// swiftlint:disable file_length

import ArgumentParser
import Foundation

// MARK: - Docs Command Group

struct DocsCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "docs",
        abstract: "Manage documentation — compose registry, generate DocC, preview locally",
        subcommands: [Compose.self, Validate.self, Generate.self, Preview.self]
    )
}

// MARK: - Registry Compose (existing)

extension DocsCommand {
    struct Compose: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "compose",
            abstract: "Compose documentation from registry"
        )

        @Option(help: "Specific document to compose")
        var document: String?

        mutating func run() async throws {
            let composer = RegistryComposer()
            try await composer.compose(document: document)
            print("✓ Documentation composed successfully.")
        }
    }
}

// MARK: - Registry Validate (existing)

extension DocsCommand {
    struct Validate: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "validate",
            abstract: "Validate documentation registry integrity"
        )

        mutating func run() async throws {
            let fm = FileManager.default
            let registryPath = "Documentation/Registry/index.yml"

            guard fm.fileExists(atPath: registryPath) else {
                print("✗ Registry not found at \(registryPath)")
                throw ExitCode.failure
            }

            print("✓ Registry file exists.")
            print("✓ Registry validation passed (basic check).")
        }
    }
}

// MARK: - DocC Generate

extension DocsCommand {
    struct Generate: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "generate",
            abstract: "Generate static HTML documentation from DocC catalogs"
        )

        @Option(name: .shortAndLong, help: "Path to package or workspace directory")
        var path: String = "."

        @Option(name: .shortAndLong, help: "Output directory for generated HTML")
        var output: String = "./docs"

        @Option(help: "Hosting base path for GitHub Pages")
        var hostingBasePath: String?

        @Option(help: "Specific target to generate docs for")
        var target: String?

        @Flag(name: .long, help: "Output as JSON")
        var json: Bool = false

        mutating func run() async throws {
            let generator = DocCGenerator()
            let result = try await generator.generate(
                path: path,
                output: output,
                hostingBasePath: hostingBasePath,
                target: target
            )

            if json {
                let encoder = JSONEncoder()
                encoder.outputFormatting = .prettyPrinted
                let data = try encoder.encode(result)
                if let string = String(data: data, encoding: .utf8) {
                    print(string)
                }
            } else {
                print("Discovering DocC catalogs...")
                if let catalog = result.catalogName {
                    print("Found: \(catalog)")
                }
                print("Building documentation...")
                if result.success {
                    print("✓ Generated \(result.pageCount) page(s)")
                    print("Output: \(result.outputPath)")
                } else {
                    print("✗ Documentation generation failed")
                    if let error = result.errorMessage {
                        print("  \(error)")
                    }
                    throw ExitCode.failure
                }
            }
        }
    }
}

// MARK: - DocC Preview

extension DocsCommand {
    struct Preview: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "preview",
            abstract: "Start a local HTTP server to preview generated documentation"
        )

        @Option(name: .shortAndLong, help: "Path to package or workspace directory")
        var path: String = "."

        @Option(name: .shortAndLong, help: "Server port")
        var port: Int = 8080

        @Option(help: "Specific target to generate docs for")
        var target: String?

        mutating func run() async throws {
            let generator = DocCGenerator()
            let previewer = DocCPreviewer()

            // Generate docs first
            let result = try await generator.generate(
                path: path,
                output: "./.swiftanvil/docs-preview",
                hostingBasePath: nil,
                target: target
            )

            guard result.success else {
                print("✗ Documentation generation failed")
                if let error = result.errorMessage {
                    print("  \(error)")
                }
                throw ExitCode.failure
            }

            // Start preview server
            try await previewer.serve(
                docsPath: result.outputPath,
                port: port,
                sourcePath: path
            )
        }
    }
}

// MARK: - DocC Generator

/// Generates static HTML documentation using DocC.
actor DocCGenerator {
    struct Result: Codable, Equatable {
        var success: Bool
        var catalogName: String?
        var pageCount: Int
        var outputPath: String
        var errorMessage: String?
    }

    func generate(
        path: String,
        output: String,
        hostingBasePath: String?,
        target: String?
    ) async throws -> Result {
        let fm = FileManager.default
        let packageURL = URL(fileURLWithPath: path).resolvingSymlinksInPath()
        let outputURL = URL(fileURLWithPath: output).resolvingSymlinksInPath()

        // Discover DocC catalogs
        let catalog = discoverDocCCatalog(in: packageURL)

        // Ensure output directory exists
        try fm.createDirectory(at: outputURL, withIntermediateDirectories: true)

        // Build docs using swift-docc-plugin or fallback to docc
        let buildResult = try await buildDocumentation(
            packagePath: packageURL,
            outputPath: outputURL,
            hostingBasePath: hostingBasePath,
            target: target,
            catalog: catalog
        )

        return Result(
            success: buildResult.success,
            catalogName: catalog?.lastPathComponent,
            pageCount: buildResult.pageCount,
            outputPath: outputURL.path,
            errorMessage: buildResult.errorMessage
        )
    }

    // MARK: - Private

    private func discoverDocCCatalog(in packageURL: URL) -> URL? {
        let fm = FileManager.default

        // Check Sources for .docc catalogs
        let sourcesURL = packageURL.appendingPathComponent("Sources", isDirectory: true)
        if fm.fileExists(atPath: sourcesURL.path) {
            if let enumerator = fm.enumerator(at: sourcesURL, includingPropertiesForKeys: [.isDirectoryKey]) {
                for case let itemURL as URL in enumerator {
                    if itemURL.pathExtension == "docc" {
                        return itemURL
                    }
                }
            }
        }

        // Check root for .docc catalogs
        if let contents = try? fm.contentsOfDirectory(at: packageURL, includingPropertiesForKeys: nil) {
            for item in contents where item.pathExtension == "docc" {
                return item
            }
        }

        return nil
    }

    private struct BuildResult {
        let success: Bool
        let pageCount: Int
        let errorMessage: String?
    }

    private func buildDocumentation(
        packagePath: URL,
        outputPath: URL,
        hostingBasePath: String?,
        target: String?,
        catalog: URL?
    ) async throws -> BuildResult {
        let runner = ShellRunner()

        // Try swift-docc-plugin first
        let targetFlag = target.map { " --target \($0)" } ?? ""
        let basePathFlag = hostingBasePath.map { " --hosting-base-path \($0)" } ?? ""

        let pluginCommand = "cd \(packagePath.path) && swift package --allow-writing-to-directory \(outputPath.path) generate-documentation\(targetFlag)\(basePathFlag) --output-path \(outputPath.path)"

        let pluginResult = try await runner.run(pluginCommand)

        if pluginResult.exitCode == 0 {
            let pageCount = try countGeneratedPages(in: outputPath)
            return BuildResult(success: true, pageCount: pageCount, errorMessage: nil)
        }

        // Fallback: try docc convert directly if catalog exists
        if let catalog {
            let doccPath = try await findDocCExecutable()
            let doccBasePathFlag = hostingBasePath.map { " --hosting-base-path \($0)" } ?? ""
            let doccCommand = "\(doccPath) convert \(catalog.path) --output-path \(outputPath.path)\(doccBasePathFlag)"

            let doccResult = try await runner.run(doccCommand)

            if doccResult.exitCode == 0 {
                let pageCount = try countGeneratedPages(in: outputPath)
                return BuildResult(success: true, pageCount: pageCount, errorMessage: nil)
            } else {
                return BuildResult(
                    success: false,
                    pageCount: 0,
                    errorMessage: "docc convert failed: \(doccResult.stderr)"
                )
            }
        }

        // No catalog and plugin failed — report error
        return BuildResult(
            success: false,
            pageCount: 0,
            errorMessage: "No DocC catalog found and swift-docc-plugin failed: \(pluginResult.stderr)"
        )
    }

    private func countGeneratedPages(in outputPath: URL) throws -> Int {
        let fm = FileManager.default
        guard let enumerator = fm.enumerator(at: outputPath, includingPropertiesForKeys: nil) else {
            return 0
        }
        var count = 0
        for case let url as URL in enumerator {
            if url.pathExtension == "html" {
                count += 1
            }
        }
        return count
    }

    private func findDocCExecutable() async throws -> String {
        let runner = ShellRunner()
        let result = try await runner.run("xcrun --find docc")
        if result.exitCode == 0 {
            return result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        // Fallback to PATH
        let whichResult = try await runner.run("which docc")
        if whichResult.exitCode == 0 {
            return whichResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
        }
        return "docc"
    }
}

// MARK: - DocC Previewer

/// Serves generated documentation via a local HTTP server.
actor DocCPreviewer {
    func serve(docsPath: String, port: Int, sourcePath: String) async throws {
        let fm = FileManager.default
        let docsURL = URL(fileURLWithPath: docsPath).resolvingSymlinksInPath()

        guard fm.fileExists(atPath: docsURL.path) else {
            print("✗ Documentation not found at \(docsPath)")
            throw ExitCode.failure
        }

        // Find the index.html within the docs output
        let indexURL = findIndexHTML(in: docsURL)
        guard indexURL != nil else {
            print("✗ No index.html found in generated documentation")
            throw ExitCode.failure
        }

        print("Preview: http://localhost:\(port)")
        print("Watching for changes... (Ctrl-C to stop)")

        // Use Python's http.server for a simple, cross-platform file server
        let runner = ShellRunner()
        let serveDir = indexURL!.deletingLastPathComponent().path
        let command = "cd \(serveDir) && python3 -m http.server \(port)"

        // Run in background and watch for source changes
        let task = Task {
            _ = try? await runner.run(command)
        }

        // Simple file watcher: poll for changes every 2 seconds
        var lastMod = lastModificationTime(in: sourcePath)
        while !task.isCancelled {
            try await Task.sleep(nanoseconds: 2_000_000_000)
            let currentMod = lastModificationTime(in: sourcePath)
            if currentMod > lastMod {
                print("\nChange detected, rebuilding...")
                lastMod = currentMod
                // Regenerate docs
                let generator = DocCGenerator()
                _ = try? await generator.generate(
                    path: sourcePath,
                    output: docsPath,
                    hostingBasePath: nil,
                    target: nil
                )
                print("✓ Rebuilt. Refresh your browser.")
            }
        }
    }

    private func findIndexHTML(in docsURL: URL) -> URL? {
        let fm = FileManager.default
        let possiblePaths = [
            docsURL.appendingPathComponent("index.html"),
            docsURL.appendingPathComponent("documentation/index.html")
        ]
        for path in possiblePaths {
            if fm.fileExists(atPath: path.path) {
                return path
            }
        }
        // Deep search
        if let enumerator = fm.enumerator(at: docsURL, includingPropertiesForKeys: nil) {
            for case let url as URL in enumerator {
                if url.lastPathComponent == "index.html" {
                    return url
                }
            }
        }
        return nil
    }

    private func lastModificationTime(in path: String) -> Date {
        let fm = FileManager.default
        let url = URL(fileURLWithPath: path)
        var latest = Date.distantPast

        guard let enumerator = fm.enumerator(at: url, includingPropertiesForKeys: [.contentModificationDateKey]) else {
            return latest
        }

        for case let itemURL as URL in enumerator {
            guard
                let values = try? itemURL.resourceValues(forKeys: [.contentModificationDateKey]),
                let modDate = values.contentModificationDate
            else {
                continue
            }
            if modDate > latest {
                latest = modDate
            }
        }

        return latest
    }
}
