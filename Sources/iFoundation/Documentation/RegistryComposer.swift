// RegistryComposer.swift
// Composes documentation from centralized registry

import Foundation
import Yams

/// Composes documentation files from the registry
actor RegistryComposer {
    private let fileManager = FileManager.default

    /// Composes all or specific documents from the registry
    func compose(document: String?) async throws {
        let registry = try loadRegistry()

        if let docName = document {
            guard let doc = registry.documents[docName] else {
                throw RegistryError.documentNotFound(docName)
            }
            try await composeDocument(doc)
        } else {
            for (_, doc) in registry.documents {
                try await composeDocument(doc)
            }
        }
    }

    // MARK: - Private

    private func loadRegistry() throws -> DocumentationRegistry {
        let path = "Documentation/Registry/index.yml"
        let url = URL(fileURLWithPath: path)
        let data = try Data(contentsOf: url)
        return try YAMLDecoder().decode(DocumentationRegistry.self, from: data)
    }

    private func composeDocument(_ document: DocumentEntry) async throws {
        var content = ""

        for source in document.sources {
            let sourcePath = "Documentation/\(source)"
            let sourceURL = URL(fileURLWithPath: sourcePath)

            if fileManager.fileExists(atPath: sourcePath) {
                let sourceContent = try String(contentsOf: sourceURL, encoding: .utf8)
                content += sourceContent + "\n\n"
            }
        }

        let outputURL = URL(fileURLWithPath: document.path)

        // Create parent directories if needed
        let parentDir = outputURL.deletingLastPathComponent()
        try fileManager.createDirectory(at: parentDir, withIntermediateDirectories: true)

        try content.write(to: outputURL, atomically: true, encoding: .utf8)
    }
}

// MARK: - Models

struct DocumentationRegistry: Codable {
    let documents: [String: DocumentEntry]
}

struct DocumentEntry: Codable {
    let path: String
    let sources: [String]
}

enum RegistryError: Error {
    case documentNotFound(String)
    case invalidRegistry(String)
}
