// ProjectVerificationReport.swift
// Report model for generated project verification

import Foundation

struct ProjectVerificationIssue: Equatable, Sendable {
    enum Severity: String, Sendable {
        case error
        case warning
    }

    let severity: Severity
    let check: String
    let message: String
    let path: String?
}

struct ProjectVerificationReport: Equatable, Sendable {
    let rootPath: String
    let issues: [ProjectVerificationIssue]

    var passed: Bool {
        errors.isEmpty
    }

    var errors: [ProjectVerificationIssue] {
        issues.filter { $0.severity == .error }
    }

    var warnings: [ProjectVerificationIssue] {
        issues.filter { $0.severity == .warning }
    }
}
