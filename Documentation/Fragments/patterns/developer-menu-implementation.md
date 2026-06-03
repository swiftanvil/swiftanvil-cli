# Pattern: Developer Menu Implementation

## Problem
Developers need tools to debug, inspect, and manipulate apps during development and TestFlight testing. These tools must never appear in App Store builds.

## Solution
A `DeveloperMenu` package that provides an in-app debug overlay, available only in Debug and TestFlight builds.

## Build Configuration Detection

```swift
public enum Distribution: Sendable {
    case debug
    case testflight
    case appstore
    
    public static var current: Self {
        #if APPSTORE
        return .appstore
        #elseif TESTFLIGHT
        return .testflight
        #else
        return .debug
        #endif
    }
    
    public var isDeveloperBuild: Bool {
        self == .debug || self == .testflight
    }
}
```

## Xcode Build Configurations

```
Debug       → SWIFT_ACTIVE_COMPILATION_CONDITIONS = DEBUG
TestFlight  → SWIFT_ACTIVE_COMPILATION_CONDITIONS = TESTFLIGHT
AppStore    → SWIFT_ACTIVE_COMPILATION_CONDITIONS = APPSTORE
```

## DeveloperMenu Package

```swift
// DeveloperMenu/DeveloperMenu.swift

#if DEBUG || TESTFLIGHT
import SwiftUI

public struct DeveloperMenu: View {
    @State private var isPresented = false
    @StateObject private var viewModel = DeveloperMenuViewModel()
    
    public init() {}
    
    public var body: some View {
        EmptyView()
            .overlay(alignment: .topTrailing) {
                if isPresented {
                    developerMenuPanel
                        .transition(.move(edge: .trailing))
                }
            }
            .onShake {
                isPresented.toggle()
            }
    }
    
    private var developerMenuPanel: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                Text("Developer Menu")
                    .font(.headline)
                Spacer()
                Button("Close") { isPresented = false }
            }
            
            // Environment Info
            Section("Environment") {
                InfoRow(label: "Build", value: viewModel.buildConfiguration)
                InfoRow(label: "Version", value: viewModel.appVersion)
                InfoRow(label: "Bundle", value: viewModel.bundleIdentifier)
            }
            
            // Feature Flags
            Section("Feature Flags") {
                ForEach(viewModel.featureFlags) { flag in
                    Toggle(flag.name, isOn: flag.binding)
                }
            }
            
            // Tools
            Section("Tools") {
                Button("Network Inspector") {
                    viewModel.showNetworkInspector()
                }
                Button("Cache Viewer") {
                    viewModel.showCacheViewer()
                }
                Button("User Defaults") {
                    viewModel.showUserDefaultsEditor()
                }
                Button("Localization") {
                    viewModel.showLocalizationTester()
                }
            }
            
            // Actions
            Section("Actions") {
                Button("Clear Cache", role: .destructive) {
                    viewModel.clearCache()
                }
                Button("Reset Onboarding") {
                    viewModel.resetOnboarding()
                }
                Button("Simulate Push") {
                    viewModel.simulatePushNotification()
                }
                Button("Export Logs") {
                    viewModel.exportLogs()
                }
                Button("Crash App", role: .destructive) {
                    fatalError("Intentional crash for testing")
                }
            }
        }
        .padding()
        .frame(width: 300)
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 8)
        .padding()
    }
}

// Shake gesture detection
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeDetector(action: action))
    }
}

private struct ShakeDetector: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: .deviceDidShake)) { _ in
                action()
            }
    }
}

extension Notification.Name {
    static let deviceDidShake = Notification.Name("deviceDidShake")
}

#else
// App Store: Empty implementation
public struct DeveloperMenu: View {
    public init() {}
    public var body: some View { EmptyView() }
}
#endif
```

## Feature Flags Integration

```swift
public struct FeatureFlags: Sendable {
    public var requirePaywall: Bool
    public var showNewFeature: Bool
    public var enableBetaUI: Bool
    
    public static func `default`(for distribution: Distribution) -> FeatureFlags {
        switch distribution {
        case .debug:
            return FeatureFlags(
                requirePaywall: false,
                showNewFeature: true,
                enableBetaUI: true
            )
        case .testflight:
            return FeatureFlags(
                requirePaywall: false,
                showNewFeature: true,
                enableBetaUI: false
            )
        case .appstore:
            return FeatureFlags(
                requirePaywall: true,
                showNewFeature: false,
                enableBetaUI: false
            )
        }
    }
}
```

## Usage in App

```swift
@main
struct MyApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
                .overlay(DeveloperMenu())
                .environment(\.featureFlags, FeatureFlags.default(for: .current))
        }
    }
}
```

## Network Inspector

```swift
#if DEBUG || TESTFLIGHT
public actor NetworkInspector {
    public static let shared = NetworkInspector()
    
    private var requests: [NetworkRequestLog] = []
    
    public func log(request: URLRequest, response: URLResponse?, data: Data?, error: Error?) {
        let log = NetworkRequestLog(
            timestamp: Date(),
            url: request.url?.absoluteString ?? "",
            method: request.httpMethod ?? "",
            requestHeaders: request.allHTTPHeaderFields ?? [:],
            requestBody: request.httpBody,
            responseStatus: (response as? HTTPURLResponse)?.statusCode,
            responseHeaders: (response as? HTTPURLResponse)?.allHeaderFields as? [String: String],
            responseBody: data,
            error: error?.localizedDescription
        )
        requests.append(log)
    }
    
    public func allRequests() -> [NetworkRequestLog] {
        requests
    }
    
    public func clear() {
        requests.removeAll()
    }
}
#endif
```

## Related
- ADR-007: Package Catalog Architecture
- Pattern: Feature Flags
