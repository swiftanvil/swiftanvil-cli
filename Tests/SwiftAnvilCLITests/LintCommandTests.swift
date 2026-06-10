// LintCommandTests.swift
// Tests for config loading and source structure linting

import Foundation
import Testing
@testable import SwiftAnvilCLI

struct SwiftAnvilConfigLoaderTests {
    @Test("returns defaults when .swiftanvil.yml is missing")
    func defaultsWhenMissing() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let config = SwiftAnvilConfigLoader.load(from: tempDir.path)
        #expect(config.lint.structure.maxLines == 350)
        #expect(config.lint.structure.maxTopLevelTypes == 4)
        #expect(config.lint.structure.mixedTypeKinds == 3)
    }

    @Test("reads custom values from .swiftanvil.yml")
    func readsCustomConfig() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let yaml = """
        lint:
          structure:
            max_lines: 500
            max_top_level_types: 6
            mixed_type_kinds: 2
        """
        let configPath = tempDir.appendingPathComponent(".swiftanvil.yml")
        try yaml.write(to: configPath, atomically: true, encoding: .utf8)

        let config = SwiftAnvilConfigLoader.load(from: tempDir.path)
        #expect(config.lint.structure.maxLines == 500)
        #expect(config.lint.structure.maxTopLevelTypes == 6)
        #expect(config.lint.structure.mixedTypeKinds == 2)
    }

    @Test("falls back to defaults on malformed YAML")
    func fallsBackOnMalformedYAML() throws {
        let fm = FileManager.default
        let tempDir = fm.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        defer { try? fm.removeItem(at: tempDir) }
        try fm.createDirectory(at: tempDir, withIntermediateDirectories: true)

        let yaml = "this is not: [ valid yaml ::::"
        let configPath = tempDir.appendingPathComponent(".swiftanvil.yml")
        try yaml.write(to: configPath, atomically: true, encoding: .utf8)

        let config = SwiftAnvilConfigLoader.load(from: tempDir.path)
        #expect(config.lint.structure.maxLines == 350)
    }
}

struct SourceStructureLinterTests {
    @Test("passes for small file with few types")
    func passesSmallFile() {
        let content = """
        import Foundation

        struct SmallModel {
            let name: String
        }
        """
        var issues: [LintCommand.LintIssue] = []
        let config = LintStructureConfig()
        let linter = LintCommand.SourceLint()
        linter.lintSourceStructure(content, path: "/tmp/SmallModel.swift", config: config, issues: &issues)
        #expect(issues.isEmpty)
    }

    @Test("fails when file exceeds max lines")
    func failsOnTooManyLines() {
        var lines: [String] = []
        for i in 0 ..< 360 {
            lines.append("// line \(i)")
        }
        let content = lines.joined(separator: "\n")
        var issues: [LintCommand.LintIssue] = []
        let config = LintStructureConfig()
        let linter = LintCommand.SourceLint()
        linter.lintSourceStructure(content, path: "/tmp/BigFile.swift", config: config, issues: &issues)
        #expect(issues.contains { $0.message.contains("360 lines") })
    }

    @Test("fails when file has too many top-level types")
    func failsOnTooManyTypes() {
        let content = """
        struct One {}
        struct Two {}
        struct Three {}
        struct Four {}
        struct Five {}
        """
        var issues: [LintCommand.LintIssue] = []
        let config = LintStructureConfig()
        let linter = LintCommand.SourceLint()
        linter.lintSourceStructure(content, path: "/tmp/ManyTypes.swift", config: config, issues: &issues)
        #expect(issues.contains { $0.message.contains("5 top-level types") })
    }

    @Test("warns when file mixes many type kinds")
    func warnsOnMixedKinds() {
        let content = """
        struct MyStruct {}
        enum MyEnum {}
        protocol MyProtocol {}
        extension MyStruct {}
        """
        var issues: [LintCommand.LintIssue] = []
        let config = LintStructureConfig()
        let linter = LintCommand.SourceLint()
        linter.lintSourceStructure(content, path: "/tmp/MixedKinds.swift", config: config, issues: &issues)
        #expect(issues.contains { $0.severity == .warning && $0.message.contains("mixes") })
    }

    @Test("respects custom config thresholds")
    func respectsCustomThresholds() {
        let content = """
        struct A {}
        struct B {}
        struct C {}
        """
        var issues: [LintCommand.LintIssue] = []
        let config = LintStructureConfig(maxLines: 10, maxTopLevelTypes: 2, mixedTypeKinds: 3)
        let linter = LintCommand.SourceLint()
        linter.lintSourceStructure(content, path: "/tmp/Custom.swift", config: config, issues: &issues)
        #expect(issues.contains { $0.message.contains("3 top-level types") })
    }
}

struct SolidLinterTests {
    @Test("passes for clean file")
    func passesCleanFile() {
        let content = """
        struct SmallModel {
            let name: String
        }
        """
        var issues: [LintCommand.LintIssue] = []
        let config = SwiftAnvilConfig()
        let linter = LintCommand.SolidLint()
        linter.lintSolidHeuristics(content, path: "/tmp/Clean.swift", config: config, issues: &issues)
        #expect(issues.isEmpty)
    }

    @Test("warns on switch without default over enum")
    func warnsOnSwitchWithoutDefault() {
        let content = """
        enum Color { case red, green, blue }
        func describe(_ color: Color) -> String {
            switch color {
            case .red: return "red"
            case .green: return "green"
            }
        }
        """
        var issues: [LintCommand.LintIssue] = []
        let config = SwiftAnvilConfig()
        let linter = LintCommand.SolidLint()
        linter.lintSolidHeuristics(content, path: "/tmp/Switch.swift", config: config, issues: &issues)
        #expect(issues.contains { $0.severity == .warning && $0.message.contains("OCP") })
    }

    @Test("warns on protocol downcast")
    func warnsOnProtocolDowncast() {
        let content = """
        protocol Drawable {}
        func draw(_ item: Drawable) {
            if let shape = item as? Circle {
                _ = shape
            }
        }
        """
        var issues: [LintCommand.LintIssue] = []
        let config = SwiftAnvilConfig()
        let linter = LintCommand.SolidLint()
        linter.lintSolidHeuristics(content, path: "/tmp/Cast.swift", config: config, issues: &issues)
        #expect(issues.contains { $0.severity == .warning && $0.message.contains("Protocol cast") })
    }

    @Test("warns on protocol with too many requirements")
    func warnsOnFatProtocol() {
        let content = """
        protocol FatProtocol {
            func a()
            func b()
            func c()
            func d()
            func e()
            func f()
        }
        """
        var issues: [LintCommand.LintIssue] = []
        let config = SwiftAnvilConfig()
        let linter = LintCommand.SolidLint()
        linter.lintSolidHeuristics(content, path: "/tmp/Fat.swift", config: config, issues: &issues)
        #expect(issues.contains { $0.severity == .warning && $0.message.contains("6 requirements") })
    }

    @Test("info on public API with concrete dependency")
    func infoOnConcreteDependency() {
        let content = """
        public struct Service {
            public init(client: HTTPClient) {}
        }
        """
        var issues: [LintCommand.LintIssue] = []
        let config = SwiftAnvilConfig()
        let linter = LintCommand.SolidLint()
        linter.lintSolidHeuristics(content, path: "/tmp/Concrete.swift", config: config, issues: &issues)
        #expect(issues.contains { $0.severity == .info && $0.message.contains("concrete type") })
    }

    @Test("respects custom protocol requirement budget")
    func respectsCustomProtocolBudget() {
        let content = """
        protocol MyProtocol {
            func a()
            func b()
            func c()
        }
        """
        var issues: [LintCommand.LintIssue] = []
        var config = SwiftAnvilConfig()
        config.lint.solid.maxProtocolRequirements = 2
        let linter = LintCommand.SolidLint()
        linter.lintSolidHeuristics(content, path: "/tmp/CustomProtocol.swift", config: config, issues: &issues)
        #expect(issues.contains { $0.message.contains("3 requirements") })
    }
}

struct TypeSafetyLinterTests {
    @Test("warns on hardcoded Text string")
    func warnsOnHardcodedText() {
        // swiftlint:disable hardcoded_display_string
        let content = """
        struct MyView: View {
            var body: some View {
                Text("Hello, world!")
            }
        }
        """
        // swiftlint:enable hardcoded_display_string
        var issues: [LintCommand.LintIssue] = []
        let config = SwiftAnvilConfig()
        let linter = LintCommand.SourceLint()
        linter.lintSourceFile(content, path: "/tmp/View.swift", config: config, issues: &issues)
        #expect(issues.contains { $0.severity == .warning && $0.message.contains("Text") })
    }

    @Test("warns on raw accessibilityIdentifier")
    func warnsOnRawAccessibilityIdentifier() {
        // swiftlint:disable hardcoded_display_string raw_accessibility_identifier
        let content = """
        Button("Tap").accessibilityIdentifier("tap_button")
        """
        // swiftlint:enable hardcoded_display_string raw_accessibility_identifier
        var issues: [LintCommand.LintIssue] = []
        let config = SwiftAnvilConfig()
        let linter = LintCommand.SourceLint()
        linter.lintSourceFile(content, path: "/tmp/A11y.swift", config: config, issues: &issues)
        #expect(issues.contains { $0.severity == .warning && $0.message.contains("accessibilityIdentifier") })
    }

    @Test("passes when no hardcoded strings present")
    func passesCleanStrings() {
        let content = """
        struct MyView: View {
            var body: some View {
                Text(AppStrings.greeting)
            }
        }
        """
        var issues: [LintCommand.LintIssue] = []
        let config = SwiftAnvilConfig()
        let linter = LintCommand.SourceLint()
        linter.lintSourceFile(content, path: "/tmp/CleanView.swift", config: config, issues: &issues)
        #expect(!issues.contains { $0.message.contains("raw string") })
    }
}
