# ADR-008: Configurable Wizard Design

## Status
Accepted

## Context
Users have diverse needs. Some want a minimal setup, others want every feature. Some prefer MVVM, others prefer TCA. Enforcing a single approach alienates potential users.

## Decision
Design the wizard as a **configuration engine** where:
1. Every choice is stored in a typed configuration
2. Choices drive template selection and generation
3. New choices can be added without breaking existing ones
4. Configuration is persisted and editable post-creation

## Configuration Schema

```swift
/// Central configuration for project generation
struct ScaffoldConfiguration: Codable, Sendable {
    // MARK: - Project Identity
    var projectName: String
    var template: ProjectTemplate
    var minimumOSVersion: String
    
    // MARK: - UI Framework
    var uiFramework: UIFramework
    var architecturePattern: ArchitecturePattern
    var stateManagement: StateManagement
    
    // MARK: - Infrastructure Packages
    var packages: PackageConfiguration
    
    // MARK: - Data & Persistence
    var persistence: PersistenceConfiguration
    
    // MARK: - Development Tools
    var developmentTools: DevelopmentToolsConfiguration
    
    // MARK: - Testing
    var testing: TestingConfiguration
    
    // MARK: - CI/CD
    var ci: CIConfiguration
    
    // MARK: - Documentation
    var documentation: DocumentationConfiguration
}

// MARK: - Enums

enum ProjectTemplate: String, Codable, CaseIterable {
    case iosApp = "ios-app"
    case macosApp = "macos-app"
    case watchosApp = "watchos-app"
    case tvosApp = "tvos-app"
    case visionosApp = "visionos-app"
    case swiftLibrary = "swift-library"
    case swiftTool = "swift-tool"
    case swiftServer = "swift-server"
    case multiplatformApp = "multiplatform-app"
}

enum UIFramework: String, Codable, CaseIterable {
    case swiftUI = "swiftui"
    case uiKit = "uikit"
    case both = "both"
}

enum ArchitecturePattern: String, Codable, CaseIterable {
    case mvvmIO = "mvvm-io"
    case viper = "viper"
    case tca = "tca"
    case clean = "clean"
}

enum StateManagement: String, Codable, CaseIterable {
    case observable = "observable"           // @Observable (iOS 17+)
    case observableObject = "observable-object" // @ObservableObject
    case tca = "tca"                         // The Composable Architecture
}

enum DependencyInjection: String, Codable, CaseIterable {
    case manual = "manual"           // Protocol + init injection
    case swinject = "swinject"       // Swinject library
    case factory = "factory"         // hmlongco/Factory
}

enum NavigationPattern: String, Codable, CaseIterable {
    case navigationStack = "navigation-stack"
    case coordinator = "coordinator"
    case tca = "tca-navigation"
}

// MARK: - Package Configuration

struct PackageConfiguration: Codable, Sendable {
    var appStrings: Bool = true
    var a11yIdentifiers: Bool = true
    var appRoutes: Bool = false
    var analyticsEvents: Bool = false
    var featureFlags: Bool = false
    var appNetworking: Bool = false
}

// MARK: - Persistence Configuration

struct PersistenceConfiguration: Codable, Sendable {
    var swiftData: Bool = false
    var coreData: Bool = false
    var cloudKit: Bool = false
    var keychain: Bool = false
}

// MARK: - Development Tools Configuration

struct DevelopmentToolsConfiguration: Codable, Sendable {
    var developerMenu: Bool = false
    var benchmarkKit: Bool = false
    var crashReporting: Bool = false
    var logging: Bool = true
}

// MARK: - Testing Configuration

struct TestingConfiguration: Codable, Sendable {
    var unitTests: Bool = true
    var uiTests: Bool = true
    var snapshotTests: Bool = false
    var performanceTests: Bool = false
}

// MARK: - CI Configuration

struct CIConfiguration: Codable, Sendable {
    var provider: CIProvider = .githubActions
    var selfHosted: Bool = false
    var codeCoverage: Bool = false
    var doccPublish: Bool = false
}

enum CIProvider: String, Codable, CaseIterable {
    case githubActions = "github-actions"
    case gitlabCI = "gitlab-ci"
    case azureDevOps = "azure-devops"
    case bitbucket = "bitbucket"
    case local = "local"           // No CI, local scripts only
}

// MARK: - Documentation Configuration

struct DocumentationConfiguration: Codable, Sendable {
    var doccCatalogs: Bool = true
    var aiContextTags: Bool = true
    var registrySystem: Bool = true
    var agentsMD: Bool = true
}
```

## Wizard Flow

```
? Project name: MyApp

? Select template:
  ○ iOS App
  ○ macOS App
  ● Multiplatform App

? Minimum iOS version: 17.0

? UI Framework:
  ● SwiftUI
  ○ UIKit
  ○ Both

? Architecture Pattern:
  ● MVVM + I/O
  ○ VIPER
  ○ TCA (The Composable Architecture)
  ○ Clean Architecture

? State Management:
  ● @Observable (iOS 17+)
  ○ @ObservableObject + Combine
  ○ TCA

? Dependency Injection:
  ● Manual (Protocol-based)
  ○ Swinject
  ○ Factory

? Navigation:
  ● NavigationStack
  ○ Coordinator Pattern
  ○ TCA Navigation

? Infrastructure Packages:
  ☑ AppStrings (type-safe localization)
  ☑ A11yIdentifiers (type-safe accessibility)
  ☐ AppRoutes (type-safe navigation)
  ☐ AnalyticsEvents (type-safe analytics)
  ☐ FeatureFlags (type-safe feature toggles)
  ☐ AppNetworking (type-safe networking)

? Data & Persistence:
  ☐ SwiftData
  ☐ Core Data
  ☐ CloudKit
  ☐ Keychain

? Development Tools:
  ☐ Developer Menu (debug/TestFlight only)
  ☐ BenchmarkKit (performance testing)
  ☐ Crash Reporting
  ☑ Logging

? Testing:
  ☑ Unit Tests
  ☑ UI Tests
  ☐ Snapshot Tests
  ☐ Performance Tests

? CI/CD:
  Provider: ● GitHub Actions ○ GitLab CI ○ Azure ○ Bitbucket ○ None
  Self-hosted runners: ☐
  Code coverage: ☐
  DocC publishing: ☐

? Documentation:
  ☑ DocC catalogs
  ☑ AI context tags (@ai-context)
  ☑ Registry system
  ☑ AGENTS.md

Generating project...
✓ Package.swift
✓ Sources/ (with chosen architecture)
✓ Packages/AppStrings/
✓ Packages/A11yIdentifiers/
✓ Tests/
✓ CI workflows
✓ Documentation
✓ Pre-commit hooks

Project ready! Run: cd MyApp && ifoundation doctor
```

## Post-Creation Configuration

Users can modify choices after creation:

```bash
# Add a package to existing project
ifoundation add-package AppNetworking

# Remove a package
ifoundation remove-package DeveloperMenu

# Update configuration
ifoundation config --set architecture-pattern=tca

# Re-run wizard for existing project
ifoundation reconfigure --interactive
```

## Validation

```swift
struct ConfigurationValidator {
    func validate(_ config: ScaffoldConfiguration) -> [ValidationError] {
        var errors: [ValidationError] = []
        
        // TCA requires TCA state management
        if config.architecturePattern == .tca && config.stateManagement != .tca {
            errors.append(.incompatible("TCA architecture requires TCA state management"))
        }
        
        // CloudKit requires iOS 16+
        if config.persistence.cloudKit && config.minimumOSVersion < "16.0" {
            errors.append(.incompatible("CloudKit requires iOS 16.0+"))
        }
        
        // SwiftData requires iOS 17+
        if config.persistence.swiftData && config.minimumOSVersion < "17.0" {
            errors.append(.incompatible("SwiftData requires iOS 17.0+"))
        }
        
        return errors
    }
}
```

## Consequences

### Positive
- **Flexibility**: Users get exactly what they want
- **Future-proof**: New options added without breaking existing
- **Discoverability**: Wizard exposes all available features
- **Consistency**: All projects have same configuration format

### Negative
- **Complexity**: Many options to maintain
- **Testing**: Combinatorial explosion of configurations
- **Documentation**: Must document all options clearly

## Related
- ADR-007: Package Catalog Architecture
- Pattern: Modular Template System


