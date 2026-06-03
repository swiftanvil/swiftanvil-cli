---
author: kimi-cli
hostVersion: k1.6
artifactKind: plan-artifact
schemaVersion: "1.0"
chainId: phase-2-core-packages
taskId: child-2.3-developer-menu
producedBy: kimi-cli
contextBudget: "12000"
createdAt: 2026-06-03T06:15:00Z
---

# Child 2.3: Developer Menu Package — Plan

## Goal

Build an in-app debug menu for development builds. Provides runtime inspection and manipulation of app state: feature flags, network requests, accessibility IDs, benchmark data, and custom debug actions. Stripped from release builds via compiler flags.

## Non-Goals

- Production crash reporting — out of scope (use Sentry/Crashlytics)
- Remote debugging / WebSocket inspector — deferred to Phase 3
- Memory graph / leak detection — deferred
- Core Data inspection — deferred
- Network request interception/modification — read-only for 2.3

## Naming

| Context | Name |
|---------|------|
| Repo | `swiftanvil-anvil-devmenu` |
| Swift Package | `AnvilDevMenu` |
| Module import | `import AnvilDevMenu` |
| Product | `.product(name: "AnvilDevMenu", package: "swiftanvil-anvil-devmenu")` |

## Platform Strategy

**SwiftUI-first, UIKit wrapper.** The menu is a SwiftUI view hierarchy. For UIKit apps, we provide a `UIViewController` wrapper.

**Compile-time stripping:** The entire package is wrapped in `#if DEBUG` at the call site. The package itself builds for all configurations, but the entry point is guarded.

```swift
#if DEBUG
import AnvilDevMenu

@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .overlay(DeveloperMenuGestureOverlay())
        }
    }
}
#endif
```

## Concurrency Model

The menu UI is `@MainActor`. Data collection (network logs, flag reads) happens on background actors. The bridge uses `@preconcurrency` or `MainActor.run` for UI updates.

## Public API Surface

### Entry Point

```swift
#if DEBUG
import AnvilDevMenu

// Option 1: Gesture trigger (triple-tap)
ContentView()
    .developerMenuOverlay()

// Option 2: Programmatic
DeveloperMenu.present()

// Option 3: Shake gesture
ContentView()
    .developerMenuOnShake()
#endif
```

### Configuration

```swift
#if DEBUG
DeveloperMenu.configure(
    featureFlags: FeatureFlags.self,      // AnvilFlags integration
    networkClient: HTTPClient.self,        // AnvilNetwork integration
    a11yIDs: A11yID.self,                 // A11yIdentifiers integration
    benchmarks: BenchmarkKit.self          // BenchmarkKit integration
)
#endif
```

### Custom Actions

```swift
#if DEBUG
DeveloperMenu.addAction(
    name: "Clear Cache",
    icon: "trash",
    action: { await Cache.shared.clear() }
)
#endif
```

### Menu Screens

```swift
// Built-in screens (auto-populated if integrations configured)
DeveloperMenu.Screens.featureFlags    // Toggle flags, view sources
DeveloperMenu.Screens.network        // View recent requests/responses
DeveloperMenu.Screens.a11y           // List all a11y IDs in view hierarchy
DeveloperMenu.Screens.benchmarks     // Run benchmarks, view history
DeveloperMenu.Screens.deviceInfo     // OS version, memory, disk
DeveloperMenu.Screens.console        // In-app log viewer
DeveloperMenu.Screens.customActions  // User-defined actions
```

## Architecture

```
AnvilDevMenu
├── DeveloperMenu.swift           # Public API + configuration
├── EntryPoints/
│   ├── GestureOverlay.swift      # Triple-tap overlay (SwiftUI)
│   ├── ShakeGesture.swift        # Shake-to-open
│   └── UIKitWrapper.swift        # UIViewController presentation
├── Screens/
│   ├── FeatureFlagsScreen.swift  # Toggle flags, view values
│   ├── NetworkScreen.swift       # Request/response log
│   ├── A11yScreen.swift          # A11y ID inspector
│   ├── BenchmarkScreen.swift     # Benchmark runner UI
│   ├── DeviceInfoScreen.swift    # System info
│   ├── ConsoleScreen.swift       # Log viewer
│   └── CustomActionsScreen.swift # User-defined actions
├── Data/
│   ├── NetworkLogger.swift       # Captures AnvilNetwork traffic
│   ├── FlagObserver.swift        # Observes AnvilFlags changes
│   └── LogCollector.swift        # os_log / print capture
├── Models/
│   ├── MenuItem.swift            # Menu item model
│   ├── NetworkLogEntry.swift     # Network request model
│   └── DeviceInfo.swift          # Device info model
└── Utilities/
    ├── ViewHierarchyScanner.swift  // Extract a11y IDs from views
    └── MemoryFormatter.swift       // Byte → human-readable
```

## Integration Design

### AnvilFlags Integration

```swift
// In AnvilDevMenu, if AnvilFlags is available
#if canImport(AnvilFlags)
import AnvilFlags

struct FeatureFlagsScreen: View {
    @State private var flags: [FeatureFlagKey: FeatureFlagValue] = [:]
    
    var body: some View {
        List(flags.keys.sorted(), id: \.self) { key in
            HStack {
                Text(key.rawValue)
                Spacer()
                Toggle("", isOn: binding(for: key))
            }
        }
        .task { flags = await FeatureFlags.allFlags() }
    }
}
#endif
```

### AnvilNetwork Integration

```swift
// NetworkLogger interceptor that feeds the dev menu
#if canImport(AnvilNetwork)
import AnvilNetwork

public struct DevMenuNetworkLogger: ResponseInterceptor {
    public func intercept(_ response: HTTPResponse, for request: HTTPRequest) async throws -> HTTPResponse {
        await NetworkLogStore.shared.append(request: request, response: response)
        return response
    }
}
#endif
```

### A11yIdentifiers Integration

```swift
// Scan view hierarchy for A11yID values
#if canImport(AnvilA11y)
import AnvilA11y

func scanA11yIDs(in view: UIView) -> [A11yID] {
    // Traverse view hierarchy, collect accessibilityIdentifiers
}
#endif
```

### BenchmarkKit Integration

```swift
// Run benchmarks from the menu
#if canImport(AnvilBench)
import AnvilBench

struct BenchmarkScreen: View {
    var body: some View {
        Button("Run All Benchmarks") {
            BenchmarkRunner.shared.runAll()
        }
    }
}
#endif
```

## Task Breakdown

| # | Task | Effort | Verification |
|---|------|--------|--------------|
| 1 | Design PublicAPI + screen hierarchy | 1h | Cross-host review |
| 2 | Implement DeveloperMenu configuration + entry points | 1h | Gesture overlay works, shake works |
| 3 | Implement FeatureFlagsScreen | 1h | Toggles flags, shows values |
| 4 | Implement NetworkScreen + NetworkLogStore | 1.5h | Captures requests, shows history |
| 5 | Implement DeviceInfoScreen + ConsoleScreen | 1h | Shows system info, logs |
| 6 | Implement CustomActionsScreen | 30m | Runs user-defined actions |
| 7 | Implement AnvilFlags integration (optional import) | 1h | `#if canImport(AnvilFlags)` |
| 8 | Implement AnvilNetwork integration (optional import) | 1h | ResponseInterceptor feeds log store |
| 9 | Implement A11y + Benchmark integration stubs | 1h | `#if canImport` guards, graceful fallback |
| 10 | Write tests (unit + UI snapshot) | 1.5h | Screens render, actions fire |
| 11 | Write README + integration guide | 30m | Clear setup instructions |
| 12 | Cross-host review | 1h | All criteria pass |

**Total: ~12h**

## Compile-Time Stripping

The package is designed to be completely stripped from release builds:

**1. Call-site `#if DEBUG`:**
```swift
#if DEBUG
import AnvilDevMenu
#endif

struct ContentView: View {
    var body: some View {
        Text("Hello")
            #if DEBUG
            .developerMenuOverlay()
            #endif
    }
}
```

**2. Swift Package conditional dependency:**
```swift
// Package.swift
targets: [
    .target(name: "MyApp", dependencies: [
        .product(name: "AnvilDevMenu", package: "swiftanvil-anvil-devmenu"),
    ], swiftSettings: [.define("DEBUG", .when(configuration: .debug))])
]
```

**3. Dead code elimination:** Swift compiler strips unused symbols. Since no DEBUG code references AnvilDevMenu in release, the linker removes it entirely.

## Network Log Store

```swift
@MainActor
final class NetworkLogStore: ObservableObject {
    static let shared = NetworkLogStore()
    @Published private(set) var entries: [NetworkLogEntry] = []
    private let maxEntries = 100
    
    func append(request: HTTPRequest, response: HTTPResponse) {
        let entry = NetworkLogEntry(
            timestamp: Date(),
            method: request.method.rawValue,
            url: request.url.absoluteString,
            statusCode: response.statusCode,
            requestBody: request.body?.encoded(),
            responseBody: response.body
        )
        entries.append(entry)
        if entries.count > maxEntries {
            entries.removeFirst()
        }
    }
    
    func clear() {
        entries.removeAll()
    }
}
```

## Device Info

```swift
struct DeviceInfo: Sendable {
    let osVersion: String
    let deviceModel: String
    let appVersion: String
    let buildNumber: String
    let memoryUsed: UInt64
    let memoryTotal: UInt64
    let diskFree: UInt64
    let diskTotal: UInt64
}
```

## Custom Actions

```swift
public struct CustomAction: Sendable {
    public let id: UUID
    public let name: String
    public let icon: String
    public let action: @Sendable () async -> Void
}

public actor CustomActionRegistry {
    private var actions: [CustomAction] = []
    
    func register(_ action: CustomAction) {
        actions.append(action)
    }
    
    func allActions() -> [CustomAction] {
        actions
    }
}
```

## Assurance Strategy

| Lens | Selected | Coverage |
|------|----------|----------|
| Planning | Screen hierarchy, integration points, stripping strategy | This plan |
| Implementation | SwiftUI correctness, @MainActor safety, optional imports | UI renders, no crashes |
| Test | Unit (models), UI (screens render), integration (optional imports) | Snapshot tests |
| Review | Exhaustive critique | Cross-host pre-impl and post-impl |

## Success Criteria

- [ ] Package builds with `swift build`
- [ ] Tests pass with `swift test`
- [ ] Menu opens via triple-tap gesture
- [ ] Menu opens via shake gesture
- [ ] FeatureFlags screen toggles flags (if AnvilFlags available)
- [ ] Network screen shows requests (if AnvilNetwork available)
- [ ] README with integration guide
- [ ] Swift 6 + StrictConcurrency
- [ ] Cross-host review approved

## Output

New repo: `github.com/swiftanvil/swiftanvil-anvil-devmenu`
