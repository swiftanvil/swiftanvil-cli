// AdoptCommand.swift
// Retroactively applies SwiftAnvil enforcement to an existing project

import ArgumentParser
import Foundation

struct AdoptCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "adopt",
        abstract: "Apply SwiftAnvil enforcement to an existing project"
    )

    @Argument(help: "Project directory to adopt")
    var path: String = FileManager.default.currentDirectoryPath

    @Flag(name: .long, help: "Dry run — show what would change without writing")
    var dryRun: Bool = false

    @Flag(name: .long, help: "Skip confirmation prompts")
    var yes: Bool = false

    mutating func run() async throws {
        let resolvedPath = PathResolver.resolve(path)
        let fm = FileManager.default

        guard fm.fileExists(atPath: (resolvedPath as NSString).appendingPathComponent("Package.swift")) else {
            print("❌ No Package.swift found at \(resolvedPath)")
            print("   Run this command from a Swift package directory, or specify --path")
            throw ExitCode.failure
        }

        print("🔍 Scanning project at \(resolvedPath)")

        let scanner = ProjectScanner(path: resolvedPath)
        let findings = try await scanner.scan()

        print("\n📋 Findings:")
        print("─────────────")
        for finding in findings {
            print("  \(finding.icon) \(finding.message)")
        }

        let applicable = findings.filter { $0.isApplicable }
        if applicable.isEmpty {
            print("\n✅ Project already follows all SwiftAnvil conventions.")
            return
        }

        print("\n🛠️  Applicable adoptions:")
        for finding in applicable {
            print("  [\(finding.category)] \(finding.message)")
        }

        if !yes && !dryRun {
            print("\nApply these changes? [y/N]:", terminator: " ")
            guard let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased(),
                  input == "y" || input == "yes" else {
                print("Aborted.")
                return
            }
        }

        let adopter = ProjectAdopter(path: resolvedPath, dryRun: dryRun)
        try await adopter.apply(findings: applicable)

        if dryRun {
            print("\n🏁 Dry run complete. No files were modified.")
        } else {
            print("\n✅ SwiftAnvil adoption complete.")
            print("   Run `swiftanvil verify --path \(resolvedPath)` to validate.")
        }
    }
}

// MARK: - Project Scanner

struct ProjectScanner {
    let path: String

    func scan() async throws -> [AdoptionFinding] {
        var findings: [AdoptionFinding] = []
        let fm = FileManager.default

        // Check for AGENTS.md
        let agentsPath = (path as NSString).appendingPathComponent("AGENTS.md")
        if !fm.fileExists(atPath: agentsPath) {
            findings.append(AdoptionFinding(
                category: "documentation",
                message: "Missing AGENTS.md — agent guidelines for AI contributors",
                icon: "🤖",
                isApplicable: true
            ))
        }

        // Check for README.md
        let readmePath = (path as NSString).appendingPathComponent("README.md")
        if !fm.fileExists(atPath: readmePath) {
            findings.append(AdoptionFinding(
                category: "documentation",
                message: "Missing README.md — project description and build instructions",
                icon: "📖",
                isApplicable: true
            ))
        }

        // Check for .gitignore
        let gitignorePath = (path as NSString).appendingPathComponent(".gitignore")
        if !fm.fileExists(atPath: gitignorePath) {
            findings.append(AdoptionFinding(
                category: "git",
                message: "Missing .gitignore — build artifacts not excluded",
                icon: "🙈",
                isApplicable: true
            ))
        }

        // Check for CI workflow
        let ciPath = (path as NSString).appendingPathComponent(".github/workflows/ci.yml")
        if !fm.fileExists(atPath: ciPath) {
            findings.append(AdoptionFinding(
                category: "ci",
                message: "Missing CI workflow — no automated build/test on PR",
                icon: "🔄",
                isApplicable: true
            ))
        }

        // Check Package.swift for Swift 6
        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        if let content = try? String(contentsOfFile: packagePath, encoding: .utf8) {
            if !content.contains("swiftLanguageModes") && !content.contains("swiftLanguageMode") {
                findings.append(AdoptionFinding(
                    category: "platform",
                    message: "Package.swift missing Swift 6 language mode",
                    icon: "⚠️",
                    isApplicable: false // requires manual edit
                ))
            }

            if !content.contains(".testTarget(") {
                findings.append(AdoptionFinding(
                    category: "testing",
                    message: "No test target in Package.swift",
                    icon: "🧪",
                    isApplicable: false // requires manual edit
                ))
            }
        }

        // Check for pre-commit hook
        let hookPath = (path as NSString).appendingPathComponent(".git/hooks/pre-commit")
        if !fm.fileExists(atPath: hookPath) {
            findings.append(AdoptionFinding(
                category: "git",
                message: "Missing pre-commit hook — no local build/test enforcement",
                icon: "🪝",
                isApplicable: true
            ))
        }

        // Check for DocC catalog
        let sourcesPath = (path as NSString).appendingPathComponent("Sources")
        var hasDocC = false
        if let sources = try? fm.contentsOfDirectory(atPath: sourcesPath) {
            for source in sources {
                let full = (sourcesPath as NSString).appendingPathComponent(source)
                var isDir: ObjCBool = false
                if fm.fileExists(atPath: full, isDirectory: &isDir), isDir.boolValue {
                    if let files = try? fm.contentsOfDirectory(atPath: full) {
                        if files.contains(where: { $0.hasSuffix(".docc") }) {
                            hasDocC = true
                            break
                        }
                    }
                }
            }
        }
        if !hasDocC {
            findings.append(AdoptionFinding(
                category: "documentation",
                message: "No DocC catalog found — public APIs undocumented",
                icon: "📚",
                isApplicable: false // requires manual creation
            ))
        }

        return findings
    }
}

// MARK: - Project Adopter

struct ProjectAdopter {
    let path: String
    let dryRun: Bool

    func apply(findings: [AdoptionFinding]) async throws {
        for finding in findings {
            switch finding.category {
            case "documentation":
                if finding.message.contains("AGENTS.md") {
                    try generateAgentsMD()
                } else if finding.message.contains("README.md") {
                    try generateREADME()
                }
            case "git":
                if finding.message.contains(".gitignore") {
                    try generateGitignore()
                } else if finding.message.contains("pre-commit") {
                    try generatePreCommitHook()
                }
            case "ci":
                try generateCIWorkflow()
            default:
                break
            }
        }
    }

    private func writeFile(_ content: String, to filename: String) throws {
        let filePath = (path as NSString).appendingPathComponent(filename)
        if dryRun {
            print("  [dry-run] Would write \(filename)")
        } else {
            try content.write(toFile: filePath, atomically: true, encoding: .utf8)
            print("  ✅ Created \(filename)")
        }
    }

    private func generateAgentsMD() throws {
        let content = """
        # Agent Guidelines

        ## Project Overview

        This project uses SwiftAnvil packages.

        ## Development Workflow

        ```bash
        swift build
        swift test
        ```

        ## Platform Policy

        See: https://github.com/swiftanvil/swiftanvil-meta/blob/main/PLATFORM_POLICY.md
        """
        try writeFile(content, to: "AGENTS.md")
    }

    private func generateREADME() throws {
        let projectName = (path as NSString).lastPathComponent
        let content = """
        # \(projectName)

        ## Build

        ```bash
        swift build
        ```

        ## Test

        ```bash
        swift test
        ```
        """
        try writeFile(content, to: "README.md")
    }

    private func generateGitignore() throws {
        let content = """
        .build/
        .swiftpm/
        *.xcodeproj
        *.xcworkspace
        DerivedData/
        .DS_Store
        *.swp
        *.swo
        *~
        .idea/
        .vscode/
        """
        try writeFile(content, to: ".gitignore")
    }

    private func generatePreCommitHook() throws {
        let content = """
        #!/bin/sh
        set -e
        echo "Running pre-commit checks..."
        swift build
        swift test
        echo "Pre-commit checks passed."
        """
        let hooksDir = (path as NSString).appendingPathComponent(".git/hooks")
        let hookPath = (hooksDir as NSString).appendingPathComponent("pre-commit")
        if dryRun {
            print("  [dry-run] Would write .git/hooks/pre-commit")
        } else {
            try FileManager.default.createDirectory(atPath: hooksDir, withIntermediateDirectories: true)
            try content.write(toFile: hookPath, atomically: true, encoding: .utf8)
            try FileManager.default.setAttributes([.posixPermissions: 0o755], ofItemAtPath: hookPath)
            print("  ✅ Created .git/hooks/pre-commit")
        }
    }

    private func generateCIWorkflow() throws {
        let content = """
        name: CI

        on:
          push:
            branches: [main, develop]
          pull_request:
            branches: [main, develop]

        jobs:
          test:
            runs-on: macos-latest
            steps:
              - uses: actions/checkout@v6
              - name: Build
                run: swift build
              - name: Test
                run: swift test
        """
        let workflowDir = (path as NSString).appendingPathComponent(".github/workflows")
        if !dryRun {
            try FileManager.default.createDirectory(atPath: workflowDir, withIntermediateDirectories: true)
        }
        try writeFile(content, to: ".github/workflows/ci.yml")
    }
}

// MARK: - Types

struct AdoptionFinding {
    let category: String
    let message: String
    let icon: String
    let isApplicable: Bool
}
