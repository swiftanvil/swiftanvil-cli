# SwiftAnvil Multi-Repo Workflow

> How we work across multiple repositories without losing our minds.

---

## 🏗️ Repository Structure

```
swiftanvil/                          ← GitHub Org
├── .github/                         ← Org profile, shared templates
│   ├── org.profile-readme            ← Renders on github.com/swiftanvil
│   ├── LICENSE                      ← MIT (applies to all repos)
│   ├── org.contributing              ← Shared contribution guidelines
│   ├── org.code-of-conduct           ← Community standards
│   └── workflows/ci.yml             ← Reusable CI template
│
├── swiftanvil-anvil-a11y/           ← Package: Accessibility identifiers
├── swiftanvil-anvil-bench/          ← Package: Performance benchmarking
├── swiftanvil-anvil-strings/        ← Package: Type-safe localization
└── swiftanvil-cli/                  ← Tool: CLI scaffolding
```

**Rule:** Each package repo is **independent**. It builds, tests, and versions on its own.

---

## 🔄 Daily Development Workflow

### 1. Pick What to Work On

Check [`roadmap.org`](roadmap.org) for current priorities. The roadmap tells you:
- Which phase is active
- Which child is next
- What the proposed API looks like

### 2. Work in the Right Repo

```bash
# Clone just the repo you need
git clone https://github.com/swiftanvil/swiftanvil-anvil-bench.git
cd swiftanvil-anvil-bench

# Create a feature branch
git checkout -b feature/my-feature

# Make changes, test locally
swift build
swift test

# Push and open PR
git push origin feature/my-feature
# Open PR via GitHub UI — template auto-fills
```

### 3. Cross-Repo Changes

Sometimes a change affects multiple packages (e.g., shared API pattern):

```bash
# Work in each repo independently
# Open separate PRs for each repo
# Link PRs with "Related to swiftanvil/swiftanvil-anvil-a11y#42"
```

**Never** use git submodules or monorepo tricks. Each repo stands alone.

---

## 📋 Pull Request Workflow

### Opening a PR

1. Push your branch
2. GitHub auto-fills the PR template from `org.pull-request-template`
3. Fill in: Summary, Changes, Testing checklist
4. Link related issues: `Fixes #123`
5. Request review from maintainer

### Review Requirements

| Repo | Required Reviews | Status Checks |
|------|-----------------|---------------|
| All package repos | 1 approval | Branch protection enforces |
| `.github` org repo | 1 approval | Branch protection enforces |

### After Merge

- Delete your branch
- Update `roadmap.org` if this completes a milestone
- Tag a release if this is a user-facing change

---

## 🏷️ Release Workflow

### Versioning

We use [Semantic Versioning](https://semver.org/):
- **MAJOR**: Breaking API changes
- **MINOR**: New features, backwards compatible
- **PATCH**: Bug fixes

### Releasing a Package

```bash
# In the package repo
git checkout main
git pull origin main

# Tag the release
git tag -a 1.2.0 -m "Release 1.2.0: Add BenchmarkTrait support"
git push origin 1.2.0

# GitHub auto-generates release notes from PRs
# Go to GitHub → Releases → Draft a new release → Auto-generate
```

### Cross-Package Dependency Updates

When `anvil-bench` 1.2.0 releases and `swiftanvil-cli` needs it:

```swift
// In swiftanvil-cli/Package.swift
.package(url: "https://github.com/swiftanvil/swiftanvil-anvil-bench.git", from: "1.2.0"),
```

Open a PR in `swiftanvil-cli` with just this change. Tests verify compatibility.

---

## 🧪 Testing Workflow

### Local Testing

```bash
# Always test before pushing
swift build
swift test

# For packages with SwiftUI components
swift test --filter BenchmarkKitSwiftUITests
```

### CI Testing

GitHub Actions runs on every PR:
- **macOS**: `swift test` on latest macOS + Xcode
- **Linux**: `swift test` in `swift:6.0` Docker container

CI config lives in each repo's `.github/workflows/ci.yml` (copied from org template).

### Cross-Package Integration Testing

For changes that span multiple packages, we don't have integration tests yet. Plan:
- Phase 3 will add a `swiftanvil-integration-tests` repo
- It pulls all packages at their latest versions and verifies they work together

---

## 📝 Documentation Workflow

### Package READMEs

Each package repo has its own `package.readme` with:
- Installation instructions
- Quick start code
- API overview
- Requirements

### API Documentation

- Use `///` doc comments on all public APIs
- DocC catalogs will be added post-v1.0
- For now, README + inline docs are sufficient

### Org-Level Docs

- `roadmap.org` — Living document, updated per phase
- `workflow.general` — This file, updated when process changes
- `org.contributing` — In `.github` repo, applies org-wide

---

## 🐛 Issue Workflow

### Reporting Bugs

1. Go to the **correct repo** (not `.github`)
2. Click Issues → New Issue → Bug Report
3. Fill the template
4. Label: `bug`

### Requesting Features

1. Go to the **correct repo**
2. Click Issues → New Issue → Feature Request
3. Fill the template
4. Label: `enhancement`

### Discussions

For questions, ideas, or community chat:
- Use GitHub Discussions on the relevant repo
- Or the `.github` repo for org-wide topics

---

## 👥 Adding Collaborators

### To a Single Repo

1. Repo Settings → Manage access → Invite a collaborator
2. Give `Write` or `Triage` permission

### To the Org

1. Org Settings → Members → Invite member
2. Choose role: `Member` (can push to repos) or `Owner` (full admin)

---

## 🚨 Emergency Procedures

### Hotfix Across Multiple Repos

```bash
# Create hotfix branches in each affected repo
git checkout -b hotfix/critical-fix

# Apply fix, test, push
git push origin hotfix/critical-fix

# Open PRs with "HOTFIX" prefix
# Request expedited review
```

### Reverting a Bad Release

```bash
# Delete the tag
git push --delete origin 1.2.0
git tag -d 1.2.0

# GitHub Release: mark as pre-release or delete
# Update Package.swift references to use previous version
```

---

## 📊 Tracking Progress

| Document | Updated When | Owned By |
|----------|-------------|----------|
| `roadmap.org` | After each phase/child completes | Kimi |
| `checklist.legacy` | After each task completes | Kimi |
| `Children/{id}/RESULT.md` | After child execution | Kimi |
| `Children/{id}/REVIEW.md` | After cross-host review | Claude |
| GitHub Releases | After version tags | Automated |

---

## 🎯 Golden Rules

1. **One repo, one concern** — Don't mix package code with CLI code
2. **Test locally, verify in CI** — Never merge without green checks
3. **Review everything** — Even "trivial" changes need a second pair of eyes
4. **Document as you go** — READMEs stay current, roadmap stays honest
5. **Version independently** — Packages release on their own schedule
6. **Link everything** — PRs reference issues, issues reference roadmap items

---

*Last updated: 2026-06-02*
