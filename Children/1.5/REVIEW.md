# Code Review: SwiftAnvil GitHub Organization Setup

**Org URL:** https://github.com/swiftanvil
**Plan:** Child 1.5 — Set Up GitHub Organization
**Reviewer:** Senior Swift Engineer (cross-host review)

---

## Summary of What Exists

| Asset | Status |
|---|---|
| Organization (`swiftanvil`) | ✅ Public, created 2026-06-02 |
| Org description | ✅ "⚡ Swift developer tooling forge. We forge the code. You ship it." |
| `.github` repo with `README.md` | ⚠️  Exists, but at wrong path (see below) |
| Code repos | ✅ 4 created: `swiftanvil-cli`, `swiftanvil-anvil-a11y`, `swiftanvil-anvil-bench`, `swiftanvil-anvil-strings` |
| Issue templates (bug + feature) | ✅ Present in all 4 code repos |
| Branch protection on `main` | ✅ Enabled on all 4 code repos |
| Discussions | ✅ Enabled on all 4 code repos |
| Repo source content (Package.swift, Sources, README, LICENSE…) | ❌ All repos are empty (size: 0) |
| CI workflows | ❌ None present |
| PR template | ❌ Missing in all repos |
| Template repo | ❌ None marked `isTemplate: true` |
| CONTRIBUTING / CODE_OF_CONDUCT / SECURITY / LICENSE | ❌ Missing |
| 2FA enforcement | ❌ Disabled at org level |

---

## Review Against Criteria

### 1. Correctness — **NEEDS_WORK**
- **Org profile README not rendering.** The README in `swiftanvil/.github` is at the **repo root** (`README.md`). GitHub only renders the org profile from `.github/profile/README.md`. Confirmed by fetching `https://github.com/swiftanvil` — only the org description appears; "We forge Swift" never renders. **Move `README.md` → `profile/README.md`.**
- README claims `anvil-a11y`, `anvil-bench`, `anvil-strings` are "✅ Stable" — they are **empty repos** (0 bytes, no Package.swift). The status badges are factually wrong and will mislead anyone landing on the org page.
- Repo naming is redundant: `swiftanvil-anvil-a11y` stutters. Either drop the `swiftanvil-` prefix (since the org namespace already provides it: `swiftanvil/anvil-a11y`) or drop the `anvil-` infix. The README itself refers to them as `anvil-a11y` etc., so the rendered docs already disagree with the repo URLs.

### 2. Completeness — **NEEDS_REVISION**
Compared against the plan's Task Breakdown and Success Criteria:

| Plan item | Status |
|---|---|
| Create organization | ✅ |
| Configure org settings | ⚠️  Description set; no `blog`/`location`/`email`/`twitter` populated |
| Create org README repo | ⚠️  Repo exists; README in wrong location |
| **Create package repo template** | ❌ No template repo exists |
| **Configure GitHub Actions CI template** | ❌ No `.github/workflows/ci.yml` anywhere |
| Issue templates | ✅ |
| **PR template** | ❌ Missing everywhere |
| **CONTRIBUTING.md / CODE_OF_CONDUCT.md** | ❌ Missing |
| **LICENSE** | ❌ Missing (README says MIT — file not committed) |
| Package skeletons (Package.swift, Sources, Tests, AGENTS.md, CHANGELOG.md) | ❌ Repos are completely empty |

Three of the plan's five Success Criteria fail: "Repo template can create working package," "CI template builds successfully," "Org README explains iFoundation" (no org README renders).

### 3. Consistency — **NEEDS_WORK**
- Plan references `iFoundation`/`ifoundation-*` throughout; the actual org is `swiftanvil`. The pivot is fine, but the plan doc should be updated to match, or a note added.
- Repo prefix is inconsistent: CLI is `swiftanvil-cli`, packages are `swiftanvil-anvil-*`. Either both should carry `anvil-` or neither should.
- Org description tagline ("We forge the code. You ship it.") differs from README tagline ("We forge Swift. You ship it."). Pick one.

### 4. Test Coverage — **N/A**
No code exists to test. CI is not configured, so the plan's `test-macos` + `test-linux` jobs (Swift 6 on Ubuntu) are unverified.

### 5. Documentation — **NEEDS_WORK**
- Org README is well-written but invisible on the org page (path bug).
- No CONTRIBUTING.md, no CODE_OF_CONDUCT.md, no SECURITY.md, no LICENSE file.
- No per-repo READMEs (repos are empty).
- README links to `CONTRIBUTING.md` which 404s.
- README advertises `brew install swiftanvil/tap/swiftanvil` — no tap exists.

### 6. Swift 6 Compliance — **N/A**
No Swift code committed yet. Plan's CI uses `swift:6.0` image, which is fine; verify once code lands.

### Bonus: Security/Hardening — **NEEDS_WORK**
- `two_factor_requirement_enabled: false` — should be **enabled** for a public org owning developer tooling.
- `members_can_delete_repositories: true` and `members_can_change_repo_visibility: true` — tighten before adding members.
- Branch protection lacks `required_status_checks` (because CI doesn't exist yet) and `enforce_admins: false`. Once CI exists, require `test-macos` + `test-linux` as status checks.
- `.github` repo has **no** branch protection — the org profile content can be force-pushed.
- No `LICENSE` despite README claim of MIT — packages are effectively "All Rights Reserved" until a LICENSE is committed.

---

## Action Items (Blockers)

1. **Move org README** from `.github/README.md` → `.github/profile/README.md` so it renders on https://github.com/swiftanvil.
2. **Stop calling empty repos "✅ Stable"** in the README — change to "🚧 Scaffolding" or remove until code lands.
3. **Add LICENSE (MIT)** to every repo and to `.github`.
4. **Add `.github/workflows/ci.yml`** (per plan) to each code repo — at minimum the swiftanvil-cli, since the plan's success criterion is "CI template builds successfully."
5. **Add `.github/PULL_REQUEST_TEMPLATE.md`** to each repo (Task #8 in plan).
6. **Create a template repo** (e.g., `swiftanvil-package-template`) with `isTemplate: true` containing Package.swift skeleton, CI, issue/PR templates, README scaffold, CHANGELOG, AGENTS.md (Task #5).
7. **Add CONTRIBUTING.md + CODE_OF_CONDUCT.md** to `.github` repo (Task #9).
8. **Enable 2FA requirement** at the org level.
9. **Resolve naming**: pick `swiftanvil/anvil-*` or `swiftanvil/swiftanvil-anvil-*` consistently and align README + repo URLs.

## Action Items (Non-blocking)

- Populate org `blog`, `location`, `twitter` fields (or set to `null` intentionally — current `location: "The Internet"` is fine).
- Disable wiki on package repos (use README + docs site instead).
- Add branch protection to `.github` repo.
- Once CI exists, require its checks in branch protection and enable `enforce_admins`.
- Tighten `members_can_delete_repositories` to admin-only.

---

## Overall Verdict

**NEEDS_REVISION**

The shell of the org is in place — repos exist, issue templates and branch protection are configured, discussions are on. But three of the plan's five success criteria fail outright: there is no repo template, no CI workflow, and the org README does not render on the org profile page because it's at the wrong path. The repos are also empty (no `Package.swift`, no `LICENSE`), while the org README publicly advertises three of them as "Stable" — that's a credibility issue if anyone discovers the org before code lands.

Recommend completing Action Items 1–6 before considering Child 1.5 done, and treating 7–9 as fast-follow.
