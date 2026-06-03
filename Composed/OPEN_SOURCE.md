# ADR-009: Open Source Strategy

## Status
Accepted

## Context
iFoundation is intended to be an open-source project that attracts contributors and becomes a standard tool in the Swift ecosystem.

## Decision
Adopt a community-first open source model with:

### License
- **MIT License**: Permissive, allows commercial use
- **Copyright**: "iFoundation Contributors"

### Governance
- **Benevolent Dictator**: You (project owner) have final say
- **Maintainer Team**: Trusted contributors with merge rights
- **Community**: Anyone can open issues and PRs

### Repository Structure for Contributors

```
iFoundation/
├── .github/
│   ├── ISSUE_TEMPLATE/
│   │   ├── bug_report.yml
│   │   ├── feature_request.yml
│   │   └── package_proposal.yml
│   ├── PULL_REQUEST_TEMPLATE.md
│   └── workflows/
│       ├── ci.yml              # Build and test
│       ├── docs.yml            # DocC generation
│       └── release.yml         # Automated releases
├── CONTRIBUTING.md             # Detailed contribution guide
├── CODE_OF_CONDUCT.md          # Community standards
├── SECURITY.md                 # Security reporting
├── CHANGELOG.md                # Release history
├── LICENSE                     # MIT License
├── README.md                   # Project overview
└── docs/                       # Additional documentation
```

### Issue Templates

#### Bug Report
```yaml
name: Bug Report
description: Report a bug in iFoundation
labels: [bug]
body:
  - type: input
    id: version
    attributes:
      label: iFoundation Version
      placeholder: e.g., 0.5.0
  - type: textarea
    id: description
    attributes:
      label: Bug Description
  - type: textarea
    id: reproduction
    attributes:
      label: Steps to Reproduce
  - type: textarea
    id: expected
    attributes:
      label: Expected Behavior
```

#### Package Proposal
```yaml
name: New Package Proposal
description: Propose a new toggleable package
description: |
  Propose a new package to be included in iFoundation's catalog.
  Packages should be type-safe, testable, and broadly useful.
labels: [enhancement, package]
body:
  - type: input
    id: name
    attributes:
      label: Package Name
  - type: textarea
    id: description
    attributes:
      label: What problem does this solve?
  - type: textarea
    id: api
    attributes:
      label: Proposed API
```

### Contribution Levels

| Level | Rights | Requirements |
|-------|--------|-------------|
| **Contributor** | Open PRs, issues | GitHub account |
| **Regular Contributor** | Triage issues | 5+ merged PRs |
| **Maintainer** | Merge PRs, manage releases | 20+ merged PRs, code review |
| **Core Maintainer** | Architecture decisions | Deep expertise, trusted by owner |

### Release Process

1. **Versioning**: Semantic Versioning (MAJOR.MINOR.PATCH)
2. **Changelog**: Auto-generated from conventional commits
3. **Release Notes**: Human-written highlights
4. **GitHub Releases**: With binaries attached
5. **Homebrew**: `brew install ifoundation`
6. **Mint**: `mint install ifoundation/ifoundation`

### Recognition

- **All Contributors** bot for automated recognition
- **Release notes** credit all contributors
- **Hall of Fame** in documentation for significant contributions

## Consequences

### Positive
- **Community growth**: Open source attracts contributors
- **Quality**: More eyes on code = better quality
- **Adoption**: Permissive license encourages use
- **Sustainability**: Distributed maintenance burden

### Negative
- **Governance overhead**: Managing community takes time
- **Decision friction**: More opinions to consider
- **Security**: Must vet contributions carefully

## Related
- ADR-007: Package Catalog Architecture
- ADR-008: Configurable Wizard Design


