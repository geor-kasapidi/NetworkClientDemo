#if canImport(Combine)

    import Combine
    import Foundation

    public extension Client {
        func call<E: Endpoint>(endpoint: E) -> AnyPublisher<E.Value, Error> {
            let subject: PassthroughSubject<E.Value, Error> = .init()

            let cancellation = self.call(endpoint: endpoint) { result in
                switch result {
                case let .success(value):
                    subject.send(value)
                    subject.send(completion: .finished)
                case let .failure(error):
                    subject.send(completion: .failure(error))
                }
            }

            return subject.handleEvents(receiveCancel: cancellation).eraseToAnyPublisher()
        }
    }

#endif
