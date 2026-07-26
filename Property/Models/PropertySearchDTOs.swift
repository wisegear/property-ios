import Foundation

struct PropertySearchResponse: Decodable, Equatable {
    let postcode: String
    let results: [PropertySearchResult]
    let meta: PaginationMeta?
}

struct PaginationMeta: Decodable, Equatable {
    let currentPage: Int
    let lastPage: Int
    let perPage: Int
    let total: Int

    enum CodingKeys: String, CodingKey {
        case currentPage = "current_page"
        case lastPage = "last_page"
        case perPage = "per_page"
        case total
    }

    var hasNextPage: Bool {
        currentPage < lastPage
    }
}

struct PropertySearchResult: Decodable, Equatable, Identifiable {
    let transactionID: String?
    let price: Int?
    let date: String?
    let propertyType: String?
    let newBuild: String?
    let duration: String?
    let paon: String?
    let saon: String?
    let street: String?
    let locality: String?
    let townCity: String?
    let district: String?
    let county: String?
    let postcode: String?
    let category: String?
    let propertySlug: String
    let url: String?

    enum CodingKeys: String, CodingKey {
        case transactionID = "transaction_id"
        case price
        case date
        case propertyType = "property_type"
        case newBuild = "new_build"
        case duration
        case paon
        case saon
        case street
        case locality
        case townCity = "town_city"
        case district
        case county
        case postcode
        case category
        case propertySlug = "property_slug"
        case url
    }

    var id: String {
        propertySlug
    }

    var formattedAddress: String {
        let building = [saon, paon]
            .compactMap { $0?.nilIfBlank }
            .joined(separator: ", ")
        let parts = [building, street, locality, townCity]
            .compactMap { $0?.nilIfBlank }
        return parts.isEmpty ? "Address unavailable" : parts.joined(separator: ", ")
    }

    var propertyTypeLabel: String {
        switch propertyType?.uppercased() {
        case "D": return "Detached"
        case "S": return "Semi-detached"
        case "T": return "Terraced"
        case "F": return "Flat"
        case "O": return "Other"
        default: return propertyType?.nilIfBlank ?? "Type unavailable"
        }
    }

    static func groupedNewest(_ results: [PropertySearchResult]) -> [PropertySearchResult] {
        var grouped: [String: PropertySearchResult] = [:]

        for result in results where !result.propertySlug.isEmpty {
            guard let current = grouped[result.propertySlug] else {
                grouped[result.propertySlug] = result
                continue
            }

            if (result.date ?? "") > (current.date ?? "") {
                grouped[result.propertySlug] = result
            }
        }

        return grouped.values.sorted {
            if ($0.date ?? "") == ($1.date ?? "") {
                return $0.formattedAddress < $1.formattedAddress
            }
            return ($0.date ?? "") > ($1.date ?? "")
        }
    }
}

extension String {
    var nilIfBlank: String? {
        let value = trimmingCharacters(in: .whitespacesAndNewlines)
        return value.isEmpty ? nil : value
    }
}
