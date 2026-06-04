// ProjectVerificationFileSystem.swift
// File-system boundary for generated project verification

import Foundation

protocol ProjectVerificationFileSystem: Sendable {
    func fileExists(atPath path: String) -> Bool
    func directoryExists(atPath path: String) -> Bool
    func readFile(atPath path: String) throws -> String
}

struct LocalProjectVerificationFileSystem: ProjectVerificationFileSystem {
    func fileExists(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && !isDirectory.boolValue
    }

    func directoryExists(atPath path: String) -> Bool {
        var isDirectory: ObjCBool = false
        let exists = FileManager.default.fileExists(atPath: path, isDirectory: &isDirectory)
        return exists && isDirectory.boolValue
    }

    func readFile(atPath path: String) throws -> String {
        try String(contentsOfFile: path, encoding: .utf8)
    }
}
