# Child 3.1 Plan: Wizard System

## Goal

Build the core interactive CLI wizard engine for `swiftanvil`. This child covers the foundation: prompt protocols, basic prompt types, terminal I/O abstraction, and typed result construction. Advanced features (multiselect, branching, themes, prebuilt wizards) move to later children.

## Non-Goals

- No multiselect prompt (Child 3.2)
- No branching flows (Child 3.2)
- No theme/styling system (Child 3.2)
- No project/package prebuilt wizards (Child 3.3)
- No template rendering (Child 3.3)
- No project generation (Child 3.3)

## What We're Building

A Swift package `AnvilWizard` that provides:

1. **Prompt protocols** — `Prompt<T>` protocol for any input that produces a typed value
2. **Basic prompts** — text (with validation), confirm (yes/no), choice (single select)
3. **Terminal I/O abstraction** — `InputReader` + `OutputWriter` protocols for testability
4. **Wizard orchestrator** — collects answers, validates, produces typed `WizardResult`
5. **Cancellation safety** — raw terminal mode restored on exit, even on Ctrl+C

## Public API Surface

```swift
import AnvilWizard

// Define a wizard with typed result — closure is throwing, answers are type-safe
let wizard = Wizard<ProjectConfig> { answers in
    ProjectConfig(
        name: try answers.get("name"),           // throws WizardError.missingAnswer if key not found
        platform: try answers.get("platform"),    // throws WizardError.typeMismatch if cast fails
        useSwiftUI: try answers.get("useSwiftUI")
    )
}

// Add steps with string keys
try await wizard
    .step(key: "name", prompt: TextPrompt("Project name").validate { !$0.isEmpty })
    .step(key: "platform", prompt: ChoicePrompt("Target platform", options: Platform.allCases))
    .step(key: "useSwiftUI", prompt: ConfirmPrompt("Use SwiftUI?", default: true))

// Run interactively
let config = try await wizard.run()

// Run non-interactively (CI, automation, tests)
let config2 = try await wizard.run(mode: .nonInteractive(answers: [
    "name": "MyApp",
    "platform": Platform.iOS,
    "useSwiftUI": true
]))
```

## Architecture

```
AnvilWizard
├── Core/
│   ├── Wizard.swift              # Main orchestrator, generic over Result
│   ├── WizardAnswers.swift       # Typed answer dictionary
│   ├── WizardError.swift         # Validation, cancellation, I/O errors
│   └── Prompt.swift              # Prompt<T> protocol
├── Prompts/
│   ├── TextPrompt.swift          # Free text + validation closure
│   ├── ChoicePrompt.swift        # Single selection from [T]
│   └── ConfirmPrompt.swift       # Bool yes/no with default
└── Terminal/
    ├── TerminalRenderer.swift    # ANSI output (colors, clear lines)
    ├── TerminalInputReader.swift # Raw mode stdin reader
    ├── InputReader.swift         # Protocol for testability
    └── OutputWriter.swift        # Protocol for testability
```

## Key Design Decisions

1. **Typed answers via closure** — `Wizard<T>` takes a closure `(WizardAnswers) -> T` that constructs the result from collected answers. This is explicit, type-safe, and avoids key-path magic.

2. **Testability via protocols** — `InputReader` reads keypresses, `OutputWriter` writes strings. Tests inject `MockInputReader` with scripted byte sequences and `MockOutputWriter` to capture output.

3. **Raw terminal mode** — `TerminalInputReader` uses `termios` to enable raw mode, restores on `defer`. Ctrl+C handled via signal handler that restores terminal before re-raising.

4. **Validation returns `Result<T, ValidationError>`** — not just `Bool`. Error messages displayed to user, retry loop.

5. **Non-interactive mode** — Explicit `.nonInteractive(answers:)` mode for CI/automation. Missing answers throw `WizardError.missingAnswer`. Type mismatches throw `WizardError.typeMismatch`. Separate from TTY detection — callers choose the mode.

6. **`WizardAnswers.get<T>(_ key: String) throws -> T`** — Type-safe answer retrieval. Throws `WizardError.missingAnswer` if key not collected. Throws `WizardError.typeMismatch` if stored value cannot cast to `T`. No force-casts, no fatal errors.

## Naming

| Aspect | Value |
|--------|-------|
| Repo | `swiftanvil-anvil-wizard` |
| Module | `AnvilWizard` |
| Product | `AnvilWizard` library |

## Platforms

macOS 13+ (CLI-only, no mobile platforms)

## Dependencies

None. Pure Swift + Foundation. No ArgumentParser dependency in this package.

## Task Breakdown

| # | Task | Est | Success Criteria |
|---|------|-----|------------------|
| 1 | Define `Prompt<T>` protocol + `WizardAnswers` | 15 min | Protocol has `ask(reader:writer:) async throws -> T` |
| 2 | Implement `TextPrompt` with `Result<T, ValidationError>` | 15 min | Validation error shown, retry loop, cancel restores terminal |
| 3 | Implement `ConfirmPrompt` | 10 min | Y/n/Enter handling, default works |
| 4 | Implement `ChoicePrompt` with arrow navigation | 20 min | Up/down moves highlight, Enter selects |
| 5 | Implement `TerminalInputReader` (raw mode + TTY detection) | 20 min | `termios` raw mode, restore on exit, non-TTY fallback |
| 6 | Implement `TerminalRenderer` (ANSI clear + colors) | 15 min | Clear lines, move cursor, basic colors |
| 7 | Implement `Wizard<T>` orchestrator | 15 min | Steps run in order, answers collected, result produced |
| 8 | Write mock reader/writer for tests | 10 min | Inject scripted input, capture output |
| 9 | Write tests (≥15 tests) | 20 min | All prompt types, validation, cancellation, non-TTY |
| 10 | Write README | 10 min | Installation, quick start, testability note |
| 11 | Create repo + push | 10 min | GitHub repo, .gitignore, CI template |

**Total: ~2.5 hours**

## Risks

1. **Raw terminal mode complexity** — `termios` is C API, needs careful setup/teardown. Mitigation: wrap in `TerminalInputReader` with `defer` restore + signal handler.
2. **Arrow key escape sequences** — Different terminals send different sequences. Mitigation: support common sequences (\x1b[A/\x1b[B for up/down), ignore unknown.
3. **Swift 6 + signal handlers** — Signal handlers can't be async. Mitigation: use `DispatchSourceSignal` or simple flag + check in main loop.

## Success Criteria

- [ ] `swift build` passes with no errors
- [ ] `swift test` passes: ≥15 tests
- [ ] Can run a 3-step wizard script that collects name, platform, confirm
- [ ] Ctrl+C during prompt restores terminal state
- [ ] Non-TTY mode reads from stdin without raw mode
- [ ] README with installation + quick start
- [ ] Cross-host review APPROVED or APPROVED_WITH_NOTES
