# SwiftAnvil Orchestration Framework

> Agent-agnostic multi-phase build system. Any model can be the builder. Any *different* model can be the reviewer.

---

## 🎯 Core Principle

**No agent is special.** The framework works identically whether the primary builder is Kimi, Claude, GPT-4, or any future model. The reviewer is always a *different* model from the builder.

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────────┐
│              Primary Builder (Any Model)                     │
│  - Plans, implements, tests, documents                       │
│  - Can be Kimi, Claude, GPT-4, Gemini, etc.                │
├─────────────────────────────────────────────────────────────┤
│  Phase N: [Active Phase]                                     │
│  ├── Child N.1: [Task]                                       │
│  ├── Child N.2: [Task]                                       │
│  └── ...                                                     │
└─────────────────────────────────────────────────────────────┘
                              │
                              ▼
┌─────────────────────────────────────────────────────────────┐
│           Cross-Host Reviewer (Different Model)              │
│  - Must be a DIFFERENT model from the builder               │
│  - Reviews all deliverables                                  │
│  - Provides feedback on code quality                         │
│  - Suggests improvements                                     │
│  - Approves phase gates                                      │
└─────────────────────────────────────────────────────────────┘
```

### Model Rotation Rule

| Session | Primary Builder | Cross-Host Reviewer | How Decided |
|---------|----------------|---------------------|-------------|
| 1 | Kimi | Claude | User picks, or random |
| 2 | Claude | GPT-4 | Must differ from builder |
| 3 | GPT-4 | Kimi | Must differ from builder |
| 4 | Kimi | GPT-4 | Rotate to avoid bias |

**Hard rule:** The reviewer model MUST be different from the builder model. No self-review.

---

## 🔄 Per-Child Workflow

Every child follows this exact sequence:

```
1. PLAN (Primary Builder)
   ├── Read ROADMAP.md for context
   ├── Define objectives, goals, non-goals
   ├── Break down into tasks
   ├── Identify risks and mitigations
   └── Write Children/{id}/PLAN.md
   
2. REVIEW (Cross-Host Reviewer — DIFFERENT model)
   ├── Read PLAN.md
   ├── Review for completeness, feasibility, consistency
   ├── Suggest improvements
   └── Write Children/{id}/REVIEW.md with verdict:
       - APPROVED: Proceed to execute
       - APPROVED_WITH_NOTES: Proceed, fix notes later
       - NEEDS_REVISION: Must fix before proceeding
   
3. EXECUTE (Primary Builder)
   ├── Implement according to approved plan
   ├── Write tests
   ├── Write documentation
   └── Verify success criteria
   
4. VERIFY (Cross-Host Reviewer — DIFFERENT model)
   ├── Read implementation
   ├── Run tests
   ├── Check test coverage
   ├── Verify documentation
   └── Write Children/{id}/REVIEW.md (execution review) with verdict
   
5. DOCUMENT (Primary Builder)
   ├── Update ROADMAP.md
   ├── Update CHECKLIST.md
   ├── Write Children/{id}/RESULT.md
   └── Commit everything
```

---

## 🎲 Model Selection Protocol

### Option A: User Picks (Default)
User says: "Build with Kimi, review with Claude."

### Option B: Random Assignment
```
available_models = [Kimi, Claude, GPT-4, Gemini]
builder = pick_random(available_models)
reviewer = pick_random(available_models - builder)
```

### Option C: Round-Robin Rotation
Track last used model. Next session uses the next model in rotation.

### Option D: Capability-Based
| Task Type | Preferred Builder | Preferred Reviewer |
|-----------|-------------------|-------------------|
| Swift code | Kimi, Claude | GPT-4 (strong on patterns) |
| Architecture | Claude | Kimi (strong on structure) |
| Documentation | Any | Any |
| DevOps/CI | GPT-4 | Kimi |

**Default:** Option A (user picks). Fallback to Option B if user doesn't specify.

---

## 📋 Review Criteria (Model-Agnostic)

The reviewer evaluates against these criteria regardless of which model they are:

| Criterion | Weight | What to Check |
|-----------|--------|---------------|
| **Correctness** | Critical | Compiles? Tests pass? No logic errors? |
| **Completeness** | High | Meets plan objectives? Nothing missing? |
| **Consistency** | High | Follows Swift idioms? Consistent with other packages? |
| **Test Coverage** | High | Tests exist? Edge cases covered? |
| **Documentation** | Medium | README? API docs? Usage examples? |
| **Swift 6 Compliance** | Medium | Strict concurrency? No warnings? |

### Review Verdicts

| Verdict | Meaning | Next Action |
|---------|---------|-------------|
| **APPROVED** | Meets all criteria | Proceed to next child/phase |
| **APPROVED_WITH_NOTES** | Minor issues, not blockers | Proceed, fix notes in next iteration |
| **NEEDS_REVISION** | Blockers found | Fix blockers, re-submit for review |

---

## 🚪 Phase Gates

| Gate | Condition | Approvers |
|------|-----------|-----------|
| Phase N → Phase N+1 | All children APPROVED or APPROVED_WITH_NOTES | Cross-host reviewer + User |
| Emergency override | User says "skip review" | User only (documented in ROADMAP.md) |

---

## 📝 Communication Protocol

### Between Builder and Reviewer

**No direct chat.** All communication is file-based:

1. Builder writes deliverables to files
2. Reviewer reads files, writes feedback to `Children/{id}/REVIEW.md`
3. Builder reads review, implements fixes, updates `Children/{id}/RESULT.md`

### File Structure

```
Children/
├── {id}/
│   ├── PLAN.md          ← Builder writes
│   ├── REVIEW.md        ← Reviewer writes (plan review)
│   ├── REVIEW.md        ← Reviewer appends (execution review)
│   ├── RESULT.md        ← Builder writes (what was done)
│   └── STATUS.md        ← Builder writes (progress updates, optional)
```

### With User

- Phase gates require explicit user approval
- User can override any decision
- User receives summaries, not raw agent output

---

## ✅ Quality Standards (Model-Agnostic)

These apply regardless of which model is building:

### Code Quality
- Swift 6.0+ compatible
- All public APIs documented with `///`
- Test coverage ≥ 80%
- No compiler warnings
- All tests pass before merge

### Documentation Quality
- README with installation + quick start
- DocC comments on public APIs
- ADR for architectural decisions (in ROADMAP.md)
- CHANGELOG for releases

### Review Quality
- Every deliverable reviewed by a DIFFERENT model
- Review must address: correctness, completeness, consistency
- Review feedback must be actionable

---

## 🛠️ Enforcement

### Automated
- CI runs on every PR (GitHub Actions)
- Tests must pass
- Branch protection requires 1 review

### Manual
- Cross-host review by different model
- User approval at phase boundaries
- ROADMAP.md updated after each child

---

## 📂 File Structure

```
swiftanvil-project/
├── ORCHESTRATION_FRAMEWORK.md     ← This file (agent-agnostic rules)
├── ROADMAP.md                      ← Living project state
├── CHECKLIST.md                    ← Task tracking
├── WORKFLOW.md                     ← Multi-repo workflow
├── Children/
│   ├── 1.1/
│   │   ├── PLAN.md
│   │   ├── REVIEW.md              ← Plan review + execution review
│   │   └── RESULT.md
│   └── ...
└── Packages/
    └── ...                         ← Actual code repos
```

---

## 🎭 Agent Role Definitions

### Primary Builder
- Plans implementation
- Writes code
- Writes tests
- Writes documentation
- Updates ROADMAP.md
- **Can be any model:** Kimi, Claude, GPT-4, Gemini, etc.

### Cross-Host Reviewer
- Reviews plans
- Reviews implementations
- Runs tests independently
- Writes REVIEW.md
- Approves phase gates
- **MUST be a different model from the builder**
- **Can be any model:** Kimi, Claude, GPT-4, Gemini, etc.

### User
- Vision and direction
- Phase gate approval
- Model selection (or delegates to random)
- Final decision authority
- Emergency override

---

## 🚨 Escalation

### If Agents Disagree
1. Both models document their positions in `Children/{id}/REVIEW.md`
2. User decides
3. Decision is final

### If Stuck
1. Model documents blocker in `Children/{id}/STATUS.md`
2. User provides guidance
3. Resume work

### If Reviewer is Unavailable
1. Document attempt in `Children/{id}/STATUS.md`
2. User can: (a) wait, (b) assign different reviewer, (c) approve without review
3. If option (c), document in ROADMAP.md as "emergency bypass"

---

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-02 | Initial framework (Kimi-specific) |
| 2.0 | 2026-06-02 | Agent-agnostic rewrite, model rotation rules |

---

*Framework is model-agnostic. Any capable LLM can be builder or reviewer. The only rule: they must be different.*
