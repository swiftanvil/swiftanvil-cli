# ADR-002: Host Agnosticism

## Status
Accepted

## Context
Development happens on macOS, CI runs on Linux/cloud, and scripts must work everywhere.

## Decision
All scripts and configurations must be host-agnostic:
- No hardcoded paths (use `PathResolver`)
- No macOS-only tools in CI paths
- Shell commands via `ShellRunner` abstraction
- Environment variables for host-specific values

## Consequences
- CI/CD works on any platform
- Local development matches CI behavior
- No "works on my machine" issues

