import Foundation

struct PropertyDetailResponse: Decodable, Equatable {
    let data: PropertyDetail
}

struct PropertyDetail: Decodable, Equatable {
    let slug: String
    let address: String?
    let propertyType: PropertyTypeDetail?
    let location: PropertyLocation?
    let transactions: [PropertyTransaction]?
    let epcCertificates: [EPCCertificate]?
    let nearbySchools: NearbySchools?
    let crime: CrimeResearch?
    let deprivation: JSONValue?
    let deprivationMessage: String?
    let councilTaxEstimate: JSONValue?
    let market: MarketResearch?

    enum CodingKeys: String, CodingKey {
        case slug
        case address
        case propertyType = "property_type"
        case location
        case transactions
        case epcCertificates = "epc_certificates"
        case nearbySchools = "nearby_schools"
        case crime
        case deprivation
        case deprivationMessage = "deprivation_message"
        case councilTaxEstimate = "council_tax_estimate"
        case market
    }
}

struct PropertyTypeDetail: Decodable, Equatable {
    let code: String?
    let label: String?
}

struct PropertyLocation: Decodable, Equatable {
    let postcode: String?
    let latitude: Double?
    let longitude: Double?
    let approximate: Bool?
}

struct PropertyTransaction: Decodable, Equatable, Identifiable {
    let date: String?
    let price: Int?
    let propertyType: String?
    let newBuild: String?
    let tenure: String?
    let category: String?

    enum CodingKeys: String, CodingKey {
        case date
        case price
        case propertyType = "property_type"
        case newBuild = "new_build"
        case tenure
        case category
    }

    var id: String {
        "\(date ?? "unknown")-\(price ?? 0)-\(category ?? "")"
    }
}

struct EPCCertificate: Decodable, Equatable, Identifiable {
    let lmkKey: String?
    let address: String?
    let postcode: String?
    let lodgementDate: String?
    let currentEnergyRating: String?
    let potentialEnergyRating: String?
    let propertyType: String?
    let totalFloorAreaSquareMetres: Double?
    let localAuthority: String?
    let matchScore: Double?
    let apiURL: String?
    let websiteURL: String?

    enum CodingKeys: String, CodingKey {
        case lmkKey = "lmk_key"
        case address
        case postcode
        case lodgementDate = "lodgement_date"
        case currentEnergyRating = "current_energy_rating"
        case potentialEnergyRating = "potential_energy_rating"
        case propertyType = "property_type"
        case totalFloorAreaSquareMetres = "total_floor_area_square_metres"
        case localAuthority = "local_authority"
        case matchScore = "match_score"
        case apiURL = "api_url"
        case websiteURL = "website_url"
    }

    var id: String {
        lmkKey ?? "\(address ?? "")-\(lodgementDate ?? "")"
    }
}

struct NearbySchools: Decodable, Equatable {
    let primary: [NearbySchool]?
    let secondary: [NearbySchool]?
}

struct NearbySchool: Decodable, Equatable, Identifiable {
    let urn: String?
    let name: String?
    let postcode: String?
    let phase: String?
    let type: String?
    let ageRange: String?
    let distanceMiles: Double?
    let latestOfstedRating: String?
    let latestInspectionDate: String?
    let url: String?
    let slug: String?
    let apiURL: String?
    let websiteURL: String?

    enum CodingKeys: String, CodingKey {
        case urn
        case name
        case postcode
        case phase
        case type
        case ageRange = "age_range"
        case distanceMiles = "distance_miles"
        case latestOfstedRating = "latest_ofsted_rating"
        case latestInspectionDate = "latest_inspection_date"
        case url
        case slug
        case apiURL = "api_url"
        case websiteURL = "website_url"
    }

    var id: String {
        urn ?? "\(name ?? "")-\(postcode ?? "")"
    }
}

struct CrimeResearch: Decodable, Equatable {
    let summary: String?
    let direction: String?
    let totalChangePercent: Double?
    let topIncrease: JSONValue?
    let topDecrease: JSONValue?
    let categories: [JSONValue]?
    let trend: [JSONValue]?

    enum CodingKeys: String, CodingKey {
        case summary
        case direction
        case totalChangePercent = "total_change_percent"
        case topIncrease = "top_increase"
        case topDecrease = "top_decrease"
        case categories
        case trend
    }
}

struct MarketResearch: Decodable, Equatable {
    let propertyPriceHistory: [JSONValue]?
    let postcode: PostcodeMarket?
    let locality: MarketArea?
    let town: MarketArea?
    let district: MarketArea?
    let county: MarketArea?

    enum CodingKeys: String, CodingKey {
        case propertyPriceHistory = "property_price_history"
        case postcode
        case locality
        case town
        case district
        case county
    }
}

struct PostcodeMarket: Decodable, Equatable {
    let priceHistory: [JSONValue]?
    let salesHistory: [JSONValue]?

    enum CodingKeys: String, CodingKey {
        case priceHistory = "price_history"
        case salesHistory = "sales_history"
    }
}

struct MarketArea: Decodable, Equatable {
    let priceHistory: [JSONValue]?
    let salesHistory: [JSONValue]?
    let propertyTypes: [JSONValue]?
    let url: String?

    enum CodingKeys: String, CodingKey {
        case priceHistory = "price_history"
        case salesHistory = "sales_history"
        case propertyTypes = "property_types"
        case url
    }
}
