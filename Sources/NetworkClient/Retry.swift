import Foundation

public typealias RetryData = (attempt: Int, error: Error)
public typealias RetryCondition = (RetryData) -> DispatchTime?

private final class AsyncRetry {
    private let client: Client
    private let queue = DispatchQueue(label: "AsyncRetry.queue")

    private var cancellation: Cancellation?

    init(client: Client) {
        self.client = client
    }

    func cancel() {
        self.queue.async {
            self.cancellation?()
            self.cancellation = nil
        }
    }

    func call<E: Endpoint>(
        endpoint: E,
        retryCondition: @escaping RetryCondition,
        completion: @escaping (Result<E.Value, Error>) -> Void
    ) {
        self.queue.async {
            self.call(
                endpoint: endpoint,
                attempt: 0,
                retryCondition: retryCondition,
                completion: completion
            )
        }
    }

    private func call<E: Endpoint>(
        endpoint: E,
        attempt: Int,
        retryCondition: @escaping RetryCondition,
        completion: @escaping (Result<E.Value, Error>) -> Void
    ) {
        self.cancellation = self.client.call(endpoint: endpoint) { result in
            if case let .failure(error) = result, let delay = retryCondition((attempt, error)) {
                self.queue.asyncAfter(deadline: delay) {
                    if self.cancellation == nil {
                        completion(result)
                    } else {
                        self.call(
                            endpoint: endpoint,
                            attempt: attempt + 1,
                            retryCondition: retryCondition,
                            completion: completion
                        )
                    }
                }
            } else {
                completion(result)
            }
        }
    }
}

public extension Client {
    func retryCall<E: Endpoint>(
        endpoint: E,
        condition: @escaping RetryCondition,
        completion: @escaping (Result<E.Value, Error>) -> Void
    ) -> Cancellation {
        let retry = AsyncRetry(client: self)
        retry.call(endpoint: endpoint, retryCondition: condition, completion: completion)
        return retry.cancel
    }
}
