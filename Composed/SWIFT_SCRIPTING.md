# ADR-010: Swift Scripting Strategy

## Status
Accepted

## Context
Scripts are needed for pre-commit hooks, CI checks, localization audits, accessibility scans, etc. Traditionally these are written in shell (bash), but shell scripts are error-prone, hard to debug, and platform-dependent.

## Decision
**All scripts in iFoundation are written in Swift**, not shell. This applies to:
- Pre-commit hooks
- CI scripts
- Localization checks
- Accessibility audits
- Benchmark comparisons
- Documentation generation

## Rationale

### Why Swift Over Shell?

| Concern | Shell (Bash) | Swift |
|---------|-------------|-------|
| Type safety | None | Full compile-time checking |
| Error handling | `set -e` (fragile) | `try/catch`, `Result` |
| IDE support | Minimal | Full Xcode/VS Code support |
| Debugging | `echo` statements | LLDB breakpoints |
| Cross-platform | macOS/Linux differences | Works identically everywhere |
| Maintainability | Hard to read | Structured, clear |
| Testing | Difficult | Unit tests with XCTest |
| LLM context | Ambiguous | Structured, typed |

### Script Structure

```swift
#!/usr/bin/env swift
// scripts/check-localization.swift
// Validates that all localization keys have translations

import Foundation

// MARK: - Types

struct LocalizationKey: Hashable {
    let key: String
    let table: String
}

struct MissingTranslation {
    let key: LocalizationKey
    let language: String
}

// MARK: - Main

@main
struct LocalizationChecker {
    static func main() async throws {
        let checker = LocalizationChecker()
        let missing = try await checker.findMissingTranslations()
        
        if missing.isEmpty {
            print("✅ All translations complete")
            exit(0)
        } else {
            print("❌ Missing \(missing.count) translations:")
            for item in missing {
                print("  - \(item.key.key) in \(item.language)")
            }
            exit(1)
        }
    }
}

// MARK: - Implementation

extension LocalizationChecker {
    func findMissingTranslations() async throws -> [MissingTranslation] {
        let catalog = try loadStringCatalog()
        let supportedLanguages = catalog.supportedLanguages
        var missing: [MissingTranslation] = []
        
        for key in catalog.keys {
            for language in supportedLanguages {
                if !catalog.hasTranslation(key: key, language: language) {
                    missing.append(MissingTranslation(key: key, language: language))
                }
            }
        }
        
        return missing
    }
    
    private func loadStringCatalog() throws -> StringCatalog {
        // Implementation
        fatalError("TODO: Implement")
    }
}

// MARK: - Models

struct StringCatalog {
    let keys: [LocalizationKey]
    let supportedLanguages: [String]
    
    func hasTranslation(key: LocalizationKey, language: String) -> Bool {
        // Implementation
        true
    }
}
```

## Script Runner

iFoundation provides a script runner for host-agnostic execution:

```bash
# Run a script
ifoundation run-script check-localization

# Run with arguments
ifoundation run-script accessibility-audit --strict

# List available scripts
ifoundation run-script --list
```

## Script Registry

```yaml
# .foundation/scripts.yml
scripts:
  check-localization:
    path: scripts/check-localization.swift
    description: Verify all strings have translations
    arguments:
      - name: strict
        type: flag
        description: Fail on warnings
    
  accessibility-audit:
    path: scripts/accessibility-audit.swift
    description: Check accessibility compliance
    
  benchmark-compare:
    path: scripts/benchmark-compare.swift
    description: Compare benchmarks with baseline
    arguments:
      - name: baseline
        type: string
        default: main
```

## Pre-commit Hook (Swift)

```swift
#!/usr/bin/env swift
// .git/hooks/pre-commit

import Foundation

@main
struct PreCommitHook {
    static func main() async throws {
        let runner = ScriptRunner()
        
        // Run checks in parallel
        async let formatCheck = runner.run("swiftformat", arguments: ["--lint", "."])
        async let lintCheck = runner.run("swiftlint", arguments: ["lint", "--strict"])
        async let localizationCheck = runner.runScript("check-localization")
        async let accessibilityCheck = runner.runScript("accessibility-audit")
        
        let results = try await [formatCheck, lintCheck, localizationCheck, accessibilityCheck]
        
        let failures = results.filter { $0.exitCode != 0 }
        if !failures.isEmpty {
            print("❌ Pre-commit checks failed:")
            for failure in failures {
                print("  - \(failure.command): \(failure.stderr)")
            }
            exit(1)
        }
        
        print("✅ All checks passed")
    }
}
```

## Shell Script Wrapper (For Git Hooks)

Since Git hooks must be executable files, we provide a thin shell wrapper:

```bash
#!/bin/sh
# .git/hooks/pre-commit (shell wrapper)
# This file is auto-generated by iFoundation

set -e

# Find Swift executable
SWIFT="$(which swift)"
if [ -z "$SWIFT" ]; then
    echo "Error: Swift not found in PATH"
    exit 1
fi

# Run the Swift pre-commit script
exec "$SWIFT" scripts/pre-commit.swift
```

## CI Script (Swift)

```swift
#!/usr/bin/env swift
// scripts/ci-build.swift

import Foundation

@main
struct CIBuild {
    static func main() async throws {
        let builder = CIBuilder()
        
        try await builder.step("Build") {
            try await shell("swift", "build")
        }
        
        try await builder.step("Test") {
            try await shell("swift", "test")
        }
        
        try await builder.step("Lint") {
            try await shell("swiftlint", "lint", "--strict")
        }
        
        try await builder.step("Documentation") {
            try await shell("swift", "docc", "convert", "...")
        }
    }
}
```

## Consequences

### Positive
- **Type safety**: Catch errors at compile time
- **IDE support**: Debug scripts in Xcode
- **Cross-platform**: Same script on macOS and Linux
- **Maintainability**: One language for everything
- **Testability**: Unit test your scripts

### Negative
- **Startup time**: Swift compilation is slower than shell
- **Binary size**: Scripts are larger than shell
- **Dependencies**: May need to resolve packages

## Mitigations
- Cache compiled scripts (`.foundation/scripts-cache/`)
- Use `swiftc` for one-time compilation
- Keep scripts focused and small

## Related
- ADR-002: Host Agnosticism
- ADR-006: Pre-commit Enforcement Rules


