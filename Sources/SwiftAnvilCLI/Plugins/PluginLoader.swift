import Foundation

/// Loads and registers plugins with error isolation.
///
/// Each plugin is instantiated and registered independently. If one plugin fails,
/// the error is logged and the remaining plugins continue loading.
public actor PluginLoader {
    private let registry: PluginRegistry
    private let configuration: PluginConfiguration

    /// Creates a new plugin loader for the given registry and configuration.
    public init(registry: PluginRegistry, configuration: PluginConfiguration) {
        self.registry = registry
        self.configuration = configuration
    }

    /// Loads a list of plugin instances into the registry.
    ///
    /// - Parameters:
    ///   - plugins: The plugin instances to load.
    ///   - logger: Optional logging closure for load events.
    /// - Returns: A summary of loaded and failed plugins.
    public func load(
        plugins: [any SwiftAnvilPlugin],
        logger: (@Sendable (String) async -> Void)? = nil
    ) async -> PluginLoadResult {
        var loaded: [String] = []
        var failed: [PluginLoadFailure] = []

        for plugin in plugins {
            let type = type(of: plugin)
            let id = type.identifier

            do {
                try await plugin.register(with: registry, configuration: configuration)
                loaded.append(id)
                await logger?("[PluginLoader] Loaded \(type.displayName) (\(id) v\(type.version))")
            } catch {
                failed.append(PluginLoadFailure(identifier: id, error: error))
                await logger?("[PluginLoader] Failed to load \(id): \(error)")
            }
        }

        return PluginLoadResult(loaded: loaded, failed: failed)
    }

    /// Loads plugins from their types (useful when plugins are compile-time dependencies).
    ///
    /// Plugins must have a parameterless init. Pass instances directly if your plugins
    /// require initialization arguments.
    public func load(
        pluginTypes: [any SwiftAnvilPlugin.Type],
        logger: (@Sendable (String) async -> Void)? = nil
    ) async -> PluginLoadResult {
        let plugins = pluginTypes.map { $0.init() }
        return await load(plugins: plugins, logger: logger)
    }
}

// MARK: - Load Result

/// Result of loading plugins.
public struct PluginLoadResult: Sendable {
    public let loaded: [String]
    public let failed: [PluginLoadFailure]

    public var allSucceeded: Bool {
        failed.isEmpty
    }

    public var allFailed: Bool {
        loaded.isEmpty && !failed.isEmpty
    }

    public init(loaded: [String], failed: [PluginLoadFailure]) {
        self.loaded = loaded
        self.failed = failed
    }
}

/// A plugin that failed to load.
public struct PluginLoadFailure: Sendable {
    public let identifier: String
    public let error: Error

    public init(identifier: String, error: Error) {
        self.identifier = identifier
        self.error = error
    }
}
