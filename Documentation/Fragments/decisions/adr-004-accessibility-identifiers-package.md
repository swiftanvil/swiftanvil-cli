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
