# Pattern: DocC for LLM Context Engineering

## Problem
AI agents working with codebases struggle with:
- Missing context about WHY code exists
- No understanding of relationships between components
- Re-generating existing solutions due to lack of discovery
- Producing code that violates architectural constraints

## Solution
Use DocC comments as **structured context injection points** for both humans and AI.

## DocC as LLM Context

### Standard DocC (Human-focused)
```swift
/// Fetches user profile.
/// - Parameter id: User ID
/// - Returns: User profile
func fetchProfile(id: String) async throws -> Profile
```

### Enhanced DocC (Human + AI)
```swift
/// Fetches the user's profile from the backend API.
///
/// Use this as the primary way to load profile data. Do NOT call
/// ``UserAPI/rawFetch(path:)`` directly — always use this method
/// to ensure caching and error handling are applied.
///
/// ## When to Use
/// - Profile screen initial load
/// - Pull-to-refresh on profile
/// - After profile update to get fresh data
///
/// ## When NOT to Use
/// - For batch operations: use ``ProfileBatchLoader`` instead
/// - For cached data only: use ``ProfileCache/get(id:)`` instead
///
/// ## Related
/// - ``ProfileViewModel`` - UI layer that calls this
/// - ``ProfileCache`` - Caching layer used internally
/// - ``AuthInterceptor`` - Adds auth token to request
///
/// ## AI Context
/// Architecture: This is part of the Repository layer in MVVM.
/// Dependencies: NetworkService, ProfileCache, AuthInterceptor.
/// Threading: Safe from any context. Internally uses custom queue.
/// Testing: Mock NetworkService and ProfileCache. See ProfileServiceTests.
///
/// - Parameter id: The user's unique identifier. Must match AuthState.currentUser.id.
/// - Returns: Complete profile with avatar URL, display name, and preferences.
/// - Throws:
///   - ``NetworkError.notConnected`` when offline
///   - ``AuthError.tokenExpired`` when session expired (triggers logout)
///   - ``ProfileError.notFound`` when user doesn't exist
func fetchProfile(id: String) async throws -> Profile
```

## Structured Sections for AI

### `@ai-context` (Custom)
```swift
/// @ai-context
/// - Layer: Repository
/// - Pattern: Async Repository with Cache-aside
/// - Test Strategy: Mock dependencies, test error paths
/// - Common Mistakes: Don't forget to invalidate cache on update
```

### `@ai-usage` (Custom)
```swift
/// @ai-usage
/// When generating code that needs profile data:
/// 1. Check if cached data is sufficient (ProfileCache)
/// 2. If not, call this method
/// 3. Handle AuthError.tokenExpired by routing to login
/// 4. Never call NetworkService directly for profile endpoints
```

## Module-Level AI Context

```markdown
<!-- Sources/MyModule/MyModule.docc/MyModule.md -->
# MyModule

## Overview
User-facing feature module for profile management.

## Architecture
- **View**: ``ProfileView``, ``EditProfileView``
- **ViewModel**: ``ProfileViewModel``, ``EditProfileViewModel``
- **Service**: ``ProfileService`` (repository layer)
- **Cache**: ``ProfileCache`` (local persistence)

## AI Agent Guide
When working on profile-related features:
1. All user-facing strings go in ``AppStrings/ProfileStrings``
2. All accessibility IDs go in ``A11yIdentifiers/ProfileA11y``
3. Network calls go through ``ProfileService``, never direct
4. Images use ``ImageLoader`` with profile-specific cache config
5. Tests mock ``ProfileServiceProtocol``, never hit network

## Common Patterns
### Adding a New Profile Field
1. Add to ``Profile`` model
2. Add to ``ProfileService.fetchProfile`` response parsing
3. Add UI in ``ProfileView`` or ``EditProfileView``
4. Add string to ``ProfileStrings``
5. Add a11y ID to ``ProfileA11y``
6. Add test in ``ProfileServiceTests``

## Dependencies
- ``AppStrings`` (localization)
- ``A11yIdentifiers`` (accessibility)
- ``NetworkModule`` (HTTP client)
- ``ImageModule`` (image loading)
```

## CI: Documentation Quality Gates

```yaml
# .github/workflows/docs-quality.yml
name: DocC Quality

on: [pull_request]

jobs:
  docs:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Check AI context coverage
        run: |
          # Verify all public APIs have @ai-context or equivalent
          ./scripts/check-ai-context.sh
      
      - name: Check cross-references
        run: |
          # Verify all ``TypeName`` references resolve
          swift docc convert --diagnose-missing-symbols
      
      - name: Generate context report
        run: |
          # Generate a summary of documented vs undocumented APIs
          # for PR review and LLM consumption
          swift docc stats --format json > docs-context.json
```

## Pre-commit: DocC Maintenance

```bash
#!/bin/sh
# Check if modified files have corresponding doc updates

MODIFIED_SWIFT=$(git diff --cached --name-only --diff-filter=AM | grep '\.swift$')

for file in $MODIFIED_SWIFT; do
    # Check if file contains public declarations without docs
    UNDOCUMENTED=$(swiftlint analyze --path "$file" --reporter json 2>/dev/null | \
        jq '[.[] | select(.rule_id == "missing_docs")] | length')
    
    if [ "$UNDOCUMENTED" -gt 0 ]; then
        echo "Warning: $file has $UNDOCUMENTED undocumented public declarations"
    fi
done
```

## Publication Strategy

### GitHub Pages (Public Repos)
```yaml
- name: Build and deploy DocC
  run: |
    swift docc convert Sources/MyModule/MyModule.docc \
      --fallback-display-name MyModule \
      --fallback-bundle-identifier com.example.MyModule \
      --output-path docs
    
    # Transform for GitHub Pages
    $(xcrun --find docc) process-archive \
      transform-for-static-hosting docs \
      --output-path _site \
      --hosting-base-path myrepo

- name: Deploy
  uses: actions/deploy-pages@v4
```

### Internal Archive (Private Repos)
```bash
# Generate .doccarchive for local viewing or internal hosting
swift docc convert Sources/MyModule/MyModule.docc \
  --fallback-display-name MyModule \
  --fallback-bundle-identifier com.example.MyModule \
  --output-path MyModule.doccarchive

# Serve locally
$(xcrun --find docc) preview MyModule.doccarchive
```

## Benefits

| Stakeholder | Benefit |
|-------------|---------|
| **Human developer** | Complete API reference, architecture guide, onboarding docs |
| **AI agent** | Structured context about intent, relationships, constraints |
| **Code reviewer** | DocC diff shows intent changes alongside code changes |
| **New contributor** | Self-service documentation reduces questions |
| **LLM orchestration** | Context window efficiency — refer to docs instead of full files |

## Related
- ADR-005: DocC Documentation Strategy for LLM Era
- ADR-006: Pre-commit Enforcement Rules
