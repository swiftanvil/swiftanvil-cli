import Foundation

// MARK: - Core Protocol

/// A plugin that extends swiftanvil CLI capabilities.
public protocol SwiftAnvilPlugin: Sendable {
    /// Unique plugin identifier (reverse-DNS style).
    static var identifier: String { get }

    /// Human-readable name.
    static var displayName: String { get }

    /// Plugin version.
    static var version: String { get }

    /// Called during CLI startup to register commands, generators, filters, and hooks.
    func register(with registry: PluginRegistry, configuration: PluginConfiguration) async throws

    /// Creates a new instance of the plugin.
    init()
}

// MARK: - Configuration

/// Configuration passed to plugins during registration.
public struct PluginConfiguration: Sendable {
    public let workingDirectory: URL

    public init(workingDirectory: URL) {
        self.workingDirectory = workingDirectory
    }
}

// MARK: - Command Protocol

/// A command registered by a plugin.
public protocol PluginCommand: Sendable {
    /// The plugin identifier that registered this command.
    var pluginIdentifier: String { get }
    /// Command name (unique within the plugin).
    var name: String { get }
    var description: String { get }
    func run(arguments: [String]) async throws
}

// MARK: - Generator Protocol

/// A generator registered by a plugin.
public protocol PluginGenerator: Sendable {
    /// The plugin identifier that registered this generator.
    var pluginIdentifier: String { get }
    /// Generator name (unique within the plugin).
    var name: String { get }
    var description: String { get }
    func generate(projectName: String, options: [String: String]) async throws
}

// MARK: - Template Filter Protocol

/// A template filter registered by a plugin.
public protocol PluginTemplateFilter: Sendable {
    /// The plugin identifier that registered this filter.
    var pluginIdentifier: String { get }
    /// Filter name (unique within the plugin).
    var name: String { get }
    func apply(_ value: String) -> String
}

// MARK: - Lifecycle Hooks

/// Lifecycle hook types.
public enum LifecycleHook: Sendable, CaseIterable {
    case preGenerate
    case postGenerate
}

/// Context passed to lifecycle hooks.
public struct HookContext: Sendable {
    public let projectName: String
    public let projectPath: URL
    public let generatorName: String

    public init(projectName: String, projectPath: URL, generatorName: String) {
        self.projectName = projectName
        self.projectPath = projectPath
        self.generatorName = generatorName
    }
}

/// Priority for hook execution order.
public enum HookPriority: Int, Sendable, Comparable {
    case low = 0
    case normal = 1
    case high = 2

    public static func < (lhs: HookPriority, rhs: HookPriority) -> Bool {
        lhs.rawValue < rhs.rawValue
    }
}

/// A stored hook entry.
public struct HookEntry: Sendable {
    public let pluginIdentifier: String
    public let priority: HookPriority
    public let action: @Sendable (HookContext) async throws -> Void

    public init(
        pluginIdentifier: String,
        priority: HookPriority,
        action: @Sendable @escaping (HookContext) async throws -> Void
    ) {
        self.pluginIdentifier = pluginIdentifier
        self.priority = priority
        self.action = action
    }
}

// MARK: - Registry Errors

public enum PluginRegistryError: Error, Sendable, Equatable {
    case duplicateCommand(plugin: String, name: String)
    case duplicateGenerator(plugin: String, name: String)
    case duplicateFilter(plugin: String, name: String)
    case duplicateHook(plugin: String, hook: LifecycleHook)
}
