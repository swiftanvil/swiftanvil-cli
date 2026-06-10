import Foundation

struct AgentInstructionsGenerator {
    let path: String

    func generate() async throws -> String {
        let fm = FileManager.default
        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        let readmePath = (path as NSString).appendingPathComponent("README.md")

        guard fm.fileExists(atPath: packagePath) else {
            throw AgentError.noPackageSwift
        }

        enum AgentError: Error {
            case noPackageSwift
        }

        var sections: [String] = []

        // Header
        sections.append("# Agent Instructions")
        sections.append("")
        sections.append("> Auto-generated from codebase analysis. Update manually as needed.")
        sections.append("")

        // Build system
        sections.append("## Build System")
        sections.append("")
        sections.append("- Build: `swift build`")
        sections.append("- Test: `swift test`")
        if fm.fileExists(atPath: (path as NSString).appendingPathComponent(".swiftformat")) {
            sections.append("- Format: `swiftformat .`")
        }
        if fm.fileExists(atPath: (path as NSString).appendingPathComponent(".swiftlint.yml")) {
            sections.append("- Lint: `swiftlint lint`")
        }
        sections.append("")

        // Platforms
        if let content = try? String(contentsOfFile: packagePath, encoding: .utf8) {
            if content.contains("platforms:") {
                let platformRegex = try? NSRegularExpression(
                    pattern: "\\.(iOS|macOS|tvOS|watchOS|visionOS)\\(\\.v(\\d+)\\)"
                )
                let range = NSRange(content.startIndex..., in: content)
                let matches = platformRegex?.matches(in: content, options: [], range: range) ?? []
                if !matches.isEmpty {
                    sections.append("## Platforms")
                    sections.append("")
                    for match in matches {
                        if
                            let platformRange = Range(match.range(at: 1), in: content),
                            let versionRange = Range(match.range(at: 2), in: content)
                        {
                            let platform = String(content[platformRange])
                            let version = String(content[versionRange])
                            sections.append("- \(platform) \(version)+")
                        }
                    }
                    sections.append("")
                }
            }
        }

        // Source structure
        let sourcesPath = (path as NSString).appendingPathComponent("Sources")
        if let entries = try? fm.contentsOfDirectory(atPath: sourcesPath) {
            sections.append("## Source Structure")
            sections.append("")
            for entry in entries.sorted() where !entry.hasPrefix(".") {
                let modulePath = (sourcesPath as NSString).appendingPathComponent(entry)
                let fileCount = (try? fm.contentsOfDirectory(atPath: modulePath))?.count ?? 0
                sections.append("- `Sources/\(entry)/` — \(fileCount) file(s)")
            }
            sections.append("")
        }

        // Test structure
        let testsPath = (path as NSString).appendingPathComponent("Tests")
        if let entries = try? fm.contentsOfDirectory(atPath: testsPath) {
            sections.append("## Test Structure")
            sections.append("")
            for entry in entries.sorted() where !entry.hasPrefix(".") {
                sections.append("- `Tests/\(entry)/`")
            }
            sections.append("")
        }

        // Dependencies
        if let content = try? String(contentsOfFile: packagePath, encoding: .utf8) {
            let depRegex = try? NSRegularExpression(
                pattern: "\\.package\\s*\\(\\s*url:\\s*\\\"([^\"]+)\\\""
            )
            let range = NSRange(content.startIndex..., in: content)
            let matches = depRegex?.matches(in: content, options: [], range: range) ?? []
            if !matches.isEmpty {
                sections.append("## Dependencies")
                sections.append("")
                for match in matches {
                    if let urlRange = Range(match.range(at: 1), in: content) {
                        sections.append("- \(String(content[urlRange]))")
                    }
                }
                sections.append("")
            }
        }

        // README summary
        if
            fm.fileExists(atPath: readmePath),
            let readme = try? String(contentsOfFile: readmePath, encoding: .utf8)
        {
            let firstParagraph = readme
                .components(separatedBy: .newlines)
                .first { !$0.isEmpty && !$0.hasPrefix("#") }
            if let paragraph = firstParagraph {
                sections.append("## Project Description")
                sections.append("")
                sections.append(paragraph)
                sections.append("")
            }
        }

        // Editing rules
        sections.append("## Editing Rules")
        sections.append("")
        sections.append("- Keep memory files small and directly actionable.")
        sections.append("- Update `packages.registry` after package status changes.")
        sections.append("- Run `swift test` after code changes.")
        sections.append("- Follow existing naming conventions.")
        sections.append("")

        return sections.joined(separator: "\n")
    }
}
