# iFoundation — Swift Project Scaffolding Tool

## Vision Statement

**iFoundation** is a world-class, host-agnostic Swift project scaffolding tool that establishes the golden path for Apple platform development. It is designed for the LLM era — where code generation is abundant, but architectural discipline, enforcement, and inclusive design are the differentiators.

The tool is not just a project generator. It is a **development infrastructure framework** that:
- Scaffolds projects with battle-tested architectural patterns
- Enforces standards through automation and guardrails
- Enables inclusive design (accessibility, localization, testing) by default
- Provides a centralized, composable documentation registry
- Optimizes for minimal token usage, maximum speed, and host-agnostic workflows
- Includes a self-improving telemetry and feedback system

---

## Core Principles

| Principle | Description |
|-----------|-------------|
| **Host Agnosticism** | All scripts, workflows, and configurations must work identically across macOS, Linux (CI), and cloud environments. No hardcoded paths, no platform assumptions. |
| **Minimal Tokenization** | Every output is designed to be LLM-friendly — modular, well-indexed, with clear boundaries. Reduces context window pressure when working with AI agents. |
| **Performance First** | Scaffolding must be instantaneous. Build systems must be optimized. Derived data, artifacts, and caches must be centrally managed and auto-purged. |
| **Inclusion by Default** | Accessibility identifiers, localization infrastructure, and test scaffolding are not optional — they are foundational. |
| **Enforcement over Convention** | Standards are not documented and hoped for; they are enforced via pre-commit hooks, linting, CI gates, and runtime assertions. |
| **Composability** | Documentation, configuration, and code are composed from a centralized registry. No duplication, no hardcoded paths. |
| **Self-Improvement** | Telemetry, logs, and feedback loops enable the tool and its agents to suggest improvements, detect drift, and evolve over time. |

---

## Project Types (Templates)

| Template | Description | Inclusive Design | Testing |
|----------|-------------|------------------|---------|
| `ios-app` | iOS application with SwiftUI or UIKit | Full (a11y, localization, Dynamic Type) | Unit + UI + Snapshot |
| `macos-app` | macOS application | Full | Unit + UI |
| `watchos-app` | watchOS application | Full | Unit |
| `tvos-app` | tvOS application | Full | Unit + UI |
| `visionos-app` | visionOS spatial application | Full | Unit + UI |
| `swift-library` | Reusable Swift package/library | N/A (non-UI) | Unit + Integration |
| `swift-tool` | Command-line tool / executable | N/A | Unit + Integration |
| `swift-server` | Server-side Swift (Vapor/Hummingbird) | N/A | Unit + Integration |
| `multiplatform-app` | Cross-platform app (iOS + macOS + tvOS + watchOS) | Full | Unit + UI per platform |
| `framework` | Multi-platform framework with XCFramework support | N/A | Unit + Integration |

---

## Architecture & Enforcement Layers

### 1. SOLID Principles Enforcement
- **Dependency Inversion**: Protocol-oriented design with dependency injection container
- **Single Responsibility**: File and type size limits enforced via linting
- **Open/Closed**: Extension-based architecture with plugin system
- **Liskov Substitution**: Protocol conformance validation in tests
- **Interface Segregation**: No god protocols; composition over inheritance

### 2. MVVM + I/O Architecture
- **Model**: Pure data structures (structs, Codable, Sendable)
- **ViewModel**: `@Observable` or `@MainActor` bound, with clear Input/Output interfaces
- **View**: SwiftUI Views with accessibility identifiers, localization keys
- **Service Layer**: Protocol-based networking, caching, persistence
- **Repository Pattern**: Data access abstraction

### 3. Accessibility Enforcement
- Every interactive SwiftUI view MUST have `.accessibilityIdentifier()`
- Every user-facing string MUST use `LocalizedStringKey`
- Color contrast validation via CI
- VoiceOver navigation flow tests in UI test suite
- Accessibility audit script in pre-commit

### 4. Localization Infrastructure
- String catalog (`.xcstrings`) setup by default
- LLM-friendly translation workflow scripts
- Pseudolocalization testing in CI
- Right-to-left layout testing support
- Pluralization and format string validation

### 5. Testing Strategy
- **Unit Tests**: Pure logic, ViewModel testing, service mocking
- **UI Tests**: Accessibility identifier-based, page object pattern
- **Snapshot Tests**: Visual regression for SwiftUI views
- **Performance Tests**: Baseline and regression detection
- **Integration Tests**: End-to-end with test doubles

---

## Documentation Registry System

A centralized, composable documentation system that avoids duplication and hardcoded paths.

```
Documentation/
├── Registry/
│   ├── index.yml              # Central routing registry
│   ├── architecture.yml       # Architecture decision records
│   ├── api.yml                # API documentation index
│   └── workflows.yml          # Workflow documentation index
├── Composed/
│   ├── package.readme              # Auto-generated from registry
│   ├── ARCHITECTURE.md        # Composed from architecture.yml + refs
│   └── SETUP.md               # Composed from templates
├── Fragments/
│   ├── principles/
│   ├── patterns/
│   ├── decisions/
│   └── references/
└── Templates/
    ├── decision-record.md
    ├── api-doc.md
    └── adr-template.md
```

**Registry Schema (YAML)**:
```yaml
# Registry/index.yml
documents:
  architecture:
    path: "Composed/ARCHITECTURE.md"
    sources:
      - "Fragments/principles/solid.md"
      - "Fragments/patterns/mvvm.md"
      - "Fragments/decisions/adr-001.md"
  setup:
    path: "Composed/SETUP.md"
    sources:
      - "Templates/setup-header.md"
      - "Fragments/workflows/build.md"
      - "Fragments/workflows/test.md"
```

The registry is consumed by a small Swift tool that composes documents at build time or on demand.

---

## Workflow & Automation

### Git Hooks (Pre-commit)
- SwiftFormat enforcement
- SwiftLint with custom rules (accessibility identifier check, localization check)
- Build verification (fast path)
- Test execution for changed files only
- Documentation registry validation

### CI/CD (GitHub Actions — Self-Hosted Ready)
- Matrix builds across iOS versions
- Accessibility audit step
- Localization completeness check
- Snapshot test comparison
- Performance regression gate
- Code coverage reporting with thresholds

### Artifact & Cache Management
- Centralized derived data in `.foundation/DerivedData/`
- Automatic purge based on age, size, or project closure
- Build artifact organization with metadata
- Temporary file sandboxing

---

## Self-Improvement System ("Immunity System")

Inspired by biological immune systems — detect anomalies, learn, adapt.

```
.foundation/telemetry/
├── logs/                      # Structured build/test logs
├── metrics/                   # Performance metrics over time
├── issues/                    # Auto-detected issues and suggestions
└── knowledge-base/            # Learned patterns and fixes
```

**Components**:
1. **Telemetry Collector**: Gathers build times, test flakiness, coverage trends
2. **Anomaly Detector**: Identifies regressions, slow tests, flaky tests
3. **Suggestion Engine**: Proposes architectural improvements, dependency updates
4. **Knowledge Base**: Accumulates project-specific patterns and solutions
5. **Health Dashboard**: CLI and web view of project health

---

## Tool Design

### Command-Line Interface

```bash
# Global installation
brew install ifoundation  # or mint install, etc.

# Create new project
ifoundation create MyApp --template ios-app

# Interactive wizard
ifoundation create MyApp --interactive

# Add module to existing project
ifoundation add-module Network --type service

# Update scaffolding
ifoundation update --check
ifoundation update --apply

# Health check
ifoundation doctor

# Compose documentation
ifoundation docs compose

# Run immunity scan
ifoundation immunity scan
ifoundation immunity report
```

### Interactive Wizard Flow

```
? Project name: MyAwesomeApp
? Select template:
  ○ iOS App (SwiftUI)
  ○ iOS App (UIKit)
  ○ macOS App
  ○ watchOS App
  ● Multiplatform App
? Minimum iOS version: 17.0
? Include SwiftUI: Yes
? Include Core Data: No
? Include CloudKit: Yes
? Enable accessibility enforcement: Yes
? Enable localization: Yes
? Target languages: [English, Spanish, French, German, Japanese, Chinese]
? Testing strategy:
  ☑ Unit Tests
  ☑ UI Tests
  ☑ Snapshot Tests
  ☐ Performance Tests
? CI provider: GitHub Actions
? Self-hosted runners: Yes
? Enable immunity system: Yes

Generating project...
✓ Package.swift / .xcodeproj
✓ Source structure (MVVM + I/O)
✓ Accessibility identifiers scaffold
✓ Localization infrastructure (6 languages)
✓ Test targets with examples
✓ Git hooks
✓ CI workflows
✓ Documentation registry
✓ Immunity system config

Project ready at ./MyAwesomeApp
Run: cd MyAwesomeApp && ifoundation doctor
```

---

## Technical Stack

| Component | Technology |
|-----------|------------|
| CLI Tool | Swift (ArgumentParser, SwiftSyntax) |
| Templates | Stencil or custom templating |
| Configuration | YAML + Codable |
| Git Hooks | Swift scripts (host-agnostic) |
| Linting | SwiftLint + custom rules |
| Formatting | SwiftFormat |
| Testing | XCTest + SnapshotTesting |
| CI | GitHub Actions (self-hosted compatible) |
| Telemetry | Structured JSON logs |

---

## File Structure (The Tool Itself)

```
iFoundation/
├── Package.swift
├── Sources/
│   ├── iFoundation/
│   │   ├── Commands/
│   │   │   ├── CreateCommand.swift
│   │   │   ├── AddModuleCommand.swift
│   │   │   ├── DoctorCommand.swift
│   │   │   ├── DocsCommand.swift
│   │   │   └── ImmunityCommand.swift
│   │   ├── Templates/
│   │   │   ├── TemplateEngine.swift
│   │   │   ├── TemplateRegistry.swift
│   │   │   └── Renderers/
│   │   ├── Scaffolding/
│   │   │   ├── ProjectGenerator.swift
│   │   │   ├── ModuleGenerator.swift
│   │   │   └── FileGenerator.swift
│   │   ├── Configuration/
│   │   │   ├── ProjectConfig.swift
│   │   │   └── TemplateConfig.swift
│   │   ├── Documentation/
│   │   │   ├── RegistryComposer.swift
│   │   │   └── DocumentRenderer.swift
│   │   ├── Immunity/
│   │   │   ├── TelemetryCollector.swift
│   │   │   ├── AnomalyDetector.swift
│   │   │   └── SuggestionEngine.swift
│   │   └── Utilities/
│   │       ├── FileSystem.swift
│   │       ├── ShellRunner.swift
│   │       └── PathResolver.swift
│   └── iFoundationCore/
│       └── Shared models and protocols
├── Templates/
│   ├── ios-app/
│   ├── macos-app/
│   ├── swift-library/
│   ├── swift-tool/
│   ├── multiplatform-app/
│   └── shared/
│       ├── git-hooks/
│       ├── ci-workflows/
│       ├── lint-configs/
│       └── docs-registry/
├── Tests/
│   ├── iFoundationTests/
│   └── IntegrationTests/
└── package.agent-instructions
```

---

## Roadmap

### Phase 1: Foundation (Weeks 1-4)
- [ ] CLI skeleton with ArgumentParser
- [ ] Basic template engine
- [ ] 3 core templates: `ios-app`, `swift-library`, `swift-tool`
- [ ] Interactive wizard
- [ ] Git hooks scaffolding
- [ ] Documentation registry system

### Phase 2: Enforcement (Weeks 5-8)
- [ ] SwiftLint custom rules (a11y, localization)
- [ ] Pre-commit hook integration
- [ ] CI workflow generation
- [ ] Accessibility identifier enforcement
- [ ] Localization infrastructure

### Phase 3: Intelligence (Weeks 9-12)
- [ ] Telemetry collection
- [ ] Anomaly detection
- [ ] Suggestion engine
- [ ] Health dashboard
- [ ] Self-update mechanism

### Phase 4: Expansion (Weeks 13-16)
- [ ] Additional templates (visionOS, server-side)
- [ ] Module add/remove commands
- [ ] Template marketplace / sharing
- [ ] IDE extensions (Xcode, VS Code)

---

## Why This Matters

In the LLM era, the bottleneck is no longer "can we write code?" — it's:
- **Can we write the RIGHT code?**
- **Can we maintain consistency across AI-generated output?**
- **Can we ensure quality, accessibility, and performance by default?**
- **Can we create infrastructure that improves itself?**

iFoundation answers these questions by providing the scaffolding, enforcement, and intelligence layer that turns AI-generated code into production-grade software.

---

## Next Steps

1. **Review and refine** this plan
2. **Lock scope** for Phase 1
3. **Set up repository structure**
4. **Begin CLI implementation**
5. **Iterate with real-world usage**
