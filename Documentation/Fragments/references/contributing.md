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

