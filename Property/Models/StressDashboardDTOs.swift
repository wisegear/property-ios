import Foundation

struct StressDashboardResponse: Decodable, Equatable {
    let data: StressDashboard
}

struct StressDashboard: Decodable, Equatable {
    let title: String
    let description: String
    let lastUpdated: String?
    let score: StressScore
    let indicators: [StressIndicator]
    let websiteURL: String?

    enum CodingKeys: String, CodingKey {
        case title
        case description
        case lastUpdated = "last_updated"
        case score
        case indicators
        case websiteURL = "website_url"
    }

    var statusCounts: [StressStatus: Int] {
        indicators.reduce(into: [:]) { counts, indicator in
            counts[indicator.status, default: 0] += 1
        }
    }
}

struct StressScore: Decodable, Equatable {
    let value: Int
    let maximum: Int
    let rawValue: Int
    let rawMaximum: Int
    let status: StressStatus
    let statusLabel: String
    let description: String

    enum CodingKeys: String, CodingKey {
        case value
        case maximum
        case rawValue = "raw_value"
        case rawMaximum = "raw_maximum"
        case status
        case statusLabel = "status_label"
        case description
    }
}

struct StressIndicator: Decodable, Equatable, Identifiable {
    let key: String
    let title: String
    let description: String
    let value: Double?
    let secondaryValue: Double?
    let unit: String
    let period: String?
    let badStreak: Int
    let status: StressStatus
    let statusLabel: String
    let score: Int
    let maximumScore: Int
    let apiURL: String?
    let websiteURL: String?

    enum CodingKeys: String, CodingKey {
        case key
        case title
        case description
        case value
        case secondaryValue = "secondary_value"
        case unit
        case period
        case badStreak = "bad_streak"
        case status
        case statusLabel = "status_label"
        case score
        case maximumScore = "maximum_score"
        case apiURL = "api_url"
        case websiteURL = "website_url"
    }

    var id: String { key }
}

enum StressStatus: String, Decodable, Equatable, CaseIterable, Hashable {
    case positive
    case neutral
    case warning
    case stress

    init(from decoder: Decoder) throws {
        let value = try decoder.singleValueContainer().decode(String.self)

        switch value.lowercased() {
        case "positive", "supportive", "green", "low":
            self = .positive
        case "neutral", "amber":
            self = .neutral
        case "stress", "dark_red", "deep":
            self = .stress
        case "warning", "potential_stress", "red":
            self = .warning
        default:
            self = .warning
        }
    }

    var label: String {
        switch self {
        case .positive: "Positive"
        case .neutral: "Neutral"
        case .warning: "Warning"
        case .stress: "Stress"
        }
    }
}
