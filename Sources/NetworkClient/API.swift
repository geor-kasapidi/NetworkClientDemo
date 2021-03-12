import Foundation

public struct APIRequest {
    public enum HTTPMethod: String {
        case GET, POST, PUT, DELETE // etc.
    }

    public var path: String
    public var method: HTTPMethod = .GET
    public var query: [String: String] = [:]
    public var headers: [String: String] = [:]
    public var body: Data?
    public var timeoutInterval: TimeInterval = 60

    public init(
        path: String,
        method: APIRequest.HTTPMethod = .GET,
        query: [String: String] = [:],
        headers: [String: String] = [:],
        body: Data? = nil,
        timeoutInterval: TimeInterval = 60
    ) {
        self.path = path
        self.method = method
        self.query = query
        self.headers = headers
        self.body = body
        self.timeoutInterval = timeoutInterval
    }
}

public final class APIEndpoint<Value>: Endpoint {
    private let request: APIRequest
    private let value: (HTTPURLResponse, Data?) throws -> Value

    public init(
        request: APIRequest,
        value: @escaping (HTTPURLResponse, Data?) throws -> Value
    ) {
        self.request = request
        self.value = value
    }

    public func makeRequest(baseURL: URL?, defaultCachePolicy: URLRequest.CachePolicy) throws -> URLRequest {
        try self.request.makeRequest(baseURL: baseURL, defaultCachePolicy: defaultCachePolicy)
    }

    public func parse(response: HTTPURLResponse, data: Data?) throws -> Value {
        guard response.statusCode < 400 else {
            throw NetworkError.errorStatusCode(response.statusCode)
        }
        return try self.value(response, data)
    }
}

public extension APIEndpoint {
    static func json<T: Decodable>(request: APIRequest, decoder: JSONDecoder = .init()) -> APIEndpoint<T> {
        .init(request: request) { (_, data) -> T in
            guard let data = data else {
                throw NetworkError.noData
            }
            return try decoder.decode(T.self, from: data)
        }
    }
}

internal extension APIRequest {
    func makeRequest(
        baseURL: URL?,
        defaultCachePolicy: URLRequest.CachePolicy
    ) throws -> URLRequest {
        guard var urlComponents = URLComponents(string: self.path) else {
            throw NetworkError.failedToCreateURLComponents(path: self.path)
        }

        if urlComponents.scheme == nil {
            urlComponents.scheme = baseURL?.scheme
        }

        if urlComponents.host == nil {
            urlComponents.host = baseURL?.host
        }

        urlComponents.queryItems = self.query.map {
            URLQueryItem(name: $0.key, value: $0.value)
        }

        guard let url = urlComponents.url else {
            throw NetworkError.failedToCreateURL(components: urlComponents)
        }

        var request = URLRequest(
            url: url,
            cachePolicy: defaultCachePolicy,
            timeoutInterval: self.timeoutInterval
        )

        request.httpMethod = self.method.rawValue

        self.headers.forEach {
            request.setValue($0.value, forHTTPHeaderField: $0.key)
        }

        request.httpBody = self.body

        return request
    }
}
