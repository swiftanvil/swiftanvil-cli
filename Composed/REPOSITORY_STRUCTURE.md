# ADR-011: Repository Structure Strategy — Monorepo with Independent Package Distribution

## Status
Accepted

## Context

We need to decide how to structure iFoundation's codebase:

1. **The CLI tool** (`ifoundation`) — the scaffolding engine
2. **The shared packages** (`AppStrings`, `A11yIdentifiers`, `AppNetworking`, etc.) — reusable libraries
3. **The templates** — project scaffolding templates

Key questions:
- Should packages live in one repo or separate repos?
- How do users consume individual packages vs. the full tool?
- How do we leverage existing work (e.g., Turnip iOS BenchmarkKit)?
- What's the standard in the Swift OSS ecosystem?

## Research Findings

### How Successful Swift OSS Projects Structure Their Code

| Project | Structure | Approach |
|---------|-----------|----------|
| **Pointfreeco** (TCA, swift-dependencies, swift-case-paths, etc.) | **Multi-repo** | Each package is a separate repo under `pointfreeco/` org. They depend on each other via SPM. |
| **Apple** (swift-nio, swift-algorithms, swift-collections, etc.) | **Multi-repo** | Each package is a separate repo under `apple/` org. Independent versioning. |
| **Vapor** (vapor, fluent, leaf, etc.) | **Multi-repo** | Each package is a separate repo under `vapor/` org. Core + ecosystem packages. |
| **Apollo iOS** | **Monorepo + Git Subtrees** | Develop in monorepo, distribute as separate SPM packages via git subtree split. |
| **Swift Package Manager itself** | **Monorepo** | Single repo with multiple targets, but SPM is a system tool, not a library. |

### Key Insights from Research

1. **Pointfreeco's approach** is the gold standard for Swift libraries:
   - Each package is independently versioned
   - Users can depend on exactly what they need
   - Clear separation of concerns
   - Easy to contribute to specific packages
   - But: harder to make cross-cutting changes

2. **Apollo's approach** (git subtree) solves the "develop together, distribute separately" problem:
   - Develop all packages in one repo for convenience
   - Auto-split to separate repos for SPM consumption
   - Best of both worlds, but requires CI automation

3. **Apple's approach** for swift-nio ecosystem:
   - Core package (`swift-nio`) + satellite packages (`swift-nio-ssl`, `swift-nio-http2`)
   - Each in separate repo
   - Core repo has tight integration, satellites extend it

## Decision

### Hybrid Approach: "iFoundation Organization with Coordinated Multi-Repo"

```
GitHub Organization: iFoundation

Repos:
├── ifoundation-cli              ← The scaffolding CLI tool
├── ifoundation-appstrings       ← Type-safe localization
├── ifoundation-a11yidentifiers  ← Type-safe accessibility
├── ifoundation-networking       ← Type-safe networking (Moya-inspired)
├── ifoundation-developermenu    ← Debug menu
├── ifoundation-benchmarkkit     ← Performance benchmarking
├── ifoundation-templates        ← Project templates (shared)
└── ifoundation-docs             ← Documentation and website
```

### Why This Structure?

#### 1. For the CLI Tool (ifoundation-cli)

This is the **orchestrator**. It:
- Depends on ALL packages as local/remote dependencies
- Generates projects that depend on selected packages
- Contains the wizard, template engine, and scaffolding logic

```swift
// ifoundation-cli/Package.swift
let package = Package(
    name: "iFoundationCLI",
    dependencies: [
        // Local development (use path)
        // .package(path: "../ifoundation-appstrings"),
        
        // Production (use URL)
        .package(url: "https://github.com/iFoundation/ifoundation-appstrings", from: "1.0.0"),
        .package(url: "https://github.com/iFoundation/ifoundation-a11yidentifiers", from: "1.0.0"),
        .package(url: "https://github.com/iFoundation/ifoundation-networking", from: "1.0.0"),
        // ... etc
    ],
    targets: [
        .executableTarget(
            name: "iFoundation",
            dependencies: [
                "AppStrings",
                "A11yIdentifiers",
                "AppNetworking",
                // ... etc
            ]
        )
    ]
)
```

#### 2. For Individual Packages

Each package is a **standalone Swift Package** that can be:
- Used independently (without the CLI)
- Versioned independently
- Contributed to independently
- Discovered independently on Swift Package Index

Example: `ifoundation-appstrings`
```swift
// ifoundation-appstrings/Package.swift
let package = Package(
    name: "AppStrings",
    products: [
        .library(name: "AppStrings", targets: ["AppStrings"])
    ],
    targets: [
        .target(name: "AppStrings"),
        .testTarget(name: "AppStringsTests", dependencies: ["AppStrings"])
    ]
)
```

#### 3. For Generated Projects

When a user runs `ifoundation create MyApp`, the generated project:
- Uses **local package references** for development
- Can be switched to **remote references** when published

```swift
// Generated MyApp/Package.swift
let package = Package(
    name: "MyApp",
    dependencies: [
        // Option A: Local (during development)
        .package(path: "Packages/AppStrings"),
        .package(path: "Packages/A11yIdentifiers"),
        
        // Option B: Remote (when publishing)
        // .package(url: "https://github.com/iFoundation/ifoundation-appstrings", from: "1.0.0"),
    ]
)
```

### Development Workflow

#### For iFoundation Contributors

```bash
# Clone the CLI tool
git clone https://github.com/iFoundation/ifoundation-cli.git
cd ifoundation-cli

# Clone packages you want to work on alongside
mkdir -p ../packages
git clone https://github.com/iFoundation/ifoundation-appstrings.git ../packages/AppStrings
git clone https://github.com/iFoundation/ifoundation-a11yidentifiers.git ../packages/A11yIdentifiers

# Use local dependencies for development
# (Package.swift uses path-based dependencies in dev mode)
```

#### For Package-Only Contributors

```bash
# Clone just the package you want to contribute to
git clone https://github.com/iFoundation/ifoundation-appstrings.git
cd ifoundation-appstrings
swift test
```

### Leveraging Existing Work (Turnip iOS)

For packages like **BenchmarkKit** where you've already done significant work in Turnip iOS:

1. **Extract** the package from Turnip iOS into a standalone package
2. **Generalize** it (remove Turnip-specific code)
3. **Publish** as `ifoundation-benchmarkkit`
4. **Use** in both Turnip iOS and iFoundation-generated projects

```bash
# From Turnip iOS
# Extract BenchmarkKit to standalone repo
git subtree split -P zaps-app/BenchmarkKit -b benchmarkkit-extract
git push https://github.com/iFoundation/ifoundation-benchmarkkit.git benchmarkkit-extract:main
```

### Versioning Strategy

| Component | Versioning | Example |
|-----------|-----------|---------|
| CLI Tool | Semantic, independent | `ifoundation-cli 2.3.1` |
| Each Package | Semantic, independent | `AppStrings 1.2.0` |
| Templates | Versioned with CLI | `templates 2.3.1` |

### Release Coordination

```yaml
# .github/workflows/release.yml
name: Coordinated Release

on:
  workflow_dispatch:
    inputs:
      version:
        description: 'Release version'
        required: true

jobs:
  # Release each package independently
  release-packages:
    strategy:
      matrix:
        package: [appstrings, a11yidentifiers, networking, developermenu, benchmarkkit]
    uses: ./.github/workflows/release-package.yml
    with:
      package: ${{ matrix.package }}
      version: ${{ github.event.inputs.version }}
  
  # Release CLI tool (depends on packages)
  release-cli:
    needs: release-packages
    uses: ./.github/workflows/release-cli.yml
    with:
      version: ${{ github.event.inputs.version }}
```

## Comparison: Monorepo vs. Multi-Repo vs. Hybrid

| Concern | Pure Monorepo | Pure Multi-Repo | Hybrid (Chosen) |
|---------|--------------|-----------------|-----------------|
| Cross-cutting changes | ✅ Easy | ❌ Hard | ✅ Easy (local dev) |
| Independent versioning | ❌ Shared | ✅ Independent | ✅ Independent |
| User can pick packages | ❌ All or nothing | ✅ Granular | ✅ Granular |
| Contribution barrier | ✅ One clone | ❌ Many clones | ✅ One clone (CLI) |
| Package discovery | ❌ Hidden | ✅ Clear | ✅ Clear (org page) |
| CI complexity | ⚠️ High | ✅ Low | ⚠️ Medium |
| SPM integration | ⚠️ All targets built | ✅ Only what you need | ✅ Only what you need |

## Consequences

### Positive
- **Best of both worlds**: Develop together, distribute separately
- **Independent evolution**: Packages can evolve at their own pace
- **Clear ownership**: Each repo has its own issues, PRs, docs
- **Easy adoption**: Users can adopt one package without the whole ecosystem
- **Community friendly**: Easy to contribute to specific packages

### Negative
- **Release coordination**: Need to coordinate releases across repos
- **Cross-repo changes**: Changes spanning multiple packages require multiple PRs
- **Discovery**: Users need to discover packages across repos

### Mitigations
- **Meta-repo for development**: A `ifoundation-dev` repo with git submodules for local development
- **Documentation hub**: `ifoundation-docs` repo lists all packages
- **Release automation**: GitHub Actions coordinate releases

## Related
- ADR-007: Package Catalog Architecture
- ADR-009: Open Source Strategy


# Pattern: Leveraging Existing Code

## Problem
You've already built excellent infrastructure in Turnip iOS (BenchmarkKit, A11yIdentifiers pattern, etc.). Rewriting from scratch would be wasteful.

## Solution
Extract, generalize, and repurpose existing code as standalone iFoundation packages.

## Extraction Process

### Step 1: Identify Extractable Code

From Turnip iOS, these packages are ready for extraction:

| Turnip Component | iFoundation Package | Effort |
|-----------------|---------------------|--------|
| `A11yIdentifiers/` | `ifoundation-a11yidentifiers` | Low (already standalone) |
| `BenchmarkKit/` | `ifoundation-benchmarkkit` | Medium (generalize) |
| `ZapUtils/` (localization) | `ifoundation-appstrings` | Medium (redesign API) |
| `TestingKit/` | `ifoundation-testingkit` | Medium (generalize) |

### Step 2: Extract with Git History

```bash
# From Turnip iOS repo
# Extract A11yIdentifiers with full git history

git subtree split -P zaps-app/A11yIdentifiers -b a11y-extract

# Create new repo
git init ifoundation-a11yidentifiers
cd ifoundation-a11yidentifiers
git pull ../turnip-ios a11y-extract

# Generalize (remove Turnip-specific code)
# - Update Package.swift (remove Turnip-specific deps)
# - Rename module from A11yIdentifiers to AppA11y or keep
# - Update README for general usage
# - Add comprehensive tests

git remote add origin https://github.com/iFoundation/ifoundation-a11yidentifiers.git
git push -u origin main
```

### Step 3: Generalize the API

**Before (Turnip-specific):**
```swift
public enum SettingsA11y {
    public static let logoutRow: A11yID = "settings.row.logout"
    // ... many Turnip-specific identifiers
}
```

**After (Generic, template-friendly):**
```swift
// Core type (unchanged)
public struct A11yID: RawRepresentable, ExpressibleByStringLiteral, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
}

// SwiftUI extension (unchanged)
extension View {
    public func a11yID(_ id: A11yID) -> some View {
        accessibilityIdentifier(id.rawValue)
    }
}

// NO predefined enums — generated per project by iFoundation CLI
// The CLI generates:
// Generated/SettingsA11y.swift
// Generated/HomeA11y.swift
// etc.
```

### Step 4: Create Template Generation

The iFoundation CLI generates the module-specific enums:

```swift
// Generated by: ifoundation create MyApp --template ios-app
// File: Packages/A11yIdentifiers/Sources/A11yIdentifiers/Modules/SettingsA11y.swift

public enum SettingsA11y {
    public enum AccountSection {
        public static let logoutRow: A11yID = "settings.account.logout"
        public static let deleteRow: A11yID = "settings.account.delete"
    }
    
    public enum HelpSection {
        public static let faqRow: A11yID = "settings.help.faq"
        public static let contactRow: A11yID = "settings.help.contact"
    }
}
```

### Step 5: Dual Usage

The same package is used by:
1. **Turnip iOS** (existing project, manual definitions)
2. **iFoundation-generated projects** (auto-generated definitions)

```swift
// Turnip iOS usage (manual, existing)
import A11yIdentifiers

button.a11yID(SettingsA11y.AccountSection.logoutRow)

// iFoundation-generated project usage (auto-generated)
import A11yIdentifiers

button.a11yID(SettingsA11y.AccountSection.logoutRow)  // Same API!
```

## BenchmarkKit Extraction Example

### Current Turnip iOS BenchmarkKit

```swift
// From Turnip iOS: zaps-app/BenchmarkKit/
// Features:
// - Benchmark recording
// - System sampling
// - Cohort analysis
// - Export blocking metrics
// - SwiftUI integration
```

### Generalized iFoundation BenchmarkKit

```swift
// ifoundation-benchmarkkit/Sources/BenchmarkKit/
// Core (unchanged from Turnip):
// - BenchmarkRecording.swift
// - BenchmarkSystemSampler.swift
// - BenchmarkCohort.swift
// - BenchmarkModels.swift

// New: Generic configuration
public struct BenchmarkConfiguration {
    public var metrics: [BenchmarkMetric]
    public var thresholds: [BenchmarkMetric: BenchmarkThreshold]
    public var iterations: Int
    
    public static let `default` = BenchmarkConfiguration(...)
}

// New: Swift Testing integration
extension Trait where Self == BenchmarkTrait {
    public static func benchmark(
        iterations: Int = 10,
        threshold: Duration? = nil
    ) -> BenchmarkTrait { ... }
}
```

### What Changes vs. What Stays

| Aspect | Turnip iOS | iFoundation | Action |
|--------|-----------|-------------|--------|
| Core sampling logic | ✅ | ✅ | **Keep as-is** |
| SwiftUI views | ✅ | ✅ | **Keep as-is** |
| Turnip-specific models | ✅ | ⬜ | **Remove/generalize** |
| Package name | `BenchmarkKit` | `BenchmarkKit` | **Keep** |
| Module imports | `import TurnipCore` | `import Foundation` | **Generalize** |
| Test data | Turnip-specific | Generic fixtures | **Replace** |

## Benefits of This Approach

1. **No duplication**: Same package used in both contexts
2. **Improvements propagate**: Fix bug in iFoundation package → Turnip gets it too
3. **Community benefits**: Others can use your battle-tested code
4. **Your investment preserved**: Years of Turnip work isn't wasted

## Related
- ADR-011: Repository Structure Strategy
- Pattern: Shared Type-Safe Packages


