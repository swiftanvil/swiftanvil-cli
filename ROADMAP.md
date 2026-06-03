# SwiftAnvil Roadmap

> The single source of truth for what we've built, what we're building, and what's next.

---

## 🗺️ At a Glance

| Phase | Theme | Status | Progress |
|-------|-------|--------|----------|
| [Phase 1](#phase-1-foundation) | Foundation | 🟢 Complete | 5/5 |
| [Phase 2](#phase-2-core-packages) | Core Packages | 🟢 Complete | 3/3 |
| [Phase 3](#phase-3-cli--integration) | CLI & Integration | 🟡 In Progress | 1/5 |
| [Phase 4](#phase-4-ecosystem) | Ecosystem | ⚪ Planned | 0/3 |

**Phase 2 Progress:** All children complete. Ready for Phase Gate 2→3.

**Legend:** 🟢 Complete | 🟡 In Progress | 🔴 Blocked | ⚪ Planned

---

## Phase 1: Foundation 🟢

> Extract existing code, establish patterns, create the org.

### 1.1 Research Swift OSS Best Practices ✅

**What we learned:**
- Multi-repo org model (Pointfreeco pattern) — each package is independent
- Swift 6 + StrictConcurrency as baseline
- Swift Testing over XCTest
- DocC for API docs, README for quickstart
- Issue templates + PR templates + CI from day one

**Decision:** `github.com/swiftanvil` as multi-repo org with `anvil-*` package naming.

**Review:** Self-reviewed (research task, not code).

### 1.2 A11yIdentifiers ✅

| Aspect | Detail |
|--------|--------|
| Repo | [`swiftanvil-anvil-a11y`](https://github.com/swiftanvil/swiftanvil-anvil-a11y) |
| Source | Extracted from Turnip iOS |
| Core Type | `A11yID` — phantom-typed, `Sendable`, `Hashable` |
| Platforms | iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, visionOS 1+ |
| Tests | 17/17 pass |
| Review | ✅ Approved (Claude cross-host) |

**Key fixes from review:**
- `#if canImport(UIKit) && !os(watchOS)` guard
- Removed redundant `@available` annotation

### 1.3 BenchmarkKit ✅

| Aspect | Detail |
|--------|--------|
| Repo | [`swiftanvil-anvil-bench`](https://github.com/swiftanvil/swiftanvil-anvil-bench) |
| Source | Extracted from Turnip iOS, generalized |
| Products | `BenchmarkKit` (core), `BenchmarkKitSwiftUI` (dashboard UI) |
| Core Types | `BenchmarkID<T>`, `BenchmarkRun`, `BenchmarkSample`, `BenchmarkTrendEvaluator`, `BenchmarkTrait` |
| Platforms | iOS 16+, macOS 13+ |
| Tests | 78/78 pass |
| Review | ✅ Approved (Claude cross-host) |

**Key fixes from review:**
- Added `BenchmarkTrait` for `@Test(.benchmark(iterations:))`
- Added comprehensive `package.readme`
- Removed empty `BenchmarkKitSwiftUITests` target
- Removed redundant `StrictConcurrency` flags

### 1.4 AppStrings ✅

| Aspect | Detail |
|--------|--------|
| Repo | [`swiftanvil-anvil-strings`](https://github.com/swiftanvil/swiftanvil-anvil-strings) |
| Source | Designed from scratch |
| Core Types | `AppString`, `AppStringCatalog`, `AppStringBuilder` |
| Platforms | iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, visionOS 1+ |
| Tests | 21/21 pass |
| Review | ✅ Approved (Claude cross-host) |

**Key fixes from review:**
- Added comprehensive `package.readme`
- Removed redundant `StrictConcurrency` flags

### 1.5 GitHub Organization ✅

| Aspect | Detail |
|--------|--------|
| Org | [`github.com/swiftanvil`](https://github.com/swiftanvil) |
| Brand | "⚡ Swift developer tooling forge. We forge the code. You ship it." |
| Repos | 4 code repos + `.github` profile repo |
| Configured | Issue templates, PR template, CI workflow, branch protection, discussions, LICENSE, CONTRIBUTING, CODE_OF_CONDUCT |
| Review | ✅ Approved (Claude cross-host) |

**Key fixes from review:**
- Moved org README to `org.profile-readme`
- Changed repo status from "Stable" → "In Progress"
- Added MIT LICENSE
- Added CI workflow template
- Added PR template
- Added org.contributing + org.code-of-conduct
- Added branch protection to `.github` repo

---

## Phase Gate: 1 → 2

- [x] All Phase 1 children complete
- [x] All Phase 1 children reviewed (code children: cross-host; research: self-reviewed)
- [x] All review blockers fixed
- [x] Phase 1 summary reviewed (Claude cross-host, 2026-06-03)
- [x] **User approval to proceed** — Phase 2 work started (Child 2.1 complete)

---

## Phase 2: Core Packages 🟡

> Build the packages that most apps need.

### 2.1 AnvilNetwork Package ✅

| Aspect | Detail |
|--------|--------|
| Repo | [`swiftanvil-anvil-network`](https://github.com/swiftanvil/swiftanvil-anvil-network) |
| Source | Designed from scratch |
| Core Types | `HTTPClient`, `HTTPRequestBuilder`, `HTTPResponse`, `HTTPTransport`, `NetworkError`, `HTTPResponseCache`, `RetryConfiguration` |
| Platforms | iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, visionOS 1+ |
| Tests | 29/29 pass |
| Review | ✅ Approved (Claude cross-host, 2 rounds: plan + impl) |

**Key design decisions:**
- `HTTPClient` = `Sendable` struct wrapping `actor HTTPClientCore` for safe concurrent access
- Builder-pattern API: `client.get("/users").header("Auth", token).decode()`
- `HTTPTransport` protocol for testability (mock injection)
- Actor-isolated LRU cache with TTL + ETag support
- Exponential backoff with full jitter, respects `Retry-After`
- Interceptor chain: `RequestInterceptor` + `ResponseInterceptor` protocols

### 2.2 FeatureFlags Package ✅

| Aspect | Detail |
|--------|--------|
| Repo | [`swiftanvil-anvil-flags`](https://github.com/swiftanvil/swiftanvil-anvil-flags) |
| Source | Designed from scratch |
| Core Types | `FeatureFlags`, `FeatureFlagSystem`, `FeatureFlagKey`, `FeatureFlagValue`, `FeatureFlagSource`, `InMemoryFeatureFlagSource`, `JSONFileFeatureFlagSource`, `ABTest`, `StableHashBucketingStrategy` |
| Platforms | iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, visionOS 1+ |
| Tests | 37/37 pass |
| Review | ✅ Approved (Claude plan v3, Codex impl — 2 rounds) |

**Key design decisions:**
- `@TaskLocal` for parallel-safe test injection (`withSystem()`)
- `FeatureFlagValueConvertible` protocol — direct unwrap for primitives, JSONDecoder for Decodable
- FNV-1a (pure Swift) for cross-platform A/B bucketing
- Actor-isolated `FeatureFlagSystem` with atomic `configure(sources:)`
- Source priority: first match wins

### 2.3 Developer Menu Package ✅

| Aspect | Detail |
|--------|--------|
| Repo | [`swiftanvil-anvil-devmenu`](https://github.com/swiftanvil/swiftanvil-anvil-devmenu) |
| Source | Designed from scratch |
| Core Types | `DeveloperMenu`, `DeveloperMenuConfiguration`, `NetworkLogStore`, `LogCollector`, `CustomAction`, `CustomActionRegistry`, `DeviceInfo`, `MenuItem`, `NetworkLogEntry` |
| Platforms | iOS 16+, macOS 13+, tvOS 16+, watchOS 9+, visionOS 1+ |
| Tests | 16/16 pass |
| Review | ✅ Approved (Codex cross-host — 2 rounds) |

**Key design decisions:**
- `@MainActor` singleton for UI-only access pattern (no TaskLocal needed)
- Triple-tap overlay (`GestureOverlay`) + shake-to-open (`ShakeDetectingWindow`)
- Optional integration stubs for AnvilFlags/AnvilNetwork via `#if canImport`
- Memory-safe: max 100 network entries, max 500 log messages
- `#if DEBUG` stripping at call site (package builds for all configs)

### ~~2.4 Documentation System~~

**Moved to Phase 3 CLI** — `swiftanvil docs generate` will handle DocC generation across all packages.

**Rationale:** Documentation generation is a tooling concern, not a runtime package. Fits better in CLI phase.

---

## Phase 3: CLI & Integration ⚪

> The `swiftanvil` CLI tool that ties everything together.

### 3.1 Wizard System ✅

| Aspect | Detail |
|--------|--------|
| Repo | [`swiftanvil-anvil-wizard`](https://github.com/swiftanvil/swiftanvil-anvil-wizard) |
| Source | Designed from scratch |
| Core Types | `Wizard<Result>`, `WizardAnswers`, `Prompt<T>`, `TextPrompt`, `ConfirmPrompt`, `ChoicePrompt`, `InputReader`, `OutputWriter`, `TerminalInputReader`, `TerminalOutputWriter` |
| Platforms | macOS 13+ |
| Tests | 20/20 pass |
| Review | ✅ Approved (Codex cross-host, 2 rounds plan + 2 rounds impl) |

**Key design decisions:**
- Generic `Wizard<Result>` with `(WizardAnswers) throws -> Result` closure for type-safe result construction
- `Prompt<T>` protocol — extensible prompt system
- `InputReader`/`OutputWriter` protocols for full testability (mock injection)
- Terminal raw mode with ISIG disabled (Ctrl-C returns byte, not SIGINT), restored via `defer`
- Non-interactive mode `.nonInteractive(answers:)` for CI/automation

### 3.2 Template Engine

Stencil-based template system for generating boilerplate code.

### 3.3 Project Generator

`swiftanvil create app` — generates a full Xcode project with SwiftAnvil packages pre-configured.

### 3.4 Documentation Generator

`swiftanvil docs generate` — generates DocC documentation across all packages with custom theme.

**Moved from Phase 2.4** — documentation is a tooling concern, not a runtime package.

### 3.5 Testing & Verification

Built-in test runner integration, snapshot testing setup, CI config generation.

---

## Phase 4: Ecosystem ⚪

> Community and distribution.

### 4.1 Community Templates

Template gallery contributed by the community.

### 4.2 Plugin System

Extensible plugin architecture for custom generators.

### 4.3 Release & Distribution

Homebrew tap, Swift Package Index listing, release automation.

---

## 📊 Test Summary

| Package | Tests | Last Verified |
|---------|-------|---------------|
| A11yIdentifiers | 17/17 | 2026-06-02 |
| BenchmarkKit | 78/78 | 2026-06-02 |
| AppStrings | 21/21 | 2026-06-02 |
| AnvilNetwork | 29/29 | 2026-06-03 |
| AnvilFlags | 37/37 | 2026-06-03 |
| AnvilDevMenu | 16/16 | 2026-06-03 |
| AnvilWizard | 20/20 | 2026-06-03 |
| iFoundation CLI | 8/8 | 2026-06-02 |
| **Total** | **225/225** | **100%** |

*Note: iFoundation CLI is the root project scaffolding tool, not a published package. Lives in this repo.*

---

## 🏛️ Architecture Decisions

| Decision | Rationale | Date |
|----------|-----------|------|
| Multi-repo org | Pointfreeco pattern — independent packages, independent versioning | 2026-06-02 |
| `swiftanvil` naming | Taken: `iFoundation`. Chosen: industrial, forge metaphor, Gen Z friendly | 2026-06-02 |
| Swift 6 + StrictConcurrency | Future-proof, eliminates data race bugs at compile time | 2026-06-02 |
| Swift Testing over XCTest | Modern, expressive, built-in concurrency support | 2026-06-02 |
| No website yet | Build packages first, website post-v1.0 | 2026-06-02 |
| Agent-agnostic orchestration | Any model can build, any *different* model can review | 2026-06-02 |
| Phase 2 simplified | AppNetworking builder-first (macros later), docs moved to CLI | 2026-06-02 |
| 5-step per-child workflow | PLAN → REVIEW → EXECUTE → VERIFY → DOCUMENT | 2026-06-03 |

---

## 🔗 Quick Links

| Resource | URL |
|----------|-----|
| Org | https://github.com/swiftanvil |
| A11yIdentifiers | https://github.com/swiftanvil/swiftanvil-anvil-a11y |
| BenchmarkKit | https://github.com/swiftanvil/swiftanvil-anvil-bench |
| AppStrings | https://github.com/swiftanvil/swiftanvil-anvil-strings |
| AnvilNetwork | https://github.com/swiftanvil/swiftanvil-anvil-network |
| AnvilFlags | https://github.com/swiftanvil/swiftanvil-anvil-flags |
| AnvilDevMenu | https://github.com/swiftanvil/swiftanvil-anvil-devmenu |
| AnvilWizard | https://github.com/swiftanvil/swiftanvil-anvil-wizard |
| CLI | https://github.com/swiftanvil/swiftanvil-cli |
| **Workflow Guide** | **workflow.general** |
| **Orchestration** | **workflow.orchestration** |

---

*Last updated: 2026-06-03*

---

## Phase Gate: 2 → 3

- [x] All Phase 2 children complete
- [x] All Phase 2 children cross-host reviewed (Codex for impl, Claude for 2.1/2.2 plans)
- [x] All review blockers fixed (3 rounds for some packages)
- [x] Phase 2 summary reviewed (Codex cross-host)
- [x] **User approval to proceed** — Phase 3 started (Child 3.1 complete)

---

## Phase 3 Progress

- [x] Child 3.1: Wizard System
- [ ] Child 3.2: Template Engine
- [ ] Child 3.3: Project Generator
- [ ] Child 3.4: Documentation Generator
- [ ] Child 3.5: Testing & Verification
