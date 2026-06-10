// ImmunityCommand.swift
// Self-improvement and telemetry system

import ArgumentParser
import Foundation

struct ImmunityCommand: AsyncParsableCommand {
    static let configuration = CommandConfiguration(
        commandName: "immunity",
        abstract: "Self-improvement and health monitoring system",
        subcommands: [Scan.self, Report.self, Suggest.self]
    )

    struct Scan: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "scan",
            abstract: "Run immunity scan on project"
        )

        @Flag(help: "Deep scan mode")
        var deep: Bool = false

        mutating func run() async throws {
            let scanner = ImmunityScanner()
            let result = try await scanner.scan(deep: deep)

            print("Immunity Scan Results:")
            print("  Health Score: \(result.healthScore)%")
            print("  Issues Found: \(result.issues.count)")
            print("  Suggestions: \(result.suggestions.count)")

            for issue in result.issues {
                print("  \(issue.severity.icon) [\(issue.category)] \(issue.description)")
            }
        }
    }

    struct Report: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "report",
            abstract: "Generate immunity health report"
        )

        @Option(help: "Output format (json, markdown, html)")
        var format: String = "markdown"

        mutating func run() async throws {
            let scanner = ImmunityScanner()
            let result = try await scanner.scan(deep: false)

            let report = generateReport(result: result, format: format)
            print(report)
        }

        private func generateReport(result: ImmunityScanResult, format: String) -> String {
            switch format {
            case "json":
                """
                {
                  "healthScore": \(result.healthScore),
                  "issues": \(result.issues.count),
                  "suggestions": \(result.suggestions.count)
                }
                """
            default:
                """
                # Immunity Health Report

                | Metric | Value |
                |--------|-------|
                | Health Score | \(result.healthScore)% |
                | Issues | \(result.issues.count) |
                | Suggestions | \(result.suggestions.count) |

                ## Issues
                \(result.issues.map { "- [\($0.severity.icon)] [\($0.category)] \($0.description)" }
                    .joined(separator: "\n"))

                ## Suggestions
                \(result.suggestions.map { "- **\($0.title)**: \($0.description)" }.joined(separator: "\n"))
                """
            }
        }
    }

    struct Suggest: AsyncParsableCommand {
        static let configuration = CommandConfiguration(
            commandName: "suggest",
            abstract: "Get improvement suggestions"
        )

        @Option(help: "Category (architecture, performance, security, accessibility)")
        var category: String?

        mutating func run() async throws {
            let engine = SuggestionEngine()
            let suggestions = try await engine.suggest(category: category)

            print("Improvement Suggestions:")
            for suggestion in suggestions {
                print("  • \(suggestion.title)")
                print("    \(suggestion.description)")
                if let impact = suggestion.impact {
                    print("    Impact: \(impact)")
                }
            }
        }
    }
}
