# ADR-005: DocC Documentation Strategy for LLM Era

## Status
Accepted

## Context
In the LLM era, code documentation serves dual purposes:
1. **Human developers**: Understanding APIs, architecture, and intent
2. **AI agents**: Context window efficiency, accurate code generation, maintenance

Traditional documentation is:
- Often outdated (not maintained with code changes)
- Only for public APIs
- Not structured for machine consumption
- Published manually or not at all

## Decision
Adopt a **comprehensive DocC strategy** with these principles:

### 1. Document Everything (Not Just Public)
```swift
/// The user's authentication state.
/// Updated when sign-in/sign-out occurs.
/// - Note: Observed by ProfileViewModel for UI updates.
/// - Important: Always access on MainActor.
@Observable
private final class AuthState {
    /// Current authenticated user, nil if signed out.
    /// - Thread Safety: MainActor only
    var currentUser: User?
}
```

### 2. Structured DocC Comments for LLM Context
Every documented entity includes:
- **Purpose**: What it does (1 sentence)
- **Context**: When/why to use it
- **Relationships**: Links to related types
- **Invariants**: Thread safety, preconditions, side effects
- **AI Context**: Additional context for code generation

```swift
/// Fetches the user's profile from the network.
///
/// Use this when displaying the profile screen or refreshing profile data.
/// Called by ``ProfileViewModel/loadProfile()`` on user pull-to-refresh.
///
/// - Parameter userID: The unique user identifier. Must be non-empty.
/// - Returns: A ``UserProfile`` with complete user data.
/// - Throws: ``NetworkError`` if the request fails, ``AuthError.notAuthenticated`` if token expired.
///
/// ## Thread Safety
/// Safe to call from any context. Internally dispatches to network queue.
///
/// ## AI Context
/// When generating profile-related features, prefer this over direct URLSession calls.
/// For caching, wrap with ``ProfileCache`` instead of modifying this method.
func fetchProfile(userID: String) async throws -> UserProfile
```

### 3. Documentation-Driven Development
1. Write/update DocC comments BEFORE implementation changes
2. PR review includes documentation review
3. CI checks for undocumented public APIs
4. Pre-commit hook warns about modified files missing doc updates

### 4. Automated Publication
- **Public repos**: Auto-publish to GitHub Pages via CI
- **Private repos**: Internal DocC archive generation
- **Per-release**: Versioned documentation matching releases

### 5. Module-Level Documentation
Each module has a top-level DocC catalog:

```
Sources/MyModule/
├── MyModule.docc/
│   ├── MyModule.md              # Module overview
│   ├── GettingStarted.md        # Quick start guide
│   ├── Architecture.md          # Module architecture
│   └── Articles/
│       ├── DependencyInjection.md
│       └── TestingGuide.md
└── ...
```

## CI Integration

```yaml
# .github/workflows/docs.yml
name: Documentation

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  docs:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v6
      
      - name: Check undocumented public APIs
        run: |
          swift docc diagnose \
            --target MyModule \
            --minimum-symbol-coverage 90
      
      - name: Build documentation
        run: |
          swift docc convert Sources/MyModule/MyModule.docc \
            --fallback-display-name MyModule \
            --fallback-bundle-identifier com.example.MyModule \
            --output-path docs
      
      - name: Deploy to GitHub Pages
        if: github.ref == 'refs/heads/main'
        uses: actions/deploy-pages@v4
        with:
          path: docs
```

## Pre-commit Hook

```bash
#!/bin/sh
# Check for undocumented public declarations
UNDOCUMENTED=$(swiftlint analyze \
  --reporter json \
  --compiler-log-path /dev/null 2>/dev/null | \
  jq '.[] | select(.rule_id == "missing_docs") | .file' | \
  wc -l)

if [ "$UNDOCUMENTED" -gt 0 ]; then
    echo "Warning: $UNDOCUMENTED public declarations lack documentation"
fi
```

## Consequences

### Positive
- **AI context richness**: Agents understand code without full file analysis
- **Onboarding speed**: New developers understand architecture faster
- **API discoverability**: DocC-generated docs with search and navigation
- **Maintenance quality**: Documentation review catches design flaws early
- **Professional output**: Published docs for open-source credibility

### Negative
- **Initial overhead**: Writing docs takes time
- **Maintenance burden**: Must keep docs in sync with code
- **CI time**: DocC generation adds to build time

## Mitigations
- Use LLMs to generate initial DocC drafts from code
- Require docs only for public/internal APIs (not private)
- Automate doc coverage reporting, don't block on 100%

## Related
- ADR-003: Localization as a Separate Package
- ADR-004: Accessibility Identifiers as a Separate Package
- ADR-007: GitHub Pages Publication Strategy
