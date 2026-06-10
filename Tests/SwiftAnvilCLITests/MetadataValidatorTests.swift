// swiftlint:disable force_try
import Foundation
import Testing
@testable import SwiftAnvilCLI

struct MetadataValidatorTests {
    private func makeTempDir() -> String {
        let temp = FileManager.default.temporaryDirectory
            .appendingPathComponent(UUID().uuidString)
        try! FileManager.default.createDirectory(at: temp, withIntermediateDirectories: true)
        return temp.path
    }

    @Test func validateWarnsOnMissingInfoPlist() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let validator = MetadataValidator(path: path)
        let findings = try await validator.validate()
        let infoPlistFindings = findings.filter { $0.category == "infoplist" }
        #expect(infoPlistFindings.count == 1)
        #expect(infoPlistFindings.first?.severity == .warning)
    }

    @Test func validateDetectsMissingPrivacyManifest() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let validator = MetadataValidator(path: path)
        let findings = try await validator.validate()
        let privacyFindings = findings.filter { $0.category == "privacy" }
        #expect(privacyFindings.count == 1)
        #expect(privacyFindings.first?.severity == .warning)
    }

    @Test func validateChecksInfoPlistKeys() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let plist: [String: Any] = [
            "CFBundleIdentifier": "com.test.app",
            "CFBundleVersion": "1",
            "CFBundleShortVersionString": "1.0.0",
            "CFBundleName": "TestApp"
        ]
        let plistPath = (path as NSString).appendingPathComponent("Info.plist")
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: URL(fileURLWithPath: plistPath))

        let validator = MetadataValidator(path: path)
        let findings = try await validator.validate()
        let infoPlistFindings = findings.filter { $0.category == "infoplist" }
        #expect(infoPlistFindings.isEmpty)
    }

    @Test func validateDetectsInvalidBundleID() async throws {
        let path = makeTempDir()
        defer { try? FileManager.default.removeItem(atPath: path) }

        let plist: [String: Any] = [
            "CFBundleIdentifier": " invalid id ",
            "CFBundleVersion": "1",
            "CFBundleShortVersionString": "1.0.0",
            "CFBundleName": "TestApp"
        ]
        let plistPath = (path as NSString).appendingPathComponent("Info.plist")
        let data = try PropertyListSerialization.data(fromPropertyList: plist, format: .xml, options: 0)
        try data.write(to: URL(fileURLWithPath: plistPath))

        let validator = MetadataValidator(path: path)
        let findings = try await validator.validate()
        let invalidID = findings.contains {
            $0.message.contains("Invalid CFBundleIdentifier")
        }
        #expect(invalidID)
    }
}
