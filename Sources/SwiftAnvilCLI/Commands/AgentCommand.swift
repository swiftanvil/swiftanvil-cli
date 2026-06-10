import ArgumentParser
import Foundation

struct AgentCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "agent",
        subcommands: [Context.self, Instructions.self, Review.self]
    )

    struct Context: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "context",
            abstract: "Generate bounded context packet for AI agents"
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

            let generator = AgentContextPackGenerator(path: resolvedPath)
            let pack = try await generator.generate()
            print(generator.format(pack))
        }
    }

    struct Instructions: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "instructions",
            abstract: "Auto-generate agent instructions from codebase analysis"
        )

        @Option(name: .shortAndLong, help: "Project directory")
        var path: String = FileManager.default.currentDirectoryPath

        @Option(name: .long, help: "Output file path (default: stdout)")
        var output: String?

        mutating func run() async throws {
            let resolvedPath = PathResolver.resolve(path)
            let generator = AgentInstructionsGenerator(path: resolvedPath)
            let instructions = try await generator.generate()

            if let outputPath = output {
                try instructions.write(toFile: outputPath, atomically: true, encoding: .utf8)
                print("✅ Instructions written to \(outputPath)")
            } else {
                print(instructions)
            }
        }
    }

    struct Review: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "review",
            abstract: "Generate review packet for cross-host review"
        )

        @Option(name: .shortAndLong, help: "Project directory")
        var path: String = FileManager.default.currentDirectoryPath

        @Option(name: .long, help: "Git ref to compare against (default: HEAD~1)")
        var since: String?

        mutating func run() async throws {
            let resolvedPath = PathResolver.resolve(path)
            let generator = ReviewPacketGenerator(path: resolvedPath)
            let packet = try await generator.generate(since: since)
            print(generator.formatMarkdown(packet))
        }
    }
}
