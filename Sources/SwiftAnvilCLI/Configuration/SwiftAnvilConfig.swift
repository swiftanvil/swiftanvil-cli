// SwiftAnvilConfig.swift
// Runtime configuration loaded from .swiftanvil.yml

import Foundation
import Yams

/// Represents the complete `.swiftanvil.yml` configuration.
struct SwiftAnvilConfig: Codable {
    var lint: LintConfig = .init()
}

/// Lint-specific configuration.
struct LintConfig: Codable {
    var structure: LintStructureConfig = .init()
}

/// Structure lint thresholds.
struct LintStructureConfig: Codable {
    var maxLines: Int = 350
    var maxTopLevelTypes: Int = 4
    var mixedTypeKinds: Int = 3

    enum CodingKeys: String, CodingKey {
        case maxLines = "max_lines"
        case maxTopLevelTypes = "max_top_level_types"
        case mixedTypeKinds = "mixed_type_kinds"
    }
}

/// Loads and merges `.swiftanvil.yml` from a project directory.
enum SwiftAnvilConfigLoader {
    /// Loads config from `projectPath/.swiftanvil.yml`.
    /// Returns defaults if the file is missing or unreadable.
    static func load(from projectPath: String) -> SwiftAnvilConfig {
        let configPath = (projectPath as NSString).appendingPathComponent(".swiftanvil.yml")
        guard
            FileManager.default.fileExists(atPath: configPath),
            let data = try? Data(contentsOf: URL(fileURLWithPath: configPath)),
            let yamlString = String(data: data, encoding: .utf8)
        else {
            return SwiftAnvilConfig()
        }

        do {
            let decoder = YAMLDecoder()
            return try decoder.decode(SwiftAnvilConfig.self, from: yamlString)
        } catch {
            print("⚠️  Could not parse .swiftanvil.yml — using defaults. Error: \(error)")
            return SwiftAnvilConfig()
        }
    }
}
