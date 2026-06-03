// CreateCommand.swift
// Scaffolds a new Swift project from a template

import ArgumentParser
import Foundation

struct CreateCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "create",
        abstract: "Create a new project from a template"
    )

    @Argument(help: "Project name")
    var projectName: String

    @Option(name: .shortAndLong, help: "Template to use")
    var template: String?

    @Flag(name: .shortAndLong, help: "Interactive wizard mode")
    var interactive: Bool = false

    @Option(name: .shortAndLong, help: "Output directory")
    var output: String?

    mutating func run() async throws {
        let generator = ProjectGenerator()

        if interactive {
            let config = try await InteractiveWizard().run(projectName: projectName)
            try await generator.generate(projectName: projectName, config: config, outputPath: output)
        } else {
            let templateName = template ?? "ios-app"
            let config = ProjectConfig(
                template: templateName,
                projectName: projectName,
                options: [:]
            )
            try await generator.generate(projectName: projectName, config: config, outputPath: output)
        }

        print("✓ Project '\(projectName)' created successfully.")
    }
}
