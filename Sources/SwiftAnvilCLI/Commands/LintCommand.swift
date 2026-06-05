// LintCommand.swift
// Progressive project linting for SwiftAnvil conventions

import ArgumentParser
import Foundation

struct LintCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "lint",
        abstract: "Lint project against SwiftAnvil conventions",
        subcommands: [
            PackageLint.self,
            SourceLint.self,
            TestLint.self,
            DependencyLint.self,
        ]
    )

    // MARK: - Package Lint

    struct PackageLint: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "package",
            abstract: "Lint Package.swift for SwiftAnvil conventions"
        )

        @Option(name: .shortAndLong, help: "Project directory")
        var path: String = FileManager.default.currentDirectoryPath

        mutating func run() async throws {
            let resolved = PathResolver.resolve(path)
            let packagePath = (resolved as NSString).appendingPathComponent("Package.swift")
            let fm = FileManager.default

            guard fm.fileExists(atPath: packagePath) else {
                print("❌ No Package.swift found at \(resolved)")
                throw ExitCode.failure
            }

            guard let content = try? String(contentsOfFile: packagePath, encoding: .utf8) else {
                print("❌ Could not read Package.swift")
                throw ExitCode.failure
            }

            var issues: [LintIssue] = []

            // Check Swift tools version
            if let match = content.range(of: #"swift-tools-version:\s*(\d+\.\d+)"#, options: .regularExpression) {
                let versionStr = String(content[match])
                if !versionStr.contains("6.") {
                    issues.append(LintIssue(
                        severity: .error,
                        message: "Swift tools version should be 6.0+ (found: \(versionStr))",
                        fix: "Update // swift-tools-version to 6.0 or later"
                    ))
                }
            } else {
                issues.append(LintIssue(
                    severity: .error,
                    message: "Missing swift-tools-version declaration",
                    fix: "Add '// swift-tools-version:6.0' as first line"
                ))
            }

            // Check Swift 6 language mode
            if !content.contains("swiftLanguageModes") && !content.contains("swiftLanguageMode") {
                issues.append(LintIssue(
                    severity: .error,
                    message: "Missing Swift 6 language mode",
                    fix: "Add 'swiftLanguageModes: [.v6]' to Package()"
                ))
            }

            // Check test target
            if !content.contains(".testTarget(") {
                issues.append(LintIssue(
                    severity: .warning,
                    message: "No test target declared",
                    fix: "Add a .testTarget to targets array"
                ))
            }

            // Check platform declarations
            let requiredPlatforms = ["iOS", "macOS", "tvOS", "watchOS", "visionOS"]
            let foundPlatforms = requiredPlatforms.filter { content.contains(".\($0)(") }
            if foundPlatforms.isEmpty {
                issues.append(LintIssue(
                    severity: .warning,
                    message: "No platform declarations found",
                    fix: "Add platforms: [.iOS(.v18), .macOS(.v15), ...]"
                ))
            }

            // Check for old platform versions
            let oldVersions = [".v13", ".v14", ".v16", ".v17"]
            for old in oldVersions {
                if content.contains(old) {
                    issues.append(LintIssue(
                        severity: .error,
                        message: "Old platform version found: \(old)",
                        fix: "Update to minimum: iOS 18, macOS 15, tvOS 18, watchOS 11, visionOS 2"
                    ))
                }
            }

            let passed = LintCommand.printLintReport(title: "Package.swift Lint", issues: issues, path: packagePath)
            if !passed { throw ExitCode.failure }
        }
    }

    // MARK: - Source Lint

    struct SourceLint: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "source",
            abstract: "Lint source files for SwiftAnvil conventions"
        )

        @Option(name: .shortAndLong, help: "Project directory")
        var path: String = FileManager.default.currentDirectoryPath

        mutating func run() async throws {
            let resolved = PathResolver.resolve(path)
            let sourcesPath = (resolved as NSString).appendingPathComponent("Sources")
            let fm = FileManager.default

            guard fm.fileExists(atPath: sourcesPath) else {
                print("❌ No Sources/ directory found")
                throw ExitCode.failure
            }

            var issues: [LintIssue] = []
            var fileCount = 0
            var doccCount = 0

            func scanDirectory(_ dir: String) {
                guard let entries = try? fm.contentsOfDirectory(atPath: dir) else { return }
                for entry in entries {
                    let fullPath = (dir as NSString).appendingPathComponent(entry)
                    var isDir: ObjCBool = false
                    let exists = fm.fileExists(atPath: fullPath, isDirectory: &isDir)

                    if exists && isDir.boolValue {
                        if entry.hasSuffix(".docc") {
                            doccCount += 1
                        } else {
                            scanDirectory(fullPath)
                        }
                    } else if entry.hasSuffix(".swift") && !entry.contains("LintCommand") {
                        fileCount += 1
                        if let content = try? String(contentsOfFile: fullPath, encoding: .utf8) {
                            lintSourceFile(content, path: fullPath, issues: &issues)
                        }
                    }
                }
            }

            scanDirectory(sourcesPath)

            if doccCount == 0 {
                issues.append(LintIssue(
                    severity: .warning,
                    message: "No DocC catalog found in Sources/",
                    fix: "Create Sources/<Target>/<Target>.docc and add documentation"
                ))
            }

            let passed = LintCommand.printLintReport(title: "Source Lint (\(fileCount) files, \(doccCount) DocC catalogs)", issues: issues, path: sourcesPath)
            if !passed { throw ExitCode.failure }
        }

        private func lintSourceFile(_ content: String, path: String, issues: inout [LintIssue]) {
            let filename = (path as NSString).lastPathComponent

            // Check for #available / @available
            if content.contains("#available") || content.contains("@available") {
                issues.append(LintIssue(
                    severity: .error,
                    message: "Found #available or @available in \(filename)",
                    fix: "Remove availability checks — all APIs must work on minimum platform"
                ))
            }

            // Check for deprecated API patterns
            let deprecatedPatterns = [
                ("NotificationCenter.default.addObserver", "Use async notifications sequence"),
                ("URLSession.shared.dataTask", "Use async URLSession methods"),
                ("DispatchQueue.main.async", "Use MainActor instead"),
                ("XCTAssert", "Use Swift Testing #expect"),
            ]
            for (pattern, suggestion) in deprecatedPatterns {
                if content.contains(pattern) {
                    issues.append(LintIssue(
                        severity: .warning,
                        message: "Found '\(pattern)' in \(filename)",
                        fix: suggestion
                    ))
                }
            }

            // Check for public API without DocC
            let publicDecls = content.components(separatedBy: .newlines).enumerated().filter { _, line in
                line.trimmingCharacters(in: .whitespaces).hasPrefix("public ") &&
                !line.contains("//") &&
                !line.contains("/*")
            }
            for (lineNum, line) in publicDecls {
                // Simple heuristic: check if previous non-empty line starts with ///
                let lines = content.components(separatedBy: .newlines)
                let prevIndex = max(0, lineNum - 1)
                let prevLine = lines[prevIndex].trimmingCharacters(in: .whitespaces)
                if !prevLine.hasPrefix("///") && !prevLine.hasPrefix("// MARK:") {
                    issues.append(LintIssue(
                        severity: .info,
                        message: "Public declaration without DocC comment in \(filename):\(lineNum + 1)",
                        fix: "Add '/// Description' before public declaration"
                    ))
                }
            }
        }
    }

    // MARK: - Test Lint

    struct TestLint: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "tests",
            abstract: "Lint test files for coverage and conventions"
        )

        @Option(name: .shortAndLong, help: "Project directory")
        var path: String = FileManager.default.currentDirectoryPath

        mutating func run() async throws {
            let resolved = PathResolver.resolve(path)
            let testsPath = (resolved as NSString).appendingPathComponent("Tests")
            let fm = FileManager.default

            guard fm.fileExists(atPath: testsPath) else {
                print("❌ No Tests/ directory found")
                throw ExitCode.failure
            }

            var issues: [LintIssue] = []
            var testFileCount = 0
            var testCount = 0

            func scanDirectory(_ dir: String) {
                guard let entries = try? fm.contentsOfDirectory(atPath: dir) else { return }
                for entry in entries {
                    let fullPath = (dir as NSString).appendingPathComponent(entry)
                    var isDir: ObjCBool = false
                    let exists = fm.fileExists(atPath: fullPath, isDirectory: &isDir)

                    if exists && isDir.boolValue {
                        scanDirectory(fullPath)
                    } else if entry.hasSuffix(".swift") {
                        testFileCount += 1
                        if let content = try? String(contentsOfFile: fullPath, encoding: .utf8) {
                            let atTests = content.components(separatedBy: "@Test").count - 1
                            let funcTests = content.components(separatedBy: "func test").count - 1
                            testCount += atTests + funcTests

                            // Check for edge case tests
                            if !content.lowercased().contains("error") &&
                               !content.lowercased().contains("invalid") &&
                               !content.lowercased().contains("empty") {
                                issues.append(LintIssue(
                                    severity: .info,
                                    message: "No obvious edge case tests in \(entry)",
                                    fix: "Add tests for error paths, invalid input, empty collections"
                                ))
                            }
                        }
                    }
                }
            }

            scanDirectory(testsPath)

            if testCount == 0 {
                issues.append(LintIssue(
                    severity: .error,
                    message: "No tests found in \(testFileCount) test files",
                    fix: "Add @Test or func test...() functions"
                ))
            } else if testCount < 3 {
                issues.append(LintIssue(
                    severity: .warning,
                    message: "Only \(testCount) test(s) found",
                    fix: "Add more tests for coverage"
                ))
            }

            let passed = LintCommand.printLintReport(title: "Test Lint (\(testFileCount) files, \(testCount) tests)", issues: issues, path: testsPath)
            if !passed { throw ExitCode.failure }
        }
    }

    // MARK: - Dependency Lint

    struct DependencyLint: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "dependencies",
            abstract: "Lint dependencies for outdated or vulnerable packages"
        )

        @Option(name: .shortAndLong, help: "Project directory")
        var path: String = FileManager.default.currentDirectoryPath

        mutating func run() async throws {
            let resolved = PathResolver.resolve(path)
            let resolvedPath = (resolved as NSString).appendingPathComponent("Package.resolved")
            let fm = FileManager.default

            guard fm.fileExists(atPath: resolvedPath) else {
                print("ℹ️  No Package.resolved found — dependencies not resolved yet")
                print("   Run 'swift package resolve' first")
                return
            }

            guard let content = try? String(contentsOfFile: resolvedPath, encoding: .utf8) else {
                print("❌ Could not read Package.resolved")
                throw ExitCode.failure
            }

            var issues: [LintIssue] = []

            // Check for branch-based dependencies (unstable)
            if content.contains("\"branch\"") || content.contains("branch\":") {
                issues.append(LintIssue(
                    severity: .warning,
                    message: "Branch-based dependencies found — not reproducible",
                    fix: "Pin to semantic version using 'from: \"x.y.z\"'"
                ))
            }

            // Check for revision-based without version
            if content.contains("\"revision\"") && !content.contains("\"version\"") {
                issues.append(LintIssue(
                    severity: .info,
                    message: "Revision-pinned dependencies without versions",
                    fix: "Prefer semantic version pinning for stability"
                ))
            }

            let passed = LintCommand.printLintReport(title: "Dependency Lint", issues: issues, path: resolvedPath)
            if !passed { throw ExitCode.failure }
        }
    }

    // MARK: - Shared Types

    struct LintIssue {
        enum Severity: String {
            case error = "error"
            case warning = "warning"
            case info = "info"

            var icon: String {
                switch self {
                case .error: return "❌"
                case .warning: return "⚠️"
                case .info: return "ℹ️"
                }
            }
        }

        let severity: Severity
        let message: String
        let fix: String
    }

    static func printLintReport(title: String, issues: [LintIssue], path: String) -> Bool {
        print("\n🔍 \(title)")
        print(String(repeating: "─", count: title.count + 2))
        print("Path: \(path)")

        let errors = issues.filter { $0.severity == .error }
        let warnings = issues.filter { $0.severity == .warning }
        let infos = issues.filter { $0.severity == .info }

        if issues.isEmpty {
            print("\n✅ All checks passed.")
            return true
        }

        for issue in errors + warnings + infos {
            print("\n  \(issue.severity.icon) [\(issue.severity.rawValue.uppercased())] \(issue.message)")
            print("     Fix: \(issue.fix)")
        }

        print("\nSummary: \(errors.count) error(s), \(warnings.count) warning(s), \(infos.count) info(s)")

        return errors.isEmpty
    }
}
