import ArgumentParser
import Foundation

struct PerfCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "perf",
        subcommands: [Logs.self, Network.self]
    )

    struct Logs: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "logs",
            abstract: "Audit logging practices in source code"
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

            print("🔍 Auditing logging practices at \(resolvedPath)\n")

            let auditor = LoggingAuditor(path: resolvedPath)
            let findings = try await auditor.audit()

            if findings.isEmpty {
                print("✅ No logging issues found.")
                return
            }

            for finding in findings {
                print("\(finding.severity.rawValue) \(finding.file):\(finding.line)")
                print("   \(finding.message)")
                print("   → \(finding.recommendation)")
            }
            print("\nFound \(findings.count) finding\(findings.count == 1 ? "" : "s").")
        }
    }

    struct Network: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "network",
            abstract: "Inspect network traffic practices in source code"
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

            print("🔍 Inspecting network practices at \(resolvedPath)\n")

            let inspector = NetworkTrafficInspector(path: resolvedPath)
            let findings = try await inspector.inspect()

            if findings.isEmpty {
                print("✅ No network issues found.")
                return
            }

            for finding in findings {
                if finding.file != "N/A" {
                    print("\(finding.severity.rawValue) \(finding.file):\(finding.line)")
                } else {
                    print("\(finding.severity.rawValue) \(finding.message)")
                }
                if finding.file != "N/A" {
                    print("   \(finding.message)")
                }
                print("   → \(finding.recommendation)")
            }
            print("\nFound \(findings.count) finding\(findings.count == 1 ? "" : "s").")
        }
    }
}
