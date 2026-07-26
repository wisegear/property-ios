import Combine
import Foundation

@MainActor
final class EPCDashboardViewModel: ObservableObject {
    @Published private(set) var dashboard: EPCDashboard?
    @Published private(set) var searchResults: [EPCSearchResult] = []
    @Published private(set) var searchPostcode: String?
    @Published private(set) var pagination: PaginationMeta?
    @Published private(set) var isLoadingDashboard = false
    @Published private(set) var isSearching = false
    @Published private(set) var error: APIError?

    let client: any PropertyResearchAPIClientProtocol
    private var dashboardTask: Task<EPCDashboard, Error>?
    private var searchTask: Task<EPCPostcodeSearch, Error>?

    init(client: any PropertyResearchAPIClientProtocol) {
        self.client = client
    }

    func loadDashboard(nation: EPCNation) async {
        if dashboard?.nation == nation.rawValue {
            return
        }

        dashboardTask?.cancel()
        searchTask?.cancel()
        searchResults = []
        searchPostcode = nil
        pagination = nil
        error = nil
        isLoadingDashboard = true

        let client = client
        let task = Task { try await client.epcDashboard(nation: nation) }
        dashboardTask = task

        do {
            dashboard = try await task.value
            try Task.checkCancellation()
            isLoadingDashboard = false
            dashboardTask = nil
        } catch is CancellationError {
            isLoadingDashboard = false
            dashboardTask = nil
        } catch {
            self.error = error as? APIError ?? .network
            isLoadingDashboard = false
            dashboardTask = nil
        }
    }

    func search(postcode: String, nation: EPCNation, page: Int = 1) async {
        let postcode = postcode.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !postcode.isEmpty else {
            error = .validation("Enter a full postcode.")
            return
        }

        searchTask?.cancel()
        error = nil
        isSearching = true

        if page == 1 {
            searchResults = []
            searchPostcode = nil
            pagination = nil
        }

        let client = client
        let task = Task {
            try await client.searchEPCs(
                postcode: postcode,
                nation: nation,
                page: page
            )
        }
        searchTask = task

        do {
            let response = try await task.value
            try Task.checkCancellation()
            searchPostcode = response.postcode
            searchResults = page == 1
                ? response.results
                : searchResults + response.results.filter { result in
                    !searchResults.contains(where: { $0.id == result.id })
                }
            pagination = response.meta
            isSearching = false
            searchTask = nil
        } catch is CancellationError {
            isSearching = false
            searchTask = nil
        } catch {
            self.error = error as? APIError ?? .network
            isSearching = false
            searchTask = nil
        }
    }

    func loadNextPage(nation: EPCNation) async {
        guard let postcode = searchPostcode,
              let pagination,
              pagination.hasNextPage,
              !isSearching else {
            return
        }

        await search(
            postcode: postcode,
            nation: nation,
            page: pagination.currentPage + 1
        )
    }

    func dismissError() {
        error = nil
    }

    func cancel() {
        dashboardTask?.cancel()
        searchTask?.cancel()
        dashboardTask = nil
        searchTask = nil
        isLoadingDashboard = false
        isSearching = false
    }
}
