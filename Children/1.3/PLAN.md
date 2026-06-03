# Child 1.3 Plan: Extract BenchmarkKit from Turnip iOS

## Objective
Extract the BenchmarkKit package from Turnip iOS into a standalone, publishable Swift package.

## Goals
- [ ] Extract with git history preserved
- [ ] Generalize (remove Turnip-specific code)
- [ ] Add Swift Testing integration
- [ ] Add documentation
- [ ] Verify it builds and tests pass independently

## Non-Goals
- [ ] Don't publish to GitHub yet
- [ ] Don't redesign core API (keep Turnip's design)
- [ ] Don't remove SwiftUI integration

## Source Location
`/Users/vishalsingh/Documents/Turnip.gg/turnip-ios/zaps-app/BenchmarkKit/`

## Task Breakdown

| # | Task | Effort | Verification |
|---|------|--------|--------------|
| 1 | Verify source exists and is complete | 5 min | `ls` shows expected files |
| 2 | Extract with git subtree split | 10 min | New branch has history |
| 3 | Review all source files for Turnip refs | 20 min | `grep -r "Turnip"` returns nothing |
| 4 | Generalize models (remove Turnip-specific) | 30 min | Generic benchmark types |
| 5 | Add Swift Testing trait integration | 30 min | `@Test(.benchmark())` works |
| 6 | Write README with usage examples | 15 min | Clear, complete |
| 7 | Write Package.swift | 5 min | Valid, minimal |
| 8 | Verify build | 10 min | `swift build` passes |
| 9 | Verify tests | 10 min | `swift test` passes |

## Generalization Details

### What Stays
- `BenchmarkRecording`
- `BenchmarkSystemSampler`
- `BenchmarkCohort`
- `BenchmarkModels`
- `BenchmarkEnvironment`
- SwiftUI integration (`BenchmarkKitSwiftUI`)

### What Changes
- Remove Turnip-specific benchmark configurations
- Remove Turnip-specific data models
- Add generic `BenchmarkConfiguration`
- Add Swift Testing integration

### New: Swift Testing Integration
```swift
extension Trait where Self == BenchmarkTrait {
    public static func benchmark(
        iterations: Int = 10,
        threshold: Duration? = nil
    ) -> BenchmarkTrait { ... }
}

// Usage:
@Test(.benchmark(iterations: 20, threshold: .milliseconds(50)))
func resizeImage() {
    let image = createImage()
    _ = image.resized(to: CGSize(width: 100, height: 100))
}
```

## Risks

| Risk | Likelihood | Mitigation |
|------|-----------|------------|
| Turnip code deeply integrated | Medium | Careful extraction + testing |
| Swift Testing compatibility | Medium | Test on Swift 6.0+ |
| Performance metrics platform-specific | Low | Test on macOS and Linux |

## Success Criteria
- Package builds with `swift build` ✅
- Tests pass with `swift test` ✅
- No Turnip-specific references ✅
- Swift Testing traits work ✅
- README has usage examples ✅

## Output Location
`Packages/ifoundation-benchmarkkit/`

## Dependencies
- Child 1.1 research (for patterns)
- Access to Turnip iOS repo
