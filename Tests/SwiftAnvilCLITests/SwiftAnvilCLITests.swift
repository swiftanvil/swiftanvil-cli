// SwiftAnvilCLITests.swift
// Unit tests for the SwiftAnvil CLI tool

import Foundation
import Testing
@testable import SwiftAnvilCLI

struct ProjectConfigTests {
    @Test func defaultOptions() {
        let config = ProjectConfig(
            template: "ios-app",
            projectName: "TestApp",
            options: [:]
        )

        #expect(config.template == "ios-app")
        #expect(config.projectName == "TestApp")
        #expect(config.useSwiftUI == true)
        #expect(config.enableAccessibility == true)
        #expect(config.enableLocalization == true)
        #expect(config.includeUnitTests == true)
        #expect(config.includeUITests == true)
    }

    @Test func customOptions() {
        let config = ProjectConfig(
            template: "swift-library",
            projectName: "TestLib",
            options: [
                "useSwiftUI": .bool(false),
                "enableAccessibility": .bool(false),
                "targetLanguages": .stringArray(["en", "ja"])
            ]
        )

        #expect(config.useSwiftUI == false)
        #expect(config.enableAccessibility == false)
        #expect(config.targetLanguages == ["en", "ja"])
    }

    @Test func macOSAppTemplateDetection() {
        let config = ProjectConfig(
            template: "macos-app",
            projectName: "MyMacApp",
            options: [:]
        )

        #expect(config.isMacOSApp == true)
        #expect(config.template == "macos-app")
    }

    @Test func iOSAppTemplateIsNotMacOS() {
        let config = ProjectConfig(
            template: "ios-app",
            projectName: "MyiOSApp",
            options: [:]
        )

        #expect(config.isMacOSApp == false)
    }
}

struct PathResolverTests {
    @Test func homeDirectoryExists() {
        let home = PathResolver.homeDirectory
        #expect(!home.isEmpty)
        #expect(home != "/tmp" || ProcessInfo.processInfo.environment["HOME"] == nil)
    }

    @Test func resolvesRelativePath() {
        let resolved = PathResolver.resolve("Sources/Main.swift", relativeTo: "/project")
        #expect(resolved == "/project/Sources/Main.swift")
    }

    @Test func resolvesAbsolutePath() {
        let resolved = PathResolver.resolve("/absolute/path")
        #expect(resolved == "/absolute/path")
    }

    @Test func resolvesTildePath() {
        let resolved = PathResolver.resolve("~/.config")
        #expect(resolved.hasPrefix("/"))
        #expect(!resolved.contains("~"))
    }
}

struct ShellRunnerTests {
    @Test func runsEchoCommand() async throws {
        let runner = ShellRunner()
        let result = try await runner.run("echo 'hello world'")
        #expect(result.exitCode == 0)
        #expect(result.stdout.contains("hello world"))
    }

    @Test func handlesFailingCommand() async throws {
        let runner = ShellRunner()
        let result = try await runner.run("false")
        #expect(result.exitCode != 0)
    }
}
