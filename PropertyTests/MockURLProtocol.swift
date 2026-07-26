import Foundation

final class MockURLProtocol: URLProtocol, @unchecked Sendable {
    typealias Handler = @Sendable (URLRequest) throws -> (HTTPURLResponse, Data)

    nonisolated(unsafe) static var handler: Handler?
    nonisolated(unsafe) static var responseDelay: TimeInterval = 0
    nonisolated(unsafe) static var requestWasCancelled = false

    private var workItem: DispatchWorkItem?

    override class func canInit(with request: URLRequest) -> Bool {
        true
    }

    override class func canonicalRequest(for request: URLRequest) -> URLRequest {
        request
    }

    override func startLoading() {
        guard let handler = Self.handler else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        let workItem = DispatchWorkItem { [weak self] in
            guard let self else {
                return
            }

            do {
                let (response, data) = try handler(request)
                client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
                client?.urlProtocol(self, didLoad: data)
                client?.urlProtocolDidFinishLoading(self)
            } catch {
                client?.urlProtocol(self, didFailWithError: error)
            }
        }

        self.workItem = workItem
        DispatchQueue.global().asyncAfter(
            deadline: .now() + Self.responseDelay,
            execute: workItem
        )
    }

    override func stopLoading() {
        Self.requestWasCancelled = true
        workItem?.cancel()
        workItem = nil
    }

    static func reset() {
        handler = nil
        responseDelay = 0
        requestWasCancelled = false
    }
}
