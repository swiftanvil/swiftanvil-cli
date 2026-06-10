import Foundation

struct LoggingFinding {
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

struct LoggingAuditor {
    let path: String

    func audit() async throws -> [LoggingFinding] {
        let fm = FileManager.default
        let sourcesPath = (path as NSString).appendingPathComponent("Sources")
        guard fm.fileExists(atPath: sourcesPath) else {
            return []
        }

        var findings: [LoggingFinding] = []
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

                if trimmed.contains("print(") {
                    findings.append(LoggingFinding(
                        file: file,
                        line: lineNum,
                        severity: .warning,
                        message: "Use of print() found",
                        recommendation: "Replace with AnvilLogger or os.log for production logging"
                    ))
                }

                if trimmed.contains("NSLog(") {
                    findings.append(LoggingFinding(
                        file: file,
                        line: lineNum,
                        severity: .warning,
                        message: "Use of NSLog() found",
                        recommendation: "Replace with AnvilLogger or os.log"
                    ))
                }

                if trimmed.contains("debugPrint(") {
                    findings.append(LoggingFinding(
                        file: file,
                        line: lineNum,
                        severity: .info,
                        message: "Use of debugPrint() found",
                        recommendation: "Ensure debugPrint is wrapped in #if DEBUG"
                    ))
                }

                if
                    trimmed.contains("OSLogType.error"),
                    !trimmed.contains("os_log")
                {
                    findings.append(LoggingFinding(
                        file: file,
                        line: lineNum,
                        severity: .info,
                        message: "Hardcoded log level found",
                        recommendation: "Use parameterized log levels for flexibility"
                    ))
                }
            }
        }

        return findings
    }
}
