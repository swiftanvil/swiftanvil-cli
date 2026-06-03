## MVVM + I/O Architecture

### Model
Pure data structures. Codable, Sendable, immutable where possible.

### ViewModel
`@Observable` or `@MainActor` bound. Clear Input/Output interfaces.

### View
SwiftUI Views with accessibility identifiers and localization keys.

### Service Layer
Protocol-based networking, caching, persistence.

### Repository Pattern
Data access abstraction. Business logic lives here, not in ViewModels.

