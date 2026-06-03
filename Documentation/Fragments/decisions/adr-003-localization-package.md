# ADR-003: Localization as a Separate Package

## Status
Accepted

## Context
In multi-module Swift projects, localization strings are often scattered across targets, leading to:
- Duplicate string definitions
- Inconsistent naming conventions
- Hardcoded literal strings in UI code
- Difficult-to-test localization coverage
- No compile-time safety for string keys

## Decision
Create a dedicated `AppStrings` (or `L10n`) Swift Package that:
1. Defines ALL user-facing strings as typed enum hierarchies
2. Exposes a single `LocalizedString` type-safe accessor
3. Is consumed by ALL other modules (app, features, UI tests)
4. Includes unit tests verifying every string has translations for all supported languages

## Structure

```
AppStrings/
├── Package.swift
└── Sources/
    └── AppStrings/
        ├── Core/
        │   ├── LocalizedString.swift      # Type-safe accessor
        │   ├── StringKey.swift            # Protocol for all keys
        │   └── LocalizationBundle.swift   # Bundle resolution
        └── Modules/
            ├── Settings/
            │   └── SettingsStrings.swift
            ├── Home/
            │   └── HomeStrings.swift
            └── Common/
                └── CommonStrings.swift
```

## Usage Pattern

```swift
// Definition
public enum SettingsStrings {
    public enum AccountSection {
        public static let title = LocalizedString("settings.account.title")
        public static let logout = LocalizedString("settings.account.logout")
        public static let deleteAccount = LocalizedString("settings.account.delete")
    }
    
    public enum HelpSection {
        public static let faqTitle = LocalizedString("settings.help.faq_title")
        public static let contactSupport = LocalizedString("settings.help.contact")
    }
}

// Usage in SwiftUI
Text(SettingsStrings.AccountSection.title)
    .accessibilityIdentifier(SettingsA11y.AccountSection.logoutRow)

// Usage with parameters
Text(SettingsStrings.HelpSection.faqTitle.withCount(5))
```

## Consequences

### Positive
- **Compile-time safety**: Cannot reference non-existent strings
- **Centralized**: All strings in one place, easy to audit
- **Testable**: Unit tests verify translation coverage per language
- **LLM-friendly**: AI agents can generate/update strings in one file
- **Reusable**: Shared across app target, feature modules, and UI tests

### Negative
- **Additional package**: Slightly more complex dependency graph
- **Coordination**: Module authors must add strings to shared package

## Related
- ADR-004: Accessibility Identifiers as a Separate Package
- ADR-005: DocC Documentation Strategy
