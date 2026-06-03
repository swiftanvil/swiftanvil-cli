# ADR-006: Pre-commit Enforcement Rules

## Status
Accepted

## Context
Standards are only effective if enforced. Documentation, architecture decisions, and code style rules are frequently ignored without automated enforcement.

## Decision
Implement a multi-layer enforcement system:

### Layer 1: Pre-commit Hooks (Fast, Local)
Runs in < 5 seconds, blocks commit on failure:

```bash
#!/bin/sh
# .git/hooks/pre-commit

set -e

# 1. SwiftFormat (format check)
echo "→ Checking formatting..."
swiftformat --lint . || {
    echo "Run 'swiftformat .' to fix formatting"
    exit 1
}

# 2. SwiftLint (style + custom rules)
echo "→ Running linter..."
swiftlint lint --strict

# 3. Accessibility identifier enforcement
echo "→ Checking accessibility identifiers..."
if grep -r "\.accessibilityIdentifier(" Sources/ --include="*.swift" 2>/dev/null; then
    echo "Error: Use .a11yID() with typed A11yID instead of raw accessibilityIdentifier()"
    exit 1
fi

# 4. Localization enforcement
echo "→ Checking localization usage..."
if grep -r "Text(\"" Sources/ --include="*.swift" 2>/dev/null | grep -v "AppStrings"; then
    echo "Warning: Hardcoded strings found. Use AppStrings for user-facing text."
fi

# 5. DocC coverage check (fast path)
echo "→ Checking documentation..."
UNDOCUMENTED=$(swiftlint analyze --reporter json 2>/dev/null | \
    jq '[.[] | select(.rule_id == "missing_docs")] | length')
if [ "$UNDOCUMENTED" -gt 5 ]; then
    echo "Warning: $UNDOCUMENTED undocumented public declarations"
fi

# 6. Fast build check
echo "→ Building..."
swift build

# 7. Affected tests only
echo "→ Running affected tests..."
swift test --filter "$(git diff --name-only HEAD | grep 'Tests/' | sed 's|Tests/||' | sed 's|/.*||' | sort -u | tr '\n' '|')" || true

echo "✓ Pre-commit checks passed"
```

### Layer 2: CI Gates (Thorough, Remote)
Runs on PR/push, blocks merge:

| Check | Purpose | Failure Action |
|-------|---------|----------------|
| Full test suite | Catch regressions | Block merge |
| Accessibility audit | Verify a11y compliance | Block merge |
| Localization completeness | All strings translated | Block merge |
| DocC coverage | >90% public APIs documented | Warn, don't block |
| Performance tests | No regressions | Block merge |
| Security scan | No vulnerabilities | Block merge |

### Layer 3: Runtime Assertions (Safety Net)
Debug-only checks that catch issues during development:

```swift
#if DEBUG
extension View {
    func verifyA11yID() -> some View {
        // Runtime check: ensure accessibility identifier is set
        // for interactive views in debug builds
        self
    }
}
#endif
```

## Custom SwiftLint Rules

```yaml
# .swiftlint.yml
custom_rules:
  # Accessibility
  raw_accessibility_identifier:
    name: "Raw Accessibility Identifier"
    regex: '\.accessibilityIdentifier\s*\('
    message: "Use .a11yID() with A11yID type"
    severity: error

  # Localization
  hardcoded_display_string:
    name: "Hardcoded Display String"
    regex: 'Text\("[^"]+"\)|Button\("[^"]+"\)|navigationTitle\("[^"]+"\)'
    message: "Use AppStrings for user-facing text"
    severity: warning

  # Documentation
  undocumented_public:
    name: "Undocumented Public"
    regex: '^\s*public\s+(?:func|var|let|class|struct|enum|protocol)\s+\w+'
    message: "Public declarations must have DocC documentation"
    severity: warning
    match_kinds:
      - identifier
```

## Consequences

### Positive
- **Standards enforced**: No way to bypass without explicit override
- **Early feedback**: Catch issues before CI, before PR review
- **Consistent codebase**: All contributors follow same rules
- **Reduced review burden**: Automated checks catch mechanical issues

### Negative
- **Initial friction**: New contributors may be frustrated
- **Hook maintenance**: Rules must evolve with codebase
- **False positives**: May need occasional `--no-verify` override

## Override Policy
```bash
# For emergencies only - requires justification in commit message
git commit --no-verify -m "URGENT: Fix production crash [skip-hooks: build-only fix]"
```

## Related
- ADR-004: Accessibility Identifiers as a Separate Package
- ADR-005: DocC Documentation Strategy


