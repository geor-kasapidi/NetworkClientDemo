import Foundation

public enum NetworkError: Swift.Error {
    case failedToCreateURLComponents(path: String)
    case failedToCreateURL(components: URLComponents)
    case noData
    case noResponse
    case errorStatusCode(Int)
}
