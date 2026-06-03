# iFoundation Build Checklist

## Phase 1: Foundation

### Child 1.1: Research Swift OSS Best Practices
- [ ] Research Pointfreeco organization structure
- [ ] Research Apple swift-* package patterns
- [ ] Research Vapor/Apollo package organization
- [ ] Document findings in `Children/1.1/RESEARCH.md`
- [ ] Cross-host review (Claude)
- [ ] **APPROVED**

### Child 1.2: Extract A11yIdentifiers from Turnip iOS
- [ ] Analyze Turnip iOS A11yIdentifiers implementation
- [ ] Design generalized API
- [ ] Create package structure
- [ ] Implement core types
- [ ] Add SwiftUI integration
- [ ] Write tests
- [ ] Write documentation
- [ ] Verify build + tests pass
- [ ] Cross-host review (Claude)
- [ ] **APPROVED**

### Child 1.3: Extract BenchmarkKit from Turnip iOS
- [ ] Analyze Turnip iOS BenchmarkKit implementation
- [ ] Design generalized API
- [ ] Create package structure
- [ ] Implement core types
- [ ] Add UI components
- [ ] Write tests
- [ ] Write documentation
- [ ] Verify build + tests pass
- [ ] Cross-host review (Claude)
- [ ] **APPROVED**

### Child 1.4: Design AppStrings Package
- [ ] Research localization patterns
- [ ] Design API
- [ ] Implement LocalizedString type
- [ ] Implement SwiftUI extensions
- [ ] Add parameter interpolation
- [ ] Write tests
- [ ] Write documentation
- [ ] Verify build + tests pass
- [ ] Cross-host review (Claude)
- [ ] **APPROVED**

### Child 1.5: Set Up GitHub Organization
- [ ] Check org name availability
- [ ] Create organization
- [ ] Configure org settings
- [ ] Create org README repo
- [ ] Create package repo template
- [ ] Configure GitHub Actions template
- [ ] Create issue templates
- [ ] Create PR template
- [ ] Document org structure
- [ ] Cross-host review (Claude)
- [ ] **APPROVED**

## Phase Gate: Phase 1 → Phase 2
- [ ] All children approved
- [ ] User approval
- [ ] Phase 2 plan ready

## Phase 2: Core Packages
- [ ] Child 2.1: AppNetworking Package
- [ ] Child 2.2: FeatureFlags Package
- [ ] Child 2.3: Developer Menu Package
- [ ] Child 2.4: Documentation System

## Phase 3: CLI & Integration
- [ ] Child 3.1: Wizard System
- [ ] Child 3.2: Template Engine
- [ ] Child 3.3: Project Generator
- [ ] Child 3.4: Testing & Verification

## Phase 4: Ecosystem
- [ ] Child 4.1: Community Templates
- [ ] Child 4.2: Plugin System
- [ ] Child 4.3: Release & Distribution

## Overall Progress

| Phase | Status | Children Complete | Total Children |
|-------|--------|-------------------|----------------|
| Phase 1 | 🟢 Complete | 5/5 | 5 |
| Phase 2 | ⚪ Planned | 0/3 | 3 |
| Phase 3 | ⚪ Planned | 0/5 | 5 |
| Phase 4 | ⚪ Planned | 0/3 | 3 |

## Single Source of Truth

📍 **ROADMAP.md** — The living document for what's built, what's next, and why.

## Phase Gate: Phase 1 → Phase 2

- [x] All children approved
- [x] All review blockers fixed
- [ ] User approval ← You are here

**Legend:**
- 🟢 Complete
- 🟡 In Progress
- 🔴 Blocked
- ⚪ Not Started

## Phase 2: Core Packages (Revised)

### Child 2.1: AppNetworking Package
- [ ] Design builder-pattern API (macros deferred to Phase 3+)
- [ ] Implement HTTP client with caching
- [ ] Add retry and observability
- [ ] Write tests
- [ ] Write README
- [ ] Cross-host review

### Child 2.2: FeatureFlags Package
- [ ] Design local + JSON file API
- [ ] Implement flag evaluation
- [ ] Add A/B test support
- [ ] Write tests
- [ ] Write README
- [ ] Cross-host review

### Child 2.3: Developer Menu Package
- [ ] Design SwiftUI debug menu
- [ ] Integrate with a11y/bench/flags
- [ ] Add release-build stripping
- [ ] Write tests
- [ ] Write README
- [ ] Cross-host review

## Phase 3: CLI & Integration (Revised)

### Child 3.1: Wizard System
- [ ] Interactive scaffolding wizard

### Child 3.2: Template Engine
- [ ] Stencil-based template system

### Child 3.3: Project Generator
- [ ] `swiftanvil create app` command

### Child 3.4: Documentation Generator
- [ ] `swiftanvil docs generate` command
- [ ] DocC integration across packages

### Child 3.5: Testing & Verification
- [ ] Built-in test runner integration
- [ ] Snapshot testing setup
- [ ] CI config generation
