# Child 1.4 Plan: Design AppStrings Package

## Objective
Design and implement a type-safe localization package from scratch, inspired by A11yIdentifiers patterns and Turnip iOS localization practices.

## Goals
- [ ] Design API (LocalizedString type, enum generation pattern)
- [ ] Implement core types
- [ ] Add SwiftUI integration
- [ ] Add tests
- [ ] Add documentation
- [ ] Verify it builds and tests pass

## Non-Goals
- [ ] Don't implement string catalog parsing (future)
- [ ] Don't implement LLM translation (future)
- [ ] Don't support plurals/complex formatting (v2)

## Design Principles
1. **Type-safe**: No string literals in UI code
2. **Consistent with A11yIdentifiers**: Same pattern, different domain
3. **LLM-friendly**: Clear structure for AI generation
4. **Testable**: Easy to verify translations exist

## Task Breakdown

| # | Task | Effort | Verification |
|---|------|--------|--------------|
| 1 | Research localization patterns | 15 min | Review A11yIdentifiers, NSLocalizedString |
| 2 | Design API | 20 min | Document in plan |
| 3 | Implement LocalizedString type | 20 min | Core functionality works |
| 4 | Implement SwiftUI extensions | 15 min | Text(LocalizedString) works |
| 5 | Add parameter interpolation | 15 min | `.with()` method works |
| 6 | Add tests | 20 min | ≥80% coverage |
| 7 | Write README | 15 min | Clear usage examples |
| 8 | Write Package.swift | 5 min | Valid, minimal |
| 9 | Verify build + tests | 10 min | All pass |

## Proposed API

```swift
// Core type
public struct LocalizedString: ExpressibleByStringLiteral, Sendable {
    public let key: String
    public let table: String
    public let bundle: Bundle
    
    public var value: String {
        NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
    }
    
    public init(_ key: String, table: String = "Localizable", bundle: Bundle = .main)
    
    public func with(_ args: CVarArg...) -> String
}

// SwiftUI integration
extension Text {
    public init(_ localized: LocalizedString)
}

// Generated per project (by CLI)
public enum SettingsStrings {
    public enum AccountSection {
        public static let title = LocalizedString("settings.account.title")
        public static let logout = LocalizedString("settings.account.logout")
    }
}

// Usage
Text(SettingsStrings.AccountSection.logout)
    .a11yID(SettingsA11y.AccountSection.logoutRow)
```

## Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| API doesn't feel Swifty | Medium | Iterate based on review |
| Overlaps with Apple's API | Low | Complement, don't replace |
| Complex localization needs | Low | Start simple, expand later |

## Success Criteria
- Package builds with `swift build` ✅
- Tests pass with `swift test` ✅
- API feels consistent with A11yIdentifiers ✅
- README has clear usage examples ✅
- Works with SwiftUI ✅

## Output Location
`Packages/ifoundation-appstrings/`

## Dependencies
- Child 1.1 research (for patterns)
- Child 1.2 output (for API consistency)
