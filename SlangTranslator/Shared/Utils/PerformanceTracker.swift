//
//  PerformanceTracker.swift
//  SlangTranslator
//
//  Helper class for Firebase Performance Monitoring traces.
//  Automatically becomes a no-op when running in app extensions.
//

import Foundation
import SwiftUI

#if canImport(FirebasePerformance)
import FirebasePerformance

final class PerformanceTracker {
    static let shared = PerformanceTracker()

    /// Check if we're running in an app extension
    private let isExtension: Bool = {
        Bundle.main.bundlePath.hasSuffix(".appex")
    }()

    private init() {}

    // MARK: - Screen Traces

    private var screenTraces: [String: Trace] = [:]

    func startScreenTrace(name: String) {
        guard !isExtension else { return }
        let traceName = "screen_\(name)"
        guard screenTraces[traceName] == nil else { return }

        if let trace = Performance.startTrace(name: traceName) {
            trace.setValue(UIDevice.current.systemVersion, forAttribute: "ios_version")
            screenTraces[traceName] = trace
        }
    }

    func stopScreenTrace(name: String) {
        guard !isExtension else { return }
        let traceName = "screen_\(name)"
        screenTraces[traceName]?.stop()
        screenTraces.removeValue(forKey: traceName)
    }

    // MARK: - Network Traces

    func startNetworkTrace(name: String, url: String) -> Trace? {
        guard !isExtension else { return nil }
        let trace = Performance.startTrace(name: "network_\(name)")
        trace?.setValue(url, forAttribute: "url")
        return trace
    }

    func stopNetworkTrace(_ trace: Trace?, success: Bool, responseSize: Int? = nil) {
        guard !isExtension else { return }
        trace?.setValue(success ? "success" : "error", forAttribute: "status")
        if let size = responseSize {
            trace?.setValue(String(size), forAttribute: "response_size")
        }
        trace?.stop()
    }

    // MARK: - Custom Operation Traces

    func startOperationTrace(name: String, attributes: [String: String] = [:]) -> Trace? {
        guard !isExtension else { return nil }
        let trace = Performance.startTrace(name: name)
        for (key, value) in attributes {
            trace?.setValue(value, forAttribute: key)
        }
        return trace
    }

    func stopOperationTrace(_ trace: Trace?, attributes: [String: Any] = [:]) {
        guard !isExtension else { return }
        for (key, value) in attributes {
            if let stringValue = value as? String {
                trace?.setValue(stringValue, forAttribute: key)
            } else if let intValue = value as? Int {
                trace?.setValue(String(intValue), forAttribute: key)
            }
        }
        trace?.stop()
    }

    // MARK: - Metrics

    func incrementMetric(_ trace: Trace?, name: String, by value: Int64 = 1) {
        guard !isExtension else { return }
        trace?.incrementMetric(name, by: value)
    }
}

#else

// MARK: - Stub when FirebasePerformance is not available

final class PerformanceTracker {
    static let shared = PerformanceTracker()
    private init() {}

    func startScreenTrace(name: String) {}
    func stopScreenTrace(name: String) {}
    func startNetworkTrace(name: String, url: String) -> Any? { nil }
    func stopNetworkTrace(_ trace: Any?, success: Bool, responseSize: Int? = nil) {}
    func startOperationTrace(name: String, attributes: [String: String] = [:]) -> Any? { nil }
    func stopOperationTrace(_ trace: Any?, attributes: [String: Any] = [:]) {}
    func incrementMetric(_ trace: Any?, name: String, by value: Int64 = 1) {}
}

#endif

// MARK: - SwiftUI View Extension

struct ScreenTraceModifier: ViewModifier {
    let screenName: String
    @State private var hasAppeared = false

    func body(content: Content) -> some View {
        content
            .onAppear {
                if !hasAppeared {
                    hasAppeared = true
                    PerformanceTracker.shared.startScreenTrace(name: screenName)
                }
            }
            .onDisappear {
                PerformanceTracker.shared.stopScreenTrace(name: screenName)
                hasAppeared = false
            }
    }
}

extension View {
    func trackScreen(_ name: String) -> some View {
        modifier(ScreenTraceModifier(screenName: name))
    }
}
