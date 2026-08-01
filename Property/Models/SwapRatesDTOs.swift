import Foundation

struct SwapRatesDashboardResponse: Decodable, Equatable {
    let data: SwapRatesDashboard
}

struct SwapRatesDashboard: Decodable, Equatable {
    let title: String
    let description: String
    let sourceNote: String
    let latestAvailableDate: String?
    let mortgageMarketSummary: SwapMarketSummary?
    let latestMovementSummary: SwapMovementSummary?
    let rates: [SwapRateSnapshot]
    let rateChart: SwapRateChart
    let bankRateComparisonChart: SwapRateChart?
    let currentRates: [CurrentSwapRate]
    let mortgageContext: SwapContentSection
    let understandingSwaps: SwapContentSection
    let faq: [SwapFAQ]
    let updateNote: String
    let websiteURL: String?

    enum CodingKeys: String, CodingKey {
        case title, description, rates, faq
        case sourceNote = "source_note"
        case latestAvailableDate = "latest_available_date"
        case mortgageMarketSummary = "mortgage_market_summary"
        case latestMovementSummary = "latest_movement_summary"
        case rateChart = "rate_chart"
        case bankRateComparisonChart = "bank_rate_comparison_chart"
        case currentRates = "current_rates"
        case mortgageContext = "mortgage_context"
        case understandingSwaps = "understanding_swaps"
        case updateNote = "update_note"
        case websiteURL = "website_url"
    }
}

struct SwapMarketSummary: Decodable, Equatable {
    let signal: String
    let explanation: String
    let signalDirection: String

    enum CodingKeys: String, CodingKey {
        case signal, explanation
        case signalDirection = "signal_direction"
    }
}

struct SwapMovementSummary: Decodable, Equatable {
    let text: String
    let direction: String
}

struct SwapRateSnapshot: Decodable, Equatable, Identifiable {
    let termYears: Int
    let label: String
    let latestRate: Double?
    let latestRateDate: String?
    let previousRate: Double?
    let previousRateDate: String?
    let latestMovement: Double?
    let fiveDayChange: Double?
    let trend: SwapTrend?
    let sparkline: [Double]
    let sparklineDates: [String]
    let range52Week: SwapRateRange

    var id: Int { termYears }

    enum CodingKeys: String, CodingKey {
        case label, trend, sparkline
        case termYears = "term_years"
        case latestRate = "latest_rate"
        case latestRateDate = "latest_rate_date"
        case previousRate = "previous_rate"
        case previousRateDate = "previous_rate_date"
        case latestMovement = "latest_movement"
        case fiveDayChange = "five_day_change"
        case sparklineDates = "sparkline_dates"
        case range52Week = "range_52_week"
    }
}

struct SwapTrend: Decodable, Equatable {
    let label: String
    let direction: String
}

struct SwapRateRange: Decodable, Equatable {
    let low: Double?
    let high: Double?
}

struct SwapRateChart: Decodable, Equatable {
    let labels: [String]
    let datasets: [SwapRateDataset]

    func points(since cutoff: Date?) -> [SwapChartPoint] {
        datasets.flatMap { dataset in
            labels.indices.compactMap { index in
                guard dataset.data.indices.contains(index),
                      let value = dataset.data[index],
                      let date = SwapDateParser.date(labels[index]),
                      cutoff == nil || date >= cutoff! else {
                    return nil
                }
                return SwapChartPoint(
                    id: "\(dataset.label)-\(labels[index])",
                    date: date,
                    series: dataset.label,
                    value: value
                )
            }
        }
    }
}

struct SwapRateDataset: Decodable, Equatable {
    let label: String
    let term: Int?
    let data: [Double?]
}

struct SwapChartPoint: Identifiable, Equatable {
    let id: String
    let date: Date
    let series: String
    let value: Double
}

struct CurrentSwapRate: Decodable, Equatable, Identifiable {
    let term: String
    let rate: Double?
    let dailyChange: Double?
    let fiveDayChange: Double?
    let rateDate: String?
    let previousRate: Double?

    var id: String { term }

    enum CodingKeys: String, CodingKey {
        case term, rate
        case dailyChange = "daily_change"
        case fiveDayChange = "five_day_change"
        case rateDate = "rate_date"
        case previousRate = "previous_rate"
    }
}

struct SwapContentSection: Decodable, Equatable {
    let title: String
    let paragraphs: [String]
}

struct SwapFAQ: Decodable, Equatable, Identifiable {
    let question: String
    let answer: String

    var id: String { question }
}

enum SwapDateParser {
    nonisolated static func date(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    nonisolated static func display(_ value: String?) -> String {
        guard let value, let date = date(value) else { return "Unavailable" }
        return date.formatted(.dateTime.day().month(.abbreviated).year())
    }
}
