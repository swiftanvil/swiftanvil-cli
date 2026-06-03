# iFoundation

> Swift project scaffolding with architectural enforcement for the LLM era.

## Vision

iFoundation is a world-class, host-agnostic Swift project scaffolding tool that establishes the golden path for Apple platform development. It is designed for the LLM era — where code generation is abundant, but architectural discipline, enforcement, and inclusive design are the differentiators.



## Core Principles

| Principle | Description |
|-----------|-------------|
| **Host Agnosticism** | All scripts, workflows, and configurations work identically across macOS, Linux, and CI environments |
| **Minimal Tokenization** | Every output is LLM-friendly — modular, well-indexed, with clear boundaries |
| **Performance First** | Scaffolding is instantaneous. Build systems are optimized. Artifacts are centrally managed |
| **Inclusion by Default** | Accessibility, localization, and test scaffolding are foundational, not optional |
| **Enforcement over Convention** | Standards are enforced via pre-commit hooks, linting, CI gates, and runtime assertions |
| **Composability** | Documentation and configuration are composed from a centralized registry |
| **Self-Improvement** | Telemetry and feedback loops enable the tool to suggest improvements and evolve |
| **Type Safety Over Strings** | All cross-cutting concerns use typed structures, never string literals |



## Quick Start

### Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/iFoundation.git
cd iFoundation

# Build the tool
swift build -c release

# Install globally (optional)
cp .build/release/iFoundation /usr/local/bin/ifoundation
```

### Create a New Project

```bash
# Interactive wizard (recommended)
ifoundation create MyApp --interactive

# Quick start with defaults
ifoundation create MyApp --template ios-app
```

### Available Templates

| Template | Description |
|----------|-------------|
| `ios-app` | iOS application with SwiftUI |
| `macos-app` | macOS application |
| `swift-library` | Reusable Swift package |
| `swift-tool` | Command-line tool |
| `multiplatform-app` | Cross-platform app |



## Contributing

1. Follow the existing code style (enforced by SwiftLint + SwiftFormat)
2. Add tests for new features
3. Update documentation registry for architectural changes
4. Run `ifoundation doctor` before submitting PRs
5. Ensure DocC comments for all public APIs

### Development Workflow

```bash
# Make changes
# ...

# Format and lint
swiftformat .
swiftlint lint

# Test
swift test

# Check health
ifoundation doctor

# Compose docs
ifoundation docs compose
```



