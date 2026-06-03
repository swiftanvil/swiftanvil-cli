---
author: codex
hostVersion: gpt-5.5
artifactKind: review-artifact
schemaVersion: "1.0"
chainId: phase-2-core-packages
taskId: child-2.2-featureflags
producedBy: codex
reviewRound: 3
---

# Cross-Host Implementation Review: AnvilFlags

**Reviewer:** Codex CLI (cross-host, different model from builder)
**Builder:** Kimi CLI
**Review Date:** 2026-06-03

## Command Run

```bash
codex review "Review the Swift package at /Users/vishalsingh/Documents/v-i-s-h-a-l/github/iFoundation/Packages/swiftanvil-anvil-flags for implementation quality. Focus on: 1) Swift 6 strict concurrency compliance, 2) API design consistency with modern Swift patterns, 3) Test coverage and correctness, 4) Any bugs or issues. Return a concise verdict: APPROVED, APPROVED_WITH_NOTES (list notes), or NEEDS_REVISION (list blockers)."
```

## Round 1 Verdict: NEEDS_REVISION

Blockers found:
1. **Flaky tests under Swift Testing parallel execution**
   - Several tests called `FeatureFlags.configure(...)`, mutating shared global state
   - Re-running `swift test` failed on `withSystem isolation`, proving order/concurrency-dependent failures

2. **A/B test cache can return invalid variants**
   - `FeatureFlagSystem.abTest` cached by `userID|test.name` only
   - Calling same test name later with different variants could return a variant not in the new `ABTest`

3. **Empty A/B variants crash**
   - `StableHashBucketingStrategy.assign` did `hash % test.variants.count`
   - Empty variants array trapped at runtime

## Fixes Applied (Builder)

1. Replaced all `FeatureFlags.configure()` calls in tests with `FeatureFlags.withSystem()`
2. Added variants to A/B cache key: `"\(userID)|\(test.name)|\(variantsKey)"`
3. Added `precondition(!variants.isEmpty)` to `ABTest.init`

## Round 2 Verdict: NEEDS_REVISION

Blocker found:
1. **A/B cache key can still collide for variant names containing commas**
   - `variants.joined(separator: ",")` could collide: `["a,b", "c"]` and `["a", "b,c"]` both → `"a,b,c"`

## Fix Applied (Builder)

- Changed to length-prefixed encoding: `variants.map { "\($0.count):\($0)" }.joined(separator: "|")`

## Round 3 Verdict: APPROVED

All blockers resolved. 37/37 tests pass.
