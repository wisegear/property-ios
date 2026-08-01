import Foundation

protocol PropertyResearchAPIClientProtocol: Sendable {
    func searchProperties(postcode: String, page: Int) async throws -> PropertySearchResponse
    func propertyDetails(slug: String) async throws -> PropertyDetail
    func epcCertificate(at url: URL) async throws -> EPCCertificateDetail
    func epcDashboard(nation: EPCNation) async throws -> EPCDashboard
    func searchEPCs(postcode: String, nation: EPCNation, page: Int) async throws -> EPCPostcodeSearch
    func school(at url: URL) async throws -> SchoolDetail
    func searchSchools(postcode: String) async throws -> SchoolPostcodeSearch
    func crimeDashboard() async throws -> CrimeDashboard
    func crimeArea(at url: URL) async throws -> CrimeAreaDetail
    func stressDashboard() async throws -> StressDashboard
    func propertyMarketDashboard() async throws -> PropertyMarketDashboard
    func swapRates() async throws -> SwapRatesDashboard
    func hpiDashboard() async throws -> HPIDashboard
}

final class PropertyResearchAPIClient: PropertyResearchAPIClientProtocol, @unchecked Sendable {
    private let session: URLSession
    private let baseURL: URL
    private let decoder: JSONDecoder

    init(
        session: URLSession = .shared,
        baseURL: URL = APIConfiguration.baseURL
    ) {
        self.session = session
        self.baseURL = baseURL
        self.decoder = JSONDecoder()
    }

    func searchProperties(postcode: String, page: Int = 1) async throws -> PropertySearchResponse {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("properties"),
            resolvingAgainstBaseURL: false
        )

        components?.queryItems = [
            URLQueryItem(name: "postcode", value: postcode),
            URLQueryItem(name: "page", value: String(page))
        ]

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        return try await send(url: url, as: PropertySearchResponse.self)
    }

    func propertyDetails(slug: String) async throws -> PropertyDetail {
        let url = baseURL
            .appendingPathComponent("properties")
            .appendingPathComponent(slug)
        let response = try await send(
            url: url,
            as: PropertyDetailResponse.self,
            notFoundError: .propertyNotFound
        )
        return response.data
    }

    func epcCertificate(at url: URL) async throws -> EPCCertificateDetail {
        let response = try await send(
            url: url,
            as: EPCCertificateDetailResponse.self,
            notFoundError: .epcCertificateNotFound
        )
        return response.data
    }

    func epcDashboard(nation: EPCNation) async throws -> EPCDashboard {
        var components = URLComponents(
            url: baseURL
                .appendingPathComponent("epc")
                .appendingPathComponent("dashboard"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "nation", value: nation.rawValue)
        ]

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        let response = try await send(url: url, as: EPCDashboardResponse.self)
        return response.data
    }

    func searchEPCs(
        postcode: String,
        nation: EPCNation,
        page: Int = 1
    ) async throws -> EPCPostcodeSearch {
        var components = URLComponents(
            url: baseURL
                .appendingPathComponent("epc")
                .appendingPathComponent("search"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "nation", value: nation.rawValue),
            URLQueryItem(name: "postcode", value: postcode),
            URLQueryItem(name: "page", value: String(page))
        ]

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        let response = try await send(url: url, as: EPCPostcodeSearchResponse.self)
        return response.data
    }

    func school(at url: URL) async throws -> SchoolDetail {
        let response = try await send(
            url: url,
            as: SchoolDetailResponse.self,
            notFoundError: .schoolNotFound
        )
        return response.data
    }

    func searchSchools(postcode: String) async throws -> SchoolPostcodeSearch {
        var components = URLComponents(
            url: baseURL.appendingPathComponent("schools"),
            resolvingAgainstBaseURL: false
        )
        components?.queryItems = [
            URLQueryItem(name: "postcode", value: postcode)
        ]

        guard let url = components?.url else {
            throw APIError.invalidURL
        }

        let response = try await send(
            url: url,
            as: SchoolPostcodeSearchResponse.self,
            notFoundError: .schoolPostcodeNotFound
        )
        return response.data
    }

    func crimeDashboard() async throws -> CrimeDashboard {
        let url = baseURL
            .appendingPathComponent("insights")
            .appendingPathComponent("crime")
        let response = try await send(url: url, as: CrimeDashboardResponse.self)
        return response.data
    }

    func crimeArea(at url: URL) async throws -> CrimeAreaDetail {
        let response = try await send(
            url: url,
            as: CrimeAreaResponse.self,
            notFoundError: .crimeAreaNotFound
        )
        return response.data
    }

    func stressDashboard() async throws -> StressDashboard {
        let url = baseURL
            .appendingPathComponent("insights")
            .appendingPathComponent("stress")
        let response = try await send(url: url, as: StressDashboardResponse.self)
        return response.data
    }

    func propertyMarketDashboard() async throws -> PropertyMarketDashboard {
        let url = baseURL
            .appendingPathComponent("property")
            .appendingPathComponent("dashboard")
        let response = try await send(
            url: url,
            as: PropertyMarketDashboardResponse.self
        )
        return response.data
    }

    func swapRates() async throws -> SwapRatesDashboard {
        let url = baseURL
            .appendingPathComponent("insights")
            .appendingPathComponent("swap-rates")
        let response = try await send(url: url, as: SwapRatesDashboardResponse.self)
        return response.data
    }

    func hpiDashboard() async throws -> HPIDashboard {
        let url = baseURL
            .appendingPathComponent("hpi")
            .appendingPathComponent("dashboard")
        let response = try await send(url: url, as: HPIDashboardResponse.self)
        return response.data
    }

    private func send<Response: Decodable>(
        url: URL,
        as type: Response.Type,
        notFoundError: APIError = .propertyNotFound
    ) async throws -> Response {
        var request = URLRequest(url: url)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Accept")

        let data: Data
        let response: URLResponse

        do {
            (data, response) = try await session.data(for: request)
        } catch is CancellationError {
            throw CancellationError()
        } catch let error as URLError {
            if error.code == .cancelled {
                throw CancellationError()
            }

            switch error.code {
            case .notConnectedToInternet, .networkConnectionLost:
                throw APIError.offline
            default:
                throw APIError.network
            }
        }

        guard let httpResponse = response as? HTTPURLResponse else {
            throw APIError.invalidResponse
        }

        switch httpResponse.statusCode {
        case 200..<300:
            do {
                return try decoder.decode(type, from: data)
            } catch {
                throw APIError.invalidData
            }
        case 422:
            let validation = try? decoder.decode(LaravelValidationResponse.self, from: data)
            let message = validation?.errors?["postcode"]?.first
                ?? validation?.message
                ?? "Enter a valid UK postcode."
            throw APIError.validation(message)
        case 404:
            throw notFoundError
        case 429:
            throw APIError.rateLimited
        case 500...599:
            throw APIError.serverUnavailable
        default:
            throw APIError.invalidResponse
        }
    }
}
