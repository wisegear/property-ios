import Combine
import Foundation

@MainActor
final class PropertyDetailViewModel: ObservableObject {
    @Published private(set) var property: PropertyDetail?
    @Published private(set) var isLoading = true
    @Published private(set) var error: APIError?

    private let slug: String
    let client: any PropertyResearchAPIClientProtocol
    private var loadTask: Task<PropertyDetail, Error>?

    init(slug: String, client: any PropertyResearchAPIClientProtocol) {
        self.slug = slug
        self.client = client
    }

    func load() async {
        guard property == nil, loadTask == nil else {
            return
        }

        loadTask?.cancel()
        isLoading = true
        error = nil

        let slug = slug
        let client = client
        let task = Task {
            try await client.propertyDetails(slug: slug)
        }
        loadTask = task

        do {
            property = try await task.value
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
        property = nil
        await load()
    }

    func cancel() {
        loadTask?.cancel()
        loadTask = nil
        isLoading = false
    }
}
