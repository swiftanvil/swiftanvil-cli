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

## Installation

```bash
# Clone the repository
git clone https://github.com/yourusername/iFoundation.git
cd iFoundation

# Build the tool
swift build -c release

# Install globally (optional)
cp .build/release/iFoundation /usr/local/bin/ifoundation
```

## Usage

### Create a New Project

```bash
# Interactive wizard (recommended)
ifoundation create MyApp --interactive

# Quick start with defaults
ifoundation create MyApp --template ios-app

# Specify output directory
ifoundation create MyApp --template ios-app --output ~/Projects
```

### Available Templates

| Template | Description |
|----------|-------------|
| `ios-app` | iOS application with SwiftUI |
| `macos-app` | macOS application |
| `watchos-app` | watchOS application |
| `tvos-app` | tvOS application |
| `visionos-app` | visionOS spatial application |
| `swift-library` | Reusable Swift package |
| `swift-tool` | Command-line tool |
| `swift-server` | Server-side Swift |
| `multiplatform-app` | Cross-platform app |

### Health Check

```bash
# Check project health
ifoundation doctor

# Auto-fix issues
ifoundation doctor --fix
```

### Documentation

```bash
# Compose documentation from registry
ifoundation docs compose

# Validate registry integrity
ifoundation docs validate
```

### Immunity System

```bash
# Run health scan
ifoundation immunity scan

# Generate report
ifoundation immunity report --format markdown

# Get suggestions
ifoundation immunity suggest --category architecture
```

## Project Structure

```
iFoundation/
├── Sources/iFoundation/
│   ├── Commands/          # CLI commands
│   ├── Templates/         # Template engine
│   ├── Scaffolding/       # Project generation
│   ├── Configuration/     # Config models
│   ├── Documentation/     # Registry composer
│   ├── Immunity/          # Self-improvement system
│   └── Utilities/         # Helpers
├── Templates/             # Project templates
├── Documentation/         # Composable docs
└── Tests/                 # Test suites
```

## Architecture

The tool itself follows the same principles it enforces:
- **MVVM + I/O** pattern in its own codebase
- **Protocol-oriented design** for extensibility
- **Actor isolation** for thread safety
- **Comprehensive testing** for reliability

## Contributing

1. Follow the existing code style (enforced by SwiftLint + SwiftFormat)
2. Add tests for new features
3. Update documentation registry for architectural changes
4. Run `ifoundation doctor` before submitting PRs

## License

MIT License — see LICENSE file for details.
