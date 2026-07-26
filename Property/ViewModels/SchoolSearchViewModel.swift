import Combine
import Foundation

@MainActor
final class SchoolSearchViewModel: ObservableObject {
    @Published private(set) var results: SchoolPostcodeSearch?
    @Published private(set) var isSearching = false
    @Published private(set) var error: APIError?

    let client: any PropertyResearchAPIClientProtocol
    private var searchTask: Task<SchoolPostcodeSearch, Error>?

    init(client: any PropertyResearchAPIClientProtocol) {
        self.client = client
    }

    @discardableResult
    func search(postcode: String) async -> Bool {
        let postcode = postcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !postcode.isEmpty else {
            error = .validation("Enter a full postcode.")
            return false
        }

        searchTask?.cancel()
        results = nil
        error = nil
        isSearching = true

        let client = client
        let task = Task {
            try await client.searchSchools(postcode: postcode)
        }
        searchTask = task

        do {
            results = try await task.value
            try Task.checkCancellation()
            isSearching = false
            searchTask = nil
            return true
        } catch is CancellationError {
            isSearching = false
            searchTask = nil
            return false
        } catch {
            self.error = error as? APIError ?? .network
            isSearching = false
            searchTask = nil
            return false
        }
    }

    func retry(postcode: String) async {
        _ = await search(postcode: postcode)
    }

    func dismissError() {
        error = nil
    }

    func cancel() {
        searchTask?.cancel()
        searchTask = nil
        isSearching = false
    }
}
