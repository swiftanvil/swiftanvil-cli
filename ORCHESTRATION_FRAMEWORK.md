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

## 🔄 Per-Child Workflow (5 Steps)

Every child follows this exact sequence. No skipping steps.

```
┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐    ┌─────────┐
│  PLAN   │───→│ REVIEW  │───→│ EXECUTE │───→│ VERIFY  │───→│DOCUMENT │
│ (Build) │    │(Cross)  │    │ (Build) │    │(Cross)  │    │ (Build) │
└─────────┘    └─────────┘    └─────────┘    └─────────┘    └─────────┘
     │              │              │              │              │
     ▼              ▼              ▼              ▼              ▼
 PLAN.md      REVIEW.md      Code+Tests     REVIEW.md      RESULT.md
                                                    +         ROADMAP.md
                                              (append)       CHECKLIST.md
```

### Step 1: PLAN (Primary Builder)

**Goal:** Define what to build, how to build it, and what success looks like.

**Actions:**
1. Read `ROADMAP.md` for context
2. Define objectives, goals, non-goals
3. Break down into tasks with estimates
4. Identify risks and mitigations
5. Define success criteria (verifiable)
6. Write `Children/{id}/PLAN.md`

**Output:** `Children/{id}/PLAN.md`

**Plan must include:**
- Goal and non-goals
- Public API surface (if applicable)
- Task breakdown with estimates
- Success criteria (checklist)
- Naming (repo, module, product)

---

### Step 2: REVIEW — Plan Review (Cross-Host Reviewer, DIFFERENT model)

**Goal:** Validate the plan before execution begins.

**Actions:**
1. Read `Children/{id}/PLAN.md`
2. Review for completeness, feasibility, consistency
3. Suggest improvements
4. Write `Children/{id}/REVIEW-PLAN.md` with verdict

**Verdicts:**

| Verdict | Meaning | Next Action |
|---------|---------|-------------|
| **APPROVED** | Plan is solid | Proceed to Step 3 |
| **APPROVED_WITH_NOTES** | Minor issues, not blockers | Proceed to Step 3, fix notes during execution |
| **NEEDS_REVISION** | Blockers found | Fix blockers, re-submit for review |

**Output:** `Children/{id}/REVIEW-PLAN.md` (or `REVIEW-PLAN-v{N}.md` for revisions)

---

### Step 3: EXECUTE (Primary Builder)

**Goal:** Implement according to the approved plan.

**Actions:**
1. Implement code
2. Write tests
3. Write documentation (README, API docs)
4. Run `swift build` — must pass
5. Run `swift test` — all must pass
6. Verify success criteria

**Rules:**
- No committing `.build/` artifacts
- Add `.gitignore` before first commit
- Commit incrementally with clear messages
- Never skip tests

**Output:** Working code in `Packages/{repo-name}/`

---

### Step 4: VERIFY — Implementation Review (Cross-Host Reviewer, DIFFERENT model)

**Goal:** Validate the implementation against the approved plan.

**Actions:**
1. Read implementation (all source files)
2. Read tests
3. Check: correctness, Swift 6 compliance, API design, test coverage
4. Verify plan items are addressed
5. Write `Children/{id}/REVIEW-IMPL.md` with verdict

**Verdicts:**

| Verdict | Meaning | Next Action |
|---------|---------|-------------|
| **APPROVED** | Meets all criteria | Proceed to Step 5 |
| **APPROVED_WITH_NOTES** | Minor issues | Proceed to Step 5, fix notes, no re-review needed |
| **NEEDS_REVISION** | Blockers found | Fix blockers, re-submit for re-review |

**Re-review:** If NEEDS_REVISION, fix blockers and go back to Step 4 (new review round).

**Output:** `Children/{id}/REVIEW-IMPL.md` (or `REVIEW-IMPL-v{N}.md` for re-reviews)

---

### Step 5: DOCUMENT (Primary Builder)

**Goal:** Record what was done and update project state.

**Actions:**
1. Write `Children/{id}/RESULT.md`
2. Update `ROADMAP.md`:
   - Mark child as complete ONLY if cross-host review is APPROVED or APPROVED_WITH_NOTES
   - If self-reviewed, mark as "complete (self-reviewed — cross-host unavailable)"
   - Update test counts
   - Update progress
3. Update `CHECKLIST.md`
4. Push final code to GitHub
5. Commit all tracking files

**Output:**
- `Children/{id}/RESULT.md`
- Updated `ROADMAP.md`
- Updated `CHECKLIST.md`
- Code pushed to GitHub

**CRITICAL:** Do NOT mark a child as "reviewed by cross-host" if the review was self-done. Be honest about review provenance in all documentation.

---

## 🚪 Phase Gate Workflow

### When a Phase Completes (All Children Done)

```
Phase N Complete
│
├── 1. Builder writes PHASE-N-SUMMARY.md
│   └── What was built, key decisions, deviations
│
├── 2. Cross-host reviewer reviews entire phase
│   └── Reads all children RESULT.md + ROADMAP.md
│   └── Writes PHASE-N-REVIEW.md
│   └── Verdict: APPROVED | NEEDS_REVISION
│
├── 3. If APPROVED:
│   └── Builder updates ROADMAP.md phase status
│   └── Builder tags phase completion in git
│   └── User approval requested for Phase N+1
│
└── 4. If NEEDS_REVISION:
    └── Fix issues in affected children
    └── Re-review
```

### Phase Gate Conditions

| Gate | Condition | Approvers |
|------|-----------|-----------|
| Child complete | Steps 1-5 done, review APPROVED | Cross-host reviewer |
| Phase N → N+1 | All children APPROVED + phase summary reviewed | Cross-host reviewer + User |
| Emergency override | User says "skip review" | User only (documented in ROADMAP) |

---

## 📂 File Structure

```
Children/
├── {id}/
│   ├── PLAN.md              ← Builder writes (Step 1)
│   ├── REVIEW-PLAN.md       ← Reviewer writes (Step 2)
│   ├── REVIEW-PLAN-v2.md    ← Reviewer writes (Step 2, if revision)
│   ├── REVIEW-IMPL.md       ← Reviewer writes (Step 4)
│   ├── REVIEW-IMPL-v2.md    ← Reviewer writes (Step 4, if re-review)
│   ├── RESULT.md            ← Builder writes (Step 5)
│   └── STATUS.md            ← Builder writes (optional, progress)
│
Phase-Summaries/
├── PHASE-1-SUMMARY.md       ← Builder writes
├── PHASE-1-REVIEW.md        ← Reviewer writes
└── ...

Root/
├── ORCHESTRATION_FRAMEWORK.md   ← This file
├── ROADMAP.md                    ← Living project state
├── CHECKLIST.md                  ← Task tracking
└── WORKFLOW.md                   ← Multi-repo workflow
```

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

---

## ✅ Quality Standards (Model-Agnostic)

### Code Quality
- Swift 6.0+ compatible
- All public APIs documented with `///`
- Test coverage ≥ 80% (where tooling supports)
- No compiler warnings
- All tests pass before merge

### Documentation Quality
- README with installation + quick start
- DocC comments on public APIs
- ADR for architectural decisions (in ROADMAP.md)

### Review Quality
- Every deliverable reviewed by a DIFFERENT model
- Review must address: correctness, completeness, consistency
- Review feedback must be actionable

---

## 🎭 Agent Role Definitions

### Primary Builder
- Plans implementation (Step 1)
- Writes code (Step 3)
- Writes tests
- Writes documentation
- Updates ROADMAP.md (Step 5)
- **Can be any model:** Kimi, Claude, GPT-4, Gemini, etc.

### Cross-Host Reviewer
- Reviews plans (Step 2)
- Reviews implementations (Step 4)
- Reviews phase summaries
- Writes REVIEW-*.md files
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
1. Both models document positions in `Children/{id}/REVIEW-*.md`
2. User decides
3. Decision is final

### If Stuck
1. Model documents blocker in `Children/{id}/STATUS.md`
2. User provides guidance
3. Resume work

### If Reviewer is Unavailable
1. Try ALL available cross-host reviewers in order: Claude CLI → Codex CLI → OpenAI CLI → any other authenticated CLI
2. Document each attempt with error output in `Children/{id}/STATUS.md`
3. Only after ALL reviewers fail, proceed with self-review
4. Self-review MUST use the same checklist as cross-host review (see Review Criteria below)
5. Self-review verdict is ALWAYS "APPROVED_WITH_NOTES" or "NEEDS_REVISION" — never "APPROVED"
6. Document in ROADMAP.md as "self-reviewed — all cross-host reviewers unavailable"
7. **NEVER mark a child as fully APPROVED without cross-host review** — the phase gate remains conditional

---

## 📝 Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | 2026-06-02 | Initial framework (Kimi-specific) |
| 2.0 | 2026-06-02 | Agent-agnostic rewrite, model rotation rules |
| 3.0 | 2026-06-03 | Formalized 5-step per-child workflow, phase gates, file structure |
| 3.1 | 2026-06-03 | Hardened reviewer-unavailable procedure, banned false-positive approvals, enforced honest review provenance |

---

*Framework is model-agnostic. Any capable LLM can be builder or reviewer. The only rule: they must be different.*
