# iFoundation — Agent Guidelines

## Project Overview

iFoundation is a Swift-based CLI tool for scaffolding Apple platform projects with enforcement for architecture, accessibility, localization, and testing.

## Key Principles

1. **Host Agnosticism**: All scripts must run on macOS, Linux, and CI environments. No hardcoded paths.
2. **Swift First**: The tool itself is written in Swift. Use Swift Package Manager.
3. **Minimal Tokenization**: Keep files small, focused, and well-indexed for LLM consumption.
4. **Performance**: Scaffolding must be fast. Optimize for speed at every layer.
5. **Enforcement > Convention**: Standards are enforced, not just documented.

## Development Workflow

- Use `swift build` and `swift test` for local development
- Follow the MVVM + I/O architecture even in the tool's own code
- Every command must have comprehensive tests
- Documentation is composed from the registry, not duplicated

## Code Style

- SwiftFormat configuration in `.swiftformat`
- SwiftLint with custom rules in `.swiftlint.yml`
- 120 character line limit
- Explicit self where required for clarity
- Protocol-oriented design

## Testing

- Unit tests for all business logic
- Integration tests for CLI commands
- Snapshot tests for generated output
- Performance tests for scaffolding speed

## Documentation

- All architecture decisions go in `Documentation/Fragments/decisions/`
- Use the registry system for composed docs
- Keep READMEs generated, not hand-written
