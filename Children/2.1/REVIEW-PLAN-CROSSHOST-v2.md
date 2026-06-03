---
author: claude-code
hostVersion: claude-sonnet-4
reviewedBy: claude-code
artifactKind: review-artifact
schemaVersion: "1.0"
chainId: phase-2-core-packages
taskId: child-2.1-appnetworking
producedBy: claude-code
contextBudget: "6000"
createdAt: 2026-06-02T23:55:00Z
---

# Cross-Host Plan Review v2: AnvilNetwork

Reviewer: Claude (cross-host). Subject: Kimi's revised PLAN.md + REVIEW-PLAN-SELF-v2.md for child task 2.1.

## TL;DR

**Verdict: APPROVED_WITH_NOTES.**

The revision is a substantial, good-faith response to the v1 review. All eight critical items (C1–C8) are addressed with specificity rather than hand-waving, and the structural concerns (concurrency model, error type, retry/cache semantics, naming, estimates) are now in defensible shape. The plan is ready to begin implementation — provided Task 1 (PublicAPI.md drafting) resolves the residual gaps called out below before any code is written.

The remaining issues are mostly in the M/L bucket from v1 plus a small number of new inconsistencies introduced by the rewrite. None are blockers; all should be tracked into Task 1.

---

## Revision Item Audit

| # | v1 Item | Status | Notes |
|---|---------|--------|-------|
| 1 | C1/C3 concurrency + Sendable | ✅ Resolved | `Sendable` struct wrapping `actor HTTPClientCore`; `RequestInterceptor`/`ResponseInterceptor` are `Sendable`, `async`, `throws`. Solid. |
| 2 | C2 result-builder | ✅ Resolved | DSL dropped for `HTTPClientConfiguration` struct. Correct call — defers DSL complexity. |
| 3 | C4 error model + H2 validation | ⚠️ Partial | `NetworkError` enum is good. `ResponseValidator` protocol declared but the *default policy* (auto-throw on non-2xx? configurable threshold? exposed body on error?) is not stated. `.invalidResponse(statusCode:body:)` implies auto-throw but say so explicitly. |
| 4 | C5 body encoding | ⚠️ Partial | JSON encoder injection ✅. Multipart/streaming deferred to 2.1b ✅. **Not covered:** form-encoded (`application/x-www-form-urlencoded`), raw `Data` body, decoder symmetry on response (per-request decoder override). |
| 5 | C6 caching | ✅ Resolved | Storage, key, TTL, ETag/304, LRU, actor isolation all stated. Good. |
| 6 | C7 retry | ✅ Resolved | Triggers, full-jitter formula, `Retry-After`, idempotency rules, interceptor re-invocation, cancellation interaction all covered. (One typo: see N1 below.) |
| 7 | C8 naming | ✅ Resolved | `AnvilNetwork` / `swiftanvil-anvil-network` table is unambiguous. |
| 8 | H1/H3/H5 cancellation, observability, clock | ✅ Resolved | Cancellation contract stated; `NetworkLogger` protocol with OSLog default; `Clock` protocol injection with `ContinuousClock` default. |
| 9 | H7/L4 PublicAPI.md + DocC | ⚠️ Partial | PublicAPI.md scheduled in Task 1 ✅. DocC catalog reduced to "GettingStarted" only — v1 review asked for Authentication, Caching, RetryPolicy, Testing-with-mocks articles. Either expand Task 11 or explicitly defer. |
| 10 | H6 estimates | ✅ Resolved | 5h → 13h (actual sum is 14h — see N2). Realistic. |
| 11 | M8 verification column | ⚠️ Partial | Tasks 5/6/7/8/9 have concrete acceptance criteria. Tasks 2/3/4/10/11/12 still vague ("Builds, thread-sanitizer clean", "All HTTP methods work"). Tighten the remaining six. |
| 12 | Rerun self-review | ✅ Resolved | Self-review v2 is structural rather than decorative. Improvement over v1. |

**Score: 8 fully resolved, 4 partially resolved, 0 unaddressed.**

---

## What the Revision Got Right

1. **Concurrency model is now defensible.** `Sendable` struct + internal actor is the idiomatic Swift 6 shape for a network client. Public value type, single actor-protected mutation point, clean Sendable inference.
2. **Interceptor protocols are properly typed.** `async throws` signatures with `Sendable` conformance handle token refresh; split between Request/Response is the right factoring; explicit "re-invoked on retry" rule eliminates a class of auth bugs.
3. **Retry math is concrete.** `delay = min(maxDelay, base * 2^attempt * random(0.5, 1.0))` is a fully-specified full-jitter implementation. Idempotency policy + `Retry-After` respect + interceptor-re-invocation rule are exactly the right three rules for this layer.
4. **Naming is reconciled** in a single table. No ambiguity for the implementer.
5. **Effort estimate honesty.** The "Claude was right, estimates were unrealistic" note is the right tone — acknowledges the issue without overcorrecting.
6. **Self-review v2 is structural.** The diff table against v1 findings + structural checklist is exactly the form a self-review should take.

---

## Remaining Notes (track into Task 1)

### N1. Idempotency rule contradicts itself
Plan says: *"Only retries GET/HEAD/PUT/DELETE by default. POST/PUT requires explicit opt-in."* `PUT` appears in both the default-on and explicit-opt-in lists. Pick one — the standard reading is GET/HEAD/PUT/DELETE/OPTIONS retryable by default (all idempotent per RFC 7231), POST opt-in.

### N2. Effort sum is off-by-one
Tasks listed sum to 14h (1 + 1.5 + 1 + 1 + 1.5 + 1.5 + 1 + 1 + 0.5 + 2 + 1 + 1), not 13h. Trivial.

### N3. Response validation policy not stated
`ResponseValidator` protocol exists but the *default behavior* isn't written down. Add one sentence: e.g., "Default validator throws `NetworkError.invalidResponse` for any non-2xx; configurable via `HTTPClientConfiguration.validator`. Response body is captured in the error case so callers can decode server error envelopes."

### N4. Header API inconsistency in examples
Two header call sites use different value types:
- `request.header(.contentType, .applicationJSON)` — typed value enum.
- `request.header(.authorization, "Bearer \(token)")` — raw string.

Both are fine, but commit to whether `HTTPHeader.Value` is a `RawRepresentable` with `ExpressibleByStringLiteral`, an enum with `.raw(String)`, or two overloads. State the merge/overwrite rule (config → interceptor → call-site) and case-insensitivity guarantee (v1 M3 still open).

### N5. Mutation shape of `HTTPRequest` is unclear
`BearerTokenInterceptor` shows `var request = request; request.header(.authorization, ...); return request` — implying `header` is a mutating method. The chained-builder example (`.body(...).header(...).send()`) reads as non-mutating returns-self. Reconcile: most ergonomic is non-mutating `func header(...) -> Self` that copies, with `var`/`mutating` only as an internal convenience. Pin it in PublicAPI.md.

### N6. Empty body / 204 / HEAD handling (v1 M6, still open)
`.decode() -> T` is not safe for `Void` / 204 / HEAD. Provide either:
- A `Void` overload (`.decode() async throws -> Void` for empty bodies), or
- `.send() -> HTTPResponse` as the no-body terminator and reserve `.decode(as:)` for `Decodable`.

### N7. Query parameters API (v1 M4, still open)
Examples only show path strings. Specify the query API: typed `[URLQueryItem]`-backed builder? Dictionary? How are duplicates and ordering handled? Path-component escaping rules? `BaseURL` + leading-slash composition?

### N8. Body encoding surface still incomplete (C5 partial)
Stated: JSON. Deferred: multipart, streaming. **Unstated:** form-encoded bodies and raw `Data`. Form bodies are common in OAuth and legacy APIs; raw `Data` is the escape hatch. Add both (likely trivial — `.body(formData:)` and `.body(rawData:contentType:)`) or explicitly list them as deferred.

### N9. SwiftPM manifest details (v1 L5, still open)
Add to Task 2 the explicit `Package.swift` shape: `swift-tools-version: 6.0`, `swiftLanguageModes: [.v6]`, `swiftSettings: [.enableUpcomingFeature("ExistentialAny"), .enableUpcomingFeature("InternalImportsByDefault")]`. The plan says "Swift 6 + StrictConcurrency (implicit, not experimental flag)" — confirm this means `swift-tools-version: 6.0` with `swiftLanguageModes: [.v6]`, not an experimental flag.

### N10. URLSession lifecycle (v1 L6, still open)
Does each `HTTPClient` own its `URLSession`? Is the session `invalidateAndCancel`ed on client deinit (which is awkward for value types — the actor would own it)? Can callers inject a custom `URLSessionConfiguration`? One paragraph in the Transport section.

### N11. OSLog + Linux tension (v1 M5, still open)
Default `NetworkLogger` impl is `os.Logger`, which is Apple-only. Platforms table is Apple-only (fine), but if SwiftAnvil ever targets Linux for server-side use, the default logger needs a `#if canImport(OSLog)` fallback. State Apple-only positioning or add the fallback now.

### N12. Auth token-refresh coalescing punted
*"Token refresh coalescing is the caller's responsibility (via `tokenProvider`)."* This is defensible but worth a sharper warning in DocC: concurrent in-flight requests during refresh is the #1 source of bugs in client networking libraries. Provide a coalescing example in the Authentication DocC article (currently not planned — see resolution of L4 above).

### N13. Test bucket specificity (v1 M7, partial)
Task 10 says "≥80% coverage, TSan clean." Stronger: list the test buckets explicitly — contract tests per public protocol, one error-path test per `NetworkError` case, cancellation tests at every async boundary (transport, retry sleep, interceptor chain), stress test for concurrent requests through a single client. The bucket list belongs in PLAN.md, not deferred to "we'll see when we write tests."

---

## Self-Review v2 Quality

The self-review is substantially improved. The diff-against-v1 table is a useful artifact; the structural checklist is the right shape. Two small misses:
- It claims "all 12 items" addressed; per the audit above, 4 are partial. The self-review should grade C-level "resolved" but flag the M/L carryovers as open (N3, N4, N6, N7, N8, N9, N10, N11).
- "APPROVED_WITH_NOTES" verdict is consistent with this reviewer's conclusion, which is the right calibration.

---

## Required Before Implementation Starts

These should be settled during Task 1 (PublicAPI.md) and re-circulated before coding begins:

1. Fix idempotency contradiction (N1).
2. Write the default response-validation policy in one sentence (N3).
3. Pin `HTTPHeader.Value` shape + merge/case rules (N4).
4. Pin `HTTPRequest` mutation shape (mutating vs. copy-returning) (N5).
5. Define `.decode()` empty-body behavior (N6).
6. Define query-parameter API and URL composition rules (N7).
7. Decide form-encoded and raw-`Data` bodies: support v1 or defer to 2.1b (N8).
8. State `Package.swift` swift-tools-version and language mode (N9).
9. Decide `URLSession` ownership and lifecycle (N10).
10. Tighten verification column on tasks 2, 3, 4, 10, 11, 12 (v1 M8 partial).

Recommended (not blocking):

11. Expand DocC catalog plan to include Authentication, Caching, RetryPolicy, Testing-with-mocks articles or explicitly defer (v1 L4 partial).
12. List test buckets in Task 10 (N13).
13. Decide OSLog/Linux posture (N11).

---

## Verdict

**APPROVED_WITH_NOTES.**

The plan is now operationally adequate for a foundational Phase-2 package. Begin Task 1 (PublicAPI.md). Resolve N1–N10 inside that artifact and circulate it for a quick cross-host API pass before starting Task 2. The remaining notes (N11–N13) can be settled inline during implementation.

Good revision. The structural pivot from "DSL with hand-waved nodes" to "Configuration struct with explicit Sendable contracts" was the right call and unblocks the rest of the work.
