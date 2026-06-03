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

