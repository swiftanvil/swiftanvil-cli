# Phase 1 Plan: Foundation

## Objective
Establish the iFoundation organization, extract existing code from Turnip iOS, and create the first packages.

## Children

### Child 1.1: Research Swift OSS Best Practices
- Research how successful Swift OSS projects organize code
- Identify patterns for package structure, CI/CD, documentation
- Document findings for use by other children
- **Output**: `Children/1.1/RESEARCH.md`
- **Effort**: 2-3 hours
- **Dependencies**: None

### Child 1.2: Extract A11yIdentifiers from Turnip iOS
- Extract the A11yIdentifiers package from Turnip iOS
- Generalize it for reuse across projects
- Create standalone package with tests
- **Output**: `Packages/ifoundation-a11yidentifiers/`
- **Effort**: 3-4 hours
- **Dependencies**: Child 1.1

### Child 1.3: Extract BenchmarkKit from Turnip iOS
- Extract the BenchmarkKit package from Turnip iOS
- Generalize it for reuse across projects
- Create standalone package with tests
- **Output**: `Packages/ifoundation-benchmarkkit/`
- **Effort**: 3-4 hours
- **Dependencies**: Child 1.1

### Child 1.4: Design AppStrings Package from Scratch
- Design a type-safe localization package
- Implement core types and SwiftUI integration
- Write tests and documentation
- **Output**: `Packages/ifoundation-appstrings/`
- **Effort**: 2-3 hours
- **Dependencies**: Child 1.1, Child 1.2

### Child 1.5: Set Up GitHub Organization
- Create `github.com/iFoundation` organization
- Set up repo templates, CI/CD, issue templates
- Create organization README and documentation
- **Output**: `github.com/iFoundation`
- **Effort**: 2-3 hours
- **Dependencies**: Child 1.1

## Phase Gate

All children must complete their success criteria before Phase 2 begins:
- [ ] Child 1.1: Research documented
- [ ] Child 1.2: Package builds and tests pass
- [ ] Child 1.3: Package builds and tests pass
- [ ] Child 1.4: Package builds and tests pass
- [ ] Child 1.5: Organization created and configured

## Parallel Execution

Children 1.2, 1.3, 1.4, and 1.5 can run in parallel after Child 1.1 completes.
Child 1.1 should complete first to provide patterns for the others.

## Cross-Host Review

Each child will be reviewed by Claude (cross-host) after execution.
Review checklist:
- Code quality and Swift idioms
- Test coverage
- Documentation completeness
- Consistency with other children
