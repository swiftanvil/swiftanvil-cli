// SwiftAnvilCLI — Swift Project Scaffolding Tool
// Host-agnostic, LLM-era project infrastructure for Apple platforms

import ArgumentParser
import Foundation

@main
struct SwiftAnvilCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "swiftanvil",
        abstract: "Swift project scaffolding with architectural enforcement",
        version: "0.3.0",
        subcommands: [
            AdoptCommand.self,
            BuildCommand.self,
            CreateCommand.self,
            DependenciesCommand.self,
            DistributeCommand.self,
            DoctorCommand.self,
            DocsCommand.self,
            PerfCommand.self,
            ImmunityCommand.self,
            LintCommand.self,
            VerifyCommand.self
        ],
        defaultSubcommand: CreateCommand.self
    )
}
