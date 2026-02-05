//
//  MockURLProtocol.swift
//  SlangTranslatorTests
//
//  Custom URLProtocol for mocking network requests in tests.
//

import Foundation

class MockURLProtocol: URLProtocol {
    static var requestHandler: ((URLRequest) throws -> (HTTPURLResponse, Data?))?
    static var requestDelay: TimeInterval = 0

    override class func canInit(with request: URLRequest) -> Bool {
        return true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        return request
    }

    override func startLoading() {
        // If no handler is set, return a default error response
        guard let handler = MockURLProtocol.requestHandler else {
            let error = NSError(
                domain: "MockURLProtocol",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "No mock handler configured"]
            )
            client?.urlProtocol(self, didFailWithError: error)
            return
        }

        do {
            if MockURLProtocol.requestDelay > 0 {
                Thread.sleep(forTimeInterval: MockURLProtocol.requestDelay)
            }

            let (response, data) = try handler(request)
            client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
            if let data = data {
                client?.urlProtocol(self, didLoad: data)
            }
            client?.urlProtocolDidFinishLoading(self)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
        }
    }

    override func stopLoading() {}

    // MARK: - Helper Methods

    static func reset() {
        requestHandler = nil
        requestDelay = 0
    }

    static func mockSuccess(statusCode: Int = 200, data: Data? = nil) {
        requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }
    }

    static func mockError(statusCode: Int, data: Data? = nil) {
        requestHandler = { request in
            let response = HTTPURLResponse(
                url: request.url!,
                statusCode: statusCode,
                httpVersion: nil,
                headerFields: nil
            )!
            return (response, data)
        }
    }

    static func mockNetworkError(_ error: URLError) {
        requestHandler = { _ in
            throw error
        }
    }

    /// Mock that fails N times then succeeds
    static func mockFailThenSucceed(failCount: Int, statusCode: Int = 500, successData: Data? = nil) {
        var attempts = 0
        requestHandler = { request in
            attempts += 1
            if attempts <= failCount {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: statusCode,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, nil)
            } else {
                let response = HTTPURLResponse(
                    url: request.url!,
                    statusCode: 200,
                    httpVersion: nil,
                    headerFields: nil
                )!
                return (response, successData)
            }
        }
    }
}
