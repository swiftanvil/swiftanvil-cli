// ProjectConfig.swift
// Centralized project configuration model

import Foundation

/// Represents the complete configuration for a new project
struct ProjectConfig: Codable, Sendable {
    let template: String
    let projectName: String
    let options: [String: ConfigValue]

    // Common options
    var minimumOSVersion: String? { options["minimumOSVersion"]?.stringValue }
    var useSwiftUI: Bool { options["useSwiftUI"]?.boolValue ?? true }
    var useCoreData: Bool { options["useCoreData"]?.boolValue ?? false }
    var useCloudKit: Bool { options["useCloudKit"]?.boolValue ?? false }
    var enableAccessibility: Bool { options["enableAccessibility"]?.boolValue ?? true }
    var enableLocalization: Bool { options["enableLocalization"]?.boolValue ?? true }
    var targetLanguages: [String] { options["targetLanguages"]?.stringArray ?? ["en"] }
    var includeUnitTests: Bool { options["includeUnitTests"]?.boolValue ?? true }
    var includeUITests: Bool { options["includeUITests"]?.boolValue ?? true }
    var includeSnapshotTests: Bool { options["includeSnapshotTests"]?.boolValue ?? false }
    var includePerformanceTests: Bool { options["includePerformanceTests"]?.boolValue ?? false }
    var ciProvider: String { options["ciProvider"]?.stringValue ?? "github-actions" }
    var useSelfHostedRunners: Bool { options["useSelfHostedRunners"]?.boolValue ?? false }
    var enableImmunity: Bool { options["enableImmunity"]?.boolValue ?? true }
}

/// Type-safe configuration values
enum ConfigValue: Codable, Sendable {
    case string(String)
    case bool(Bool)
    case int(Int)
    case stringArray([String])

    var stringValue: String? {
        if case .string(let value) = self { return value }
        return nil
    }

    var boolValue: Bool? {
        if case .bool(let value) = self { return value }
        return nil
    }

    var intValue: Int? {
        if case .int(let value) = self { return value }
        return nil
    }

    var stringArray: [String]? {
        if case .stringArray(let value) = self { return value }
        return nil
    }
}
