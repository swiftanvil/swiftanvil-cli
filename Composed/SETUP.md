# Setup Guide

This guide covers installation, configuration, and getting started with iFoundation.



## Installation

### Prerequisites

- macOS 14.0+ or Linux with Swift 6.0+
- Swift Package Manager
- Git

### From Source

```bash
git clone https://github.com/yourusername/iFoundation.git
cd iFoundation
swift build -c release
sudo cp .build/release/iFoundation /usr/local/bin/ifoundation
```

### Verify Installation

```bash
ifoundation --version
ifoundation doctor
```



## Configuration

iFoundation uses a centralized configuration system. Projects can be configured via:

1. **Interactive wizard**: `ifoundation create MyApp --interactive`
2. **Command-line flags**: `ifoundation create MyApp --template ios-app`
3. **Configuration file**: `.foundation/config.yml`

### Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `template` | Project template | `ios-app` |
| `minimumOSVersion` | Minimum OS version | `17.0` |
| `useSwiftUI` | Include SwiftUI | `true` |
| `enableAccessibility` | Enable a11y enforcement | `true` |
| `enableLocalization` | Enable localization | `true` |
| `targetLanguages` | Supported languages | `["en"]` |
| `includeUnitTests` | Include unit tests | `true` |
| `includeUITests` | Include UI tests | `true` |
| `ciProvider` | CI/CD provider | `github-actions` |
| `enableImmunity` | Enable immunity system | `true` |



## Building

### Build the Tool

```bash
swift build
swift build -c release
```

### Build a Generated Project

```bash
cd MyApp
swift build
```

### Build for iOS Simulator

```bash
xcodebuild build -scheme MyApp -destination 'platform=iOS Simulator,name=iPhone 16'
```



## Testing

### Run Tool Tests

```bash
swift test
```

### Run Project Tests

```bash
cd MyApp
swift test
```

### Run with Coverage

```bash
swift test --enable-code-coverage
```

### Run Specific Test Target

```bash
swift test --filter MyAppTests
```



