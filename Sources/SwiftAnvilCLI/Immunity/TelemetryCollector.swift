// TelemetryCollector.swift
// Collects project telemetry data

import Foundation

/// Protocol for telemetry collection
protocol TelemetryCollector: Sendable {
    func collect() async throws -> [String: MetricValue]
}

enum MetricValue: Sendable {
    case double(Double)
    case int(Int)
    case string(String)
    case bool(Bool)
}

// MARK: - Concrete Collectors

struct BuildMetricsCollector: TelemetryCollector {
    func collect() async throws -> [String: MetricValue] {
        // Collect build time, cache hit rate, etc.
        return [
            "buildTime": .double(0),
            "cacheHitRate": .double(0),
        ]
    }
}

struct TestMetricsCollector: TelemetryCollector {
    func collect() async throws -> [String: MetricValue] {
        // Collect test count, duration, failure rate
        return [
            "testCount": .int(0),
            "testDuration": .double(0),
            "failureRate": .double(0),
        ]
    }
}

struct CoverageCollector: TelemetryCollector {
    func collect() async throws -> [String: MetricValue] {
        // Collect code coverage metrics
        return [
            "lineCoverage": .double(0),
            "branchCoverage": .double(0),
        ]
    }
}
