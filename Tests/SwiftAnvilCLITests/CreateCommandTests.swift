// CreateCommandTests.swift
// Tests for project generation with different templates

import Foundation
import Testing
@testable import SwiftAnvilCLI

@Suite("CreateCommand — macOS App Template")
struct MacOSAppTemplateTests {
    @Test("generates macOS-only Package.swift")
    func generatesMacOSPackageManifest() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        let config = ProjectConfig(
            template: "macos-app",
            projectName: "MyMacApp",
            options: [:]
        )

        let generator = ProjectGenerator()
        try await generator.generate(projectName: "MyMacApp", config: config, outputPath: tempDir.path)

        let packageSwift = tempDir.appendingPathComponent("MyMacApp/Package.swift")
        let content = try String(contentsOf: packageSwift, encoding: .utf8)

        #expect(content.contains(".macOS(.v15)"))
        #expect(!content.contains(".iOS("))
        #expect(content.contains("swiftanvil-anvil-network"))
        #expect(content.contains("swiftanvil-anvil-flags"))
        #expect(content.contains("AnvilNetwork"))
        #expect(content.contains("AnvilFlags"))
    }

    @Test("creates MenuBar and Settings directories")
    func createsMacOSSpecificDirectories() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        let config = ProjectConfig(
            template: "macos-app",
            projectName: "MyMacApp",
            options: [:]
        )

        let generator = ProjectGenerator()
        try await generator.generate(projectName: "MyMacApp", config: config, outputPath: tempDir.path)

        let menuBarDir = tempDir.appendingPathComponent("MyMacApp/Sources/MyMacApp/MenuBar")
        let settingsDir = tempDir.appendingPathComponent("MyMacApp/Sources/MyMacApp/Settings")
        let uiTestsDir = tempDir.appendingPathComponent("MyMacApp/Tests/MyMacAppUITests")

        #expect(fm.fileExists(atPath: menuBarDir.path))
        #expect(fm.fileExists(atPath: settingsDir.path))
        #expect(!fm.fileExists(atPath: uiTestsDir.path))
    }

    @Test("generates MenuBarExtra in app entry point")
    func generatesMenuBarExtra() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        let config = ProjectConfig(
            template: "macos-app",
            projectName: "MyMacApp",
            options: [:]
        )

        let generator = ProjectGenerator()
        try await generator.generate(projectName: "MyMacApp", config: config, outputPath: tempDir.path)

        let appFile = tempDir.appendingPathComponent("MyMacApp/Sources/MyMacApp/MyMacAppApp.swift")
        let content = try String(contentsOf: appFile, encoding: .utf8)

        #expect(content.contains("MenuBarExtra"))
        #expect(content.contains("WindowGroup"))
        #expect(content.contains("Settings"))
        #expect(content.contains("@main"))
    }

    @Test("generates MenuBarView and SettingsView")
    func generatesMacOSViews() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        let config = ProjectConfig(
            template: "macos-app",
            projectName: "MyMacApp",
            options: [:]
        )

        let generator = ProjectGenerator()
        try await generator.generate(projectName: "MyMacApp", config: config, outputPath: tempDir.path)

        let menuBarView = tempDir.appendingPathComponent("MyMacApp/Sources/MyMacApp/MenuBar/MenuBarView.swift")
        let settingsView = tempDir.appendingPathComponent("MyMacApp/Sources/MyMacApp/Settings/SettingsView.swift")

        let menuBarContent = try String(contentsOf: menuBarView, encoding: .utf8)
        let settingsContent = try String(contentsOf: settingsView, encoding: .utf8)

        #expect(menuBarContent.contains("MenuBarView"))
        #expect(menuBarContent.contains("NSApp"))
        #expect(settingsContent.contains("SettingsView"))
        #expect(settingsContent.contains("Form"))
    }

    @Test("generated macOS project builds successfully")
    func generatedProjectBuilds() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        let config = ProjectConfig(
            template: "macos-app",
            projectName: "MyMacApp",
            options: [:]
        )

        let generator = ProjectGenerator()
        try await generator.generate(projectName: "MyMacApp", config: config, outputPath: tempDir.path)

        let projectDir = tempDir.appendingPathComponent("MyMacApp")
        let runner = ShellRunner()
        let result = try await runner.run("cd \(projectDir.path) && swift build 2>&1")

        #expect(result.exitCode == 0, "Build failed: \(result.stdout)\(result.stderr)")
    }
}

@Suite("CreateCommand — iOS App Template (regression)")
struct IOSAppTemplateTests {
    @Test("iOS template still generates iOS + macOS platforms")
    func iOSPackageManifestUnchanged() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        let config = ProjectConfig(
            template: "ios-app",
            projectName: "MyiOSApp",
            options: [:]
        )

        let generator = ProjectGenerator()
        try await generator.generate(projectName: "MyiOSApp", config: config, outputPath: tempDir.path)

        let packageSwift = tempDir.appendingPathComponent("MyiOSApp/Package.swift")
        let content = try String(contentsOf: packageSwift, encoding: .utf8)

        // swiftlint:disable platform_policy_old_version
        #expect(content.contains(".iOS(.v17)"))
        #expect(content.contains(".macOS(.v14)"))
        // swiftlint:enable platform_policy_old_version
        #expect(!content.contains("swiftanvil-anvil-network"))
    }

    @Test("iOS template creates UITests directory")
    func iOSCreatesUITests() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        let config = ProjectConfig(
            template: "ios-app",
            projectName: "MyiOSApp",
            options: [:]
        )

        let generator = ProjectGenerator()
        try await generator.generate(projectName: "MyiOSApp", config: config, outputPath: tempDir.path)

        let uiTestsDir = tempDir.appendingPathComponent("MyiOSApp/Tests/MyiOSAppUITests")
        #expect(fm.fileExists(atPath: uiTestsDir.path))
    }

    @Test("iOS template generates XCUIApplication UI tests")
    func iOSGeneratesXCUIApplicationTests() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        let config = ProjectConfig(
            template: "ios-app",
            projectName: "MyiOSApp",
            options: [:]
        )

        let generator = ProjectGenerator()
        try await generator.generate(projectName: "MyiOSApp", config: config, outputPath: tempDir.path)

        let uiTestFile = tempDir.appendingPathComponent("MyiOSApp/Tests/MyiOSAppUITests/MyiOSAppUITests.swift")
        let content = try String(contentsOf: uiTestFile, encoding: .utf8)

        #expect(content.contains("XCUIApplication"))
    }

    @Test("iOS template generates block-direct-push workflow")
    func iOSGeneratesBlockDirectPushWorkflow() async throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }

        let config = ProjectConfig(
            template: "ios-app",
            projectName: "MyiOSApp",
            options: [:]
        )

        let generator = ProjectGenerator()
        try await generator.generate(projectName: "MyiOSApp", config: config, outputPath: tempDir.path)

        let workflowPath = tempDir.appendingPathComponent("MyiOSApp/.github/workflows/block-direct-push.yml")
        #expect(fm.fileExists(atPath: workflowPath.path))

        let content = try String(contentsOf: workflowPath, encoding: .utf8)
        #expect(content.contains("Block Direct Push"))
        #expect(content.contains("DIRECT PUSH TO MAIN DETECTED"))
    }
}
