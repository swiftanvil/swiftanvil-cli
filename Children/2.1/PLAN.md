---
author: kimi-cli
hostVersion: k1.6
artifactKind: plan-artifact
schemaVersion: "1.0"
chainId: phase-2-core-packages
taskId: child-2.1-appnetworking
producedBy: kimi-cli
contextBudget: "12000"
createdAt: 2026-06-02T23:45:00Z
---

# Child 2.1: AnvilNetwork Package — Revised Plan

## Goal

Build a type-safe, Swift 6-strict HTTP client with builder-pattern API, configurable caching, retry, and observability. Sets the pattern for all Phase 2 packages.

## Non-Goals

- Macro-based API (`@GET`) — deferred to Phase 3+
- WebSocket support — future enhancement
- GraphQL client — out of scope
- Multipart uploads — Phase 2.1b (follow-up child)
- Streaming bodies — Phase 2.1b

## Naming

| Context | Name |
|---------|------|
| Repo | `swiftanvil-anvil-network` |
| Swift Package | `AnvilNetwork` |
| Module import | `import AnvilNetwork` |
| Product | `.product(name: "AnvilNetwork", package: "swiftanvil-anvil-network")` |

## Concurrency Model

`HTTPClient` is a `Sendable` struct wrapping an internal `actor HTTPClientCore`. Public API is value-type (immutable config, copy-on-write interceptors). All mutating operations go through the actor.

```swift
public struct HTTPClient: Sendable {
    private let core: HTTPClientCore  // actor
}
```

## Error Model

```swift
public enum NetworkError: Error, Sendable {
    case transport(URLError)
    case invalidResponse(statusCode: Int, body: Data?)
    case decoding(Error, Data)
    case encoding(Error)
    case retryExhausted(NetworkError, attempts: Int)
    case cancelled
    case interceptorRejected(reason: String)
}
```

## Public API Surface

### Core Types

```swift
// Client
public struct HTTPClient: Sendable
public struct HTTPClientConfiguration: Sendable

// Request/Response
public struct HTTPRequest: Sendable
public struct HTTPResponse: Sendable
public struct HTTPMethod: Sendable, Hashable

// Configuration
public struct CacheConfiguration: Sendable
public struct RetryConfiguration: Sendable
public struct TimeoutConfiguration: Sendable

// Interceptors
public protocol RequestInterceptor: Sendable {
    func intercept(_ request: HTTPRequest) async throws -> HTTPRequest
}
public protocol ResponseInterceptor: Sendable {
    func intercept(_ response: HTTPResponse, for request: HTTPRequest) async throws -> HTTPResponse
}

// Transport (testability seam)
public protocol HTTPTransport: Sendable {
    func send(_ request: HTTPRequest) async throws -> HTTPResponse
}

// Validation
public protocol ResponseValidator: Sendable {
    func validate(_ response: HTTPResponse) throws
}
```

### Usage

```swift
import AnvilNetwork

// Basic GET with auto-decode
let client = HTTPClient(configuration: .default)
let user: User = try await client.request(.get("/users/\(id)")).decode()

// With configuration
let client = HTTPClient(configuration: HTTPClientConfiguration(
    baseURL: URL(string: "https://api.example.com")!,
    timeout: .init(request: 30, resource: 300),
    cache: .init(strategy: .memory(maxSize: 10_000_000), ttl: 300),
    retry: .init(maxAttempts: 3, backoff: .exponential(base: 1.0, maxDelay: 60), retryableStatusCodes: [408, 429, 500, 502, 503, 504]),
    decoder: JSONDecoder()
))

// POST with body
let response = try await client.request(.post("/users"))
    .body(newUser, encoder: JSONEncoder())
    .header(.contentType, .applicationJSON)
    .send()

// With interceptors
let authedClient = client
    .addingRequestInterceptor(AuthInterceptor(tokenProvider: tokenStore))
    .addingResponseInterceptor(LoggingInterceptor())
```

## Task Breakdown (Revised Estimates)

| # | Task | Effort | Verification |
|---|------|--------|--------------|
| 1 | Design PublicAPI.md + concurrency contract | 1h | Cross-host review of API surface |
| 2 | Implement HTTPClient core + actor isolation | 1.5h | Builds, thread-sanitizer clean |
| 3 | Implement HTTPRequest/HTTPResponse + methods | 1h | All HTTP methods work, headers correct |
| 4 | Implement URLSessionTransport + HTTPTransport protocol | 1h | Can swap to mock transport |
| 5 | Implement caching (memory, TTL, ETag) | 1.5h | Cache hit returns cached data, 304 revalidates |
| 6 | Implement retry (exponential backoff, jitter, Retry-After) | 1.5h | 503×2 then 200 succeeds on 3rd try |
| 7 | Implement interceptors (request + response chains) | 1h | Auth interceptor adds header, logging prints |
| 8 | Implement response validation + error model | 1h | Non-2xx throws NetworkError.invalidResponse |
| 9 | Implement cancellation propagation | 30m | Task cancellation cancels in-flight request |
| 10 | Write tests (unit + integration + concurrency stress) | 2h | ≥80% coverage, TSan clean |
| 11 | Write README + DocC catalog | 1h | Clear examples, API reference |
| 12 | Cross-host review | 1h | All criteria pass |

**Total: ~13h** (was ~5h — Claude was right, estimates were unrealistic)

## Caching Semantics

- **Storage**: In-memory only for Phase 2. Disk cache in 2.1b.
- **Key**: URL + method + `Authorization` header hash (if present)
- **TTL**: Configurable per response, default 300s
- **Revalidation**: `ETag`/`If-None-Match` support, 304 handling
- **Eviction**: LRU when max size exceeded
- **Thread safety**: Actor-isolated cache store

## Retry Semantics

- **Triggers**: Network errors, 408, 429, 500, 502, 503, 504. Configurable.
- **Backoff**: Exponential with full jitter. `delay = min(maxDelay, base * 2^attempt * random(0.5, 1.0))`
- **Retry-After**: Respected if present (seconds or HTTP-date)
- **Idempotency**: Only retries GET/HEAD/PUT/DELETE by default. POST/PUT requires explicit opt-in.
- **Interceptor re-invocation**: Yes, on each retry attempt
- **Cancellation**: Cancels retry loop, surfaces `NetworkError.cancelled`

## Authentication

Deferred to interceptor pattern. Provide `BearerTokenInterceptor` as example:

```swift
public struct BearerTokenInterceptor: RequestInterceptor {
    private let tokenProvider: @Sendable () async throws -> String
    
    public func intercept(_ request: HTTPRequest) async throws -> HTTPRequest {
        var request = request
        request.header(.authorization, "Bearer \(try await tokenProvider())")
        return request
    }
}
```

Token refresh coalescing is the caller's responsibility (via `tokenProvider`).

## Observability

Internal `NetworkLogger` protocol with default `OSLog` implementation. No external dependencies.

```swift
public protocol NetworkLogger: Sendable {
    func logRequest(_ request: HTTPRequest)
    func logResponse(_ response: HTTPResponse, duration: Duration)
    func logError(_ error: NetworkError, for request: HTTPRequest)
}
```

## Testability

- `HTTPTransport` protocol for mock transport
- `Clock` protocol injection for retry/backoff timing (default: `ContinuousClock`)
- `NetworkLogger` protocol for test assertions

## Assurance Strategy

| Lens | Selected | Coverage |
|------|----------|----------|
| Planning | Architecture, API design, concurrency model | PublicAPI.md, this plan |
| Implementation | Correctness, concurrency, error handling, cancellation | Actor isolation, Sendable contracts |
| Test | Unit, integration, concurrency stress, error paths | Mock transport, TSan, cancellation |
| Review | Exhaustive critique (2 passes: API + full) | Cross-host pre-impl and post-impl |

## Success Criteria

- [ ] Package builds with `swift build`
- [ ] Tests pass with `swift test`
- [ ] Test coverage ≥ 80% (measured via `swift test --enable-code-coverage`)
- [ ] Thread-sanitizer clean (`swift test --sanitize=thread`)
- [ ] README with usage examples
- [ ] DocC catalog with GettingStarted
- [ ] Swift 6 + StrictConcurrency (implicit, not experimental flag)
- [ ] Cross-host review approved

## Output

New repo: `github.com/swiftanvil/swiftanvil-anvil-network`
