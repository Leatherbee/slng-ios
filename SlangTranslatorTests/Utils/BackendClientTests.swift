//
//  BackendClientTests.swift
//  SlangTranslatorTests
//
//  Tests for BackendClient including retry logic.
//

import Testing
import Foundation
@testable import SLNG

struct BackendClientTests {

    // MARK: - Setup

    private func createMockSession() -> URLSession {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [MockURLProtocol.self]
        return URLSession(configuration: config)
    }

    private func createClient(retryConfig: RetryConfiguration = .none) -> BackendClient {
        let baseURL = URL(string: "https://api.test.com")!
        return BackendClient(
            baseURL: baseURL,
            session: createMockSession(),
            retryConfig: retryConfig
        )
    }

    // MARK: - Basic Request Tests

    @Test func makeRequest_createsCorrectURL() async throws {
        let client = createClient()
        let request = client.makeRequest(path: "api/v1/test", method: "GET")

        #expect(request.url?.absoluteString == "https://api.test.com/api/v1/test")
        #expect(request.httpMethod == "GET")
    }

    @Test func makeRequest_withBearerToken_addsAuthorizationHeader() async throws {
        let baseURL = URL(string: "https://api.test.com")!
        let client = BackendClient(
            baseURL: baseURL,
            bearerToken: "test-token",
            session: createMockSession(),
            retryConfig: .none
        )

        let request = client.makeRequest(path: "api/v1/test", method: "POST")

        #expect(request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        #expect(request.httpMethod == "POST")
    }

    // MARK: - Success Response Tests

    @Test func performRequest_successfulResponse_returnsData() async throws {
        let client = createClient()
        let expectedData = "{\"message\":\"success\"}".data(using: .utf8)!

        MockURLProtocol.mockSuccess(statusCode: 200, data: expectedData)

        let request = client.makeRequest(path: "api/v1/test")
        let (data, response) = try await client.performRequest(request)

        let httpResponse = response as? HTTPURLResponse
        #expect(httpResponse?.statusCode == 200)
        #expect(data == expectedData)

        MockURLProtocol.reset()
    }

    @Test func performRequest_201Response_returnsData() async throws {
        let client = createClient()
        let expectedData = "{\"created\":true}".data(using: .utf8)!

        MockURLProtocol.mockSuccess(statusCode: 201, data: expectedData)

        let request = client.makeRequest(path: "api/v1/test", method: "POST")
        let (data, response) = try await client.performRequest(request)

        let httpResponse = response as? HTTPURLResponse
        #expect(httpResponse?.statusCode == 201)
        #expect(data == expectedData)

        MockURLProtocol.reset()
    }

    // MARK: - Client Error Tests (4xx - No Retry)

    @Test func performRequest_400Error_throwsClientErrorWithoutRetry() async throws {
        let client = createClient(retryConfig: .default)
        let errorBody = "{\"error\":\"Bad Request\"}".data(using: .utf8)

        MockURLProtocol.mockError(statusCode: 400, data: errorBody)

        let request = client.makeRequest(path: "api/v1/test")

        do {
            _ = try await client.performRequest(request)
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as NetworkError {
            if case .clientError(let statusCode, let body) = error {
                #expect(statusCode == 400)
                #expect(body?.contains("Bad Request") == true)
            } else {
                #expect(Bool(false), "Expected clientError")
            }
        }

        MockURLProtocol.reset()
    }

    @Test func performRequest_404Error_throwsClientError() async throws {
        let client = createClient(retryConfig: .default)

        MockURLProtocol.mockError(statusCode: 404)

        let request = client.makeRequest(path: "api/v1/notfound")

        do {
            _ = try await client.performRequest(request)
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as NetworkError {
            if case .clientError(let statusCode, _) = error {
                #expect(statusCode == 404)
            } else {
                #expect(Bool(false), "Expected clientError")
            }
        }

        MockURLProtocol.reset()
    }

    // MARK: - Server Error Tests (5xx - With Retry)

    @Test func performRequest_500Error_retriesAndFails() async throws {
        // Use no retry for faster test
        let client = createClient(retryConfig: .none)

        MockURLProtocol.mockError(statusCode: 500)

        let request = client.makeRequest(path: "api/v1/test")

        do {
            _ = try await client.performRequest(request)
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as NetworkError {
            if case .serverError(let statusCode, _) = error {
                #expect(statusCode == 500)
            } else {
                #expect(Bool(false), "Expected serverError, got \(error)")
            }
        }

        MockURLProtocol.reset()
    }

    @Test func performRequest_500ThenSuccess_retriesAndSucceeds() async throws {
        let retryConfig = RetryConfiguration(
            maxRetries: 3,
            baseDelay: 0.1, // Short delay for test
            maxDelay: 1.0,
            retryableStatusCodes: [500, 502, 503, 504]
        )
        let client = createClient(retryConfig: retryConfig)
        let successData = "{\"success\":true}".data(using: .utf8)!

        // Fail twice, then succeed
        MockURLProtocol.mockFailThenSucceed(failCount: 2, statusCode: 500, successData: successData)

        let request = client.makeRequest(path: "api/v1/test")
        let (data, response) = try await client.performRequest(request)

        let httpResponse = response as? HTTPURLResponse
        #expect(httpResponse?.statusCode == 200)
        #expect(data == successData)

        MockURLProtocol.reset()
    }

    // MARK: - Rate Limiting Tests (429)

    @Test func performRequest_429Error_retriesWithLongerDelay() async throws {
        let retryConfig = RetryConfiguration(
            maxRetries: 2,
            baseDelay: 0.1,
            maxDelay: 1.0,
            retryableStatusCodes: [429, 500]
        )
        let client = createClient(retryConfig: retryConfig)
        let successData = "{\"ok\":true}".data(using: .utf8)!

        MockURLProtocol.mockFailThenSucceed(failCount: 1, statusCode: 429, successData: successData)

        let request = client.makeRequest(path: "api/v1/test")
        let (data, _) = try await client.performRequest(request)

        #expect(data == successData)

        MockURLProtocol.reset()
    }

    // MARK: - Network Error Tests

    @Test func performRequest_noInternetConnection_throwsNetworkError() async throws {
        let client = createClient(retryConfig: .none)

        MockURLProtocol.mockNetworkError(URLError(.notConnectedToInternet))

        let request = client.makeRequest(path: "api/v1/test")

        do {
            _ = try await client.performRequest(request)
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as NetworkError {
            if case .noInternetConnection = error {
                #expect(true)
            } else {
                #expect(Bool(false), "Expected noInternetConnection, got \(error)")
            }
        }

        MockURLProtocol.reset()
    }

    @Test func performRequest_timeout_throwsTimeoutError() async throws {
        let client = createClient(retryConfig: .none)

        MockURLProtocol.mockNetworkError(URLError(.timedOut))

        let request = client.makeRequest(path: "api/v1/test")

        do {
            _ = try await client.performRequest(request)
            #expect(Bool(false), "Should have thrown an error")
        } catch let error as NetworkError {
            if case .timeout = error {
                #expect(true)
            } else {
                #expect(Bool(false), "Expected timeout, got \(error)")
            }
        }

        MockURLProtocol.reset()
    }

    // MARK: - Retry Configuration Tests

    @Test func retryConfiguration_default_hasCorrectValues() async throws {
        let config = RetryConfiguration.default

        #expect(config.maxRetries == 3)
        #expect(config.baseDelay == 1.0)
        #expect(config.maxDelay == 10.0)
        #expect(config.retryableStatusCodes.contains(500))
        #expect(config.retryableStatusCodes.contains(429))
    }

    @Test func retryConfiguration_aggressive_hasMoreRetries() async throws {
        let config = RetryConfiguration.aggressive

        #expect(config.maxRetries == 5)
        #expect(config.baseDelay == 0.5)
    }

    @Test func retryConfiguration_none_hasZeroRetries() async throws {
        let config = RetryConfiguration.none

        #expect(config.maxRetries == 0)
    }

    // MARK: - NetworkError Tests

    @Test func networkError_errorDescriptions_areCorrect() async throws {
        #expect(NetworkError.noInternetConnection.errorDescription?.contains("internet") == true)
        #expect(NetworkError.timeout.errorDescription?.contains("timed out") == true)
        #expect(NetworkError.serverError(statusCode: 500, body: nil).errorDescription?.contains("500") == true)
        #expect(NetworkError.clientError(statusCode: 404, body: nil).errorDescription?.contains("404") == true)
        #expect(NetworkError.invalidResponse.errorDescription?.contains("Invalid") == true)
    }

    @Test func networkError_isRetryable_correctlyIdentifiesRetryableErrors() async throws {
        #expect(NetworkError.noInternetConnection.isRetryable == true)
        #expect(NetworkError.timeout.isRetryable == true)
        #expect(NetworkError.serverError(statusCode: 500, body: nil).isRetryable == true)
        #expect(NetworkError.clientError(statusCode: 400, body: nil).isRetryable == false)
        #expect(NetworkError.invalidResponse.isRetryable == false)
    }
}
