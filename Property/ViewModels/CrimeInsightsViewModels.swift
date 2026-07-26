import Combine
import Foundation

@MainActor
final class CrimeDashboardViewModel: ObservableObject {
    @Published private(set) var dashboard: CrimeDashboard?
    @Published private(set) var isLoading = true
    @Published private(set) var error: APIError?

    let client: any PropertyResearchAPIClientProtocol
    private var loadTask: Task<CrimeDashboard, Error>?

    init(client: any PropertyResearchAPIClientProtocol) {
        self.client = client
    }

    func load() async {
        guard dashboard == nil, loadTask == nil else { return }

        isLoading = true
        error = nil
        let client = client
        let task = Task { try await client.crimeDashboard() }
        loadTask = task

        do {
            dashboard = try await task.value
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
        dashboard = nil
        await load()
    }

    func cancel() {
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
    }
}

@MainActor
final class CrimeAreaViewModel: ObservableObject {
    @Published private(set) var area: CrimeAreaDetail?
    @Published private(set) var isLoading = true
    @Published private(set) var error: APIError?

    private let apiURL: URL
    private let client: any PropertyResearchAPIClientProtocol
    private var loadTask: Task<CrimeAreaDetail, Error>?

    init(apiURL: URL, client: any PropertyResearchAPIClientProtocol) {
        self.apiURL = apiURL
        self.client = client
    }

    func load() async {
        guard area == nil, loadTask == nil else { return }

        isLoading = true
        error = nil
        let apiURL = apiURL
        let client = client
        let task = Task { try await client.crimeArea(at: apiURL) }
        loadTask = task

        do {
            area = try await task.value
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
        area = nil
        await load()
    }

    func cancel() {
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
    }
}
