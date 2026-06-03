## SOLID Principles

iFoundation-generated projects follow SOLID principles:

### Single Responsibility
Each file and type has one reason to change. File size limits enforced via linting.

### Open/Closed
Extensions and protocols enable adding functionality without modifying existing code.

### Liskov Substitution
Protocol conformance validated in tests. Subtypes are fully substitutable.

### Interface Segregation
No "god protocols." Composition over inheritance.

### Dependency Inversion
Depend on protocols, not concrete types. Dependency injection container provided.

