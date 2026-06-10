import ArgumentParser
import Foundation

struct DependenciesCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "deps",
        subcommands: [Graph.self]
    )

    struct Graph: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "graph",
            abstract: "Generate dependency graph visualization"
        )

        @Option(name: .shortAndLong, help: "Project directory")
        var path: String = FileManager.default.currentDirectoryPath

        @Option(name: .long, help: "Output format: mermaid (default) or dot")
        var format: GraphFormat = .mermaid

        enum GraphFormat: String, ExpressibleByArgument {
            case mermaid
            case dot
        }

        mutating func run() async throws {
            let resolvedPath = PathResolver.resolve(path)
            let packagePath = (resolvedPath as NSString).appendingPathComponent("Package.swift")

            guard FileManager.default.fileExists(atPath: packagePath) else {
                print("❌ No Package.swift found at \(resolvedPath)")
                throw ExitCode.failure
            }

            let visualizer = DependencyGraphVisualizer(path: resolvedPath)
            let nodes = try visualizer.parseGraph()

            if nodes.isEmpty {
                print("⚠️ No dependencies found.")
                return
            }

            let cycles = visualizer.detectCycles(nodes)
            if !cycles.isEmpty {
                print("🔴 Circular dependencies detected:")
                for cycle in cycles {
                    print("   \(cycle.joined(separator: " → "))")
                }
                print("")
            }

            let output: String = switch format {
            case .mermaid:
                visualizer.generateMermaid(nodes)
            case .dot:
                visualizer.generateDOT(nodes)
            }

            print(output)
        }
    }
}
