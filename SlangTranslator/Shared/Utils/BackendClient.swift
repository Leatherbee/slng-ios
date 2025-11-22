import Foundation

final class BackendClient {
    let baseURL: URL
    let session: URLSession
    let bearerToken: String?

    init(baseURL: URL, bearerToken: String? = nil, session: URLSession? = nil) {
        let cfg = URLSessionConfiguration.ephemeral
        cfg.timeoutIntervalForRequest = 60
        cfg.timeoutIntervalForResource = 90
        self.session = session ?? URLSession(configuration: cfg)
        self.baseURL = baseURL
        self.bearerToken = bearerToken
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
}
