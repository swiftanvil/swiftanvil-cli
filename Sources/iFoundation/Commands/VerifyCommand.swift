// VerifyCommand.swift
// Verifies generated SwiftAnvil project output

import ArgumentParser
import Foundation

struct VerifyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "verify",
        abstract: "Verify generated project structure and CI contract"
    )

    @Option(name: .shortAndLong, help: "Generated project directory to verify")
    var path: String = FileManager.default.currentDirectoryPath

    mutating func run() async throws {
        let resolvedPath = PathResolver.resolve(path)
        let report = ProjectVerifier().verify(path: resolvedPath)

        print("Verification Report")
        print("===================")
        print("Project: \(report.rootPath)")

        if report.issues.isEmpty {
            print("\nPASS No verification issues found.")
            return
        }

        for issue in report.issues {
            let location = issue.path.map { " [\($0)]" } ?? ""
            print("\n\(issue.severity.rawValue.uppercased()) \(issue.check)\(location)")
            print("  \(issue.message)")
        }

        print("\nSummary: \(report.errors.count) error(s), \(report.warnings.count) warning(s).")

        if !report.passed {
            throw ExitCode.failure
        }
    }
}
