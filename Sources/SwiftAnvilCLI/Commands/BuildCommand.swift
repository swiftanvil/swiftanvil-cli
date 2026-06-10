import ArgumentParser
import Foundation

struct BuildCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "build",
        subcommands: [Optimize.self, Audit.self, Size.self, Cache.self]
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

    struct Audit: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "audit",
            abstract: "Audit build settings for suboptimal configurations"
        )

        @Option(name: .shortAndLong, help: "Project directory to audit")
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

            print("🔍 Auditing build settings at \(resolvedPath)\n")

            let auditor = BuildSettingsAuditor(path: resolvedPath)
            let findings = try await auditor.audit()

            if findings.isEmpty {
                print("✅ No build setting issues found.")
                return
            }

            switch format {
            case .table:
                printTable(findings)
            case .json:
                printJSON(findings)
            }
        }

        private func printTable(_ findings: [BuildSettingsFinding]) {
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

        private func printJSON(_ findings: [BuildSettingsFinding]) {
            let objects = findings.map { finding -> [String: String] in
                [
                    "category": finding.category,
                    "severity": finding.severity.rawValue,
                    "message": finding.message,
                    "recommendation": finding.recommendation
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

    struct Size: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "size",
            abstract: "Analyze binary size breakdown and suggest reductions"
        )

        @Option(name: .shortAndLong, help: "Project directory to analyze")
        var path: String = FileManager.default.currentDirectoryPath

        mutating func run() async throws {
            let resolvedPath = PathResolver.resolve(path)
            let packagePath = (resolvedPath as NSString).appendingPathComponent("Package.swift")

            guard FileManager.default.fileExists(atPath: packagePath) else {
                print("❌ No Package.swift found at \(resolvedPath)")
                throw ExitCode.failure
            }

            print("📦 Analyzing binary size at \(resolvedPath)\n")

            let analyzer = BinarySizeAnalyzer(path: resolvedPath)
            let breakdown = try await analyzer.analyze()

            print("Total: \(byteString(breakdown.totalBytes))\n")

            if breakdown.sections.isEmpty {
                print("⚠️ No binaries found. Build with `swift build -c release` first.")
                return
            }

            print(String(format: "%-40s %12s %8s", "Section", "Size", "%"))
            print(String(repeating: "─", count: 64))
            for section in breakdown.sections {
                print(String(
                    format: "%-40s %12s %7.1f%%",
                    section.name,
                    byteString(section.bytes),
                    section.percentage
                ))
            }

            if !breakdown.recommendations.isEmpty {
                print("\n💡 Recommendations:")
                for rec in breakdown.recommendations {
                    print("   • \(rec)")
                }
            }
        }

        private func byteString(_ bytes: Int) -> String {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter.string(fromByteCount: Int64(bytes))
        }
    }

    struct Cache: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "cache",
            abstract: "Analyze build cache efficiency and suggest cleanup"
        )

        @Option(name: .shortAndLong, help: "Project directory to analyze")
        var path: String = FileManager.default.currentDirectoryPath

        mutating func run() async throws {
            let resolvedPath = PathResolver.resolve(path)
            let packagePath = (resolvedPath as NSString).appendingPathComponent("Package.swift")

            guard FileManager.default.fileExists(atPath: packagePath) else {
                print("❌ No Package.swift found at \(resolvedPath)")
                throw ExitCode.failure
            }

            print("🗑️ Analyzing cache efficiency at \(resolvedPath)\n")

            let reporter = CacheEfficiencyReporter(path: resolvedPath)
            let report = try await reporter.analyze()

            print("Build directory: \(byteString(report.buildDirSize))")
            print("DerivedData (est.): \(byteString(report.derivedDataSize))")
            print("Swift modules: \(report.moduleCount)")
            print("Stale artifacts: \(report.staleArtifactCount)")

            print("\n💡 Recommendations:")
            for rec in report.recommendations {
                print("   • \(rec)")
            }
        }

        private func byteString(_ bytes: Int) -> String {
            let formatter = ByteCountFormatter()
            formatter.countStyle = .file
            return formatter.string(fromByteCount: Int64(bytes))
        }
    }
}
