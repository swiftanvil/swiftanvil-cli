// swiftlint:disable force_try
import Foundation
import Testing
@testable import SwiftAnvilCLI

struct LoggingAuditorTests {
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

    @Test func auditDetectsPrint() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        writeSource(at: path, file: "Logger.swift", content: """
        func log() {
            print("hello")
        }
        """)

        let auditor = LoggingAuditor(path: path)
        let findings = try await auditor.audit()
        #expect(findings.count == 1)
        #expect(findings.first?.message.contains("print()") == true)
    }

    @Test func auditDetectsNSLog() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        writeSource(at: path, file: "Logger.swift", content: """
        func log() {
            NSLog("hello")
        }
        """)

        let auditor = LoggingAuditor(path: path)
        let findings = try await auditor.audit()
        let nslogFindings = findings.filter { $0.message.contains("NSLog") }
        #expect(nslogFindings.count == 1)
    }

    @Test func auditIgnoresComments() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        writeSource(at: path, file: "Logger.swift", content: """
        // print("commented out")
        func log() {
            debugPrint("ok")
        }
        """)

        let auditor = LoggingAuditor(path: path)
        let findings = try await auditor.audit()
        let printFindings = findings.filter { $0.message.contains("print()") }
        #expect(printFindings.isEmpty)
    }
}
