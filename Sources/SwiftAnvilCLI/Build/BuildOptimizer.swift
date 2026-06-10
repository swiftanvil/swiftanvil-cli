import Foundation

struct BuildOptimization {
    let category: String
    let severity: Severity
    let message: String
    let recommendation: String

    enum Severity: String, CaseIterable {
        case info = "ℹ️"
        case warning = "⚠️"
        case error = "❌"
    }
}

struct TargetInfo {
    let name: String
    let dependencies: [String]
    let sourceFileCount: Int
    let isTest: Bool
}

struct BuildOptimizer {
    let path: String

    func analyze() async throws -> [BuildOptimization] {
        var optimizations: [BuildOptimization] = []

        let targets = try parseTargets()
        optimizations.append(contentsOf: analyzeGraph(targets: targets))
        optimizations.append(contentsOf: suggestSplitting(targets: targets))
        optimizations.append(contentsOf: recommendWMO(targets: targets))
        optimizations.append(contentsOf: detectRedundantRebuilds(targets: targets))

        return optimizations
    }

    // MARK: - Package.swift Parsing

    func parseTargets() throws -> [TargetInfo] {
        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        guard
            FileManager.default.fileExists(atPath: packagePath),
            let content = try? String(contentsOfFile: packagePath, encoding: .utf8)
        else {
            return []
        }

        var targets: [TargetInfo] = []

        // Extract .target(name: "...", dependencies: [...])
        let targetPattern = #"\.target\(\s*name:\s*"([^"]+)"(?:[^)]*dependencies:\s*\[([^\]]*)\])?[^)]*\)"#
        if let regex = try? NSRegularExpression(pattern: targetPattern, options: [.dotMatchesLineSeparators]) {
            let range = NSRange(content.startIndex..., in: content)
            let matches = regex.matches(in: content, options: [], range: range)
            for match in matches {
                let nameRange = match.range(at: 1)
                let depRange = match.range(at: 2)

                let name = String(content[Range(nameRange, in: content)!])
                let depString = depRange.location != NSNotFound ? String(content[Range(depRange, in: content)!]) : ""
                let dependencies = extractDependencyNames(from: depString)

                let sourceCount = countSourceFiles(for: name)
                targets.append(TargetInfo(
                    name: name,
                    dependencies: dependencies,
                    sourceFileCount: sourceCount,
                    isTest: false
                ))
            }
        }

        // Extract .testTarget(name: "...", dependencies: [...])
        let testPattern = #"\.testTarget\(\s*name:\s*"([^"]+)"(?:[^)]*dependencies:\s*\[([^\]]*)\])?[^)]*\)"#
        if let regex = try? NSRegularExpression(pattern: testPattern, options: [.dotMatchesLineSeparators]) {
            let range = NSRange(content.startIndex..., in: content)
            let matches = regex.matches(in: content, options: [], range: range)
            for match in matches {
                let nameRange = match.range(at: 1)
                let depRange = match.range(at: 2)

                let name = String(content[Range(nameRange, in: content)!])
                let depString = depRange.location != NSNotFound ? String(content[Range(depRange, in: content)!]) : ""
                let dependencies = extractDependencyNames(from: depString)

                let sourceCount = countSourceFiles(for: name, tests: true)
                targets.append(TargetInfo(
                    name: name,
                    dependencies: dependencies,
                    sourceFileCount: sourceCount,
                    isTest: true
                ))
            }
        }

        return targets
    }

    private func extractDependencyNames(from string: String) -> [String] {
        var names: [String] = []
        // Match .product(name: "...", ...) or "..." or .target(name: "...")
        let patterns = [
            #"name:\s*"([^"]+)""#,
            #""([^"]+)""#
        ]
        for pattern in patterns {
            if let regex = try? NSRegularExpression(pattern: pattern) {
                let range = NSRange(string.startIndex..., in: string)
                let matches = regex.matches(in: string, options: [], range: range)
                for match in matches {
                    if let matchRange = Range(match.range(at: 1), in: string) {
                        names.append(String(string[matchRange]))
                    }
                }
            }
        }
        return Array(Set(names))
    }

    private func countSourceFiles(for targetName: String, tests: Bool = false) -> Int {
        let dir = tests ? "Tests/\(targetName)" : "Sources/\(targetName)"
        let fullPath = (path as NSString).appendingPathComponent(dir)
        guard FileManager.default.fileExists(atPath: fullPath) else { return 0 }
        if let enumerator = FileManager.default.enumerator(atPath: fullPath) {
            return enumerator.compactMap { $0 as? String }.count(where: { $0.hasSuffix(".swift") })
        }
        return 0
    }

    // MARK: - Graph Analysis

    private func analyzeGraph(targets: [TargetInfo]) -> [BuildOptimization] {
        var results: [BuildOptimization] = []

        // Detect circular dependencies
        let cycles = findCycles(targets: targets)
        for cycle in cycles {
            results.append(BuildOptimization(
                category: "graph",
                severity: .error,
                message: "Circular dependency detected: \(cycle.joined(separator: " → "))",
                recommendation: "Refactor to break the cycle. Extract shared protocol into a separate module."
            ))
        }

        // Measure max depth
        let maxDepth = targets.map { dependencyDepth(of: $0.name, targets: targets, visited: []) }.max() ?? 0
        if maxDepth > 5 {
            results.append(BuildOptimization(
                category: "graph",
                severity: .warning,
                message: "Deep dependency chain: max depth is \(maxDepth)",
                recommendation: "Consider flattening the module hierarchy. Deep chains slow incremental builds."
            ))
        }

        // Count orphaned targets (no dependents)
        let allDeps = Set(targets.flatMap(\.dependencies))
        let orphaned = targets.filter { !allDeps.contains($0.name) && !$0.isTest }
        if orphaned.count > 1 {
            results.append(BuildOptimization(
                category: "graph",
                severity: .info,
                message: "\(orphaned.count) leaf targets with no dependents",
                recommendation: "These are good candidates for Whole Module Optimization (WMO)."
            ))
        }

        return results
    }

    private func findCycles(targets: [TargetInfo]) -> [[String]] {
        var cycles: [[String]] = []
        let targetMap = Dictionary(uniqueKeysWithValues: targets.map { ($0.name, $0) })

        for target in targets {
            var path: [String] = []
            var visited: Set<String> = []
            dfs(target.name, targetMap: targetMap, path: &path, visited: &visited, cycles: &cycles)
        }

        return cycles.map { Array($0) }
    }

    private func dfs(
        _ name: String,
        targetMap: [String: TargetInfo],
        path: inout [String],
        visited: inout Set<String>,
        cycles: inout [[String]]
    ) {
        if let index = path.firstIndex(of: name) {
            let cycle = Array(path[index...]) + [name]
            if !cycles.contains(cycle) {
                cycles.append(cycle)
            }
            return
        }

        guard let target = targetMap[name], !visited.contains(name) else { return }
        visited.insert(name)
        path.append(name)

        for dep in target.dependencies {
            dfs(dep, targetMap: targetMap, path: &path, visited: &visited, cycles: &cycles)
        }

        path.removeLast()
    }

    private func dependencyDepth(of name: String, targets: [TargetInfo], visited: [String]) -> Int {
        guard !visited.contains(name) else { return 0 }
        guard let target = targets.first(where: { $0.name == name }) else { return 0 }
        let newVisited = visited + [name]
        let childDepths = target.dependencies.map { dependencyDepth(of: $0, targets: targets, visited: newVisited) }
        return 1 + (childDepths.max() ?? 0)
    }

    // MARK: - Module Splitting

    private func suggestSplitting(targets: [TargetInfo]) -> [BuildOptimization] {
        var results: [BuildOptimization] = []

        for target in targets where !target.isTest {
            if target.sourceFileCount > 50 {
                results.append(BuildOptimization(
                    category: "splitting",
                    severity: .warning,
                    message: "Target '\(target.name)' has \(target.sourceFileCount) source files",
                    recommendation: "Consider splitting into smaller modules (e.g., \(target.name)Core, \(target.name)UI, \(target.name)Network)."
                ))
            } else if target.sourceFileCount > 30 {
                results.append(BuildOptimization(
                    category: "splitting",
                    severity: .info,
                    message: "Target '\(target.name)' has \(target.sourceFileCount) source files",
                    recommendation: "Monitor growth. Split when exceeding 50 files."
                ))
            }
        }

        return results
    }

    // MARK: - WMO Recommendation

    private func recommendWMO(targets: [TargetInfo]) -> [BuildOptimization] {
        var results: [BuildOptimization] = []

        for target in targets where !target.isTest {
            let depCount = target.dependencies.count
            let isLeaf = !targets.contains(where: { $0.dependencies.contains(target.name) })

            if isLeaf, target.sourceFileCount < 20 {
                results.append(BuildOptimization(
                    category: "wmo",
                    severity: .info,
                    message: "Target '\(target.name)' is a small leaf module (\(target.sourceFileCount) files)",
                    recommendation: "Enable Whole Module Optimization (WMO) for faster compile times: " +
                        ".unsafeFlags(['-whole-module-optimization'])"
                ))
            }

            if depCount > 5 {
                results.append(BuildOptimization(
                    category: "wmo",
                    severity: .warning,
                    message: "Target '\(target.name)' has \(depCount) dependencies",
                    recommendation: "Use incremental builds. Avoid WMO on high-fan-out targets " +
                        "to prevent cascading rebuilds."
                ))
            }
        }

        return results
    }

    // MARK: - Redundant Rebuild Detection

    private func detectRedundantRebuilds(targets: [TargetInfo]) -> [BuildOptimization] {
        var results: [BuildOptimization] = []

        // Check for targets with overly broad source declarations
        for target in targets where !target.isTest {
            if target.sourceFileCount == 0 {
                results.append(BuildOptimization(
                    category: "rebuild",
                    severity: .warning,
                    message: "Target '\(target.name)' has no source files detected",
                    recommendation: "Verify the Sources/\(target.name) directory exists and contains .swift files."
                ))
            }
        }

        return results
    }
}
