// PathResolver.swift
// Host-agnostic path resolution

import Foundation

/// Resolves paths in a host-agnostic manner
enum PathResolver {
    /// Returns the user's home directory in a cross-platform way
    static var homeDirectory: String {
        #if os(macOS) || os(iOS)
        return NSHomeDirectory()
        #else
        if let home = ProcessInfo.processInfo.environment["HOME"] {
            return home
        }
        return "/tmp"
        #endif
    }

    /// Resolves a path relative to the current working directory
    static func resolve(_ path: String, relativeTo base: String? = nil) -> String {
        let basePath = base ?? FileManager.default.currentDirectoryPath

        if path.hasPrefix("~") {
            return path.replacingOccurrences(of: "~", with: homeDirectory)
        }

        if path.hasPrefix("/") {
            return path
        }

        return "\(basePath)/\(path)"
    }

    /// Returns a centralized cache directory for the tool
    static var cacheDirectory: String {
        let cachePath = "\(homeDirectory)/.swiftanvil/cache"
        try? FileManager.default.createDirectory(
            atPath: cachePath,
            withIntermediateDirectories: true
        )
        return cachePath
    }

    /// Returns a centralized temporary directory
    static var temporaryDirectory: String {
        let tempPath = "\(homeDirectory)/.swiftanvil/tmp"
        try? FileManager.default.createDirectory(
            atPath: tempPath,
            withIntermediateDirectories: true
        )
        return tempPath
    }
}
