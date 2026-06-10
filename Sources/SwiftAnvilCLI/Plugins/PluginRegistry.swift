import Foundation

/// Registry that plugins use to hook into the CLI.
///
/// All registration methods are actor-isolated and enforce uniqueness constraints.
public actor PluginRegistry {
    private var commandsByID: [String: any PluginCommand] = [:]
    private var generatorsByID: [String: any PluginGenerator] = [:]
    private var filtersByID: [String: any PluginTemplateFilter] = [:]
    private var hooksByType: [LifecycleHook: [HookEntry]] = [:]

    /// Creates an empty plugin registry.
    public init() { }

    // MARK: - Registration

    /// Registers a plugin command.
    ///
    /// - Throws: `PluginRegistryError.duplicateCommand` if a command with the same
    ///   plugin identifier and name already exists.
    public func registerCommand(_ command: any PluginCommand) throws {
        let id = "\(command.pluginIdentifier):\(command.name)"
        guard commandsByID[id] == nil else {
            throw PluginRegistryError.duplicateCommand(
                plugin: command.pluginIdentifier,
                name: command.name
            )
        }
        commandsByID[id] = command
    }

    /// Registers a plugin generator.
    ///
    /// - Throws: `PluginRegistryError.duplicateGenerator` if a generator with the same
    ///   plugin identifier and name already exists.
    public func registerGenerator(_ generator: any PluginGenerator) throws {
        let id = "\(generator.pluginIdentifier):\(generator.name)"
        guard generatorsByID[id] == nil else {
            throw PluginRegistryError.duplicateGenerator(
                plugin: generator.pluginIdentifier,
                name: generator.name
            )
        }
        generatorsByID[id] = generator
    }

    /// Registers a template filter.
    ///
    /// - Throws: `PluginRegistryError.duplicateFilter` if a filter with the same
    ///   plugin identifier and name already exists.
    public func registerTemplateFilter(_ filter: any PluginTemplateFilter) throws {
        let id = "\(filter.pluginIdentifier):\(filter.name)"
        guard filtersByID[id] == nil else {
            throw PluginRegistryError.duplicateFilter(
                plugin: filter.pluginIdentifier,
                name: filter.name
            )
        }
        filtersByID[id] = filter
    }

    /// Registers a lifecycle hook.
    ///
    /// - Parameters:
    ///   - hook: The lifecycle hook type.
    ///   - pluginIdentifier: The plugin registering the hook.
    ///   - priority: Execution priority (higher runs first).
    ///   - action: The hook action to execute.
    public func registerHook(
        _ hook: LifecycleHook,
        pluginIdentifier: String,
        priority: HookPriority = .normal,
        action: @Sendable @escaping (HookContext) async throws -> Void
    ) {
        let entry = HookEntry(
            pluginIdentifier: pluginIdentifier,
            priority: priority,
            action: action
        )
        hooksByType[hook, default: []].append(entry)
    }

    // MARK: - Queries

    /// Returns all registered commands.
    public func commands() -> [any PluginCommand] {
        Array(commandsByID.values)
    }

    /// Returns all registered generators.
    public func generators() -> [any PluginGenerator] {
        Array(generatorsByID.values)
    }

    /// Returns all registered template filters.
    public func filters() -> [any PluginTemplateFilter] {
        Array(filtersByID.values)
    }

    /// Returns hooks for the given lifecycle type, sorted by priority (highest first).
    public func hooks(for hook: LifecycleHook) -> [HookEntry] {
        hooksByType[hook, default: []].sorted { $0.priority > $1.priority }
    }

    /// Returns a command by its namespaced ID.
    public func command(id: String) -> (any PluginCommand)? {
        commandsByID[id]
    }

    /// Returns a generator by its namespaced ID.
    public func generator(id: String) -> (any PluginGenerator)? {
        generatorsByID[id]
    }

    /// Returns a filter by its namespaced ID.
    public func filter(id: String) -> (any PluginTemplateFilter)? {
        filtersByID[id]
    }

    // MARK: - Execution

    /// Executes all hooks of the given type with the provided context.
    /// Hooks run sequentially in priority order (highest first).
    /// If a hook throws, the error is logged and remaining hooks continue.
    public func executeHooks(_ hook: LifecycleHook, context: HookContext) async {
        let entries = hooks(for: hook)
        for entry in entries {
            do {
                try await entry.action(context)
            } catch {
                print("[Plugin: \(entry.pluginIdentifier)] Hook \(hook) failed: \(error)")
            }
        }
    }
}
