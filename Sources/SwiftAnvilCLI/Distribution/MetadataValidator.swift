import Foundation

struct MetadataFinding {
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

struct MetadataValidator {
    let path: String

    func validate() async throws -> [MetadataFinding] {
        var findings: [MetadataFinding] = []

        try findings.append(contentsOf: validateInfoPlist())
        try findings.append(contentsOf: validatePrivacyManifest())
        try findings.append(contentsOf: validateEntitlements())

        return findings
    }

    // MARK: - Info.plist

    private func validateInfoPlist() throws -> [MetadataFinding] {
        let fm = FileManager.default
        let infoPlistPath = (path as NSString).appendingPathComponent("Info.plist")

        // Also search in common subdirectories
        var searchPaths = [infoPlistPath]
        let sourcesPath = (path as NSString).appendingPathComponent("Sources")
        if let entries = try? fm.contentsOfDirectory(atPath: sourcesPath) {
            for entry in entries {
                let nested = (sourcesPath as NSString).appendingPathComponent(entry)
                let nestedPlist = (nested as NSString).appendingPathComponent("Info.plist")
                searchPaths.append(nestedPlist)
            }
        }

        var foundAny = false
        var findings: [MetadataFinding] = []

        for plistPath in searchPaths where fm.fileExists(atPath: plistPath) {
            foundAny = true
            guard let dict = NSDictionary(contentsOfFile: plistPath) as? [String: Any] else {
                findings.append(MetadataFinding(
                    category: "infoplist",
                    severity: .error,
                    message: "Could not parse \(plistPath)",
                    recommendation: "Ensure Info.plist is valid XML/plist format"
                ))
                continue
            }

            let requiredKeys = [
                "CFBundleIdentifier",
                "CFBundleVersion",
                "CFBundleShortVersionString",
                "CFBundleName"
            ]
            for key in requiredKeys {
                if dict[key] == nil {
                    findings.append(MetadataFinding(
                        category: "infoplist",
                        severity: .error,
                        message: "Info.plist missing required key: \(key)",
                        recommendation: "Add \(key) to Info.plist"
                    ))
                }
            }

            // Check bundle identifier format
            if let bundleID = dict["CFBundleIdentifier"] as? String {
                if bundleID.contains(" ") || bundleID.hasPrefix(".") || bundleID.hasSuffix(".") {
                    findings.append(MetadataFinding(
                        category: "infoplist",
                        severity: .warning,
                        message: "Invalid CFBundleIdentifier format: '\(bundleID)'",
                        recommendation: "Use reverse-DNS format: com.example.app"
                    ))
                }
            }

            // Check for UIRequiredDeviceCapabilities on iOS
            if
                dict["LSRequiresIPhoneOS"] as? Bool == true,
                dict["UIRequiredDeviceCapabilities"] == nil
            {
                findings.append(MetadataFinding(
                    category: "infoplist",
                    severity: .info,
                    message: "iOS app missing UIRequiredDeviceCapabilities",
                    recommendation: "Consider adding required capabilities (armv7, wifi, etc.)"
                ))
            }
        }

        if !foundAny {
            findings.append(MetadataFinding(
                category: "infoplist",
                severity: .warning,
                message: "No Info.plist found in project",
                recommendation: "Add Info.plist with required bundle metadata"
            ))
        }

        return findings
    }

    // MARK: - Privacy Manifest

    private func validatePrivacyManifest() throws -> [MetadataFinding] {
        let fm = FileManager.default
        let manifestPath = (path as NSString).appendingPathComponent("PrivacyInfo.xcprivacy")

        guard fm.fileExists(atPath: manifestPath) else {
            return [MetadataFinding(
                category: "privacy",
                severity: .warning,
                message: "PrivacyInfo.xcprivacy not found",
                recommendation: "Apple requires privacy manifests for apps and SDKs starting spring 2024"
            )]
        }

        guard
            let data = try? Data(contentsOf: URL(fileURLWithPath: manifestPath)),
            let dict = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else {
            return [MetadataFinding(
                category: "privacy",
                severity: .error,
                message: "PrivacyInfo.xcprivacy is not valid JSON",
                recommendation: "Validate the manifest with `plutil -lint`"
            )]
        }

        var findings: [MetadataFinding] = []

        let requiredReasonAPIs = dict["NSPrivacyAccessedAPITypes"] as? [[String: Any]] ?? []
        if requiredReasonAPIs.isEmpty {
            findings.append(MetadataFinding(
                category: "privacy",
                severity: .info,
                message: "Privacy manifest has no NSPrivacyAccessedAPITypes",
                recommendation: "Add required reason APIs if you use file timestamp, disk space, or system boot time APIs"
            ))
        } else {
            for api in requiredReasonAPIs {
                if api["NSPrivacyAccessedAPIType"] == nil {
                    findings.append(MetadataFinding(
                        category: "privacy",
                        severity: .error,
                        message: "Privacy manifest API entry missing NSPrivacyAccessedAPIType",
                        recommendation: "Specify the API category (e.g., NSPrivacyAccessedAPICategoryFileTimestamp)"
                    ))
                }
                if api["NSPrivacyAccessedAPITypeReasons"] == nil {
                    findings.append(MetadataFinding(
                        category: "privacy",
                        severity: .error,
                        message: "Privacy manifest API entry missing NSPrivacyAccessedAPITypeReasons",
                        recommendation: "Add the required reason codes for each API category"
                    ))
                }
            }
        }

        return findings
    }

    // MARK: - Entitlements

    private func validateEntitlements() throws -> [MetadataFinding] {
        let fm = FileManager.default
        let entitlementsPath = (path as NSString).appendingPathComponent("entitlements.plist")

        guard fm.fileExists(atPath: entitlementsPath) else {
            return []
        }

        guard let dict = NSDictionary(contentsOfFile: entitlementsPath) as? [String: Any] else {
            return [MetadataFinding(
                category: "entitlements",
                severity: .error,
                message: "Could not parse entitlements.plist",
                recommendation: "Ensure entitlements file is valid plist format"
            )]
        }

        var findings: [MetadataFinding] = []

        // Check for get-task-allow in release
        if dict["get-task-allow"] as? Bool == true {
            findings.append(MetadataFinding(
                category: "entitlements",
                severity: .warning,
                message: "get-task-allow is enabled",
                recommendation: "Disable get-task-allow for release builds (enables debugging)"
            ))
        }

        // Check for dangerous entitlements
        let dangerousEntitlements = [
            "com.apple.security.cs.disable-library-validation",
            "com.apple.security.cs.allow-dyld-environment-variables",
            "com.apple.security.get-task-allow"
        ]
        for entitlement in dangerousEntitlements {
            if dict[entitlement] != nil {
                findings.append(MetadataFinding(
                    category: "entitlements",
                    severity: .warning,
                    message: "Potentially dangerous entitlement: \(entitlement)",
                    recommendation: "Review if this entitlement is necessary for production"
                ))
            }
        }

        return findings
    }
}
