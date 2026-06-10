import ArgumentParser
import Foundation

struct BuildCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "build",
        subcommands: [Optimize.self]
    )

    struct Optimize: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "optimize",
            abstract: "Analyze build graph and suggest optimizations"
        )

        @Option(name: .shortAndLong, help: "Project directory to analyze")
        var path: String = FileManager.default.currentDirectoryPath

        @Option(name: .long, help: "Output format: table (default) or json")
        var format: OutputFormat = .table

        enum OutputFormat: String, ExpressibleByArgument {
            case table
            case json
        }

        mutating func run() async throws {
            let resolvedPath = PathResolver.resolve(path)
            let packagePath = (resolvedPath as NSString).appendingPathComponent("Package.swift")

            guard FileManager.default.fileExists(atPath: packagePath) else {
                print("❌ No Package.swift found at \(resolvedPath)")
                throw ExitCode.failure
            }

            print("🔍 Analyzing build graph at \(resolvedPath)\n")

            let optimizer = BuildOptimizer(path: resolvedPath)
            let optimizations = try await optimizer.analyze()

            if optimizations.isEmpty {
                print("✅ No optimization opportunities found. Your build graph looks healthy!")
                return
            }

            switch format {
            case .table:
                printTable(optimizations)
            case .json:
                printJSON(optimizations)
            }
        }

        private func printTable(_ optimizations: [BuildOptimization]) {
            let grouped = Dictionary(grouping: optimizations, by: \.category)
            for (category, items) in grouped.sorted(by: { $0.key < $1.key }) {
                print("\n【 \(category.uppercased()) 】")
                print(String(repeating: "─", count: 60))
                for opt in items {
                    print("\(opt.severity.rawValue) \(opt.message)")
                    print("   → \(opt.recommendation)")
                }
            }
            print("\n\nFound \(optimizations.count) optimization\(optimizations.count == 1 ? "" : "s").")
        }

        private func printJSON(_ optimizations: [BuildOptimization]) {
            let objects = optimizations.map { opt -> [String: String] in
                [
                    "category": opt.category,
                    "severity": opt.severity.rawValue,
                    "message": opt.message,
                    "recommendation": opt.recommendation
                ]
            }
            if
                let data = try? JSONSerialization.data(withJSONObject: objects, options: .prettyPrinted),
                let json = String(data: data, encoding: .utf8)
            {
                print(json)
            }
        }
    }
}
