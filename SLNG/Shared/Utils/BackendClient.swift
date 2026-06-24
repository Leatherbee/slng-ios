import Foundation

// MARK: - Retry Configuration

struct RetryConfiguration {
    let maxRetries: Int
    let baseDelay: TimeInterval
    let maxDelay: TimeInterval
    let retryableStatusCodes: Set<Int>

    static let `default` = RetryConfiguration(
        maxRetries: 3,
        baseDelay: 1.0,
        maxDelay: 10.0,
        retryableStatusCodes: [408, 429, 500, 502, 503, 504]
    )

    static let aggressive = RetryConfiguration(
        maxRetries: 5,
        baseDelay: 0.5,
        maxDelay: 15.0,
        retryableStatusCodes: [408, 429, 500, 502, 503, 504]
    )

    static let none = RetryConfiguration(
        maxRetries: 0,
        baseDelay: 0,
        maxDelay: 0,
        retryableStatusCodes: []
    )
}

// MARK: - Network Errors

enum NetworkError: Error, LocalizedError {
    case noInternetConnection
    case timeout
    case serverError(statusCode: Int, body: String?)
    case clientError(statusCode: Int, body: String?)
    case maxRetriesExceeded(lastError: Error)
    case invalidResponse

    var errorDescription: String? {
        switch self {
        case .noInternetConnection:
            return "No internet connection. Please check your network."
        case .timeout:
            return "Request timed out. Please try again."
        case .serverError(let code, _):
            return "Server error (\(code)). Please try again later."
        case .clientError(let code, _):
            return "Request failed (\(code))."
        case .maxRetriesExceeded:
            return "Request failed after multiple attempts. Please try again later."
        case .invalidResponse:
            return "Invalid response from server."
        }
    }

    var isRetryable: Bool {
        switch self {
        case .noInternetConnection, .timeout, .serverError, .maxRetriesExceeded:
            return true
        case .clientError, .invalidResponse:
            return false
        }
    }
}

// MARK: - Backend Client

final class BackendClient {
    let baseURL: URL
    let session: URLSession
    let bearerToken: String?
    let retryConfig: RetryConfiguration

    init(
        baseURL: URL,
        bearerToken: String? = nil,
        session: URLSession? = nil,
        retryConfig: RetryConfiguration = .default
    ) {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 60
        cfg.timeoutIntervalForResource = 90
        self.session = session ?? URLSession(configuration: cfg)
        self.baseURL = baseURL
        self.bearerToken = bearerToken
        self.retryConfig = retryConfig
    }

    func makeRequest(path: String, method: String = "GET") -> URLRequest {
        let url = baseURL.appendingPathComponent(path)
        var req = URLRequest(url: url)
        req.httpMethod = method
        if let bearerToken {
            req.setValue("Bearer \(bearerToken)", forHTTPHeaderField: "Authorization")
        }
        return req
    }

    // MARK: - Request with Retry

    /// Performs a network request with automatic retry on failure
    func performRequest(_ request: URLRequest) async throws -> (Data, URLResponse) {
        var lastError: Error = NetworkError.invalidResponse

        for attempt in 0...retryConfig.maxRetries {
            do {
                let (data, response) = try await session.data(for: request)

                // Check if response is HTTP response
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw NetworkError.invalidResponse
                }

                // Success - return data
                if (200..<300).contains(httpResponse.statusCode) {
                    return (data, response)
                }

                // Client error (4xx) - don't retry
                if (400..<500).contains(httpResponse.statusCode) && httpResponse.statusCode != 408 && httpResponse.statusCode != 429 {
                    let body = String(data: data, encoding: .utf8)
                    throw NetworkError.clientError(statusCode: httpResponse.statusCode, body: body)
                }

                // Server error or retryable status - might retry
                if retryConfig.retryableStatusCodes.contains(httpResponse.statusCode) {
                    let body = String(data: data, encoding: .utf8)
                    lastError = NetworkError.serverError(statusCode: httpResponse.statusCode, body: body)

                    // Don't retry if this was the last attempt
                    if attempt < retryConfig.maxRetries {
                        let delay = calculateDelay(for: attempt, statusCode: httpResponse.statusCode)
                        logInfo("Retry attempt \(attempt + 1)/\(retryConfig.maxRetries) after \(String(format: "%.1f", delay))s (status: \(httpResponse.statusCode))", category: .network)
                        try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                        continue
                    }
                } else {
                    // Non-retryable server error
                    let body = String(data: data, encoding: .utf8)
                    throw NetworkError.serverError(statusCode: httpResponse.statusCode, body: body)
                }

            } catch let error as NetworkError {
                // Re-throw non-retryable network errors
                if !error.isRetryable {
                    throw error
                }
                lastError = error

            } catch let urlError as URLError {
                // Handle URL errors
                lastError = mapURLError(urlError)

                // Only retry on network-related errors
                if isRetryableURLError(urlError) && attempt < retryConfig.maxRetries {
                    let delay = calculateDelay(for: attempt)
                    logInfo("Retry attempt \(attempt + 1)/\(retryConfig.maxRetries) after \(String(format: "%.1f", delay))s (error: \(urlError.code.rawValue))", category: .network)
                    try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000_000))
                    continue
                }

            } catch {
                lastError = error
            }
        }

        // All retries exhausted
        throw NetworkError.maxRetriesExceeded(lastError: lastError)
    }

    // MARK: - Helper Methods

    private func calculateDelay(for attempt: Int, statusCode: Int? = nil) -> TimeInterval {
        // Special handling for rate limiting (429) - use longer delay
        if statusCode == 429 {
            return min(retryConfig.maxDelay, retryConfig.baseDelay * pow(2.0, Double(attempt)) * 2)
        }

        // Exponential backoff with jitter
        let exponentialDelay = retryConfig.baseDelay * pow(2.0, Double(attempt))
        let jitter = Double.random(in: 0...0.3) * exponentialDelay
        return min(retryConfig.maxDelay, exponentialDelay + jitter)
    }

    private func isRetryableURLError(_ error: URLError) -> Bool {
        let retryableCodes: [URLError.Code] = [
            .timedOut,
            .cannotFindHost,
            .cannotConnectToHost,
            .networkConnectionLost,
            .dnsLookupFailed,
            .notConnectedToInternet,
            .secureConnectionFailed
        ]
        return retryableCodes.contains(error.code)
    }

    private func mapURLError(_ error: URLError) -> NetworkError {
        switch error.code {
        case .notConnectedToInternet, .networkConnectionLost:
            return .noInternetConnection
        case .timedOut:
            return .timeout
        default:
            return .serverError(statusCode: error.code.rawValue, body: error.localizedDescription)
        }
    }
}
