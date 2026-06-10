import ArgumentParser
import Foundation

struct HealthCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "health",
        abstract: "Repository health monitoring and reporting",
        subcommands: [Scan.self]
    )

    struct Scan: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "scan",
            abstract: "Run comprehensive health scan"
        )

        @Option(name: .shortAndLong, help: "Project directory")
        var path: String = FileManager.default.currentDirectoryPath

        @Flag(name: .long, help: "Quick scan: skip tests, only staged files")
        var quick: Bool = false

        @Option(name: .long, help: "Output format: markdown (default) or json")
        var format: OutputFormat = .markdown

        @Option(name: .long, help: "Write report to file path")
        var output: String?

        enum OutputFormat: String, ExpressibleByArgument {
            case markdown
            case json
        }

        mutating func run() async throws {
            let resolvedPath = PathResolver.resolve(path)
            let packagePath = (resolvedPath as NSString).appendingPathComponent("Package.swift")

            guard FileManager.default.fileExists(atPath: packagePath) else {
                print("❌ No Package.swift found at \(resolvedPath)")
                throw ExitCode.failure
            }

            print("🔍 Scanning health at \(resolvedPath)\n")

            let scanner = HealthScanner(path: resolvedPath, quick: quick)
            let report = try await scanner.scan()

            let outputContent: String
            switch format {
            case .markdown:
                outputContent = scanner.formatMarkdown(report)
            case .json:
                let encoder = JSONEncoder()
                encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
                let data = try encoder.encode(report)
                outputContent = String(data: data, encoding: .utf8) ?? "{}"
            }

            if let outputPath = output {
                try outputContent.write(toFile: outputPath, atomically: true, encoding: .utf8)
                print("✅ Report written to \(outputPath)")
            } else {
                print(outputContent)
            }

            // Exit with failure if health is bad
            if report.overall == .fail {
                throw ExitCode.failure
            }
        }
    }
}
