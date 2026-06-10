import Foundation

struct AgentContextPack {
    let projectName: String
    let architecture: String
    let recentChanges: [String]
    let testPolicy: String
    let dependencies: [String]
    let conventions: [String]
}

struct AgentContextPackGenerator {
    let path: String

    func generate() async throws -> AgentContextPack {
        let fm = FileManager.default
        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        let readmePath = (path as NSString).appendingPathComponent("README.md")
        let agentsPath = (path as NSString).appendingPathComponent("AGENTS.md")

        // Parse Package.swift for name and deps
        var projectName = "Unknown"
        var dependencies: [String] = []
        if let content = try? String(contentsOfFile: packagePath, encoding: .utf8) {
            let nameRegex = try? NSRegularExpression(pattern: "name:\\s*\\\"([^\"]+)\\\"")
            let range = NSRange(content.startIndex..., in: content)
            if
                let match = nameRegex?.firstMatch(in: content, options: [], range: range),
                let nameRange = Range(match.range(at: 1), in: content)
            {
                projectName = String(content[nameRange])
            }

            let depRegex = try? NSRegularExpression(
                pattern: "\\.package\\s*\\(\\s*url:\\s*\\\"([^\"]+)\\\""
            )
            let depMatches = depRegex?.matches(in: content, options: [], range: range) ?? []
            for match in depMatches {
                if let urlRange = Range(match.range(at: 1), in: content) {
                    let url = String(content[urlRange])
                    let name = url.split(separator: "/").last?
                        .replacingOccurrences(of: ".git", with: "") ?? url
                    dependencies.append(name)
                }
            }
        }

        // Recent changes
        let runner = ShellRunner()
        let logResult = try? await runner.run(
            "git -C '\(path)' log -10 --oneline --no-merges"
        )
        let recentChanges = logResult?.stdout
            .split(separator: "\n")
            .map(String.init)
            .filter { !$0.isEmpty } ?? []

        // Test policy from AGENTS.md or README
        var testPolicy = "Run `swift test` before committing."
        var conventions: [String] = []
        for docsPath in [agentsPath, readmePath] where fm.fileExists(atPath: docsPath) {
            guard let content = try? String(contentsOfFile: docsPath, encoding: .utf8) else { continue }
            if content.contains("test") || content.contains("Test") {
                testPolicy = content
                    .components(separatedBy: .newlines)
                    .first { $0.lowercased().contains("test") } ?? testPolicy
            }
            if content.contains("convention") || content.contains("style") {
                let styleLines = content
                    .components(separatedBy: .newlines)
                    .filter { $0.lowercased().contains("convention") || $0.lowercased().contains("style") }
                conventions.append(contentsOf: styleLines.prefix(5))
            }
        }

        // Architecture summary
        var architecture = "Swift Package with SPM."
        let sourcesPath = (path as NSString).appendingPathComponent("Sources")
        if let entries = try? fm.contentsOfDirectory(atPath: sourcesPath) {
            let modules = entries.filter { !$0.hasPrefix(".") }
            architecture = "Swift Package with \(modules.count) source module(s): "
                + modules.joined(separator: ", ") + "."
        }

        return AgentContextPack(
            projectName: projectName,
            architecture: architecture,
            recentChanges: recentChanges,
            testPolicy: testPolicy,
            dependencies: dependencies,
            conventions: conventions.isEmpty ? ["Follow Swift style guide"] : conventions
        )
    }

    func format(_ pack: AgentContextPack) -> String {
        var lines: [String] = []
        lines.append("# Agent Context Pack: \(pack.projectName)")
        lines.append("")
        lines.append("## Architecture")
        lines.append(pack.architecture)
        lines.append("")
        lines.append("## Dependencies")
        if pack.dependencies.isEmpty {
            lines.append("No external dependencies.")
        } else {
            for dep in pack.dependencies {
                lines.append("- \(dep)")
            }
        }
        lines.append("")
        lines.append("## Recent Changes (last 10 commits)")
        if pack.recentChanges.isEmpty {
            lines.append("No recent changes found.")
        } else {
            for change in pack.recentChanges {
                lines.append("- \(change)")
            }
        }
        lines.append("")
        lines.append("## Test Policy")
        lines.append(pack.testPolicy)
        lines.append("")
        lines.append("## Conventions")
        for convention in pack.conventions {
            lines.append("- \(convention)")
        }
        return lines.joined(separator: "\n")
    }
}
