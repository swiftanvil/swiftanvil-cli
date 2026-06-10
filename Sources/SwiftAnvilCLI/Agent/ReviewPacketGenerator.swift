import Foundation

struct ReviewPacket {
    let diff: String
    let testSummary: String
    let architectureNotes: String
    let policyChecks: [PolicyCheck]

    struct PolicyCheck {
        let name: String
        let passed: Bool
        let details: String
    }
}

struct ReviewPacketGenerator {
    let path: String

    func generate(since ref: String? = nil) async throws -> ReviewPacket {
        let runner = ShellRunner()

        // Git diff
        let diffRef = ref ?? "HEAD~1"
        let diffResult = try? await runner.run("git -C '\(path)' diff \(diffRef)..HEAD")
        let diff = diffResult?.stdout ?? "No diff available."

        // Test summary
        let testResult = try? await runner.run("cd '\(path)' && swift test 2>&1 | tail -20")
        let testSummary = testResult?.stdout ?? "Tests not run."

        // Architecture notes
        var architectureNotes = ""
        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        if let content = try? String(contentsOfFile: packagePath, encoding: .utf8) {
            let moduleRegex = try? NSRegularExpression(
                pattern: "name:\\s*\\\"([^\"]+)\\\""
            )
            let range = NSRange(content.startIndex..., in: content)
            let matches = moduleRegex?.matches(in: content, options: [], range: range) ?? []
            let names = matches.compactMap { match -> String? in
                if let nameRange = Range(match.range(at: 1), in: content) {
                    return String(content[nameRange])
                }
                return nil
            }
            architectureNotes = "Modules: \(names.joined(separator: ", "))"
        }

        // Policy checks
        var policyChecks: [ReviewPacket.PolicyCheck] = []

        // Check tests pass
        let testsPassed = testSummary.contains("passed") && !testSummary.contains("failed")
        policyChecks.append(ReviewPacket.PolicyCheck(
            name: "Tests Pass",
            passed: testsPassed,
            details: testsPassed ? "All tests passed" : "Test failures detected"
        ))

        // Check lint
        let lintResult = try? await runner.run("cd '\(path)' && swiftlint lint --quiet 2>&1")
        let lintClean = lintResult?.stdout.isEmpty != false && lintResult?.stderr.isEmpty != false
        policyChecks.append(ReviewPacket.PolicyCheck(
            name: "Lint Clean",
            passed: lintClean,
            details: lintClean ? "No lint violations" : "Lint issues present"
        ))

        // Check formatting
        let formatResult = try? await runner.run(
            "cd '\(path)' && swiftformat --lint . 2>&1 | grep -c 'require formatting' || true"
        )
        let formatClean = formatResult?.stdout.trimmingCharacters(in: .whitespacesAndNewlines) == "0"
        policyChecks.append(ReviewPacket.PolicyCheck(
            name: "Format Clean",
            passed: formatClean,
            details: formatClean ? "No formatting issues" : "Formatting issues present"
        ))

        // Check documentation
        let readmeExists = FileManager.default.fileExists(
            atPath: (path as NSString).appendingPathComponent("README.md")
        )
        policyChecks.append(ReviewPacket.PolicyCheck(
            name: "README Present",
            passed: readmeExists,
            details: readmeExists ? "README.md found" : "README.md missing"
        ))

        return ReviewPacket(
            diff: diff,
            testSummary: testSummary,
            architectureNotes: architectureNotes,
            policyChecks: policyChecks
        )
    }

    func formatMarkdown(_ packet: ReviewPacket) -> String {
        var lines: [String] = []
        lines.append("# Review Packet")
        lines.append("")

        lines.append("## Policy Checks")
        lines.append("")
        for check in packet.policyChecks {
            let status = check.passed ? "✅" : "❌"
            lines.append("- \(status) **\(check.name)**: \(check.details)")
        }
        lines.append("")

        lines.append("## Architecture")
        lines.append(packet.architectureNotes)
        lines.append("")

        lines.append("## Test Summary")
        lines.append("```")
        lines.append(packet.testSummary)
        lines.append("```")
        lines.append("")

        lines.append("## Diff")
        lines.append("```diff")
        lines.append(packet.diff)
        lines.append("```")

        return lines.joined(separator: "\n")
    }
}
