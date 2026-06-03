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

