import Foundation

struct DependencyNode {
    let name: String
    let dependencies: [String]
}

struct DependencyGraphVisualizer {
    let path: String

    func parseGraph() throws -> [DependencyNode] {
        let packagePath = (path as NSString).appendingPathComponent("Package.swift")
        guard let content = try? String(contentsOfFile: packagePath, encoding: .utf8) else {
            return []
        }

        // Parse package dependencies (external)
        var nodes: [DependencyNode] = []
        let packageDepRegex = try NSRegularExpression(
            pattern: "\\.package\\s*\\(\\s*url:\\s*\\\"([^\"]+)\\\""
        )
        let range = NSRange(content.startIndex..., in: content)
        let packageMatches = packageDepRegex.matches(in: content, options: [], range: range)
        for match in packageMatches {
            if let urlRange = Range(match.range(at: 1), in: content) {
                let url = String(content[urlRange])
                let name = url.split(separator: "/").last?
                    .replacingOccurrences(of: ".git", with: "") ?? url
                nodes.append(DependencyNode(name: name, dependencies: []))
            }
        }

        // Parse target dependencies (internal)
        let targetRegex = try NSRegularExpression(
            pattern: "\\.target\\s*\\(\\s*name:\\s*\\\"([^\"]+)\\\"(.*?)\\)"
        )
        let targetMatches = targetRegex.matches(in: content, options: [], range: range)
        for match in targetMatches {
            guard
                let nameRange = Range(match.range(at: 1), in: content),
                let bodyRange = Range(match.range(at: 2), in: content)
            else { continue }

            let targetName = String(content[nameRange])
            let body = String(content[bodyRange])

            var deps: [String] = []
            let depRegex = try NSRegularExpression(
                pattern: "dependencies:\\s*\\[(.*?)\\]"
            )
            let bodyRangeNS = NSRange(body.startIndex..., in: body)
            if
                let depMatch = depRegex.firstMatch(in: body, options: [], range: bodyRangeNS),
                let depListRange = Range(depMatch.range(at: 1), in: body)
            {
                let depList = String(body[depListRange])
                let nameRegex = try NSRegularExpression(pattern: "\\\"([^\"]+)\\\"")
                let depListRangeNS = NSRange(depList.startIndex..., in: depList)
                let nameMatches = nameRegex.matches(in: depList, options: [], range: depListRangeNS)
                for nm in nameMatches {
                    if let nmRange = Range(nm.range(at: 1), in: depList) {
                        deps.append(String(depList[nmRange]))
                    }
                }
            }

            nodes.append(DependencyNode(name: targetName, dependencies: deps))
        }

        return nodes
    }

    func generateMermaid(_ nodes: [DependencyNode]) -> String {
        var lines = ["graph TD"]
        var seenEdges = Set<String>()

        for node in nodes {
            for dep in node.dependencies {
                let edge = "    \(sanitize(node.name)) --> \(sanitize(dep))"
                if !seenEdges.contains(edge) {
                    lines.append(edge)
                    seenEdges.insert(edge)
                }
            }
        }

        return lines.joined(separator: "\n")
    }

    func generateDOT(_ nodes: [DependencyNode]) -> String {
        var lines = ["digraph Dependencies {"]
        var seenEdges = Set<String>()

        for node in nodes {
            for dep in node.dependencies {
                let edge = "    \"\(node.name)\" -> \"\(dep)\";"
                if !seenEdges.contains(edge) {
                    lines.append(edge)
                    seenEdges.insert(edge)
                }
            }
        }

        lines.append("}")
        return lines.joined(separator: "\n")
    }

    func detectCycles(_ nodes: [DependencyNode]) -> [[String]] {
        var adjacency: [String: [String]] = [:]
        for node in nodes {
            adjacency[node.name] = node.dependencies
        }

        var cycles: [[String]] = []
        var visited = Set<String>()
        var stack = Set<String>()
        var path: [String] = []

        func dfs(_ node: String) {
            visited.insert(node)
            stack.insert(node)
            path.append(node)

            for neighbor in adjacency[node] ?? [] {
                if stack.contains(neighbor) {
                    if let idx = path.firstIndex(of: neighbor) {
                        cycles.append(Array(path[idx...]) + [neighbor])
                    }
                } else if !visited.contains(neighbor) {
                    dfs(neighbor)
                }
            }

            path.removeLast()
            stack.remove(node)
        }

        for node in nodes.map(\.name) {
            if !visited.contains(node) {
                dfs(node)
            }
        }

        return cycles
    }

    private func sanitize(_ name: String) -> String {
        name.replacingOccurrences(of: "-", with: "_")
            .replacingOccurrences(of: ".", with: "_")
    }
}
