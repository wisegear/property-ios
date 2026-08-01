import Combine

@MainActor
final class HPIDashboardViewModel: ObservableObject {
    @Published private(set) var dashboard: HPIDashboard?
    @Published private(set) var error: APIError?

    private let client: any PropertyResearchAPIClientProtocol
    private var loadTask: Task<HPIDashboard, Error>?

    init(client: any PropertyResearchAPIClientProtocol) {
        self.client = client
    }

    func load() async {
        guard dashboard == nil, loadTask == nil else { return }
        error = nil
        let client = client
        let task = Task { try await client.hpiDashboard() }
        loadTask = task

        do {
            dashboard = try await task.value
            try Task.checkCancellation()
            loadTask = nil
        } catch is CancellationError {
            loadTask = nil
        } catch {
            self.error = error as? APIError ?? .network
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
    }
}
