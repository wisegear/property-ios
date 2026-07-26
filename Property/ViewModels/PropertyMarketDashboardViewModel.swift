import Combine
import Foundation

@MainActor
final class PropertyMarketDashboardViewModel: ObservableObject {
    @Published private(set) var dashboard: PropertyMarketDashboard?
    @Published private(set) var isLoading = true
    @Published private(set) var error: APIError?

    private let client: any PropertyResearchAPIClientProtocol
    private var loadTask: Task<PropertyMarketDashboard, Error>?

    init(client: any PropertyResearchAPIClientProtocol) {
        self.client = client
    }

    func load() async {
        guard dashboard == nil, loadTask == nil else { return }
        await request()
    }

    func refresh() async {
        guard loadTask == nil else { return }
        await request()
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

    private func request() async {
        isLoading = true
        error = nil

        let client = client
        let task = Task { try await client.propertyMarketDashboard() }
        loadTask = task

        do {
            let result = try await task.value
            try Task.checkCancellation()
            dashboard = result
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
}

