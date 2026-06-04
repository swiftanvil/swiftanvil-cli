# Child 1.5 Plan: Set Up GitHub Organization

## Objective
Set up the iFoundation GitHub organization with proper structure, CI/CD templates, and documentation.

## Goals
- [ ] Create GitHub organization
- [ ] Create repo templates for packages
- [ ] Configure GitHub Actions CI template
- [ ] Set up issue/PR templates
- [ ] Create organization README
- [ ] Document org structure

## Non-Goals
- [ ] Don't publish packages yet (wait for verification)
- [ ] Don't set up funding/sponsors yet
- [ ] Don't create all repos (just templates + org repo)

## Task Breakdown

| # | Task | Effort | Verification |
|---|------|--------|--------------|
| 1 | Check GitHub org name availability | 5 min | Name is available |
| 2 | Create organization | 5 min | Org exists, public |
| 3 | Configure org settings | 10 min | Profile, description, links |
| 4 | Create org README repo | 10 min | `.github` repo with profile README |
| 5 | Create package repo template | 15 min | Template with Package.swift, CI, docs |
| 6 | Configure GitHub Actions template | 15 min | Swift build + test workflow |
| 7 | Create issue templates | 10 min | Bug report, feature request |
| 8 | Create PR template | 5 min | Clear checklist |
| 9 | Document org structure | 10 min | CONTRIBUTING.md, CODE_OF_CONDUCT.md |

## Org Structure

```
github.com/iFoundation
├── .github/                    ← Org profile README
├── ifoundation-cli/            ← CLI tool repo (future)
├── ifoundation-appstrings/     ← Package repo (from Child 1.4)
├── ifoundation-a11yidentifiers/ ← Package repo (from Child 1.2)
├── ifoundation-benchmarkkit/   ← Package repo (from Child 1.3)
└── ifoundation-templates/      ← Template repo (future)
```

## Repo Template Contents

Each package repo should have:
```
REPO_NAME/
├── .github/
│   ├── workflows/
│   │   └── ci.yml              ← Build + test
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   └── feature_request.yml
│   └── PULL_REQUEST_TEMPLATE.md
├── Sources/
│   └── PackageName/
├── Tests/
│   └── PackageNameTests/
├── Package.swift
├── README.md
├── LICENSE
├── CHANGELOG.md
└── AGENTS.md
```

## CI Template

```yaml
# .github/workflows/ci.yml
name: CI

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  test-macos:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v6
      - name: Build
        run: swift build
      - name: Test
        run: swift test

  test-linux:
    runs-on: ubuntu-latest
    container:
      image: swift:6.0
    steps:
      - uses: actions/checkout@v6
      - name: Build
        run: swift build
      - name: Test
        run: swift test
```

## Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Org name taken | Low | Have backups: swift-foundation, app-foundation |
| GitHub Actions limits | Low | Public repos have unlimited minutes |
| Template doesn't work | Medium | Test with dummy repo first |

## Success Criteria
- Organization exists and is public ✅
- Org README explains iFoundation ✅
- Repo template can create working package ✅
- CI template builds successfully ✅
- Issue templates render correctly ✅

## Output Location
`github.com/iFoundation`

## Dependencies
- Child 1.1 research (for org structure patterns)
- GitHub account with org creation permissions
