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
