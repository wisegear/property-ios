import Foundation

struct SchoolDetailResponse: Decodable, Equatable {
    let data: SchoolDetail
}

struct SchoolDetail: Decodable, Equatable {
    let slug: String
    let urn: String?
    let name: String?
    let phase: String?
    let establishmentType: String?
    let ageRange: SchoolAgeRange?
    let pupilCount: Int?
    let capacity: Int?
    let address: String?
    let postcode: String?
    let latitude: Double?
    let longitude: Double?
    let telephone: String?
    let schoolWebsite: String?
    let headteacher: String?
    let localAuthority: String?
    let religiousCharacter: String?
    let admissionsPolicy: String?
    let gender: String?
    let boardingStatus: String?
    let trust: String?
    let academySponsor: String?
    let openingDate: String?
    let currentOfstedRating: String?
    let latestInspectionDate: String?
    let inspectionType: String?
    let inspectionOutcome: String?
    let ofstedReportURL: String?
    let localPropertyMarket: SchoolLocalPropertyMarket?
    let websiteURL: String?

    enum CodingKeys: String, CodingKey {
        case slug
        case urn
        case name
        case phase
        case establishmentType = "establishment_type"
        case ageRange = "age_range"
        case pupilCount = "pupil_count"
        case capacity
        case address
        case postcode
        case latitude
        case longitude
        case telephone
        case schoolWebsite = "school_website"
        case headteacher
        case localAuthority = "local_authority"
        case religiousCharacter = "religious_character"
        case admissionsPolicy = "admissions_policy"
        case gender
        case boardingStatus = "boarding_status"
        case trust
        case academySponsor = "academy_sponsor"
        case openingDate = "opening_date"
        case currentOfstedRating = "current_ofsted_rating"
        case latestInspectionDate = "latest_inspection_date"
        case inspectionType = "inspection_type"
        case inspectionOutcome = "inspection_outcome"
        case ofstedReportURL = "ofsted_report_url"
        case localPropertyMarket = "local_property_market"
        case websiteURL = "website_url"
    }
}

struct SchoolAgeRange: Decodable, Equatable {
    let minimum: Int?
    let maximum: Int?
    let label: String?
}

struct SchoolLocalPropertyMarket: Decodable, Equatable {
    let outcode: String?
    let nearbyStreets: [SchoolNearbyStreet]?
    let recentSales: [SchoolRecentSale]?
    let updatedLabel: String?

    enum CodingKeys: String, CodingKey {
        case outcode
        case nearbyStreets = "nearby_streets"
        case recentSales = "recent_sales"
        case updatedLabel = "updated_label"
    }
}

struct SchoolNearbyStreet: Decodable, Equatable, Identifiable {
    let name: String?
    let salesCount: Int?
    let averagePrice: Int?
    let averagePriceLabel: String?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case name
        case salesCount = "sales_count"
        case averagePrice = "average_price"
        case averagePriceLabel = "average_price_label"
        case url
    }

    var id: String {
        url ?? "\(name ?? "")-\(salesCount ?? 0)-\(averagePrice ?? 0)"
    }
}

struct SchoolRecentSale: Decodable, Equatable, Identifiable {
    let address: String?
    let postcode: String?
    let price: Int?
    let priceLabel: String?
    let dateLabel: String?
    let propertyType: String?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case address
        case postcode
        case price
        case priceLabel = "price_label"
        case dateLabel = "date_label"
        case propertyType = "property_type"
        case url
    }

    var id: String {
        url ?? "\(address ?? "")-\(dateLabel ?? "")-\(price ?? 0)"
    }
}
