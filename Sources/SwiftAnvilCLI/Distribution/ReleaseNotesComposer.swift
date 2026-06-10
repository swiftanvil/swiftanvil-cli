import Foundation

struct ReleaseNotes {
    let version: String
    let sections: [Section]

    struct Section {
        let title: String
        let items: [String]
    }
}

struct ReleaseNotesComposer {
    let path: String

    func compose(since tag: String? = nil) async throws -> ReleaseNotes {
        let runner = ShellRunner()

        // Determine the version/tag range
        let rangeRef: String
        if let tag {
            rangeRef = tag
        } else {
            let latestTagResult = try? await runner.run(
                "git -C '\(path)' describe --tags --abbrev=0"
            )
            if
                let result = latestTagResult,
                result.exitCode == 0,
                let tagName = result.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
                    .split(separator: "\n").first
            {
                rangeRef = String(tagName)
            } else {
                rangeRef = "HEAD~20"
            }
        }

        let logResult = try await runner.run(
            "git -C '\(path)' log \(rangeRef)..HEAD --pretty=format:'%s' --no-merges"
        )

        let commits = logResult.stdout
            .split(separator: "\n")
            .map { String($0).trimmingCharacters(in: .whitespaces) }
            .filter { !$0.isEmpty }

        // Infer next version from commits
        let version = try await inferNextVersion(since: rangeRef, runner: runner)

        // Categorize commits
        var features: [String] = []
        var fixes: [String] = []
        var docs: [String] = []
        var chores: [String] = []
        var other: [String] = []

        for commit in commits {
            let lower = commit.lowercased()
            if lower.hasPrefix("feat") || lower.hasPrefix("add") || lower.hasPrefix("implement") {
                features.append(cleanCommitMessage(commit))
            } else if lower.hasPrefix("fix") || lower.hasPrefix("bugfix") || lower.hasPrefix("hotfix") {
                fixes.append(cleanCommitMessage(commit))
            } else if lower.hasPrefix("doc") || lower.hasPrefix("readme") {
                docs.append(cleanCommitMessage(commit))
            } else if lower.hasPrefix("chore") || lower.hasPrefix("refactor") || lower.hasPrefix("style") {
                chores.append(cleanCommitMessage(commit))
            } else {
                other.append(cleanCommitMessage(commit))
            }
        }

        var sections: [ReleaseNotes.Section] = []
        if !features.isEmpty {
            sections.append(ReleaseNotes.Section(title: "✨ Features", items: features))
        }
        if !fixes.isEmpty {
            sections.append(ReleaseNotes.Section(title: "🐛 Bug Fixes", items: fixes))
        }
        if !docs.isEmpty {
            sections.append(ReleaseNotes.Section(title: "📝 Documentation", items: docs))
        }
        if !chores.isEmpty {
            sections.append(ReleaseNotes.Section(title: "🔧 Chores", items: chores))
        }
        if !other.isEmpty {
            sections.append(ReleaseNotes.Section(title: "🔄 Other Changes", items: other))
        }

        return ReleaseNotes(version: version, sections: sections)
    }

    func formatMarkdown(_ notes: ReleaseNotes) -> String {
        var lines: [String] = []
        lines.append("## \(notes.version)")
        lines.append("")

        if notes.sections.isEmpty {
            lines.append("No changes since last release.")
            return lines.joined(separator: "\n")
        }

        for section in notes.sections {
            lines.append("### \(section.title)")
            lines.append("")
            for item in section.items {
                lines.append("- \(item)")
            }
            lines.append("")
        }

        return lines.joined(separator: "\n")
    }

    // MARK: - Private

    private func inferNextVersion(
        since rangeRef: String,
        runner: ShellRunner
    ) async throws -> String {
        let result = try await runner.run(
            "git -C '\(path)' describe --tags --abbrev=0"
        )
        guard result.exitCode == 0 else {
            return "0.1.0"
        }

        let latestTag = result.stdout
            .trimmingCharacters(in: .whitespacesAndNewlines)
            .split(separator: "\n")
            .first
            .map(String.init) ?? "0.0.0"

        // Check for breaking changes
        let breakingResult = try await runner.run(
            "git -C '\(path)' log \(rangeRef)..HEAD --pretty=format:'%s' --grep='BREAKING'"
        )
        let hasBreaking = !breakingResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        // Check for features
        let featureResult = try await runner.run(
            "git -C '\(path)' log \(rangeRef)..HEAD --pretty=format:'%s' --grep='^feat'"
        )
        let hasFeatures = !featureResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines)
            .isEmpty

        guard let version = SemVer(latestTag) else {
            return latestTag
        }

        if hasBreaking {
            return "\(version.major + 1).0.0"
        } else if hasFeatures {
            return "\(version.major).\(version.minor + 1).0"
        } else {
            return "\(version.major).\(version.minor).\(version.patch + 1)"
        }
    }

    private func cleanCommitMessage(_ message: String) -> String {
        let prefixes = [
            "feat:", "feat(", "fix:", "fix(", "docs:", "docs(",
            "chore:", "chore(", "refactor:", "refactor(", "style:", "style(",
            "test:", "test(", "perf:", "perf(", "ci:", "ci(",
            "build:", "build(", "revert:", "revert("
        ]
        var cleaned = message
        for prefix in prefixes {
            if cleaned.lowercased().hasPrefix(prefix) {
                if let range = cleaned.range(of: ")") {
                    cleaned = String(cleaned[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                } else if let range = cleaned.range(of: ":") {
                    cleaned = String(cleaned[range.upperBound...]).trimmingCharacters(in: .whitespaces)
                }
                break
            }
        }
        return cleaned
    }
}

private struct SemVer {
    let major: Int
    let minor: Int
    let patch: Int

    init?(_ string: String) {
        let clean = string.trimmingCharacters(in: CharacterSet(charactersIn: "vV"))
        let parts = clean.split(separator: ".")
        guard
            parts.count >= 3,
            let major = Int(parts[0]),
            let minor = Int(parts[1]),
            let patch = Int(parts[2])
        else {
            return nil
        }
        self.major = major
        self.minor = minor
        self.patch = patch
    }
}
