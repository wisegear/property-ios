import Combine
import Foundation

@MainActor
final class PropertySearchViewModel: ObservableObject {
    @Published private(set) var postcode = ""
    @Published private(set) var properties: [PropertySearchResult] = []
    @Published private(set) var meta: PaginationMeta?
    @Published private(set) var isSearching = false
    @Published private(set) var isLoadingMore = false
    @Published private(set) var error: APIError?

    let client: any PropertyResearchAPIClientProtocol

    private var searchTask: Task<PropertySearchResponse, Error>?
    private var paginationTask: Task<PropertySearchResponse, Error>?

    init(client: any PropertyResearchAPIClientProtocol) {
        self.client = client
    }

    var hasMorePages: Bool {
        meta?.hasNextPage == true
    }

    @discardableResult
    func search(postcode rawPostcode: String) async -> Bool {
        cancelRequests()

        let trimmedPostcode = rawPostcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmedPostcode.isEmpty else {
            error = .validation("Enter a UK postcode.")
            return false
        }

        guard Self.isValidUKPostcode(trimmedPostcode) else {
            error = .validation("Enter a valid UK postcode, for example SW7 5PH.")
            return false
        }

        postcode = trimmedPostcode
        properties = []
        meta = nil
        error = nil
        isSearching = true

        let client = client
        let task = Task {
            try await client.searchProperties(postcode: trimmedPostcode, page: 1)
        }
        searchTask = task

        do {
            let response = try await task.value
            try Task.checkCancellation()
            postcode = response.postcode
            properties = PropertySearchResult.groupedNewest(response.results)
            meta = response.meta
            isSearching = false
            searchTask = nil
            return true
        } catch is CancellationError {
            isSearching = false
            searchTask = nil
            return false
        } catch {
            self.error = Self.apiError(from: error)
            isSearching = false
            searchTask = nil
            return false
        }
    }

    func loadNextPageIfNeeded(currentProperty: PropertySearchResult) async {
        guard currentProperty.id == properties.last?.id,
              hasMorePages,
              !isLoadingMore,
              let currentPage = meta?.currentPage else {
            return
        }

        isLoadingMore = true
        error = nil

        let postcode = postcode
        let nextPage = currentPage + 1
        let client = client
        let task = Task {
            try await client.searchProperties(postcode: postcode, page: nextPage)
        }
        paginationTask = task

        do {
            let response = try await task.value
            try Task.checkCancellation()
            properties = PropertySearchResult.groupedNewest(properties + response.results)
            meta = response.meta
            isLoadingMore = false
            paginationTask = nil
        } catch is CancellationError {
            isLoadingMore = false
            paginationTask = nil
        } catch {
            self.error = Self.apiError(from: error)
            isLoadingMore = false
            paginationTask = nil
        }
    }

    func retry() async -> Bool {
        await search(postcode: postcode)
    }

    func dismissError() {
        error = nil
    }

    func cancelRequests() {
        searchTask?.cancel()
        paginationTask?.cancel()
        searchTask = nil
        paginationTask = nil
        isSearching = false
        isLoadingMore = false
    }

    static func isValidUKPostcode(_ postcode: String) -> Bool {
        let pattern = #"^[A-Za-z]{1,2}\d[A-Za-z\d]?\s?\d[A-Za-z]{2}$"#
        return postcode.range(of: pattern, options: .regularExpression) != nil
    }

    private static func apiError(from error: Error) -> APIError {
        error as? APIError ?? .network
    }
}
