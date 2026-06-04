// VerifyCommand.swift
// Verifies generated SwiftAnvil project output and example projects

import ArgumentParser
import Foundation

struct VerifyCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "verify",
        abstract: "Verify generated project structure, CI contract, or example project conventions"
    )

    @Option(name: .shortAndLong, help: "Project directory to verify")
    var path: String = FileManager.default.currentDirectoryPath

    @Flag(name: .long, help: "Verify as an example project (SwiftAnvil conventions)")
    var example: Bool = false

    mutating func run() async throws {
        let resolvedPath = PathResolver.resolve(path)

        if example {
            try await verifyExample(path: resolvedPath)
        } else {
            try await verifyProject(path: resolvedPath)
        }
    }

    private func verifyProject(path: String) async throws {
        let report = ProjectVerifier().verify(path: path)

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

    private func verifyExample(path: String) async throws {
        print("Example Project Verification")
        print("============================")
        print("Project: \(path)")

        let verifier = ExampleProjectVerifier()
        let report = verifier.verify(path: path)

        for issue in report.issues {
            let location = issue.path.map { " [\($0)]" } ?? ""
            print("\n\(issue.severity.rawValue.uppercased()) \(issue.check)\(location)")
            print("  \(issue.message)")
        }

        print("\nSummary: \(report.errors.count) error(s), \(report.warnings.count) warning(s).")

        if report.passed {
            print("\nPASS Example project meets SwiftAnvil conventions.")
        } else {
            print("\nFAIL Example project does not meet all conventions.")
            throw ExitCode.failure
        }
    }
}

// MARK: - Example Project Verifier

struct ExampleProjectVerifier: Sendable {
    func verify(path rootPath: String) -> ProjectVerificationReport {
        let fm = FileManager.default
        var issues: [ProjectVerificationIssue] = []

        // Required files for all examples
        let requiredFiles = [
            "Package.swift",
            "README.md",
            ".gitignore",
        ]

        for file in requiredFiles {
            let fullPath = (rootPath as NSString).appendingPathComponent(file)
            if !fm.fileExists(atPath: fullPath) {
                issues.append(ProjectVerificationIssue(
                    severity: .error,
                    check: "required-file",
                    message: "Missing required file \(file).",
                    path: file
                ))
            }
        }

        // Required directories
        let requiredDirs = ["Sources", "Tests"]
        for dir in requiredDirs {
            let fullPath = (rootPath as NSString).appendingPathComponent(dir)
            var isDir: ObjCBool = false
            let exists = fm.fileExists(atPath: fullPath, isDirectory: &isDir)
            if !exists || !isDir.boolValue {
                issues.append(ProjectVerificationIssue(
                    severity: .error,
                    check: "required-directory",
                    message: "Missing required directory \(dir).",
                    path: dir
                ))
            }
        }

        // Package.swift checks
        let packagePath = (rootPath as NSString).appendingPathComponent("Package.swift")
        if fm.fileExists(atPath: packagePath) {
            if let content = try? String(contentsOfFile: packagePath, encoding: .utf8) {
                if !content.contains("swift-tools-version:") {
                    issues.append(ProjectVerificationIssue(
                        severity: .error,
                        check: "package-tools-version",
                        message: "Package.swift must declare a Swift tools version.",
                        path: "Package.swift"
                    ))
                }
                if !content.contains("swiftLanguageModes") && !content.contains("swiftLanguageMode") {
                    issues.append(ProjectVerificationIssue(
                        severity: .warning,
                        check: "package-swift-6",
                        message: "Package.swift should opt into Swift 6 language mode.",
                        path: "Package.swift"
                    ))
                }
                if !content.contains(".testTarget(") {
                    issues.append(ProjectVerificationIssue(
                        severity: .warning,
                        check: "package-test-target",
                        message: "Package.swift should declare at least one test target.",
                        path: "Package.swift"
                    ))
                }
            }
        }

        // README checks
        let readmePath = (rootPath as NSString).appendingPathComponent("README.md")
        if fm.fileExists(atPath: readmePath) {
            if let content = try? String(contentsOfFile: readmePath, encoding: .utf8) {
                if !content.contains("Build") || !content.contains("Test") {
                    issues.append(ProjectVerificationIssue(
                        severity: .warning,
                        check: "readme-build-test",
                        message: "README should include build and test instructions.",
                        path: "README.md"
                    ))
                }
            }
        }

        return ProjectVerificationReport(rootPath: rootPath, issues: issues)
    }
}
