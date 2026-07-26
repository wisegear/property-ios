import Foundation

struct CrimeDashboardResponse: Decodable, Equatable {
    let data: CrimeDashboard
}

struct CrimeAreaResponse: Decodable, Equatable {
    let data: CrimeAreaDetail
}

struct CrimeDashboard: Decodable, Equatable {
    let latestMonth: String?
    let latestMonthLabel: String?
    let summary: CrimePeriodSummary
    let chart: CrimeChart
    let crimeTypes: [CrimeTypeSummary]
    let drivers: CrimeDrivers
    let areas: [CrimeAreaSummary]
    let websiteURL: String?

    enum CodingKeys: String, CodingKey {
        case latestMonth = "latest_month"
        case latestMonthLabel = "latest_month_label"
        case summary
        case chart
        case crimeTypes = "crime_types"
        case drivers
        case areas
        case websiteURL = "website_url"
    }
}

struct CrimeAreaDetail: Decodable, Equatable {
    let area: String?
    let areaSlug: String
    let latestMonth: String?
    let latestMonthLabel: String?
    let summary: CrimePeriodSummary
    let chart: CrimeChart
    let crimeBreakdown: [CrimeAreaBreakdown]
    let drivers: CrimeDrivers
    let websiteURL: String?

    enum CodingKeys: String, CodingKey {
        case area
        case areaSlug = "area_slug"
        case latestMonth = "latest_month"
        case latestMonthLabel = "latest_month_label"
        case summary
        case chart
        case crimeBreakdown = "crime_breakdown"
        case drivers
        case websiteURL = "website_url"
    }
}

struct CrimePeriodSummary: Decodable, Equatable {
    let total12Months: Int
    let previous12Months: Int
    let percentageChange: Double
    let last3MonthsTotal: Int
    let previous3MonthsTotal: Int
    let last3MonthsChange: Double

    enum CodingKeys: String, CodingKey {
        case total12Months = "total_12m"
        case previous12Months = "prev_12m"
        case percentageChange = "pct_change"
        case last3MonthsTotal = "last_3m_total"
        case previous3MonthsTotal = "prev_3m_total"
        case last3MonthsChange = "last_3m_change"
    }
}

struct CrimeChart: Decodable, Equatable {
    let labels: [String]
    let currentYear: [Int]
    let previousYear: [Int]

    enum CodingKeys: String, CodingKey {
        case labels
        case currentYear = "current_year"
        case previousYear = "previous_year"
    }

    var points: [CrimeChartPoint] {
        labels.indices.flatMap { index in
            [
                CrimeChartPoint(
                    id: "current-\(index)",
                    month: labels[index],
                    index: index,
                    series: "Latest 12 months",
                    value: currentYear.indices.contains(index) ? currentYear[index] : 0
                ),
                CrimeChartPoint(
                    id: "previous-\(index)",
                    month: labels[index],
                    index: index,
                    series: "Previous 12 months",
                    value: previousYear.indices.contains(index) ? previousYear[index] : 0
                )
            ]
        }
    }
}

struct CrimeChartPoint: Identifiable, Equatable {
    let id: String
    let month: String
    let index: Int
    let series: String
    let value: Int
}

struct CrimeTypeSummary: Decodable, Equatable, Identifiable {
    let type: String
    let total12Months: Int
    let previous12Months: Int
    let yearOnYearChange: Double
    let sharePercentage: Double
    let trend: String?

    enum CodingKeys: String, CodingKey {
        case type
        case total12Months = "total_12m"
        case previous12Months = "total_prev_12m"
        case yearOnYearChange = "yoy_change"
        case sharePercentage = "share_pct"
        case trend
    }

    var id: String { type }
}

struct CrimeDrivers: Decodable, Equatable {
    let overallYearOnYear: Double
    let increases: [CrimeDriver]
    let decreases: [CrimeDriver]

    enum CodingKeys: String, CodingKey {
        case overallYearOnYear = "overall_yoy"
        case increases
        case decreases
    }
}

struct CrimeDriver: Decodable, Equatable, Identifiable {
    let type: String
    let impact: Int
    let yearOnYearChange: Double

    enum CodingKeys: String, CodingKey {
        case type
        case impact
        case yearOnYearChange = "yoy_change"
    }

    var id: String { "\(type)-\(impact)" }
}

struct CrimeAreaSummary: Decodable, Equatable, Identifiable {
    let area: String
    let slug: String
    let total12Months: Int
    let previous12Months: Int
    let percentageChange: Double
    let trend: String?
    let apiURL: String?
    let websiteURL: String?

    enum CodingKeys: String, CodingKey {
        case area
        case slug
        case total12Months = "total_12m"
        case previous12Months = "prev_12m"
        case percentageChange = "pct_change"
        case trend
        case apiURL = "api_url"
        case websiteURL = "website_url"
    }

    var id: String { slug }
}

struct CrimeAreaBreakdown: Decodable, Equatable, Identifiable {
    let type: String
    let total12Months: Int
    let previous12Months: Int
    let yearOnYearChange: Double
    let sharePercentage: Double
    let impact: Int
    let trend: String?
    let nationalYearOnYear: Double?
    let isLargest: Bool?

    enum CodingKeys: String, CodingKey {
        case type
        case total12Months = "total_12m"
        case previous12Months = "total_prev_12m"
        case yearOnYearChange = "yoy_change"
        case sharePercentage = "share_pct"
        case impact
        case trend
        case nationalYearOnYear = "national_yoy"
        case isLargest = "is_largest"
    }

    var id: String { type }
}
