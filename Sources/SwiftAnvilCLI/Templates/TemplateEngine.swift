// TemplateEngine.swift
// Host-agnostic template rendering engine

import Foundation
import Stencil
import PathKit

/// Renders templates with project configuration context
actor TemplateEngine {
    private let environment: Environment

    init() {
        let fm = FileManager.default
        let currentPath = fm.currentDirectoryPath

        let possiblePaths = [
            currentPath + "/Templates",
            currentPath + "/../Templates",
            currentPath + "/../../Templates",
        ]

        let templatePaths: [Path] = possiblePaths
            .filter { fm.fileExists(atPath: $0) }
            .map { Path($0) }

        self.environment = Environment(loader: FileSystemLoader(paths: templatePaths))
    }

    /// Renders a single template file
    func render(template: String, context: some Encodable) async throws -> String {
        let dict = try context.toDictionary()
        return try environment.renderTemplate(name: template, context: dict)
    }

    /// Renders a complete template set for a project type
    func renderTemplateSet(template: String, config: ProjectConfig) async throws -> [(String, String)] {
        let fm = FileManager.default
        let manifestPath = "\(fm.currentDirectoryPath)/Templates/\(template)/manifest.yml"

        guard fm.fileExists(atPath: manifestPath) else {
            throw GenerationError.templateNotFound(template)
        }

        // Parse manifest and render each file
        return []
    }
}

// MARK: - Encodable to Dictionary Conversion

extension Encodable {
    func toDictionary() throws -> [String: Any] {
        let data = try JSONEncoder().encode(self)
        let json = try JSONSerialization.jsonObject(with: data)
        guard let dict = json as? [String: Any] else {
            throw TemplateError.encodingFailed
        }
        return dict
    }
}

enum TemplateError: Error {
    case encodingFailed
    case templateNotFound(String)
}
