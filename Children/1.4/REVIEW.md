# Code Review: AppStrings Package

**Package:** `ifoundation-appstrings`
**Build:** ✅ clean | **Tests:** ✅ 21/21 pass | **Warnings-as-errors build:** ✅ clean

---

## 1. Correctness — PASS

- `swift build` and `swift test` both succeed; 21 tests in 4 suites pass.
- Built with `-warnings-as-errors`: zero warnings.
- `String(format: value, arguments: arguments)` is the correct overload (`[CVarArg]` array form), so variadic forwarding in `with(_:)` is sound.
- `AppStringBuilder` provides both `buildBlock` and the newer `buildPartialBlock` overloads — slight overlap but Swift resolves it fine.

## 2. Completeness — NEEDS_WORK

| Plan goal | Status |
|-----------|--------|
| Core `LocalizedString`/`AppString` type | ✅ |
| SwiftUI integration | ✅ (Text, Button, Label, Picker, Toggle, NavigationLink, Section — generous) |
| `.with(...)` interpolation | ✅ |
| Tests | ✅ |
| Documentation comments | ✅ |
| **README** | ❌ **Missing** |
| Build + tests pass | ✅ |

**Action items**
- Add a `README.md` at the package root. The plan lists it as a Task and a Success Criterion ("README has clear usage examples ✅"). The sibling `ifoundation-a11yidentifiers` ships a README — be consistent.

## 3. Consistency — PASS (with one minor)

- Mirrors `A11yID`'s shape well: `Hashable, Sendable, ExpressibleByStringLiteral`, hierarchical enum usage pattern, same documentation cadence.
- Plan's "Proposed API" name was `LocalizedString`; implementation chose `AppString`. This is actually **better** (avoids collision with SwiftUI's `LocalizedString`/`LocalizedStringKey`) and matches the module/product name. Worth flagging that the plan and implementation diverged, but the choice is defensible.
- `AppString` doesn't conform to `RawRepresentable` (A11yID does). Reasonable here — `AppString` is more than a string — but worth a comment in docs.

## 4. Test Coverage — NEEDS_WORK (minor)

Coverage of types, equality, catalog, builder, and nested enum usage patterns is solid. Gaps:
- **No test for `with(_:)`** — the format/interpolation API ships untested.
- **No test for `value` / `string`** — the actual localization lookup is never exercised (even just confirming that an unknown key falls back to the key string).
- No test for `ExpressibleByStringLiteral`-via-conversion at a Text init site, but that's stylistic.

**Action items**
- Add at least one test that calls `.with("Ada", 42)` on a key like `"%@ is %d"` (which will fall through as the key itself, so `String(format:)` is exercised).
- Add a test asserting `AppString("missing").value == "missing"` to lock in the fallback semantic the catalog relies on.

## 5. Documentation — NEEDS_WORK

- All public types and members have DocC-style comments with usage blocks — good.
- README absent (covered above).
- `AppStringBuilder`: include a one-line note that consumers usually rely on generated code rather than writing builders by hand (currently the example is misleading-looking since `@AppStringBuilder` on a stored property would be unusual outside tests).

## 6. Swift 6 Compliance — PASS (with cleanup)

- `swiftLanguageModes: [.v6]` — good.
- `Sendable` conformance on `AppString` and `AppStringCatalog`; `Bundle` is `@unchecked Sendable` upstream, so this composes correctly.
- `enableExperimentalFeature("StrictConcurrency")` is **redundant** under Swift 6 language mode (strict concurrency is the default). Recommend removing it to avoid future deprecation noise.

**Action items**
- Drop `swiftSettings: [.enableExperimentalFeature("StrictConcurrency")]` from `Package.swift` — Swift 6 mode already enforces it.

---

## Other Observations (non-blocking)

- `Bundle` equality in tests (`#expect(string.bundle == .main)`) relies on reference identity via `NSObject`'s `==`. Works, but fragile if anyone constructs an `AppString` with a synthesized bundle later.
- The `Section` overload `init(_:content:)` shadows existing SwiftUI initializers reasonably, but the constraint `Footer == EmptyView` will silently lose the no-footer-but-with-text-footer overload. Likely fine.
- `missingKeys` returns `[String]` while `keys` also returns `[String]` — symmetric. The `key == resolved` heuristic for "missing" is reasonable but worth a doc warning: a translation whose value is literally identical to the key (e.g., `"OK" -> "OK"`) will be flagged as missing. Already noted in the doc comment — good.

---

## Overall Verdict: **APPROVED_WITH_NOTES**

Strictly, the plan listed the README as a Success Criterion ✅ and it's absent, which would justify NEEDS_REVISION. But the code itself is well-designed, well-documented inline, consistent with the sibling package, and ready to use. Treat this as approved pending two small follow-ups:

**Must-fix before declaring 1.4 complete:**
1. Add `README.md` with usage examples (mirroring `ifoundation-a11yidentifiers/README.md`).
2. Remove the redundant `StrictConcurrency` experimental flag from `Package.swift`.

**Should-fix (next pass):**
3. Add tests for `with(_:)` and for the missing-key fallback in `value`.
