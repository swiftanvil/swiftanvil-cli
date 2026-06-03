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
