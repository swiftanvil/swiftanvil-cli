// swiftlint:disable force_try
import Foundation
import Testing
@testable import SwiftAnvilCLI

struct NetworkTrafficInspectorTests {
    private func makeTempDir() -> String {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp.path
    }

    private func writeSource(at path: String, file: String, content: String) {
        let sourcesPath = (path as NSString).appendingPathComponent("Sources/App")
        try! FileManager.default.createDirectory(atPath: sourcesPath, withIntermediateDirectories: true)
        let filePath = (sourcesPath as NSString).appendingPathComponent(file)
        try! content.write(toFile: filePath, atomically: true, encoding: .utf8)
    }

    @Test func inspectDetectsHTTP() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        writeSource(at: path, file: "API.swift", content: """
        let url = URL(string: "http://example.com/api")!
        """)

        let inspector = NetworkTrafficInspector(path: path)
        let findings = try await inspector.inspect()
        let httpFindings = findings.filter { $0.message.contains("HTTP") }
        #expect(httpFindings.count == 1)
        #expect(httpFindings.first?.severity == .error)
    }

    @Test func inspectDetectsHardcodedURL() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        writeSource(at: path, file: "API.swift", content: """
        let baseURL = "https://api.myapp.com/v1"
        """)

        let inspector = NetworkTrafficInspector(path: path)
        let findings = try await inspector.inspect()
        let hardcodedFindings = findings.filter { $0.message.contains("Hardcoded") }
        #expect(hardcodedFindings.count == 1)
    }

    @Test func inspectIgnoresLocalhost() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        writeSource(at: path, file: "API.swift", content: """
        let baseURL = "https://localhost:8080"
        """)

        let inspector = NetworkTrafficInspector(path: path)
        let findings = try await inspector.inspect()
        let hardcodedFindings = findings.filter { $0.message.contains("Hardcoded") }
        #expect(hardcodedFindings.isEmpty)
    }
}
