# ADR-001: Project Structure

## Status
Accepted

## Context
Swift projects need consistent structure for maintainability and AI agent comprehension.

## Decision
Adopt a flat, feature-based structure:

```
Sources/
├── App/              # App entry point
├── Features/         # Feature modules
│   ├── Home/
│   ├── Settings/
│   └── ...
├── SharedPackages/   # Cross-cutting concerns
│   ├── AppStrings/
│   ├── A11yIdentifiers/
│   └── ...
└── Core/             # Shared utilities
```

## Consequences
- Clear separation of concerns
- Easy to navigate for humans and AI
- Feature modules can be extracted to separate packages

