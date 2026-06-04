# Pattern: Benchmarking Infrastructure

## Problem
Performance regressions are hard to catch. Without systematic benchmarking, apps gradually slow down over time.

## Solution
A `BenchmarkKit` package inspired by Turnip iOS and Apple's open-source Benchmark package.

## Architecture

```swift
// BenchmarkKit/BenchmarkConfiguration.swift

public struct BenchmarkConfiguration {
    public var iterations: Int
    public var warmupIterations: Int
    public var metrics: [BenchmarkMetric]
    public var thresholds: [BenchmarkMetric: BenchmarkThreshold]
    
    public static let `default` = BenchmarkConfiguration(
        iterations: 10,
        warmupIterations: 3,
        metrics: [.wallClockTime, .cpuTime, .memoryAllocations],
        thresholds: [:]
    )
}

public enum BenchmarkMetric: Hashable, Sendable {
    case wallClockTime
    case cpuTime
    case memoryAllocations
    case peakMemory
    case contextSwitches
    case threadCount
    case instructions
}

public struct BenchmarkThreshold {
    public var max: Duration?
    public var median: Duration?
    public var p95: Duration?
    
    public init(max: Duration? = nil, median: Duration? = nil, p95: Duration? = nil) {
        self.max = max
        self.median = median
        self.p95 = p95
    }
}
```

## Benchmark Runner

```swift
// BenchmarkKit/BenchmarkRunner.swift

public actor BenchmarkRunner {
    private let configuration: BenchmarkConfiguration
    
    public init(configuration: BenchmarkConfiguration = .default) {
        self.configuration = configuration
    }
    
    public func run(
        name: String,
        _ operation: @escaping () async throws -> Void
    ) async throws -> BenchmarkResult {
        // Warmup
        for _ in 0..<configuration.warmupIterations {
            try await operation()
        }
        
        // Measure
        var measurements: [BenchmarkMeasurement] = []
        for _ in 0..<configuration.iterations {
            let measurement = try await measure(operation)
            measurements.append(measurement)
        }
        
        let result = BenchmarkResult(
            name: name,
            measurements: measurements,
            configuration: configuration
        )
        
        // Validate thresholds
        try validateThresholds(result)
        
        return result
    }
    
    private func measure(_ operation: () async throws -> Void) async throws -> BenchmarkMeasurement {
        let start = ContinuousClock().now
        let memStart = getMemoryUsage()
        
        try await operation()
        
        let end = ContinuousClock().now
        let memEnd = getMemoryUsage()
        
        return BenchmarkMeasurement(
            duration: start.duration(to: end),
            memoryDelta: memEnd - memStart
        )
    }
    
    private func validateThresholds(_ result: BenchmarkResult) throws {
        for (metric, threshold) in configuration.thresholds {
            let value = result.statistics[metric]
            
            if let max = threshold.max, value?.max ?? .zero > max {
                throw BenchmarkError.thresholdExceeded(
                    metric: metric,
                    expected: max,
                    actual: value?.max ?? .zero
                )
            }
        }
    }
}
```

## Swift Testing Integration

```swift
// BenchmarkKit/SwiftTestingIntegration.swift

import Testing

extension Trait where Self == BenchmarkTrait {
    public static func benchmark(
        iterations: Int = 10,
        threshold: Duration? = nil
    ) -> BenchmarkTrait {
        BenchmarkTrait(
            iterations: iterations,
            threshold: threshold
        )
    }
}

public struct BenchmarkTrait: Trait {
    public let iterations: Int
    public let threshold: Duration?
    
    public func execute(
        _ function: @escaping () async throws -> Void
    ) async rethrows {
        let runner = BenchmarkRunner(configuration: .init(
            iterations: iterations,
            warmupIterations: 3,
            metrics: [.wallClockTime],
            thresholds: threshold.map { [.wallClockTime: .init(median: $0)] } ?? [:]
        ))
        
        let result = try await runner.run(name: "benchmark", function)
        
        // Report results
        print("Benchmark Results:")
        print("  Median: \(result.statistics[.wallClockTime]?.median ?? .zero)")
        print("  P95: \(result.statistics[.wallClockTime]?.p95 ?? .zero)")
        print("  Max: \(result.statistics[.wallClockTime]?.max ?? .zero)")
    }
}
```

## Usage in Tests

```swift
import Testing
import BenchmarkKit

struct ImageProcessingBenchmarks {
    @Test(.benchmark(iterations: 20, threshold: .milliseconds(50)))
    func resizeLargeImage() {
        let image = createLargeImage()
        _ = image.resized(to: CGSize(width: 100, height: 100))
    }
    
    @Test(.benchmark(iterations: 10))
    func applyFilter() {
        let image = createLargeImage()
        _ = image.applyFilter(.sepia)
    }
}
```

## Benchmark Results

```swift
public struct BenchmarkResult: Sendable {
    public let name: String
    public let measurements: [BenchmarkMeasurement]
    public let configuration: BenchmarkConfiguration
    
    public var statistics: [BenchmarkMetric: BenchmarkStatistics] {
        // Compute min, max, median, mean, p95, p99, stddev
    }
}

public struct BenchmarkStatistics: Sendable {
    public let min: Duration
    public let max: Duration
    public let median: Duration
    public let mean: Duration
    public let p95: Duration
    public let p99: Duration
    public let standardDeviation: Duration
}
```

## CI Integration

```yaml
# .github/workflows/benchmark.yml
name: Benchmark

on:
  push:
    branches: [main]
  pull_request:
    branches: [main]

jobs:
  benchmark:
    runs-on: macos-latest
    steps:
      - uses: actions/checkout@v6
      
      - name: Run benchmarks
        run: swift package benchmark
      
      - name: Compare with baseline
        run: swift package benchmark --compare main --format markdown > benchmark.md
      
      - name: Comment PR
        if: github.event_name == 'pull_request'
        uses: actions/github-script@v7
        with:
          script: |
            const fs = require('fs');
            const body = fs.readFileSync('benchmark.md', 'utf8');
            github.rest.issues.createComment({
              issue_number: context.issue.number,
              owner: context.repo.owner,
              repo: context.repo.repo,
              body: '## Benchmark Results\n' + body
            });
```

## Related
- ADR-007: Package Catalog Architecture
- Apple's open-source Benchmark package
- Turnip iOS BenchmarkKit


