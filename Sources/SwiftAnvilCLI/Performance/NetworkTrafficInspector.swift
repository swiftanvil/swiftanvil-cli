import Foundation

struct NetworkFinding {
    let file: String
    let line: Int
    let severity: Severity
    let message: String
    let recommendation: String

    enum Severity: String {
        case error = "🔴"
        case warning = "🟡"
        case info = "🟢"
    }
}

struct NetworkTrafficInspector {
    let path: String

    func inspect() async throws -> [NetworkFinding] {
        let fm = FileManager.default
        let sourcesPath = (path as NSString).appendingPathComponent("Sources")
        guard fm.fileExists(atPath: sourcesPath) else {
            return []
        }

        var findings: [NetworkFinding] = []
        let enumerator = fm.enumerator(atPath: sourcesPath)

        while let file = enumerator?.nextObject() as? String {
            guard file.hasSuffix(".swift") else { continue }
            let filePath = (sourcesPath as NSString).appendingPathComponent(file)
            guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else { continue }

            let lines = content.split(separator: "\n", omittingEmptySubsequences: false)
            for (index, line) in lines.enumerated() {
                let lineNum = index + 1
                let trimmed = line.trimmingCharacters(in: .whitespaces)

                // Skip comments
                if trimmed.hasPrefix("//") || trimmed.hasPrefix("/*") || trimmed.hasPrefix("*") {
                    continue
                }

                // Detect hardcoded HTTP URLs
                if let range = trimmed.range(of: "http://") {
                    findings.append(NetworkFinding(
                        file: file,
                        line: lineNum,
                        severity: .error,
                        message: "Insecure HTTP URL found",
                        recommendation: "Use HTTPS for all network requests"
                    ))
                }

                // Detect hardcoded URLs in general (outside config/tests)
                if
                    trimmed.contains("https://"),
                    !file.contains("Test"),
                    !file.contains("Config"),
                    !trimmed.contains("example.com"),
                    !trimmed.contains("localhost")
                {
                    let urlRegex = try? NSRegularExpression(pattern: "https?://[^\\s\"'`]+")
                    let range = NSRange(trimmed.startIndex..., in: trimmed)
                    if let match = urlRegex?.firstMatch(in: trimmed, options: [], range: range) {
                        findings.append(NetworkFinding(
                            file: file,
                            line: lineNum,
                            severity: .warning,
                            message: "Hardcoded URL found in source",
                            recommendation: "Move URLs to configuration or environment variables"
                        ))
                    }
                }
            }
        }

        // Check for certificate pinning stubs
        let hasPinning = findings.contains { $0.message.contains("pinning") }
        if !hasPinning {
            let hasNetworkCode = !findings.isEmpty || (try? hasAnyNetworkCode()) == true
            if hasNetworkCode {
                findings.append(NetworkFinding(
                    file: "N/A",
                    line: 0,
                    severity: .info,
                    message: "No certificate pinning detected",
                    recommendation: "Consider implementing certificate pinning for sensitive APIs"
                ))
            }
        }

        return findings
    }

    private func hasAnyNetworkCode() throws -> Bool {
        let fm = FileManager.default
        let sourcesPath = (path as NSString).appendingPathComponent("Sources")
        let enumerator = fm.enumerator(atPath: sourcesPath)
        while let file = enumerator?.nextObject() as? String {
            guard file.hasSuffix(".swift") else { continue }
            let filePath = (sourcesPath as NSString).appendingPathComponent(file)
            guard let content = try? String(contentsOfFile: filePath, encoding: .utf8) else { continue }
            if content.contains("URLSession") || content.contains("HTTPClient") || content.contains("URLRequest") {
                return true
            }
        }
        return false
    }
}
