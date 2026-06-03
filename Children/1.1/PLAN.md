# Child 1.1 Plan: Research Swift OSS Best Practices

## Objective
Research and document how successful Swift OSS projects structure their repos, handle versioning, manage CI/CD, and build community — producing actionable recommendations for iFoundation.

## Goals
- [ ] Document repo structure patterns from 4+ successful orgs
- [ ] Document versioning strategies
- [ ] Document CI/CD best practices for Swift packages
- [ ] Document community building strategies
- [ ] Produce actionable recommendations for iFoundation

## Non-Goals
- [ ] Don't implement anything
- [ ] Don't make final decisions (recommend only)
- [ ] Don't research non-Swift ecosystems

## Task Breakdown

| # | Task | Effort | Output | Verification |
|---|------|--------|--------|--------------|
| 1 | Research Pointfreeco org structure | 15 min | Notes on 5+ repos | Cover TCA, dependencies, case-paths, navigation |
| 2 | Research Apple swift-* org structure | 15 min | Notes on 5+ repos | Cover nio, algorithms, collections, atomics |
| 3 | Research Vapor org structure | 10 min | Notes on 3+ repos | Cover vapor, fluent, leaf |
| 4 | Research Apollo iOS monorepo→multi-repo | 10 min | Notes on approach | Cover git subtree strategy |
| 5 | Document CI/CD patterns | 15 min | Notes on GitHub Actions | Cover Swift package CI best practices |
| 6 | Document versioning strategies | 10 min | Notes on semantic versioning | Cover independent vs coordinated versioning |
| 7 | Compile recommendations | 15 min | `Research/OSS_Best_Practices.md` | Actionable, specific to iFoundation |

## Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Research becomes too broad | Medium | Strict 90-min timebox |
| Recommendations too generic | Low | Tie every recommendation to iFoundation context |
| Missing key project | Medium | Start with known leaders, expand if time |

## Success Criteria
- Document covers all 4 orgs with specific examples
- Document has ≥10 actionable recommendations
- Document is referenced by other children
- Document is suitable for iFoundation documentation

## Research Questions to Answer

1. How does Pointfreeco handle 20+ repos? (Org structure, naming, dependencies)
2. How does Apple handle versioning across swift-* packages?
3. How does Vapor manage core vs ecosystem packages?
4. How did Apollo solve monorepo→multi-repo transition?
5. What CI patterns work best for Swift packages?
6. How do successful projects build community?
7. What documentation patterns attract contributors?

## Output Location
`Research/OSS_Best_Practices.md`

## Dependencies
None (first child, provides input to others)
