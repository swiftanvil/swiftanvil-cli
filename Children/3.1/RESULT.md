# Child 3.1 Result: AnvilWizard

## Summary

Interactive CLI wizard engine for `swiftanvil`. Provides typed prompts, validation, and both interactive (terminal) and non-interactive (CI) execution modes.

## Deliverables

| Item | Status |
|------|--------|
| Package code | ✅ Complete |
| Unit tests | ✅ 20/20 pass |
| README | ✅ Complete |
| GitHub repo | ✅ [`swiftanvil/swiftanvil-anvil-wizard`](https://github.com/swiftanvil/swiftanvil-anvil-wizard) |

## Test Results

```
Test run with 20 tests in 5 suites passed after 0.001 seconds.
```

### Test Breakdown

| Suite | Tests |
|-------|-------|
| WizardAnswers | 5 (store/retrieve, missing, type mismatch, has) |
| TextPrompt | 4 (basic input, default, validation retry, cancelled) |
| ConfirmPrompt | 4 (yes, no, default, invalid retry) |
| ChoicePrompt | 4 (select first, navigate down, cancelled, empty options) |
| Wizard | 3 (non-interactive success, missing answer, type mismatch) |

## Key Design Decisions

1. **`Wizard<Result>` generic** — Result built via `(WizardAnswers) throws -> Result` closure. Type-safe, explicit.
2. **`Prompt<T>` protocol** — Any type can be a prompt. Text, confirm, choice provided.
3. **`InputReader` / `OutputWriter`** — Protocol-based I/O for full testability. Mock reader injects scripted input.
4. **Terminal safety** — Raw mode disables ISIG (so Ctrl-C returns byte, not SIGINT). Restored via `defer`.
5. **Non-interactive mode** — `.nonInteractive(answers:)` for CI/automation. Missing answers throw.

## Review History

| Round | Type | Reviewer | Verdict |
|-------|------|----------|---------|
| 1 | Plan | Codex | NEEDS_REVISION (5 blockers) |
| 2 | Plan | Codex | APPROVED |
| 1 | Impl | Codex | NEEDS_REVISION (2 blockers: raw mode, EOF loop) |
| 2 | Impl | Codex | APPROVED |

## Artifacts

- Repo: https://github.com/swiftanvil/swiftanvil-anvil-wizard
- Module: `AnvilWizard`
- Swift: 6.0+
- Platforms: macOS 13+
