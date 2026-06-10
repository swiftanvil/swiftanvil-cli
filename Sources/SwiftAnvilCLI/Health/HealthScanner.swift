import Foundation

struct RepoHealthReport: Codable {
    let repoName: String
    let timestamp: String
    let overall: HealthStatus
    let dimensions: [HealthDimension]

    enum HealthStatus: String, Codable {
        case pass
        case warn
        case fail
    }

    struct HealthDimension: Codable {
        let name: String
        let status: HealthStatus
        let score: Int // 0-100
        let message: String
        let details: [String]
    }
}

struct HealthScanner {
    let path: String
    let quick: Bool // only staged files / fast checks

    func scan() async throws -> RepoHealthReport {
        let repoName = (path as NSString).lastPathComponent
        var dimensions: [RepoHealthReport.HealthDimension] = []
        var worstStatus = RepoHealthReport.HealthStatus.pass

        func add(_ dim: RepoHealthReport.HealthDimension) {
            dimensions.append(dim)
            if dim.status == .fail || (dim.status == .warn && worstStatus == .pass) {
                worstStatus = dim.status
            }
        }

        if !quick { add(try await scanTests()) }
        add(await scanFormat())
        add(await scanLint())
        add(try await scanBuildAudit())
        add(await scanStructure())
        add(try await scanLogging())
        add(try await scanNetwork())

        let formatter = ISO8601DateFormatter()
        formatter.timeZone = TimeZone(identifier: "UTC")
        return RepoHealthReport(
            repoName: repoName,
            timestamp: formatter.string(from: Date()),
            overall: worstStatus,
            dimensions: dimensions
        )
    }

    // MARK: - Dimension Scans

    private func scanTests() async throws -> RepoHealthReport.HealthDimension {
        let result = try? await ShellRunner().run("cd '\(path)' && swift test 2>&1 | tail -5")
        let output = result?.stdout ?? ""
        let passed = output.contains("passed") && !output.contains("failed")
        let count = parseTestCount(output)
        return RepoHealthReport.HealthDimension(
            name: "tests",
            status: passed ? .pass : .fail,
            score: passed ? 100 : 0,
            message: passed ? "\(count) tests passed" : "Test failures detected",
            details: output.split(separator: "\n").map(String.init)
        )
    }

    private func scanFormat() async -> RepoHealthReport.HealthDimension {
        let result = try? await ShellRunner().run(
            "cd '\(path)' && swiftformat --lint . 2>&1 | grep -c 'require formatting' || true"
        )
        let issues = Int(result?.stdout.trimmingCharacters(in: .whitespacesAndNewlines) ?? "0") ?? 0
        return RepoHealthReport.HealthDimension(
            name: "format",
            status: issues == 0 ? .pass : .fail,
            score: max(0, 100 - issues * 5),
            message: issues == 0 ? "Format clean" : "\(issues) file(s) require formatting",
            details: issues == 0 ? [] : ["Run `swiftformat .` to fix"]
        )
    }

    private func scanLint() async -> RepoHealthReport.HealthDimension {
        let result = try? await ShellRunner().run("cd '\(path)' && swiftlint lint --quiet 2>&1")
        let output = result?.stdout ?? ""
        let errors = output.components(separatedBy: ": error:").count - 1
        let warnings = output.components(separatedBy: ": warning:").count - 1
        let status: RepoHealthReport.HealthStatus = errors > 0 ? .fail : warnings > 0 ? .warn : .pass
        let score = max(0, 100 - errors * 10 - warnings * 2)
        let message = errors == 0 && warnings == 0 ? "Lint clean"
            : errors == 0 ? "\(warnings) warning(s)"
            : "\(errors) error(s), \(warnings) warning(s)"
        return RepoHealthReport.HealthDimension(
            name: "lint",
            status: status,
            score: score,
            message: message,
            details: output.split(separator: "\n").map(String.init).filter { $0.contains(":") }
        )
    }

    private func scanBuildAudit() async throws -> RepoHealthReport.HealthDimension {
        let findings = try await BuildSettingsAuditor(path: path).audit()
        let errors = findings.count(where: { $0.severity == .error })
        let warnings = findings.count(where: { $0.severity == .warning })
        let status: RepoHealthReport.HealthStatus = errors > 0 ? .fail : warnings > 0 ? .warn : .pass
        return RepoHealthReport.HealthDimension(
            name: "build-audit",
            status: status,
            score: max(0, 100 - errors * 15 - warnings * 5),
            message: errors == 0 && warnings == 0 ? "Build settings clean"
                : "\(errors) error(s), \(warnings) warning(s)",
            details: findings.prefix(5).map { "\($0.severity.rawValue) \($0.message)" }
        )
    }

    private func scanStructure() async -> RepoHealthReport.HealthDimension {
        let configPath = (path as NSString).appendingPathComponent(".swiftanvil.yml")
        guard FileManager.default.fileExists(atPath: configPath) else {
            return RepoHealthReport.HealthDimension(
                name: "structure", status: .pass, score: 100,
                message: "No .swiftanvil.yml config", details: []
            )
        }
        let result = try? await ShellRunner().run(
            "cd '\(path)' && swift run SwiftAnvilCLI lint source 2>&1 | tail -20"
        )
        let output = result?.stdout ?? ""
        let hasErrors = output.contains("error") || output.contains("Error")
        return RepoHealthReport.HealthDimension(
            name: "structure",
            status: hasErrors ? .warn : .pass,
            score: hasErrors ? 70 : 100,
            message: hasErrors ? "Source structure issues detected" : "Source structure clean",
            details: output.split(separator: "\n").map(String.init)
        )
    }

    private func scanLogging() async throws -> RepoHealthReport.HealthDimension {
        let findings = try await LoggingAuditor(path: path).audit()
        let errors = findings.count(where: { $0.severity == .error })
        let status: RepoHealthReport.HealthStatus = errors > 0 ? .fail : findings.isEmpty ? .pass : .warn
        return RepoHealthReport.HealthDimension(
            name: "logging",
            status: status,
            score: max(0, 100 - findings.count * 5),
            message: findings.isEmpty ? "No logging issues" : "\(findings.count) logging issue(s)",
            details: findings.prefix(5).map { "\($0.file):\($0.line) \($0.message)" }
        )
    }

    private func scanNetwork() async throws -> RepoHealthReport.HealthDimension {
        let findings = try await NetworkTrafficInspector(path: path).inspect()
        let errors = findings.count(where: { $0.severity == .error })
        let status: RepoHealthReport.HealthStatus = errors > 0 ? .fail : findings.isEmpty ? .pass : .warn
        return RepoHealthReport.HealthDimension(
            name: "network",
            status: status,
            score: max(0, 100 - findings.count * 10),
            message: findings.isEmpty ? "No network issues" : "\(findings.count) network issue(s)",
            details: findings.prefix(5).map(\.message)
        )
    }

    func writeJSON(_ report: RepoHealthReport, to outputPath: String) throws {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        let data = try encoder.encode(report)
        try data.write(to: URL(fileURLWithPath: outputPath))
    }

    func formatMarkdown(_ report: RepoHealthReport) -> String {
        var lines: [String] = []
        let statusEmoji = report.overall == .pass ? "🟢" : report.overall == .warn ? "🟡" : "🔴"
        lines.append("# Health Report: \(report.repoName)")
        lines.append("")
        lines.append("**Overall:** \(statusEmoji) \(report.overall.rawValue.uppercased())")
        lines.append("**Timestamp:** \(report.timestamp)")
        lines.append("")
        lines.append("| Dimension | Status | Score | Message |")
        lines.append("|-----------|--------|-------|---------|")
        for dim in report.dimensions {
            let emoji = dim.status == .pass ? "🟢" : dim.status == .warn ? "🟡" : "🔴"
            lines.append("| \(dim.name) | \(emoji) \(dim.status.rawValue) | \(dim.score) | \(dim.message) |")
        }
        lines.append("")
        for dim in report.dimensions where !dim.details.isEmpty {
            lines.append("## \(dim.name)")
            for detail in dim.details.prefix(10) {
                lines.append("- \(detail)")
            }
            lines.append("")
        }
        return lines.joined(separator: "\n")
    }

    private func parseTestCount(_ output: String) -> Int {
        let regex = try? NSRegularExpression(pattern: "(\\d+) tests?")
        let range = NSRange(output.startIndex..., in: output)
        guard
            let match = regex?.firstMatch(in: output, options: [], range: range),
            let countRange = Range(match.range(at: 1), in: output),
            let count = Int(output[countRange])
        else {
            return 0
        }
        return count
    }
}
