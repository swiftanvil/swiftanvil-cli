---
author: kimi-cli
hostVersion: k1.6
artifactKind: plan-artifact
schemaVersion: "1.0"
chainId: phase-2-core-packages
taskId: child-2.2-featureflags
producedBy: kimi-cli
contextBudget: "12000"
createdAt: 2026-06-03T06:00:00Z
revisedAt: 2026-06-03T06:05:00Z
---

# Child 2.2: FeatureFlags Package — Plan (Revised v2)

## Goal

Build a type-safe, extensible feature flag system for Swift. Supports local flags (compile-time + JSON), remote flag providers (pluggable), and A/B test bucketing. Sets the pattern for configuration-driven behavior in SwiftAnvil apps.

## Non-Goals

- Real-time remote flag syncing (polling/WebSocket) — deferred to Phase 2.2b
- Feature flag analytics/telemetry — out of scope
- Complex targeting rules (device, locale, OS version) — Phase 2.2b
- LaunchDarkly/Firebase native SDKs — we provide protocol adapters, not SDK wrappers
- UI for toggling flags — that's Child 2.3 (Developer Menu)
- Flag-change notifications / `AsyncSequence` — deferred to 2.2b (remote sync needed first)

## Naming

| Context | Name |
|---------|------|
| Repo | `swiftanvil-anvil-flags` |
| Swift Package | `AnvilFlags` |
| Module import | `import AnvilFlags` |
| Product | `.product(name: "AnvilFlags", package: "swiftanvil-anvil-flags")` |

## Concurrency Model

**Singleton pattern with TaskLocal test injection.** `FeatureFlags` uses `@TaskLocal` to route reads to either the default shared system or an injected test system. This ensures thread-safe, race-free test isolation under Swift 6 strict concurrency.

```swift
public struct FeatureFlags: Sendable {
    @TaskLocal private static var current: FeatureFlagSystem = FeatureFlagSystem()
    
    // All static methods read from Self.current (TaskLocal)
    // Default: shared system. In tests: injected system via withSystem().
}
```

**Why TaskLocal:**
- Parallel tests each run in their own task → each gets its own injected system
- No global mutable state → no data races
- `withSystem()` is scoped → injection automatically reverts after operation

## Public API Surface

### Core Types

```swift
// Main API — singleton facade with TaskLocal test injection
public struct FeatureFlags: Sendable {
    @TaskLocal private static var current: FeatureFlagSystem = FeatureFlagSystem()
    
    public static func configure(sources: [FeatureFlagSource]) async
    public static func isEnabled(_ key: FeatureFlagKey) async -> Bool
    public static func value<T: FeatureFlagValueConvertible>(_ key: FeatureFlagKey, as: T.Type, default: T) async -> T
    public static func abTest(_ test: ABTest, forUser userID: String) async -> ABTestAssignment
    
    // Test injection: runs operation with a custom system, isolated to this task
    public static func withSystem<T>(_ system: FeatureFlagSystem, _ operation: () async throws -> T) async rethrows -> T
}

// System actor
public actor FeatureFlagSystem: Sendable {
    public init(sources: [FeatureFlagSource] = [])
    public func value(for key: FeatureFlagKey) -> FeatureFlagValue?
    public func isEnabled(_ key: FeatureFlagKey) -> Bool
    public func abTest(_ test: ABTest, forUser userID: String) -> ABTestAssignment
    public func configure(sources: [FeatureFlagSource])
}

// Flag key
public struct FeatureFlagKey: RawRepresentable, Sendable, Hashable {
    public let rawValue: String
    public init(_ rawValue: String)
}

// Flag value
public enum FeatureFlagValue: Sendable {
    case bool(Bool)
    case string(String)
    case int(Int)
    case double(Double)
    case json(Data)
}

// Typed conversion protocol
public protocol FeatureFlagValueConvertible: Sendable {
    static func convert(from value: FeatureFlagValue) -> Self?
}

// Conformances: Bool, Int, Double, String, Data (direct unwrap), T: Decodable (JSONDecoder fallback)

// Sources
public protocol FeatureFlagSource: Sendable {
    func value(for key: FeatureFlagKey) async -> FeatureFlagValue?
}

extension FeatureFlagSource {
    // Default: sources that don't support enumeration return empty.
    // InMemory and JSONFile sources override this. Needed for Developer Menu (Child 2.3).
    public func allFlags() async -> [FeatureFlagKey: FeatureFlagValue] { [:] }
}

// Built-in sources
public struct InMemoryFeatureFlagSource: FeatureFlagSource {
    public init(_ flags: [FeatureFlagKey: FeatureFlagValue])
    public mutating func set(_ value: FeatureFlagValue, for key: FeatureFlagKey)
    
    // Note: Mutation is pre-configuration only. After handing to FeatureFlagSystem,
    // the system holds its own copy. Runtime overrides use FeatureFlagSystem.configure().
}

public struct JSONFileFeatureFlagSource: FeatureFlagSource {
    public init(fileName: String, bundle: Bundle = .main)
}

// A/B Testing
public struct ABTest: Sendable {
    public let name: String
    public let variants: [String]
    public init(name: String, variants: [String])
}

public struct ABTestAssignment: Sendable {
    public let test: ABTest
    public let variant: String
}

public protocol ABTestBucketingStrategy: Sendable {
    func assign(_ test: ABTest, for userID: String) -> String
}

public struct StableHashBucketingStrategy: ABTestBucketingStrategy {
    // Uses FNV-1a (pure Swift, no CryptoKit, works on Linux)
    public init()
}
```

### Usage

```swift
import AnvilFlags

// Define flags in one place
extension FeatureFlagKey {
    static let newOnboarding = FeatureFlagKey("new_onboarding")
    static let maxRetries = FeatureFlagKey("max_retries")
    static let apiEndpoint = FeatureFlagKey("api_endpoint")
}

// Configure once at app launch
await FeatureFlags.configure(sources: [
    InMemoryFeatureFlagSource([
        .newOnboarding: .bool(false),
        .maxRetries: .int(3)
    ]),
    JSONFileFeatureFlagSource(fileName: "flags.json")
])

// Read flags anywhere
if await FeatureFlags.isEnabled(.newOnboarding) {
    showNewOnboarding()
}

let maxRetries = await FeatureFlags.value(.maxRetries, as: Int.self, default: 3)
let endpoint = await FeatureFlags.value(.apiEndpoint, as: String.self, default: "https://api.example.com")

// Decode JSON flag to custom type
struct CheckoutConfig: Decodable { let enabled: Bool; let timeout: Int }
let config = await FeatureFlags.value(.checkoutConfig, as: CheckoutConfig.self, default: CheckoutConfig(enabled: false, timeout: 30))

// A/B test
let assignment = await FeatureFlags.abTest(
    ABTest(name: "checkout_flow", variants: ["control", "variant_a"]),
    forUser: userID
)
if assignment.variant == "variant_a" {
    showVariantA()
}
```

### Test Override Pattern

```swift
// In tests: inject a mock system with overrides
let testSystem = FeatureFlagSystem(sources: [
    InMemoryFeatureFlagSource([.newOnboarding: .bool(true)])
])

await FeatureFlags.withSystem(testSystem) {
    #expect(await FeatureFlags.isEnabled(.newOnboarding) == true)
}
```

## Task Breakdown

| # | Task | Effort | Verification |
|---|------|--------|--------------|
| 1 | Design PublicAPI + source priority model | 1h | Cross-host review |
| 2 | Implement FeatureFlagKey + FeatureFlagValue + FeatureFlagValueConvertible | 30m | Type-safe, Sendable |
| 3 | Implement FeatureFlagSystem actor | 1h | Thread-safe reads, source priority |
| 4 | Implement InMemoryFeatureFlagSource | 30m | Mutable overrides, compile-time defaults |
| 5 | Implement JSONFileFeatureFlagSource | 1h | JSON parsing, nested objects → .json(Data) |
| 6 | Implement source priority / fallback chain | 1h | First-match wins, default applies |
| 7 | Implement A/B test + FNV-1a bucketing | 1.5h | Deterministic, stable, cross-platform |
| 8 | Implement typed value accessors + test injection | 1h | `isEnabled`, `value(as:default:)`, `withSystem` |
| 9 | Write tests (unit + integration + A/B determinism) | 2.5h | Mock sources, hash stability, test overrides |
| 10 | Write README + examples | 30m | Clear usage patterns |
| 11 | Cross-host review | 1h | All criteria pass |

**Total: ~11h**

## Source Priority Model

Flags are resolved by querying sources in order. First source to return a value wins.

```
Source 1 (highest priority) → value? → return
Source 2 → value? → return
...
Source N (lowest priority) → value? → return
Default (caller-provided) → return
```

**Reconfiguration:** `configure(sources:)` is replace-all, callable any time, last-writer-wins. Sources are stored as an immutable array (no mutation after set). Actor isolation guarantees atomic reads: concurrent reads see either the old or new source list, never a partial update.

## A/B Test Bucketing

Uses **FNV-1a** (32-bit) on `userID + "|" + testName` for stable, deterministic, cross-platform hashing. No CryptoKit dependency. Works on Linux.

```swift
// hash = FNV1a("user123|checkout_flow")
// variantIndex = hash % variants.count
// Result: always same variant for same user + test
// Note: slight bias when UInt32.max+1 is not divisible by variants.count.
// Negligible for typical variant counts (2-10). Documented, not a bug.
```

**Properties:**
- Deterministic: same user + test → same variant
- Stable: survives app restarts, device changes (if userID is stable)
- Cross-platform: FNV-1a is pure Swift, no Apple-only dependencies
- Configurable: custom `ABTestBucketingStrategy`

## Flag Types

| Swift Type | FeatureFlagValue | Conversion |
|------------|------------------|------------|
| `Bool` | `.bool(true)` | Direct unwrap |
| `Int` | `.int(42)` | Direct unwrap |
| `Double` | `.double(1.5)` | Direct unwrap |
| `String` | `.string("...")` | Direct unwrap |
| `Data` | `.json(Data)` | Direct unwrap |
| `T: Decodable` | `.json(Data)` | JSONDecoder.decode |

**Type mismatch behavior:** Returns caller-provided `default`. No error thrown. Callers who need error visibility can read raw `FeatureFlagValue` and switch.

## JSON File Format

```json
{
  "new_onboarding": true,
  "max_retries": 5,
  "api_endpoint": "https://api.example.com",
  "checkout_config": {
    "enabled": true,
    "timeout": 30
  }
}
```

**Parsing rules:**
- Top-level keys become `FeatureFlagKey`
- JSON primitives → matching `FeatureFlagValue` case
- Nested objects/arrays → `.json(Data)` containing the re-encoded sub-value
- Callers decode `.json(Data)` via `value(_, as: T.self, default:)` where `T: Decodable`

## Error Model

```swift
public enum FeatureFlagError: Error, Sendable {
    case fileNotFound(String)
    case jsonDecodingFailed(String)  // stores description, not Error (smaller, no payload exposure)
    case notConfigured
}
```

**Error handling:** Public API uses defaults (no throws). Errors are internal (file not found → no value → default returned). `FeatureFlagError` is for diagnostic/logging use.

## Assurance Strategy

| Lens | Selected | Coverage |
|------|----------|----------|
| Planning | API design, source priority model, bucketing algorithm | This plan |
| Implementation | Correctness, concurrency, type safety | Actor isolation, Sendable contracts |
| Test | Unit, integration, A/B bucketing determinism, test overrides | Mock sources, hash stability, `withSystem` |
| Review | Exhaustive critique | Cross-host pre-impl and post-impl |

## Success Criteria

- [ ] Package builds with `swift build`
- [ ] Tests pass with `swift test`
- [ ] Test coverage ≥ 80%
- [ ] README with usage examples
- [ ] Swift 6 + StrictConcurrency
- [ ] Cross-host review approved

## Output

New repo: `github.com/swiftanvil/swiftanvil-anvil-flags`
