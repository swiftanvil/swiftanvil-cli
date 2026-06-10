// ProjectVerifier.swift
// Static verification for generated SwiftAnvil projects

import Foundation

struct ProjectVerifier {
    private let fileSystem: any ProjectVerificationFileSystem
    private let policy: ProjectVerificationPolicy

    init(
        fileSystem: any ProjectVerificationFileSystem = LocalProjectVerificationFileSystem(),
        policy: ProjectVerificationPolicy = .current
    ) {
        self.fileSystem = fileSystem
        self.policy = policy
    }

    func verify(path rootPath: String) -> ProjectVerificationReport {
        let normalizedRootPath = URL(fileURLWithPath: rootPath).standardizedFileURL.path
        var issues: [ProjectVerificationIssue] = []

        issues.append(contentsOf: verifyRequiredStructure(rootPath: normalizedRootPath))
        issues.append(contentsOf: verifyPackageManifest(rootPath: normalizedRootPath))
        issues.append(contentsOf: verifyWorkflow(rootPath: normalizedRootPath))
        issues.append(contentsOf: verifyDocumentationRegistry(rootPath: normalizedRootPath))

        return ProjectVerificationReport(rootPath: normalizedRootPath, issues: issues)
    }

    private func verifyRequiredStructure(rootPath: String) -> [ProjectVerificationIssue] {
        var issues: [ProjectVerificationIssue] = []

        for requiredFile in policy.requiredFiles {
            let absolutePath = path(rootPath, requiredFile)
            if !fileSystem.fileExists(atPath: absolutePath) {
                issues.append(makeError(
                    check: "required-file",
                    message: "Missing required file \(requiredFile).",
                    path: requiredFile
                ))
            }
        }

        for requiredDirectory in policy.requiredDirectories {
            let absolutePath = path(rootPath, requiredDirectory)
            if !fileSystem.directoryExists(atPath: absolutePath) {
                issues.append(makeError(
                    check: "required-directory",
                    message: "Missing required directory \(requiredDirectory).",
                    path: requiredDirectory
                ))
            }
        }

        return issues
    }

    private func verifyPackageManifest(rootPath: String) -> [ProjectVerificationIssue] {
        let relativePath = policy.packageManifestPath
        let absolutePath = path(rootPath, relativePath)

        guard fileSystem.fileExists(atPath: absolutePath) else {
            return []
        }

        do {
            let manifest = try fileSystem.readFile(atPath: absolutePath)
            var issues: [ProjectVerificationIssue] = []

            if !manifest.contains("swift-tools-version:") {
                issues.append(makeError(
                    check: "package-tools-version",
                    message: "Package manifest must declare a Swift tools version.",
                    path: relativePath
                ))
            }

            if !manifest.contains(".testTarget(") {
                issues.append(makeError(
                    check: "package-test-target",
                    message: "Package manifest must declare at least one test target.",
                    path: relativePath
                ))
            }

            if !manifest.contains(policy.requiredSwiftLanguageMode) {
                issues.append(warning(
                    check: "package-swift-6",
                    message: "Package manifest should opt into Swift 6 language mode.",
                    path: relativePath
                ))
            }

            return issues
        } catch {
            return [makeError(
                check: "package-readable",
                message: "Could not read Package.swift: \(error.localizedDescription)",
                path: relativePath
            )]
        }
    }

    private func verifyWorkflow(rootPath: String) -> [ProjectVerificationIssue] {
        let relativePath = policy.ciWorkflowPath
        let absolutePath = path(rootPath, relativePath)

        guard fileSystem.fileExists(atPath: absolutePath) else {
            return []
        }

        do {
            let workflow = try fileSystem.readFile(atPath: absolutePath)
            var issues: [ProjectVerificationIssue] = []

            if !workflow.contains(policy.requiredCheckoutAction) {
                issues.append(makeError(
                    check: "ci-checkout-version",
                    message: "CI workflow must use \(policy.requiredCheckoutAction).",
                    path: relativePath
                ))
            }

            if !workflow.contains("swift build") {
                issues.append(makeError(
                    check: "ci-build-step",
                    message: "CI workflow must run swift build.",
                    path: relativePath
                ))
            }

            if !workflow.contains("swift test") {
                issues.append(makeError(
                    check: "ci-test-step",
                    message: "CI workflow must run swift test.",
                    path: relativePath
                ))
            }

            return issues
        } catch {
            return [makeError(
                check: "ci-readable",
                message: "Could not read CI workflow: \(error.localizedDescription)",
                path: relativePath
            )]
        }
    }

    private func verifyDocumentationRegistry(rootPath: String) -> [ProjectVerificationIssue] {
        let relativePath = policy.documentationRegistryPath
        let absolutePath = path(rootPath, relativePath)

        guard fileSystem.fileExists(atPath: absolutePath) else {
            return []
        }

        do {
            let registry = try fileSystem.readFile(atPath: absolutePath)
            var issues: [ProjectVerificationIssue] = []

            if !registry.contains("documents:") {
                issues.append(makeError(
                    check: "registry-documents",
                    message: "Documentation registry must contain a documents section.",
                    path: relativePath
                ))
            }

            if !registry.contains("sources:") {
                issues.append(makeError(
                    check: "registry-sources",
                    message: "Documentation registry entries must declare sources.",
                    path: relativePath
                ))
            }

            return issues
        } catch {
            return [makeError(
                check: "registry-readable",
                message: "Could not read documentation registry: \(error.localizedDescription)",
                path: relativePath
            )]
        }
    }

    private func path(_ rootPath: String, _ relativePath: String) -> String {
        URL(fileURLWithPath: rootPath).appendingPathComponent(relativePath).path
    }

    private func makeError(check: String, message: String, path: String?) -> ProjectVerificationIssue {
        ProjectVerificationIssue(severity: .error, check: check, message: message, path: path)
    }

    private func warning(check: String, message: String, path: String?) -> ProjectVerificationIssue {
        ProjectVerificationIssue(severity: .warning, check: check, message: message, path: path)
    }
}
