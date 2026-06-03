# Pattern: Networking Layer Design

## Problem
Networking code is often:
- Scattered across the codebase
- Untyped (string URLs, dictionaries)
- Hard to test (requires real network calls)
- Inconsistent (different patterns per module)

## Solution
A type-safe networking layer inspired by Moya, built as an `AppNetworking` package.

## Architecture

```
AppNetworking/
├── Core/
│   ├── NetworkProvider.swift       # Main request executor
│   ├── NetworkTarget.swift         # Protocol for API definitions
│   ├── NetworkTask.swift           # Request body types
│   ├── NetworkError.swift          # Error types
│   └── NetworkInterceptor.swift    # Auth, logging, retry
├── Plugins/
│   ├── AuthPlugin.swift            # Token injection
│   ├── LoggingPlugin.swift         # Request/response logging
│   └── RetryPlugin.swift           # Automatic retry
└── Testing/
    ├── NetworkStubbing.swift       # Mock responses
    └── NetworkTesting.swift        # Test helpers
```

## Core Types

### NetworkTarget (Protocol)

```swift
public protocol NetworkTarget: Sendable {
    var baseURL: URL { get }
    var path: String { get }
    var method: HTTPMethod { get }
    var task: NetworkTask { get }
    var headers: [String: String]? { get }
}

public extension NetworkTarget {
    var headers: [String: String]? { nil }
}
```

### NetworkTask (Enum)

```swift
public enum NetworkTask: Sendable {
    case requestPlain
    case requestParameters([String: Sendable])
    case requestJSON(Encodable)
    case uploadMultipart([MultipartFormData])
    case downloadFile(destination: URL)
}
```

### NetworkProvider

```swift
public actor NetworkProvider<T: NetworkTarget> {
    private let session: URLSession
    private let interceptors: [NetworkInterceptor]
    private let decoder: JSONDecoder
    
    public init(
        session: URLSession = .shared,
        interceptors: [NetworkInterceptor] = [],
        decoder: JSONDecoder = JSONDecoder()
    ) {
        self.session = session
        self.interceptors = interceptors
        self.decoder = decoder
    }
    
    public func request<R: Decodable>(_ target: T) async throws -> R {
        let request = try buildRequest(for: target)
        let (data, response) = try await session.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NetworkError.invalidResponse
        }
        
        guard (200..<300).contains(httpResponse.statusCode) else {
            throw NetworkError.httpError(statusCode: httpResponse.statusCode, data: data)
        }
        
        return try decoder.decode(R.self, from: data)
    }
    
    private func buildRequest(for target: T) throws -> URLRequest {
        var request = URLRequest(url: target.baseURL.appendingPathComponent(target.path))
        request.httpMethod = target.method.rawValue
        
        // Apply task
        switch target.task {
        case .requestPlain:
            break
        case .requestParameters(let params):
            request.url = request.url?.appending(queryItems: params.map {
                URLQueryItem(name: $0.key, value: String(describing: $0.value))
            })
        case .requestJSON(let body):
            request.httpBody = try JSONEncoder().encode(body)
            request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        // ... other cases
        }
        
        // Apply headers
        target.headers?.forEach { request.setValue($0.value, forHTTPHeaderField: $0.key) }
        
        return request
    }
}
```

## Usage Example

```swift
// Define API
public enum UserAPI {
    case getProfile(id: String)
    case updateProfile(id: String, profile: UpdateProfileRequest)
    case deleteAccount(id: String)
}

// Conform to NetworkTarget
extension UserAPI: NetworkTarget {
    public var baseURL: URL {
        URL(string: "https://api.example.com/v1")!
    }
    
    public var path: String {
        switch self {
        case .getProfile(let id), .updateProfile(let id, _):
            return "/users/\(id)"
        case .deleteAccount(let id):
            return "/users/\(id)"
        }
    }
    
    public var method: HTTPMethod {
        switch self {
        case .getProfile: return .get
        case .updateProfile: return .put
        case .deleteAccount: return .delete
        }
    }
    
    public var task: NetworkTask {
        switch self {
        case .getProfile, .deleteAccount:
            return .requestPlain
        case .updateProfile(_, let profile):
            return .requestJSON(profile)
        }
    }
}

// Use in service
public actor UserService {
    private let provider: NetworkProvider<UserAPI>
    
    public init(provider: NetworkProvider<UserAPI> = NetworkProvider()) {
        self.provider = provider
    }
    
    public func getProfile(id: String) async throws -> UserProfile {
        try await provider.request(.getProfile(id: id))
    }
}
```

## Testing with Stubs

```swift
import Testing
@testable import AppNetworking

struct UserServiceTests {
    @Test func getProfileSuccess() async throws {
        // Given
        let expectedProfile = UserProfile(id: "123", name: "John")
        let stub = NetworkStub<UserAPI>(
            target: .getProfile(id: "123"),
            response: .success(expectedProfile)
        )
        let provider = NetworkProvider<UserAPI>(stubs: [stub])
        let service = UserService(provider: provider)
        
        // When
        let profile = try await service.getProfile(id: "123")
        
        // Then
        #expect(profile.id == "123")
        #expect(profile.name == "John")
    }
    
    @Test func getProfileFailure() async throws {
        // Given
        let stub = NetworkStub<UserAPI>(
            target: .getProfile(id: "999"),
            response: .failure(.notFound)
        )
        let provider = NetworkProvider<UserAPI>(stubs: [stub])
        let service = UserService(provider: provider)
        
        // Then
        await #expect(throws: NetworkError.notFound) {
            try await service.getProfile(id: "999")
        }
    }
}
```

## Interceptors

```swift
public protocol NetworkInterceptor: Sendable {
    func intercept(request: URLRequest) async throws -> URLRequest
    func intercept(response: URLResponse, data: Data) async throws -> Data
}

// Auth interceptor
public struct AuthInterceptor: NetworkInterceptor {
    private let tokenProvider: TokenProvider
    
    public func intercept(request: URLRequest) async throws -> URLRequest {
        var request = request
        let token = try await tokenProvider.getToken()
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        return request
    }
    
    public func intercept(response: URLResponse, data: Data) async throws -> Data {
        data
    }
}
```

## Related
- ADR-007: Package Catalog Architecture
- Pattern: Shared Type-Safe Packages
