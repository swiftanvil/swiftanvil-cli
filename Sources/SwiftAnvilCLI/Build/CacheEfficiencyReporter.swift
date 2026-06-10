import Foundation

struct CacheEfficiencyReport {
    let buildDirSize: Int
    let derivedDataSize: Int
    let moduleCount: Int
    let staleArtifactCount: Int
    let recommendations: [String]
}

struct CacheEfficiencyReporter {
    let path: String

    func analyze() async throws -> CacheEfficiencyReport {
        let fm = FileManager.default
        let buildPath = (path as NSString).appendingPathComponent(".build")

        var buildDirSize = 0
        var moduleCount = 0
        var staleArtifactCount = 0
        var recommendations: [String] = []

        // Analyze .build directory
        if fm.fileExists(atPath: buildPath) {
            let enumerator = fm.enumerator(atPath: buildPath)
            while let file = enumerator?.nextObject() as? String {
                let fullPath = (buildPath as NSString).appendingPathComponent(file)
                if let attrs = try? fm.attributesOfItem(atPath: fullPath) {
                    buildDirSize += (attrs[.size] as? Int) ?? 0
                }

                if file.hasSuffix(".swiftmodule") {
                    moduleCount += 1
                }

                // Detect stale artifacts: .o files without corresponding .swift files
                if file.hasSuffix(".o") {
                    let sourceName = (file as NSString).deletingPathExtension + ".swift"
                    let sourcePath = (path as NSString).appendingPathComponent("Sources/" + sourceName)
                    if !fm.fileExists(atPath: sourcePath) {
                        staleArtifactCount += 1
                    }
                }
            }
        }

        // DerivedData estimate (common locations)
        var derivedDataSize = 0
        let derivedDataPaths = [
            "~/Library/Developer/Xcode/DerivedData",
            "~/Library/Caches/org.swift.swiftpm"
        ]
        for derivedPath in derivedDataPaths {
            let expanded = derivedPath.replacingOccurrences(of: "~", with: NSHomeDirectory())
            if let attrs = try? fm.attributesOfItem(atPath: expanded) {
                derivedDataSize += (attrs[.size] as? Int) ?? 0
            }
        }

        // Recommendations
        if buildDirSize > 500_000_000 {
            recommendations.append(
                "Build directory exceeds 500 MB. Run `swift package clean` to reclaim space."
            )
        }
        if staleArtifactCount > 0 {
            recommendations.append(
                "Found \(staleArtifactCount) stale object file(s). Run `swift package clean` to remove."
            )
        }
        if moduleCount > 50 {
            recommendations.append(
                "High module count (\(moduleCount)). Consider flattening dependencies to improve build parallelism."
            )
        }
        if derivedDataSize > 2_000_000_000 {
            recommendations.append(
                "DerivedData exceeds 2 GB. Consider cleaning: `rm -rf ~/Library/Developer/Xcode/DerivedData`"
            )
        }
        if recommendations.isEmpty {
            recommendations.append("Cache looks healthy. No action needed.")
        }

        return CacheEfficiencyReport(
            buildDirSize: buildDirSize,
            derivedDataSize: derivedDataSize,
            moduleCount: moduleCount,
            staleArtifactCount: staleArtifactCount,
            recommendations: recommendations
        )
    }
}
