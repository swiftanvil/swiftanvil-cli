// ImmunityScanner.swift
// Scans project health and detects anomalies

import Foundation

/// Scans project for health issues and improvement opportunities
actor ImmunityScanner {
    private let collectors: [TelemetryCollector] = [
        BuildMetricsCollector(),
        TestMetricsCollector(),
        CoverageCollector(),
    ]

    private let detectors: [AnomalyDetector] = [
        BuildTimeDetector(),
        TestFlakinessDetector(),
        CoverageRegressionDetector(),
    ]

    /// Performs a full immunity scan
    func scan(deep: Bool) async throws -> ImmunityScanResult {
        var allIssues: [ImmunityIssue] = []
        var allSuggestions: [ImmunitySuggestion] = []

        // Collect telemetry
        for collector in collectors {
            _ = try await collector.collect()
            // Store metrics for trend analysis
        }

        // Run anomaly detectors
        for detector in detectors {
            let issues = try await detector.detect(deep: deep)
            allIssues.append(contentsOf: issues)
        }

        // Generate suggestions based on findings
        let suggestionEngine = SuggestionEngine()
        allSuggestions = try await suggestionEngine.generate(from: allIssues)

        let healthScore = calculateHealthScore(issues: allIssues)

        return ImmunityScanResult(
            healthScore: healthScore,
            issues: allIssues,
            suggestions: allSuggestions
        )
    }

    private func calculateHealthScore(issues: [ImmunityIssue]) -> Int {
        let baseScore = 100
        let deductions = issues.reduce(0) { total, issue in
            switch issue.severity {
            case .critical: return total + 25
            case .warning: return total + 10
            case .info: return total + 2
            }
        }
        return max(0, baseScore - deductions)
    }
}

// MARK: - Result Types

struct ImmunityScanResult {
    let healthScore: Int
    let issues: [ImmunityIssue]
    let suggestions: [ImmunitySuggestion]
}

struct ImmunityIssue {
    enum Severity {
        case critical, warning, info

        var icon: String {
            switch self {
            case .critical: return "🔴"
            case .warning: return "🟡"
            case .info: return "🔵"
            }
        }
    }

    let severity: Severity
    let category: String
    let description: String
    let recommendation: String?
}

struct ImmunitySuggestion {
    let title: String
    let description: String
    let impact: String?
    let effort: String?
}
