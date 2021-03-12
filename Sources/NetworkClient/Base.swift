import Foundation

public typealias Cancellation = () -> Void

public protocol Endpoint: AnyObject {
    associatedtype Value

    func makeRequest(baseURL: URL?, defaultCachePolicy: URLRequest.CachePolicy) throws -> URLRequest

    func parse(response: HTTPURLResponse, data: Data?) throws -> Value
}

public protocol Client: AnyObject {
    func call<E: Endpoint>(endpoint: E, completion: @escaping (Result<E.Value, Error>) -> Void) -> Cancellation
}
