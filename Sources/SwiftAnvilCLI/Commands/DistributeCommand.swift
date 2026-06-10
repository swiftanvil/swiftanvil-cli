import ArgumentParser
import Foundation

struct DistributeCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "distribute",
        subcommands: [Validate.self, Notes.self]
    )

    struct Validate: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "validate",
            abstract: "Validate app metadata for distribution"
        )

        @Option(name: .shortAndLong, help: "Project directory")
        var path: String = FileManager.default.currentDirectoryPath

        mutating func run() async throws {
            let resolvedPath = PathResolver.resolve(path)
            let packagePath = (resolvedPath as NSString).appendingPathComponent("Package.swift")

            guard FileManager.default.fileExists(atPath: packagePath) else {
                print("❌ No Package.swift found at \(resolvedPath)")
                throw ExitCode.failure
            }

            print("🔍 Validating metadata at \(resolvedPath)\n")

            let validator = MetadataValidator(path: resolvedPath)
            let findings = try await validator.validate()

            if findings.isEmpty {
                print("✅ All metadata looks good.")
                return
            }

            let grouped = Dictionary(grouping: findings, by: \.category)
            for (category, items) in grouped.sorted(by: { $0.key < $1.key }) {
                print("\n【 \(category.uppercased()) 】")
                print(String(repeating: "─", count: 60))
                for finding in items {
                    print("\(finding.severity.rawValue) \(finding.message)")
                    print("   → \(finding.recommendation)")
                }
            }
            print("\n\nFound \(findings.count) finding\(findings.count == 1 ? "" : "s").")
        }
    }

    struct Notes: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "notes",
            abstract: "Compose release notes from git history"
        )

        @Option(name: .shortAndLong, help: "Project directory")
        var path: String = FileManager.default.currentDirectoryPath

        @Option(name: .long, help: "Tag to compare against (defaults to latest tag)")
        var since: String?

        mutating func run() async throws {
            let resolvedPath = PathResolver.resolve(path)

            guard FileManager.default.fileExists(atPath: resolvedPath) else {
                print("❌ Directory not found: \(resolvedPath)")
                throw ExitCode.failure
            }

            let composer = ReleaseNotesComposer(path: resolvedPath)
            let notes = try await composer.compose(since: since)

            print(composer.formatMarkdown(notes))
        }
    }
}
