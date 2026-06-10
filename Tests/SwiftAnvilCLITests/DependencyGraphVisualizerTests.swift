// swiftlint:disable force_try
import Foundation
import Testing
@testable import SwiftAnvilCLI

struct DependencyGraphVisualizerTests {
    private func makeTempDir() -> String {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp.path
    }

    private func writePackage(at path: String, content: String) {
        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        let fullContent = """
        // swift-tools-version:6.0
        import PackageDescription
        \(content)
        """
        try! fullContent.write(toFile: packagePath, atomically: true, encoding: .utf8)
    }

    @Test func parseGraphExtractsTargetsAndDeps() throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        writePackage(at: path, content: """
        let package = Package(
            name: "GraphTest",
            products: [
                .library(name: "GraphTest", targets: ["Core", "UI"])
            ],
            dependencies: [
                .package(url: "https://github.com/apple/swift-argument-parser.git", from: "1.0.0")
            ],
            targets: [
                .target(name: "Core"),
                .target(name: "UI", dependencies: ["Core"])
            ]
        )
        """)

        let visualizer = DependencyGraphVisualizer(path: path)
        let nodes = try visualizer.parseGraph()

        let targetNodes = nodes.filter { $0.name == "Core" || $0.name == "UI" }
        #expect(targetNodes.count == 2)

        let uiNode = nodes.first { $0.name == "UI" }
        #expect(uiNode?.dependencies.contains("Core") == true)
    }

    @Test func generateMermaidProducesValidOutput() {
        let nodes = [
            DependencyNode(name: "App", dependencies: ["Core", "UI"]),
            DependencyNode(name: "UI", dependencies: ["Core"]),
            DependencyNode(name: "Core", dependencies: [])
        ]

        let visualizer = DependencyGraphVisualizer(path: "/tmp")
        let mermaid = visualizer.generateMermaid(nodes)

        #expect(mermaid.contains("graph TD"))
        #expect(mermaid.contains("App --> Core"))
        #expect(mermaid.contains("App --> UI"))
        #expect(mermaid.contains("UI --> Core"))
    }

    @Test func detectCyclesFindsCircularDeps() throws {
        let nodes = [
            DependencyNode(name: "A", dependencies: ["B"]),
            DependencyNode(name: "B", dependencies: ["C"]),
            DependencyNode(name: "C", dependencies: ["A"])
        ]

        let visualizer = DependencyGraphVisualizer(path: "/tmp")
        let cycles = visualizer.detectCycles(nodes)

        #expect(!cycles.isEmpty)
        let firstCycle = try #require(cycles.first)
        #expect(firstCycle.contains("A"))
        #expect(firstCycle.contains("B"))
        #expect(firstCycle.contains("C"))
    }

    @Test func detectCyclesReturnsEmptyForAcyclic() {
        let nodes = [
            DependencyNode(name: "App", dependencies: ["Core"]),
            DependencyNode(name: "Core", dependencies: ["Utils"]),
            DependencyNode(name: "Utils", dependencies: [])
        ]

        let visualizer = DependencyGraphVisualizer(path: "/tmp")
        let cycles = visualizer.detectCycles(nodes)

        #expect(cycles.isEmpty)
    }
}
