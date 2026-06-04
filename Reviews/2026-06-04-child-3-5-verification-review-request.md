# Child 3.5 Verification Review Request

## Intent

Review the first Child 3.5 implementation for SwiftAnvil generated-project verification.

The goal is to close the Phase 3 gap by adding a machine-checkable verifier to `swiftanvil-cli` before creating
any separate integration-test repository. The chosen ownership model is:

- Keep command UX and static generated-project verification in `swiftanvil-cli`.
- Extract a dedicated verification package later only if multiple repositories need the same verifier API.
- Defer a separate integration-test repository until SwiftAnvil has a real cross-repository test matrix.

## Review Scope

Please review the current branch diff against `main`, with emphasis on:

- Whether `ifoundation verify --path <project>` is the right first enforcement surface.
- Whether the verifier checks are appropriately static, deterministic, and testable.
- Whether generated CI validation is meaningful enough for the first slice.
- Whether the file-system boundary and report model are suitable for future expansion.
- Whether any obvious Phase 3 requirement is still missing before this can proceed to PR.

## Verification Already Run

- `swift test`
- Generated-project smoke test:
  - `swift run iFoundation create VerificationProbe --output <tmpdir>`
  - `swift run iFoundation verify --path <tmpdir>/VerificationProbe`
- `../swiftanvil-enforcement/scripts/enforce-local.sh --root . --registry-root ../swiftanvil-meta`

## Known Constraints

- `swiftformat` is not installed on this machine, so formatting was compiler-checked and manually inspected.
- This slice does not run `swift build` or `swift test` inside generated projects yet. It validates the generated
  project contract first; execution-based integration testing remains deferred by plan.
