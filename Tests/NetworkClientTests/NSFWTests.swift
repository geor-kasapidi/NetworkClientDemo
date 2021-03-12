import NetworkClient
import XCTest

final class NetworkTests: XCTestCase {
    func testExample() {
        let client = DefaultClient(baseURL: URL(string: "https://jsonplaceholder.typicode.com"))

        struct User: Decodable {
            var id: Int
        }

        let endpoint: APIEndpoint<[User]> = .json(
            request: .init(
                path: "/users",
                method: .GET
            )
        )

        var result: Result<[User], Error> = .success([])

        let group = DispatchGroup()

        group.enter()
        _ = client.call(endpoint: endpoint) { response in
            result = response
            group.leave()
        }

        group.wait()

        switch result {
        case let .success(users):
            XCTAssert(users.map(\.id) == Array(1 ... 10))
        case let .failure(error):
            XCTFail(error.localizedDescription)
        }
    }

    func testRetry() {
        let client = DefaultClient()

        struct Message: Decodable {
            var msg: String
        }

        let endpoint: APIEndpoint<Message> = .json(
            request: .init(
                path: "https://demo9248177.mockable.io/fail",
                method: .GET,
                query: ["qwe": "xyz"],
                headers: ["X-QWE": "123"]
            )
        )

        let group = DispatchGroup()
        group.enter()
        _ = client.retryCall(endpoint: endpoint) { retryData -> DispatchTime? in
            if retryData.attempt < 3 {
                return .now() + 1
            }
            return nil
        } completion: { result in
            switch result {
            case let .success(message):
                print(message)
            case let .failure(error):
                print(error)
            }
            group.leave()
        }

        group.wait()

        // https://demo9248177.mockable.io/fail
    }
}
