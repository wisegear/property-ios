import Foundation

struct SchoolPostcodeSearchResponse: Decodable, Equatable {
    let data: SchoolPostcodeSearch
}

struct SchoolPostcodeSearch: Decodable, Equatable {
    let postcode: String
    let latitude: Double?
    let longitude: Double?
    let primary: [SchoolSearchResult]
    let secondary: [SchoolSearchResult]
}

struct SchoolSearchResult: Decodable, Equatable, Identifiable {
    let urn: String?
    let name: String?
    let slug: String
    let postcode: String?
    let phase: String?
    let establishmentType: String?
    let ageRange: String?
    let distanceMiles: Double?
    let currentOfstedRating: String?
    let latestInspectionDate: String?
    let apiURL: String?
    let websiteURL: String?

    enum CodingKeys: String, CodingKey {
        case urn
        case name
        case slug
        case postcode
        case phase
        case establishmentType = "establishment_type"
        case ageRange = "age_range"
        case distanceMiles = "distance_miles"
        case currentOfstedRating = "current_ofsted_rating"
        case latestInspectionDate = "latest_inspection_date"
        case apiURL = "api_url"
        case websiteURL = "website_url"
    }

    var id: String {
        urn ?? slug
    }
}
