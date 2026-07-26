import Foundation

enum EPCNation: String, CaseIterable, Identifiable {
    case englandWales = "england-wales"
    case scotland

    var id: String { rawValue }

    var label: String {
        switch self {
        case .englandWales: return "England & Wales"
        case .scotland: return "Scotland"
        }
    }
}

struct EPCDashboardResponse: Decodable, Equatable {
    let data: EPCDashboard
}

struct EPCDashboard: Decodable, Equatable {
    let nation: String
    let nationLabel: String
    let availableFrom: String?
    let statistics: EPCDashboardStatistics
    let certificatesByYear: [EPCCertificateYear]
    let currentRatingsByYear: [EPCRatingYear]
    let potentialRatingsByYear: [EPCRatingYear]
    let ratingDistribution: [EPCRatingDistribution]
    let tenureByYear: [EPCTenureYear]
    let websiteURL: String?

    enum CodingKeys: String, CodingKey {
        case nation
        case nationLabel = "nation_label"
        case availableFrom = "available_from"
        case statistics
        case certificatesByYear = "certificates_by_year"
        case currentRatingsByYear = "current_ratings_by_year"
        case potentialRatingsByYear = "potential_ratings_by_year"
        case ratingDistribution = "rating_distribution"
        case tenureByYear = "tenure_by_year"
        case websiteURL = "website_url"
    }
}

struct EPCDashboardStatistics: Decodable, Equatable {
    let totalCertificates: Int
    let latestLodgementDate: String?
    let last30Days: Int
    let last12Months: Int

    enum CodingKeys: String, CodingKey {
        case totalCertificates = "total_certificates"
        case latestLodgementDate = "latest_lodgement_date"
        case last30Days = "last_30_days"
        case last12Months = "last_12_months"
    }
}

struct EPCCertificateYear: Decodable, Equatable, Identifiable {
    let year: Int
    let count: Int
    var id: Int { year }
}

struct EPCRatingYear: Decodable, Equatable, Identifiable {
    let year: Int
    let rating: String?
    let count: Int
    let percentage: Double
    var id: String { "\(year)-\(rating ?? "unknown")" }
}

struct EPCRatingDistribution: Decodable, Equatable, Identifiable {
    let rating: String?
    let count: Int
    let percentage: Double
    var id: String { rating ?? "Unknown" }
}

struct EPCTenureYear: Decodable, Equatable, Identifiable {
    let year: Int
    let tenure: String?
    let count: Int
    let percentage: Double
    var id: String { "\(year)-\(tenure ?? "unknown")" }
}

struct EPCPostcodeSearchResponse: Decodable, Equatable {
    let data: EPCPostcodeSearch
}

struct EPCPostcodeSearch: Decodable, Equatable {
    let nation: String
    let nationLabel: String
    let postcode: String
    let results: [EPCSearchResult]
    let meta: PaginationMeta

    enum CodingKeys: String, CodingKey {
        case nation
        case nationLabel = "nation_label"
        case postcode
        case results
        case meta
    }
}

struct EPCSearchResult: Decodable, Equatable, Identifiable {
    let reference: String
    let address: String?
    let postcode: String?
    let lodgementDate: String?
    let currentEnergyRating: String?
    let potentialEnergyRating: String?
    let propertyType: String?
    let totalFloorAreaSquareMetres: Double?
    let localAuthority: String?
    let apiURL: String?
    let websiteURL: String?

    enum CodingKeys: String, CodingKey {
        case reference
        case address
        case postcode
        case lodgementDate = "lodgement_date"
        case currentEnergyRating = "current_energy_rating"
        case potentialEnergyRating = "potential_energy_rating"
        case propertyType = "property_type"
        case totalFloorAreaSquareMetres = "total_floor_area_square_metres"
        case localAuthority = "local_authority"
        case apiURL = "api_url"
        case websiteURL = "website_url"
    }

    var id: String { reference }
}
