// ShellRunner.swift
// Host-agnostic shell command execution

import Foundation

/// Runs shell commands in a host-agnostic manner
actor ShellRunner {
    struct Result {
        let exitCode: Int32
        let stdout: String
        let stderr: String
    }

    /// Runs a shell command and returns the result
    func run(_ command: String, in directory: String? = nil) async throws -> Result {
        let process = Process()
        let stdoutPipe = Pipe()
        let stderrPipe = Pipe()

        process.executableURL = URL(fileURLWithPath: "/bin/sh")
        process.arguments = ["-c", command]
        process.standardOutput = stdoutPipe
        process.standardError = stderrPipe

        if let directory = directory {
            process.currentDirectoryURL = URL(fileURLWithPath: directory)
        }

        // Set environment to be host-agnostic
        var environment = ProcessInfo.processInfo.environment
        environment["LANG"] = "en_US.UTF-8"
        process.environment = environment

        try process.run()
        process.waitUntilExit()

        let stdout = String(data: stdoutPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""
        let stderr = String(data: stderrPipe.fileHandleForReading.readDataToEndOfFile(), encoding: .utf8) ?? ""

        return Result(
            exitCode: process.terminationStatus,
            stdout: stdout,
            stderr: stderr
        )
    }

    /// Runs a command and throws on non-zero exit
    func runOrThrow(_ command: String, in directory: String? = nil) async throws -> String {
        let result = try await run(command, in: directory)
        guard result.exitCode == 0 else {
            throw ShellError.commandFailed(command: command, stderr: result.stderr)
        }
        return result.stdout
    }
}

enum ShellError: Error {
    case commandFailed(command: String, stderr: String)
}
