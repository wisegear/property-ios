import Combine
import Foundation

@MainActor
final class EPCCertificateViewModel: ObservableObject {
    @Published private(set) var certificate: EPCCertificateDetail?
    @Published private(set) var isLoading = true
    @Published private(set) var error: APIError?

    private let apiURL: URL
    private let client: any PropertyResearchAPIClientProtocol
    private var loadTask: Task<EPCCertificateDetail, Error>?

    init(apiURL: URL, client: any PropertyResearchAPIClientProtocol) {
        self.apiURL = apiURL
        self.client = client
    }

    func load() async {
        guard certificate == nil, loadTask == nil else {
            return
        }

        isLoading = true
        error = nil

        let apiURL = apiURL
        let client = client
        let task = Task {
            try await client.epcCertificate(at: apiURL)
        }
        loadTask = task

        do {
            certificate = try await task.value
            try Task.checkCancellation()
            isLoading = false
            loadTask = nil
        } catch is CancellationError {
            isLoading = false
            loadTask = nil
        } catch {
            self.error = error as? APIError ?? .network
            isLoading = false
            loadTask = nil
        }
    }

    func retry() async {
        certificate = nil
        await load()
    }

    func cancel() {
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
    }
}
