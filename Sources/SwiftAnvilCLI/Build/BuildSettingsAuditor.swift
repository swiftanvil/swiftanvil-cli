import Foundation

struct BuildSettingsFinding {
    let category: String
    let severity: Severity
    let message: String
    let recommendation: String

    enum Severity: String {
        case error = "🔴"
        case warning = "🟡"
        case info = "🟢"
    }
}

struct BuildSettingsAuditor {
    let path: String

    func audit() async throws -> [BuildSettingsFinding] {
        var findings: [BuildSettingsFinding] = []

        try findings.append(contentsOf: auditPackageSwift())
        try findings.append(contentsOf: auditXcodeProject())

        return findings
    }

    // MARK: - Package.swift Audit

    private func auditPackageSwift() throws -> [BuildSettingsFinding] {
        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        guard
            FileManager.default.fileExists(atPath: packagePath),
            let content = try? String(contentsOfFile: packagePath, encoding: .utf8)
        else {
            return []
        }

        var findings: [BuildSettingsFinding] = []

        // Swift tools version
        let toolsVersionRegex = try NSRegularExpression(
            pattern: "// swift-tools-version:\\s*(\\d+\\.\\d+)"
        )
        let range = NSRange(content.startIndex..., in: content)
        if
            let match = toolsVersionRegex.firstMatch(in: content, options: [], range: range),
            let versionRange = Range(match.range(at: 1), in: content)
        {
            let version = String(content[versionRange])
            if
                let major = version.split(separator: ".").first,
                let majorInt = Int(major),
                majorInt < 6
            {
                findings.append(BuildSettingsFinding(
                    category: "version",
                    severity: .warning,
                    message: "Package.swift uses swift-tools-version \(version)",
                    recommendation: "Upgrade to swift-tools-version:6.0 for Swift 6 language mode"
                ))
            }
        } else {
            findings.append(BuildSettingsFinding(
                category: "version",
                severity: .warning,
                message: "Package.swift missing swift-tools-version comment",
                recommendation: "Add '// swift-tools-version:6.0' at the top of Package.swift"
            ))
        }

        // Swift language mode
        if !content.contains("swiftLanguageModes") {
            findings.append(BuildSettingsFinding(
                category: "language",
                severity: .warning,
                message: "Package.swift missing swiftLanguageModes declaration",
                recommendation: "Add .swiftLanguageModes([.v6]) to Package.swift for StrictConcurrency"
            ))
        }

        // Platforms
        if !content.contains("platforms:") {
            findings.append(BuildSettingsFinding(
                category: "platform",
                severity: .info,
                message: "Package.swift missing explicit platform declarations",
                recommendation: "Add platforms: [.iOS(.v18), .macOS(.v15)] to set minimum OS versions"
            ))
        }

        // StrictConcurrency (deprecated pattern)
        if content.contains("enableExperimentalFeature(\"StrictConcurrency\")") {
            findings.append(BuildSettingsFinding(
                category: "concurrency",
                severity: .warning,
                message: "Package.swift uses deprecated StrictConcurrency experimental feature",
                recommendation: "Replace with .swiftLanguageModes([.v6])"
            ))
        }

        // Unsafe flags
        let unsafeFlagsRegex = try NSRegularExpression(pattern: "unsafeFlags")
        let unsafeMatches = unsafeFlagsRegex.matches(in: content, options: [], range: range)
        if !unsafeMatches.isEmpty {
            findings.append(BuildSettingsFinding(
                category: "flags",
                severity: .warning,
                message: "Package.swift contains \(unsafeMatches.count) unsafeFlags usage(s)",
                recommendation: "Review unsafeFlags — they block library consumers from release builds"
            ))
        }

        // Binary targets with URLs
        let binaryTargetRegex = try NSRegularExpression(
            pattern: "\\.binaryTarget\\s*\\(.*?url:\\s*\\\"([^\"]+)\\\""
        )
        let binaryMatches = binaryTargetRegex.matches(in: content, options: [], range: range)
        for match in binaryMatches {
            if let urlRange = Range(match.range(at: 1), in: content) {
                let url = String(content[urlRange])
                if !url.hasPrefix("https://") {
                    findings.append(BuildSettingsFinding(
                        category: "security",
                        severity: .error,
                        message: "Binary target uses non-HTTPS URL: \(url)",
                        recommendation: "Use HTTPS URLs for all binary targets"
                    ))
                }
            }
        }

        return findings
    }

    // MARK: - Xcode Project Audit

    private func auditXcodeProject() throws -> [BuildSettingsFinding] {
        let fm = FileManager.default
        let contents = try? fm.contentsOfDirectory(atPath: path)
        let xcodeProjs = contents?.filter { $0.hasSuffix(".xcodeproj") } ?? []

        var findings: [BuildSettingsFinding] = []

        for proj in xcodeProjs {
            let pbxprojPath = (path as NSString).appendingPathComponent(
                "\(proj)/project.pbxproj"
            )
            guard
                fm.fileExists(atPath: pbxprojPath),
                let content = try? String(contentsOfFile: pbxprojPath, encoding: .utf8)
            else {
                continue
            }

            // DEAD_CODE_STRIPPING
            if content.contains("DEAD_CODE_STRIPPING = NO") {
                findings.append(BuildSettingsFinding(
                    category: "settings",
                    severity: .warning,
                    message: "\(proj): DEAD_CODE_STRIPPING is disabled",
                    recommendation: "Enable DEAD_CODE_STRIPPING = YES to reduce binary size"
                ))
            }

            // SWIFT_VERSION
            if content.contains("SWIFT_VERSION = 4") || content.contains("SWIFT_VERSION = 5.0") {
                findings.append(BuildSettingsFinding(
                    category: "settings",
                    severity: .warning,
                    message: "\(proj): SWIFT_VERSION is outdated",
                    recommendation: "Set SWIFT_VERSION = 6.0"
                ))
            }

            if !content.contains("SWIFT_VERSION") {
                findings.append(BuildSettingsFinding(
                    category: "settings",
                    severity: .warning,
                    message: "\(proj): SWIFT_VERSION not found in build settings",
                    recommendation: "Explicitly set SWIFT_VERSION = 6.0"
                ))
            }

            // Optimization level
            if content.contains("SWIFT_OPTIMIZATION_LEVEL = \"-Onone\"") {
                findings.append(BuildSettingsFinding(
                    category: "settings",
                    severity: .warning,
                    message: "\(proj): Release configuration uses -Onone",
                    recommendation: "Set SWIFT_OPTIMIZATION_LEVEL = -O for release builds"
                ))
            }

            // Bitcode (deprecated)
            if content.contains("ENABLE_BITCODE = YES") {
                findings.append(BuildSettingsFinding(
                    category: "settings",
                    severity: .warning,
                    message: "\(proj): ENABLE_BITCODE is enabled",
                    recommendation: "Bitcode is deprecated by Apple — disable it"
                ))
            }

            // Strip
            if content.contains("STRIP_INSTALLED_PRODUCT = NO") {
                findings.append(BuildSettingsFinding(
                    category: "settings",
                    severity: .info,
                    message: "\(proj): STRIP_INSTALLED_PRODUCT is disabled",
                    recommendation: "Enable STRIP_INSTALLED_PRODUCT = YES to reduce binary size"
                ))
            }
        }

        return findings
    }
}
