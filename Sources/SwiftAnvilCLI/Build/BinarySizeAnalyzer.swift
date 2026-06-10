import Foundation

struct BinarySizeBreakdown {
    let totalBytes: Int
    let sections: [Section]
    let recommendations: [String]

    struct Section {
        let name: String
        let bytes: Int
        let percentage: Double
    }
}

struct BinarySizeAnalyzer {
    let path: String

    func analyze() async throws -> BinarySizeBreakdown {
        let fm = FileManager.default
        let buildPath = (path as NSString).appendingPathComponent(".build/release")

        // Find executable or .a / .dylib files
        let entries = (try? fm.contentsOfDirectory(atPath: buildPath)) ?? []
        let binaries = entries.filter {
            $0.hasSuffix(".a") || $0.hasSuffix(".dylib") || $0.hasSuffix(".so")
                || !$0.contains(".")
        }

        var totalBytes = 0
        var sections: [BinarySizeBreakdown.Section] = []
        var recommendations: [String] = []

        // Gather sizes via `size` command if available, otherwise file sizes
        let runner = ShellRunner()
        let sizeResult = try? await runner.run("which size")
        let sizeAvailable = sizeResult?.exitCode == 0

        for binary in binaries {
            let binaryPath = (buildPath as NSString).appendingPathComponent(binary)
            let attrs = try? fm.attributesOfItem(atPath: binaryPath)
            let fileSize = (attrs?[.size] as? Int) ?? 0
            totalBytes += fileSize

            if sizeAvailable, !binary.hasSuffix(".dylib"), !binary.hasSuffix(".so") {
                let sizeOutput = try? await runner.run("size -m '\(binaryPath)'")
                if let sizeOutput, sizeOutput.exitCode == 0 {
                    let parsed = parseSizeOutput(sizeOutput.stdout, binaryName: binary)
                    sections.append(contentsOf: parsed)
                } else {
                    sections.append(BinarySizeBreakdown.Section(
                        name: binary,
                        bytes: fileSize,
                        percentage: 0
                    ))
                }
            } else {
                sections.append(BinarySizeBreakdown.Section(
                    name: binary,
                    bytes: fileSize,
                    percentage: 0
                ))
            }
        }

        // If no binaries found, try .build/debug for rough sizing
        if totalBytes == 0 {
            let debugPath = (path as NSString).appendingPathComponent(".build/debug")
            let debugEntries = (try? fm.contentsOfDirectory(atPath: debugPath)) ?? []
            let debugBinaries = debugEntries.filter {
                !$0.contains(".") || $0.hasSuffix(".a") || $0.hasSuffix(".dylib")
            }
            for binary in debugBinaries {
                let binaryPath = (debugPath as NSString).appendingPathComponent(binary)
                let attrs = try? fm.attributesOfItem(atPath: binaryPath)
                let fileSize = (attrs?[.size] as? Int) ?? 0
                totalBytes += fileSize
                sections.append(BinarySizeBreakdown.Section(
                    name: "\(binary) (debug)",
                    bytes: fileSize,
                    percentage: 0
                ))
            }
        }

        // Calculate percentages
        if totalBytes > 0 {
            sections = sections.map { section in
                BinarySizeBreakdown.Section(
                    name: section.name,
                    bytes: section.bytes,
                    percentage: Double(section.bytes) / Double(totalBytes) * 100
                )
            }
        }

        // Recommendations
        if totalBytes > 10_000_000 {
            recommendations.append(
                "Binary exceeds 10 MB. Consider stripping symbols and enabling dead code stripping."
            )
        }
        if binaries.contains(where: { $0.hasSuffix(".dylib") }) {
            recommendations.append(
                "Dynamic libraries increase launch time. Consider static linking where possible."
            )
        }
        if !recommendations.contains(where: { $0.contains("strip") }) {
            recommendations.append(
                "Run `strip -x` on release binaries to remove non-global symbols."
            )
        }

        return BinarySizeBreakdown(
            totalBytes: totalBytes,
            sections: sections.sorted(by: { $0.bytes > $1.bytes }),
            recommendations: recommendations
        )
    }

    private func parseSizeOutput(
        _ output: String,
        binaryName: String
    ) -> [BinarySizeBreakdown.Section] {
        var sections: [BinarySizeBreakdown.Section] = []
        let lines = output.split(separator: "\n")
        for line in lines {
            let trimmed = line.trimmingCharacters(in: .whitespaces)
            if trimmed.hasPrefix("Section ") || trimmed.isEmpty {
                continue
            }
            let parts = trimmed.split(separator: " ", omittingEmptySubsequences: true)
            if
                parts.count >= 3,
                let size = Int(parts[1].trimmingCharacters(in: .whitespaces))
            {
                let name = String(parts[0]).trimmingCharacters(in: .whitespaces)
                sections.append(BinarySizeBreakdown.Section(
                    name: "\(binaryName):\(name)",
                    bytes: size,
                    percentage: 0
                ))
            }
        }
        return sections
    }
}
