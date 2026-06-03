# Principle: Type Safety Over String Literals

## Statement
All cross-cutting concerns that are traditionally expressed as string literals MUST be expressed as typed, compile-safe structures. This applies to:

- Localization strings
- Accessibility identifiers
- Notification names
- User defaults keys
- URL routes / deep links
- Analytics events
- Feature flags

## Rationale

### The String Literal Problem
```swift
// ❌ BAD: String literals
Text("Hello, world!")                          // Hardcoded, untranslatable
button.accessibilityIdentifier("logout_btn")   // Typo = silent failure
NotificationCenter.default.post(name: Notification.Name("user_logged_in"), object: nil)
UserDefaults.standard.set(true, forKey: "has_seen_onboarding")
```

Problems:
1. **Typos**: `"logout_btn"` vs `"logout_button"` — runtime failure
2. **No autocomplete**: IDE can't suggest available options
3. **No refactoring**: Rename requires global search/replace
4. **No audit**: Can't enumerate all identifiers programmatically
5. **Duplication**: Same string defined in multiple places
6. **LLM confusion**: Ambiguous context, hard to maintain consistency

### The Type-Safe Solution
```swift
// ✅ GOOD: Type-safe structures
Text(SettingsStrings.Home.greeting)            // Localized, typed
button.a11yID(SettingsA11y.Account.logoutRow)  // Compile-safe
NotificationCenter.default.post(name: .userLoggedIn, object: nil)
UserDefaults.standard.set(true, forKey: .hasSeenOnboarding)
```

Benefits:
1. **Compile-time safety**: Typos are compilation errors
2. **IDE autocomplete**: Discover all available options
3. **Refactoring**: Rename with IDE tools, updates everywhere
4. **Auditability**: Enumerate all cases programmatically
5. **Single source of truth**: Defined once, used everywhere
6. **LLM clarity**: Structured context, consistent patterns

## Implementation Pattern

### Step 1: Define the Core Type
```swift
public struct TypedString: RawRepresentable, ExpressibleByStringLiteral, Hashable, Sendable {
    public let rawValue: String
    public init(rawValue: String) { self.rawValue = rawValue }
    public init(stringLiteral value: String) { self.rawValue = value }
}
```

### Step 2: Define Module Namespaces
```swift
public enum SettingsStrings {
    public enum AccountSection {
        public static let title = TypedString("settings.account.title")
        public static let logout = TypedString("settings.account.logout")
    }
}
```

### Step 3: Provide Convenience APIs
```swift
extension Text {
    init(_ typed: TypedString) {
        self.init(LocalizedStringKey(typed.rawValue))
    }
}

extension View {
    func a11yID(_ id: TypedString) -> some View {
        accessibilityIdentifier(id.rawValue)
    }
}
```

## Enforcement

### SwiftLint Rule
```yaml
custom_rules:
  no_hardcoded_strings:
    regex: 'Text\("[^"]+"\)|Button\("[^"]+"\)'
    message: "Use AppStrings instead of hardcoded strings"
    severity: error
```

### Pre-commit Hook
```bash
if grep -r "\.accessibilityIdentifier(" Sources/ --include="*.swift"; then
    echo "Error: Use .a11yID() with typed identifiers"
    exit 1
fi
```

## Scope

This principle applies to ALL iFoundation-generated projects. The scaffolding tool will:
1. Generate `AppStrings` and `A11yIdentifiers` packages by default
2. Include enforcement rules in generated SwiftLint config
3. Generate pre-commit hooks that block raw string usage
4. Provide templates for adding new typed string categories

## Related
- ADR-003: Localization as a Separate Package
- ADR-004: Accessibility Identifiers as a Separate Package
- ADR-006: Pre-commit Enforcement Rules


# Pattern: Shared Type-Safe Packages

## Problem
Hardcoded string literals for localization and accessibility identifiers lead to:
- Runtime errors from typos
- Inconsistency between app and test targets
- No IDE autocomplete or refactoring support
- Difficult to audit coverage

## Solution
Create dedicated Swift packages that expose type-safe APIs for cross-cutting concerns.

## Pattern Structure

### Package: `AppStrings` (Localization)

```swift
// Core/LocalizedString.swift
public struct LocalizedString: ExpressibleByStringLiteral, Sendable {
    public let key: String
    public let table: String
    public let bundle: Bundle
    
    public var value: String {
        NSLocalizedString(key, tableName: table, bundle: bundle, comment: "")
    }
    
    public init(_ key: String, table: String = "Localizable", bundle: Bundle = .main) {
        self.key = key
        self.table = table
        self.bundle = bundle
    }
    
    public init(stringLiteral value: String) {
        self.key = value
        self.table = "Localizable"
        self.bundle = .main
    }
    
    public func with(_ args: CVarArg...) -> String {
        String(format: value, arguments: args)
    }
}

// SwiftUI Integration
extension Text {
    public init(_ localized: LocalizedString) {
        self.init(LocalizedStringKey(localized.key))
    }
}

// Module Definitions
public enum SettingsStrings {
    public enum AccountSection {
        public static let title = LocalizedString("settings.account.title")
        public static let logout = LocalizedString("settings.account.logout")
    }
}
```

### Package: `A11yIdentifiers` (Accessibility)

```swift
// Core/A11yID.swift
public struct A11yID: RawRepresentable, ExpressibleByStringLiteral, Hashable, Sendable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
    public func appending(_ segment: String) -> A11yID {
        A11yID(rawValue: rawValue.isEmpty ? segment : "\(rawValue).\(segment)")
    }
    
    public func appending(_ segment: Int) -> A11yID {
        A11yID(rawValue: rawValue.isEmpty ? "\(segment)" : "\(rawValue).\(segment)")
    }
}

// SwiftUI Extension
@available(iOS 14.0, macOS 11.0, *)
extension View {
    @inlinable
    public func a11yID(_ id: A11yID) -> some View {
        accessibilityIdentifier(id.rawValue)
    }
}

// UIKit Extension
#if canImport(UIKit)
import UIKit

extension UIView {
    @inlinable
    public func setA11ID(_ id: A11yID) {
        accessibilityIdentifier = id.rawValue
    }
}
#endif

// Module Definitions
public enum SettingsA11y {
    public enum AccountSection {
        public static let logoutRow: A11yID = "settings.account.logout"
        public static let deleteRow: A11yID = "settings.account.delete"
    }
}
```

## Usage in App Code

```swift
import SwiftUI
import AppStrings
import A11yIdentifiers

struct SettingsView: View {
    var body: some View {
        List {
            Section(header: Text(SettingsStrings.AccountSection.title)) {
                Button(action: logout) {
                    Text(SettingsStrings.AccountSection.logout)
                }
                .a11yID(SettingsA11y.AccountSection.logoutRow)
            }
        }
    }
}
```

## Usage in UI Tests

```swift
import XCTest
import A11yIdentifiers

final class SettingsUITests: XCTestCase {
    func testLogoutButtonExists() {
        let app = XCUIApplication()
        app.launch()
        
        let logoutButton = app.buttons[SettingsA11y.AccountSection.logoutRow.rawValue]
        XCTAssertTrue(logoutButton.exists)
    }
}
```

## Benefits

| Concern | String Literal | Type-Safe Package |
|---------|---------------|-------------------|
| Typos | Runtime crash | Compile-time error |
| Refactoring | Manual search/replace | IDE rename support |
| Autocomplete | None | Full IDE support |
| App/Test sync | Manual | Shared source |
| Coverage audit | Impossible | Enumerate all cases |
| LLM context | Ambiguous | Structured, clear |

## Testing Strategy

```swift
// AppStringsTests.swift
import Testing
import AppStrings

struct LocalizationCoverageTests {
    @Test func allStringsHaveTranslations() {
        let supportedLanguages = ["en", "es", "fr", "de", "ja"]
        let allStrings = collectAllStrings()
        
        for string in allStrings {
            for language in supportedLanguages {
                #expect(
                    hasTranslation(string, language: language),
                    "Missing \(language) translation for \(string.key)"
                )
            }
        }
    }
    
    @Test func noDuplicateKeys() {
        let allKeys = collectAllKeys()
        let uniqueKeys = Set(allKeys)
        #expect(allKeys.count == uniqueKeys.count, "Duplicate localization keys found")
    }
}
```

## Related
- ADR-003: Localization as a Separate Package
- ADR-004: Accessibility Identifiers as a Separate Package
- ADR-006: Pre-commit Enforcement Rules


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


# ADR-004: Accessibility Identifiers as a Separate Package

## Status
Accepted

## Context
Accessibility identifiers are critical for:
1. UI automation testing (XCUITest)
2. VoiceOver navigation
3. Automated accessibility audits

Common problems:
- Hardcoded string literals scattered across app and test targets
- App and tests use different identifiers for the same element
- No compile-time verification that identifiers exist
- Inconsistent naming conventions

## Decision
Create a dedicated `A11yIdentifiers` Swift Package that:
1. Defines ALL accessibility identifiers as typed `A11yID` values
2. Provides `.a11yID()` view modifiers for SwiftUI and UIKit
3. Is consumed by BOTH app target AND UI test target
4. Enforces hierarchical dot-notation naming (e.g., `settings.account.logoutRow`)

## Structure (Based on Turnip iOS Pattern)

```
A11yIdentifiers/
├── Package.swift
└── Sources/
    └── A11yIdentifiers/
        ├── Core/
        │   ├── A11yID.swift              # RawRepresentable type
        │   ├── View+A11y.swift           # SwiftUI modifier
        │   └── UIView+A11y.swift         # UIKit extension
        └── Modules/
            ├── Settings/
            │   └── SettingsA11y.swift
            ├── Home/
            │   └── HomeA11y.swift
            └── Common/
                └── CommonA11y.swift
```

## Core Type

```swift
public struct A11yID: RawRepresentable, ExpressibleByStringLiteral, Hashable, Sendable {
    public let rawValue: String
    
    public init(rawValue: String) {
        self.rawValue = rawValue
    }
    
    public init(stringLiteral value: String) {
        self.rawValue = value
    }
    
    public func appending(_ segment: String) -> A11yID {
        A11yID(rawValue: rawValue.isEmpty ? segment : "\(rawValue).\(segment)")
    }
}

// SwiftUI Extension
@available(iOS 14.0, macOS 11.0, *)
extension View {
    @inlinable
    public func a11yID(_ id: A11yID) -> some View {
        accessibilityIdentifier(id.rawValue)
    }
}
```

## Usage Pattern

```swift
// Definition
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

// Usage in SwiftUI
Button("Logout") {
    logout()
}
.a11yID(SettingsA11y.AccountSection.logoutRow)

// Usage in UI Tests
let logoutButton = app.buttons[SettingsA11y.AccountSection.logoutRow.rawValue]
XCTAssertTrue(logoutButton.exists)
```

## Enforcement

### SwiftLint Custom Rule
```yaml
custom_rules:
  raw_accessibility_identifier:
    name: "Raw Accessibility Identifier"
    regex: '\.accessibilityIdentifier\s*\('
    message: "Use .a11yID() with A11yID type instead of raw accessibilityIdentifier()"
    severity: error
```

### Pre-commit Hook
```bash
# Reject direct accessibilityIdentifier calls
if grep -r "\.accessibilityIdentifier(" Sources/ --include="*.swift"; then
    echo "Error: Use .a11yID() with typed A11yID instead"
    exit 1
fi
```

## Consequences

### Positive
- **Single source of truth**: Same identifier in app and tests
- **Compile-time safety**: Cannot use undefined identifiers
- **IDE autocomplete**: Discover all available identifiers
- **Refactoring safe**: Rename identifiers across app + tests
- **Namespace organized**: Hierarchical structure prevents collisions

### Negative
- **Additional package**: One more dependency to manage
- **Discipline required**: Developers must add identifiers before using

## Related
- ADR-003: Localization as a Separate Package
- ADR-006: Pre-commit Enforcement Rules


