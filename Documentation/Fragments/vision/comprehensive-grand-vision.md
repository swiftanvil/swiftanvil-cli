# iFoundation Grand Vision

> A world-class, open-source Swift project scaffolding ecosystem designed for the LLM era.

## Mission

Empower Swift developers to create production-grade Apple platform projects with architectural discipline, inclusive design, and AI-native workflows — all from a single command.

## Philosophy

**"Convention through configuration, enforcement through automation."**

Every decision in iFoundation is:
- **Configurable**: Users choose what they want, not forced into opinions
- **Enforceable**: Standards are automated, not documented and hoped for
- **LLM-Native**: The entire ecosystem is designed for AI agent collaboration
- **Community-Driven**: Open source with clear contribution paths

---

## The Complete Feature Matrix

### Core Scaffolding (Always Included)

| Feature | Description | Configurable |
|---------|-------------|-------------|
| Project Structure | MVVM + I/O architecture | ✅ Template selection |
| Swift Package Manager | Modern SPM-based project | ✅ Or Xcode project |
| Git Setup | `.gitignore`, initial commit | ✅ Optional |
| README Generation | Project-specific README | ✅ Template-based |

### Type-Safe Shared Packages (Toggleable)

| Package | Purpose | Default | Enforcement |
|---------|---------|---------|-------------|
| **AppStrings** | Type-safe localization | ✅ On | SwiftLint + pre-commit |
| **A11yIdentifiers** | Type-safe accessibility IDs | ✅ On | SwiftLint + pre-commit |
| **AppRoutes** | Type-safe navigation/deep links | ⬜ Off | SwiftLint |
| **AnalyticsEvents** | Type-safe analytics tracking | ⬜ Off | SwiftLint |
| **FeatureFlags** | Type-safe feature toggles | ⬜ Off | SwiftLint |
| **AppNetworking** | Type-safe network layer (Moya-inspired) | ⬜ Off | SwiftLint |

### Data & Persistence (Toggleable)

| Feature | Purpose | Default | Notes |
|---------|---------|---------|-------|
| **SwiftData** | Modern persistence | ⬜ Off | iOS 17+ |
| **Core Data** | Classic persistence | ⬜ Off | Legacy support |
| **CloudKit** | Cloud synchronization | ⬜ Off | Requires entitlements |
| **Keychain** | Secure storage wrapper | ⬜ Off | Always useful |

### Development & Debugging (Toggleable)

| Feature | Purpose | Default | Notes |
|---------|---------|---------|-------|
| **DeveloperMenu** | In-app debug menu | ⬜ Off | Debug/TestFlight only |
| **BenchmarkKit** | Performance benchmarking | ⬜ Off | Based on Turnip pattern |
| **CrashReporting** | Crash analytics setup | ⬜ Off | Sentry/Crashlytics |
| **Logging** | Structured logging | ✅ On | OSLog + custom |

### Testing (Toggleable)

| Feature | Purpose | Default | Notes |
|---------|---------|---------|-------|
| **Unit Tests** | XCTest/Swift Testing | ✅ On | Always recommended |
| **UI Tests** | XCUITest with A11yIdentifiers | ✅ On | Uses shared package |
| **Snapshot Tests** | Visual regression | ⬜ Off | Pointfreeco lib |
| **Performance Tests** | XCTMetric benchmarks | ⬜ Off | CI regression gates |

### CI/CD (Configurable)

| Feature | Providers | Default | Notes |
|---------|-----------|---------|-------|
| **CI Workflows** | GitHub Actions, GitLab CI, Azure, Bitbucket | GitHub Actions | Self-hosted compatible |
| **Code Coverage** | Codecov, Coveralls | ⬜ Off | Threshold gates |
| **DocC Publishing** | GitHub Pages | ⬜ Off | Auto-publish on release |

### Documentation (Toggleable)

| Feature | Purpose | Default | Notes |
|---------|---------|---------|-------|
| **DocC Catalogs** | API documentation | ✅ On | Per module |
| **AI Context Tags** | `@ai-context`, `@ai-usage` | ✅ On | LLM guidance |
| **Registry System** | Composable documentation | ✅ On | Centralized |
| **AGENTS.md** | AI agent project context | ✅ On | Auto-generated |

### Intelligence (Toggleable)

| Feature | Purpose | Default | Notes |
|---------|---------|---------|-------|
| **Immunity System** | Self-improvement telemetry | ✅ On | Health monitoring |
| **Pre-commit Hooks** | Local enforcement | ✅ On | Fast checks |
| **SwiftLint Rules** | Style + custom rules | ✅ On | Accessibility, localization |
| **SwiftFormat** | Code formatting | ✅ On | Consistent style |

---

## Architecture Choices (Configurable)

### UI Framework
- SwiftUI (default)
- UIKit (for legacy/iPad-specific)
- Both (hybrid approach)

### Architecture Pattern
- MVVM + I/O (default)
- VIPER
- TCA (The Composable Architecture)
- Clean Architecture

### State Management
- `@Observable` (SwiftUI native)
- `@ObservableObject` + Combine
- The Composable Architecture (Pointfreeco)

### Dependency Injection
- Manual protocol-based (default)
- Swinject
- Factory (hmlongco)

### Networking
- URLSession + custom layer (default)
- Alamofire
- Moya-inspired (type-safe enum-based)

### Navigation
- SwiftUI NavigationStack (default)
- UIKit Coordinator pattern
- The Composable Architecture Navigation

---

## The Developer Menu (Debug/TestFlight Only)

Inspired by industry best practices, the Developer Menu is an in-app overlay (shake gesture or triple-tap) available only in Debug and TestFlight builds:

```swift
public struct DeveloperMenu {
    // Environment Info
    var buildConfiguration: String      // Debug / TestFlight / AppStore
    var appVersion: String
    var bundleIdentifier: String
    var deviceInfo: DeviceInfo

    // Feature Toggles
    var featureFlags: [FeatureFlag]     // All flags with on/off switches

    // Debugging Tools
    var networkInspector: NetworkInspector    // Request/response logging
    var cacheViewer: CacheViewer              // Browse cached data
    var userDefaultsEditor: UserDefaultsEditor // Edit UserDefaults
    var localizationTester: LocalizationTester // Switch languages live

    // Actions
    func clearCache()
    func resetOnboarding()
    func simulatePushNotification()
    func crashApp()                          // For crash reporting test
    func exportLogs()
}
```

### Build Configuration Detection

```swift
public enum Distribution: Sendable {
    case debug
    case testflight
    case appstore

    static var current: Self {
        #if APPSTORE
        return .appstore
        #elseif TESTFLIGHT
        return .testflight
        #else
        return .debug
        #endif
    }

    var isDeveloperBuild: Bool {
        self == .debug || self == .testflight
    }
}
```

---

## Benchmarking Infrastructure

Based on the Turnip iOS BenchmarkKit pattern and Apple's open-source Benchmark package:

### BenchmarkKit Package Structure

```swift
// Core benchmarking types
public struct BenchmarkConfiguration {
    var iterations: Int
    var warmupIterations: Int
    var metrics: [BenchmarkMetric]
}

public enum BenchmarkMetric {
    case cpuTime
    case wallClockTime
    case memoryAllocations
    case peakMemory
    case contextSwitches
}

// Usage in tests
struct ImageProcessingBenchmarks {
    @Test(.timed(threshold: .milliseconds(50), metric: .median))
    func resizeLargeImage() {
        let image = createLargeImage()
        _ = image.resized(to: CGSize(width: 100, height: 100))
    }
}
```

### CI Integration

```yaml
# Benchmark regression detection
- name: Run benchmarks
  run: swift package benchmark

- name: Compare with baseline
  run: swift package benchmark --compare main
```

---

## Networking Layer (AppNetworking Package)

Inspired by Moya's type-safe enum-based API definition:

```swift
// Define API as enum
public enum UserAPI {
    case getProfile(id: String)
    case updateProfile(id: String, name: String, email: String)
    case deleteAccount(id: String)
}

// Conform to TargetType (Moya-inspired)
extension UserAPI: NetworkTarget {
    public var baseURL: URL {
        URL(string: "https://api.example.com")!
    }

    public var path: String {
        switch self {
        case .getProfile(let id), .updateProfile(let id, _, _):
            return "/users/\(id)"
        case .deleteAccount(let id):
            return "/users/\(id)"
        }
    }

    public var method: HTTPMethod {
        switch self {
        case .getProfile: return .get
        case .updateProfile: return .put
        case .deleteAccount: return .delete
        }
    }

    public var task: NetworkTask {
        switch self {
        case .getProfile, .deleteAccount:
            return .requestPlain
        case .updateProfile(_, let name, let email):
            return .requestParameters(["name": name, "email": email])
        }
    }
}

// Usage
let provider = NetworkProvider<UserAPI>()
let profile = try await provider.request(.getProfile(id: "123"))
```

### Mocking for Tests

```swift
// Automatic mock generation
let mockProvider = NetworkProvider<UserAPI>(stubClosure: .immediate)
mockProvider.stub(.getProfile(id: "123"), with: .success(sampleProfile))
```

---

## Open Source Strategy

### Repository Structure

```
iFoundation/
├── Package.swift                    # Main CLI tool
├── Sources/
│   └── iFoundation/                 # CLI implementation
├── Templates/                       # Project templates
│   ├── ios-app/
│   ├── macos-app/
│   ├── swift-library/
│   └── shared/
│       ├── packages/                # Shared package templates
│       │   ├── AppStrings/
│       │   ├── A11yIdentifiers/
│       │   ├── AppNetworking/
│       │   ├── BenchmarkKit/
│       │   └── DeveloperMenu/
│       ├── ci-workflows/
│       ├── git-hooks/
│       └── lint-configs/
├── Documentation/                   # Composable docs
├── Tests/                           # Tool tests
├── CONTRIBUTING.md                  # Contribution guide
├── CODE_OF_CONDUCT.md              # Community standards
├── LICENSE                         # MIT License
└── .github/
    ├── ISSUE_TEMPLATE/             # Bug reports, features
    ├── PULL_REQUEST_TEMPLATE.md
    └── workflows/                  # CI for iFoundation itself
```

### Contribution Workflow

1. **Issue First**: All contributions start with an issue
2. **Discussion**: Community discussion on approach
3. **Draft PR**: Early feedback on direction
4. **Review**: Code + documentation + tests
5. **Merge**: Squash and merge with conventional commits

### Recognition

- **Contributors** section in README
- **All Contributors** bot for automated recognition
- **Release notes** credit contributors
- **Maintainer ladder** for long-term contributors

---

## Swift Scripting Strategy

All scripts in iFoundation are written in Swift (not shell) for:
- **Type safety**: Catch errors at compile time
- **IDE support**: Debug scripts in Xcode
- **Cross-platform**: Run on macOS and Linux
- **Maintainability**: One language for everything

### Script Structure

```swift
#!/usr/bin/swift
// scripts/check-localization.swift

import Foundation

struct LocalizationChecker {
    func run() async throws {
        let strings = try await collectAllStrings()
        let missing = try await findMissingTranslations(strings)
        
        if !missing.isEmpty {
            print("❌ Missing translations found:")
            for item in missing {
                print("  - \(item.key) in \(item.language)")
            }
            exit(1)
        }
        
        print("✅ All translations complete")
    }
}

try await LocalizationChecker().run()
```

### Script Runner

```bash
# Host-agnostic script execution
ifoundation run-script check-localization
ifoundation run-script accessibility-audit
ifoundation run-script benchmark-compare
```

---

## LLM Integration Roadmap

### Phase 1: Context-Rich Scaffolding (Current)
- AGENTS.md with project context
- DocC with `@ai-context` tags
- Structured, modular code

### Phase 2: Agent Instructions (Next)
```
.ai/
├── instructions/
│   ├── architecture.md       # How to structure code
│   ├── testing.md            # Testing requirements
│   └── documentation.md      # Doc standards
├── constraints/
│   ├── no-hardcoded-strings.md
│   ├── accessibility-required.md
│   └── protocol-oriented.md
└── examples/
    ├── good-viewmodel.swift
    └── good-service.swift
```

### Phase 3: Auto-Sync (Future)
- Code changes trigger doc updates
- AI suggests improvements based on immunity data
- Template updates propagate to existing projects

---

## Success Metrics

| Metric | Target | Measurement |
|--------|--------|-------------|
| GitHub Stars | 1,000+ | Community interest |
| Contributors | 50+ | Open source health |
| Time to scaffold | < 30s | Developer experience |
| Pre-commit pass rate | > 95% | Quality enforcement |
| CI build time (cached) | < 2min | Developer velocity |
| DocC coverage | > 90% | Documentation quality |
| Type-safe coverage | 100% | String literal elimination |

---

## Related Documents

- ADR-003: Localization as a Separate Package
- ADR-004: Accessibility Identifiers as a Separate Package
- ADR-005: DocC Documentation Strategy
- ADR-006: Pre-commit Enforcement Rules
- ADR-007: Package Catalog Architecture
- ADR-008: Configurable Wizard Design
- Pattern: Shared Type-Safe Packages
- Pattern: DocC for LLM Context Engineering
- Pattern: Networking Layer Design
- Pattern: Developer Menu Implementation
- Pattern: Benchmarking Infrastructure
