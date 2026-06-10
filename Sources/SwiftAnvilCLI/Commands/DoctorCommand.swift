// DoctorCommand.swift
// Validates the environment and project health

import ArgumentParser
import Foundation

struct DoctorCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "doctor",
        abstract: "Check environment and project health"
    )

    @Flag(name: .shortAndLong, help: "Fix issues automatically")
    var fix: Bool = false

    mutating func run() async throws {
        print("Running health checks...")

        var issues: [HealthIssue] = []

        // Check Swift installation
        let runner = ShellRunner()
        let swiftResult = try await runner.run("swift --version")
        if swiftResult.exitCode != 0 {
            issues.append(HealthIssue(
                severity: .error,
                message: "Swift is not installed or not in PATH",
                fixable: false
            ))
        } else {
            issues.append(HealthIssue(
                severity: .info,
                message: "Swift: \(swiftResult.stdout.trimmingCharacters(in: .whitespacesAndNewlines))",
                fixable: false
            ))
        }

        // Check Git
        let gitResult = try await runner.run("git --version")
        if gitResult.exitCode != 0 {
            issues.append(HealthIssue(
                severity: .warning,
                message: "Git is not installed",
                fixable: false
            ))
        }

        // Check for project files
        let fm = FileManager.default
        let currentPath = fm.currentDirectoryPath
        let hasPackageSwift = fm.fileExists(atPath: "\(currentPath)/Package.swift")
        let hasXcodeProj =
            !((try? fm.contentsOfDirectory(atPath: currentPath).filter { $0.hasSuffix(".xcodeproj") }) ?? []).isEmpty

        if !hasPackageSwift, !hasXcodeProj {
            issues.append(HealthIssue(
                severity: .warning,
                message: "No Package.swift or .xcodeproj found in current directory",
                fixable: false
            ))
        }

        // Print report
        print("\nHealth Report:")
        print("──────────────")

        for issue in issues {
            print("  \(issue.severity.icon) \(issue.message)")
        }

        let errors = issues.filter { $0.severity == .error }
        let warnings = issues.filter { $0.severity == .warning }

        if errors.isEmpty, warnings.isEmpty {
            print("\n✓ All checks passed.")
        } else if !errors.isEmpty {
            print("\n✗ Found \(errors.count) error(s) and \(warnings.count) warning(s).")
            throw ExitCode.failure
        } else {
            print("\n⚠ Found \(warnings.count) warning(s).")
        }
    }
}

enum HealthSeverity: String {
    case error
    case warning
    case info

    var icon: String {
        switch self {
        case .error: "✗"
        case .warning: "⚠"
        case .info: "ℹ"
        }
    }
}

struct HealthIssue {
    let severity: HealthSeverity
    let message: String
    let fixable: Bool
}

struct HealthReport {
    let isHealthy: Bool
    let issues: [HealthIssue]
    let summary: String
}
