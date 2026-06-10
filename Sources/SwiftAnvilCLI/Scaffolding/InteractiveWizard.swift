// InteractiveWizard.swift
// Interactive project configuration wizard

import Foundation

/// Guides the user through interactive project configuration
struct InteractiveWizard {
    func run(projectName: String) async throws -> ProjectConfig {
        print("\n🚀 SwiftAnvil Project Wizard")
        print("─────────────────────────────\n")

        // Template selection
        let template = try await selectTemplate()

        // Platform-specific options
        let minOSVersion = try await prompt("Minimum OS version", default: "17.0")
        let useSwiftUI = try await confirm("Use SwiftUI?", default: true)

        // Data layer
        let useCoreData = try await confirm("Include Core Data?", default: false)
        let useCloudKit = try await confirm("Include CloudKit?", default: false)

        // Inclusive design
        let enableAccessibility = try await confirm("Enable accessibility enforcement?", default: true)
        let enableLocalization = try await confirm("Enable localization?", default: true)

        let targetLanguages: [String] = if enableLocalization {
            try await selectLanguages()
        } else {
            ["en"]
        }

        // Testing
        let includeUnitTests = try await confirm("Include unit tests?", default: true)
        let includeUITests = try await confirm("Include UI tests?", default: true)
        let includeSnapshotTests = try await confirm("Include snapshot tests?", default: false)
        let includePerformanceTests = try await confirm("Include performance tests?", default: false)

        // CI/CD
        let ciProvider = try await selectCIProvider()
        let useSelfHosted = try await confirm("Use self-hosted runners?", default: false)

        // Intelligence
        let enableImmunity = try await confirm("Enable immunity system?", default: true)

        let options: [String: ConfigValue] = [
            "minimumOSVersion": .string(minOSVersion),
            "useSwiftUI": .bool(useSwiftUI),
            "useCoreData": .bool(useCoreData),
            "useCloudKit": .bool(useCloudKit),
            "enableAccessibility": .bool(enableAccessibility),
            "enableLocalization": .bool(enableLocalization),
            "targetLanguages": .stringArray(targetLanguages),
            "includeUnitTests": .bool(includeUnitTests),
            "includeUITests": .bool(includeUITests),
            "includeSnapshotTests": .bool(includeSnapshotTests),
            "includePerformanceTests": .bool(includePerformanceTests),
            "ciProvider": .string(ciProvider),
            "useSelfHostedRunners": .bool(useSelfHosted),
            "enableImmunity": .bool(enableImmunity)
        ]

        return ProjectConfig(template: template, projectName: projectName, options: options)
    }

    // MARK: - Private Helpers

    private func selectTemplate() async throws -> String {
        let templates = [
            ("ios-app", "iOS App (SwiftUI)"),
            ("ios-uikit", "iOS App (UIKit)"),
            ("macos-app", "macOS App"),
            ("watchos-app", "watchOS App"),
            ("tvos-app", "tvOS App"),
            ("visionos-app", "visionOS App"),
            ("swift-library", "Swift Library"),
            ("swift-tool", "Command Line Tool"),
            ("swift-server", "Server-side Swift"),
            ("multiplatform-app", "Multiplatform App")
        ]

        print("Available templates:")
        for (index, (_, name)) in templates.enumerated() {
            print("  \(index + 1). \(name)")
        }

        let selection = try await prompt("Select template (1-\(templates.count))", default: "1")
        let index = (Int(selection) ?? 1) - 1
        return templates[min(max(index, 0), templates.count - 1)].0
    }

    private func selectLanguages() async throws -> [String] {
        let languages = [
            ("en", "English"),
            ("es", "Spanish"),
            ("fr", "French"),
            ("de", "German"),
            ("ja", "Japanese"),
            ("zh-Hans", "Chinese (Simplified)"),
            ("zh-Hant", "Chinese (Traditional)"),
            ("ko", "Korean"),
            ("pt", "Portuguese"),
            ("ru", "Russian"),
            ("ar", "Arabic"),
            ("hi", "Hindi")
        ]

        print("\nAvailable languages:")
        for (code, name) in languages {
            print("  \(code) - \(name)")
        }

        let input = try await prompt("Enter language codes (comma-separated)", default: "en")
        return input.split(separator: ",").map { $0.trimmingCharacters(in: .whitespaces) }
    }

    private func selectCIProvider() async throws -> String {
        print("\nCI Providers:")
        print("  1. GitHub Actions")
        print("  2. GitLab CI")
        print("  3. Azure DevOps")
        print("  4. Bitbucket Pipelines")

        let selection = try await prompt("Select CI provider", default: "1")
        switch selection {
        case "2": return "gitlab-ci"
        case "3": return "azure-devops"
        case "4": return "bitbucket"
        default: return "github-actions"
        }
    }

    private func prompt(_ message: String, default defaultValue: String) async throws -> String {
        print("\(message) [\(defaultValue)]:", terminator: " ")
        guard let input = readLine()?.trimmingCharacters(in: .whitespaces) else {
            return defaultValue
        }
        return input.isEmpty ? defaultValue : input
    }

    private func confirm(_ message: String, default defaultValue: Bool) async throws -> Bool {
        let defaultStr = defaultValue ? "Y/n" : "y/N"
        print("\(message) [\(defaultStr)]:", terminator: " ")
        guard let input = readLine()?.trimmingCharacters(in: .whitespaces).lowercased() else {
            return defaultValue
        }
        if input.isEmpty { return defaultValue }
        return input == "y" || input == "yes"
    }
}
