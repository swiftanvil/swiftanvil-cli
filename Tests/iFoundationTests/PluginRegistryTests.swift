import Foundation
import Testing
@testable import iFoundation

// MARK: - Mock Plugin Types

struct MockCommand: PluginCommand {
    let pluginIdentifier: String
    let name: String
    let description: String
    
    func run(arguments: [String]) async throws {
    }
}

struct MockGenerator: PluginGenerator {
    let pluginIdentifier: String
    let name: String
    let description: String
    
    func generate(projectName: String, options: [String: String]) async throws {
    }
}

struct MockFilter: PluginTemplateFilter {
    let pluginIdentifier: String
    let name: String
    
    func apply(_ value: String) -> String {
        value.uppercased()
    }
}

struct FailingPlugin: SwiftAnvilPlugin {
    static let identifier = "com.test.failing"
    static let displayName = "Failing Plugin"
    static let version = "1.0.0"
    
    init() {}
    
    func register(with registry: PluginRegistry, configuration: PluginConfiguration) async throws {
        throw TestError.registrationFailed
    }
}

enum TestError: Error {
    case registrationFailed
}

// MARK: - PluginRegistry Tests

@Suite("PluginRegistry")
struct PluginRegistryTests {
    
    @Test("registers a command")
    func registerCommand() async throws {
        let registry = PluginRegistry()
        let command = MockCommand(
            pluginIdentifier: "com.test.plugin",
            name: "hello",
            description: "Says hello"
        )
        try await registry.registerCommand(command)
        
        let commands = await registry.commands()
        #expect(commands.count == 1)
        #expect(await registry.command(id: "com.test.plugin:hello") != nil)
    }
    
    @Test("rejects duplicate command")
    func duplicateCommand() async {
        let registry = PluginRegistry()
        let command1 = MockCommand(
            pluginIdentifier: "com.test.plugin",
            name: "hello",
            description: "First"
        )
        let command2 = MockCommand(
            pluginIdentifier: "com.test.plugin",
            name: "hello",
            description: "Second"
        )
        
        do {
            try await registry.registerCommand(command1)
            try await registry.registerCommand(command2)
            #expect(Bool(false), "Should have thrown duplicate command error")
        } catch {
            #expect(error is PluginRegistryError)
        }
    }
    
    @Test("allows same command name from different plugins")
    func differentPluginsSameCommand() async throws {
        let registry = PluginRegistry()
        let command1 = MockCommand(
            pluginIdentifier: "com.test.plugin-a",
            name: "hello",
            description: "A"
        )
        let command2 = MockCommand(
            pluginIdentifier: "com.test.plugin-b",
            name: "hello",
            description: "B"
        )
        
        try await registry.registerCommand(command1)
        try await registry.registerCommand(command2)
        
        let commands = await registry.commands()
        #expect(commands.count == 2)
    }
    
    @Test("registers a generator")
    func registerGenerator() async throws {
        let registry = PluginRegistry()
        let generator = MockGenerator(
            pluginIdentifier: "com.test.plugin",
            name: "swiftui",
            description: "SwiftUI app"
        )
        try await registry.registerGenerator(generator)
        
        let generators = await registry.generators()
        #expect(generators.count == 1)
    }
    
    @Test("rejects duplicate generator")
    func duplicateGenerator() async {
        let registry = PluginRegistry()
        let gen1 = MockGenerator(pluginIdentifier: "com.test.plugin", name: "gen", description: "A")
        let gen2 = MockGenerator(pluginIdentifier: "com.test.plugin", name: "gen", description: "B")
        
        do {
            try await registry.registerGenerator(gen1)
            try await registry.registerGenerator(gen2)
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is PluginRegistryError)
        }
    }
    
    @Test("registers a template filter")
    func registerFilter() async throws {
        let registry = PluginRegistry()
        let filter = MockFilter(
            pluginIdentifier: "com.test.plugin",
            name: "uppercase"
        )
        try await registry.registerTemplateFilter(filter)
        
        let filters = await registry.filters()
        #expect(filters.count == 1)
    }
    
    @Test("rejects duplicate filter")
    func duplicateFilter() async {
        let registry = PluginRegistry()
        let f1 = MockFilter(pluginIdentifier: "com.test.plugin", name: "upper")
        let f2 = MockFilter(pluginIdentifier: "com.test.plugin", name: "upper")
        
        do {
            try await registry.registerTemplateFilter(f1)
            try await registry.registerTemplateFilter(f2)
            #expect(Bool(false), "Should have thrown")
        } catch {
            #expect(error is PluginRegistryError)
        }
    }
    
    @Test("registers hooks with priority ordering")
    func hookPriority() async throws {
        let registry = PluginRegistry()
        let orderBox = OrderBox()
        
        await registry.registerHook(
            .preGenerate,
            pluginIdentifier: "com.test.low",
            priority: .low
        ) { _ in
            await orderBox.append("low")
        }
        
        await registry.registerHook(
            .preGenerate,
            pluginIdentifier: "com.test.high",
            priority: .high
        ) { _ in
            await orderBox.append("high")
        }
        
        await registry.registerHook(
            .preGenerate,
            pluginIdentifier: "com.test.normal",
            priority: .normal
        ) { _ in
            await orderBox.append("normal")
        }
        
        let context = HookContext(
            projectName: "Test",
            projectPath: URL(fileURLWithPath: "/tmp/test"),
            generatorName: "default"
        )
        await registry.executeHooks(.preGenerate, context: context)
        
        let executionOrder = await orderBox.values
        #expect(executionOrder == ["high", "normal", "low"])
    }
    
    @Test("executes post-generate hooks")
    func postGenerateHooks() async throws {
        let registry = PluginRegistry()
        let flagBox = FlagBox()
        
        await registry.registerHook(
            .postGenerate,
            pluginIdentifier: "com.test.plugin",
            priority: .normal
        ) { _ in
            await flagBox.set()
        }
        
        let context = HookContext(
            projectName: "Test",
            projectPath: URL(fileURLWithPath: "/tmp/test"),
            generatorName: "default"
        )
        await registry.executeHooks(.postGenerate, context: context)
        
        #expect(await flagBox.isSet)
    }
    
    @Test("hook execution continues after one fails")
    func hookErrorIsolation() async throws {
        let registry = PluginRegistry()
        let flagBox = FlagBox()
        
        await registry.registerHook(
            .preGenerate,
            pluginIdentifier: "com.test.failing",
            priority: .high
        ) { _ in
            throw TestError.registrationFailed
        }
        
        await registry.registerHook(
            .preGenerate,
            pluginIdentifier: "com.test.good",
            priority: .normal
        ) { _ in
            await flagBox.set()
        }
        
        let context = HookContext(
            projectName: "Test",
            projectPath: URL(fileURLWithPath: "/tmp/test"),
            generatorName: "default"
        )
        await registry.executeHooks(.preGenerate, context: context)
        
        #expect(await flagBox.isSet)
    }
    
    @Test("returns empty arrays when no registrations")
    func emptyRegistry() async {
        let registry = PluginRegistry()
        #expect(await registry.commands().isEmpty)
        #expect(await registry.generators().isEmpty)
        #expect(await registry.filters().isEmpty)
        #expect(await registry.hooks(for: .preGenerate).isEmpty)
    }
}

// MARK: - PluginLoader Tests

@Suite("PluginLoader")
struct PluginLoaderTests {
    
    struct GoodPlugin: SwiftAnvilPlugin {
        static let identifier = "com.test.good"
        static let displayName = "Good Plugin"
        static let version = "1.0.0"
        
        init() {}
        
        func register(with registry: PluginRegistry, configuration: PluginConfiguration) async throws {
            let command = MockCommand(
                pluginIdentifier: Self.identifier,
                name: "hello",
                description: "Hello command"
            )
            try await registry.registerCommand(command)
        }
    }
    
    @Test("loads plugins successfully")
    func loadSuccess() async throws {
        let registry = PluginRegistry()
        let config = PluginConfiguration(workingDirectory: URL(fileURLWithPath: "/tmp"))
        let loader = PluginLoader(registry: registry, configuration: config)
        
        let result = await loader.load(plugins: [GoodPlugin()])
        
        #expect(result.loaded.count == 1)
        #expect(result.failed.isEmpty)
        #expect(result.allSucceeded)
        
        let commands = await registry.commands()
        #expect(commands.count == 1)
    }
    
    @Test("isolates failing plugins")
    func loadWithFailure() async throws {
        let registry = PluginRegistry()
        let config = PluginConfiguration(workingDirectory: URL(fileURLWithPath: "/tmp"))
        let loader = PluginLoader(registry: registry, configuration: config)
        
        let result = await loader.load(plugins: [GoodPlugin(), FailingPlugin()])
        
        #expect(result.loaded.count == 1)
        #expect(result.failed.count == 1)
        #expect(!result.allSucceeded)
        #expect(!result.allFailed)
        
        // Good plugin should still be registered
        let commands = await registry.commands()
        #expect(commands.count == 1)
    }
    
    @Test("load from types")
    func loadFromTypes() async throws {
        let registry = PluginRegistry()
        let config = PluginConfiguration(workingDirectory: URL(fileURLWithPath: "/tmp"))
        let loader = PluginLoader(registry: registry, configuration: config)
        
        let result = await loader.load(pluginTypes: [GoodPlugin.self])
        
        #expect(result.loaded.count == 1)
        #expect(result.allSucceeded)
    }
    
    @Test("logs load events")
    func loadLogging() async throws {
        let registry = PluginRegistry()
        let config = PluginConfiguration(workingDirectory: URL(fileURLWithPath: "/tmp"))
        let loader = PluginLoader(registry: registry, configuration: config)
        
        let logBox = LogBox()
        let result = await loader.load(plugins: [GoodPlugin()]) { log in
            await logBox.append(log)
        }
        
        #expect(result.allSucceeded)
        let logs = await logBox.values
        #expect(!logs.isEmpty)
        #expect(logs.contains(where: { $0.contains("Loaded") }))
    }
    
    @Test("logs failures")
    func failureLogging() async throws {
        let registry = PluginRegistry()
        let config = PluginConfiguration(workingDirectory: URL(fileURLWithPath: "/tmp"))
        let loader = PluginLoader(registry: registry, configuration: config)
        
        let logBox = LogBox()
        let result = await loader.load(plugins: [FailingPlugin()]) { log in
            await logBox.append(log)
        }
        
        #expect(!result.allSucceeded)
        let logs = await logBox.values
        #expect(logs.contains(where: { $0.contains("Failed") }))
    }
}

// MARK: - Helpers

/// Thread-safe log collector for testing.
actor LogBox {
    private var logs: [String] = []
    
    func append(_ log: String) {
        logs.append(log)
    }
    
    var values: [String] { logs }
}

/// Thread-safe order tracker for testing.
actor OrderBox {
    private var items: [String] = []
    
    func append(_ item: String) {
        items.append(item)
    }
    
    var values: [String] { items }
}

/// Thread-safe flag for testing.
actor FlagBox {
    private var flag = false
    
    func set() {
        flag = true
    }
    
    var isSet: Bool { flag }
}
