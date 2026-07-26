import Foundation

struct PropertyMarketDashboardResponse: Decodable, Equatable {
    let data: PropertyMarketDashboard
}

struct PropertyMarketDashboard: Decodable, Equatable {
    let metadata: PropertyMarketMetadata
    let summary: PropertyMarketSummary
    let monthlySales: [PropertyMonthlySales]
    let rollingMarket: [PropertyRollingMarket]
    let largestSales: [PropertyLargestSale]
    let propertyTypes: [PropertyTypeMarket]
    let stockMix: [PropertyStockMix]
    let tenureMix: [PropertyTenureMix]
    let yearOnYear: [PropertyMarketYearOnYear]

    enum CodingKeys: String, CodingKey {
        case metadata
        case summary
        case monthlySales = "monthly_sales"
        case rollingMarket = "rolling_market"
        case largestSales = "largest_sales"
        case propertyTypes = "property_types"
        case stockMix = "stock_mix"
        case tenureMix = "tenure_mix"
        case yearOnYear = "year_on_year"
    }
}

struct PropertyMarketMetadata: Decodable, Equatable {
    let region: String
    let latestMonth: String
    let rangeStart: String?
    let rollingWindowMonths: Int
    let category: String
    let source: String
    let isProvisional: Bool
    let generatedAt: String?

    enum CodingKeys: String, CodingKey {
        case region
        case latestMonth = "latest_month"
        case rangeStart = "range_start"
        case rollingWindowMonths = "rolling_window_months"
        case category
        case source
        case isProvisional = "is_provisional"
        case generatedAt = "generated_at"
    }
}

struct PropertyMarketSummary: Decodable, Equatable {
    let sales: Int?
    let medianPrice: Int?
    let medianPriceChange: Double?
    let salesVolumeChange: Double?

    enum CodingKeys: String, CodingKey {
        case sales
        case medianPrice = "median_price"
        case medianPriceChange = "median_price_change"
        case salesVolumeChange = "sales_volume_change"
    }
}

struct PropertyMonthlySales: Decodable, Equatable, Identifiable {
    let period: String
    let value: Int
    let isProvisional: Bool

    var id: String { period }

    enum CodingKeys: String, CodingKey {
        case period
        case value
        case isProvisional = "is_provisional"
    }
}

struct PropertyRollingMarket: Decodable, Equatable, Identifiable {
    let period: String
    let sales: Int
    let medianPrice: Int?
    let percentile90: Int?
    let top5Average: Int?
    let largestSale: Int?

    var id: String { period }

    enum CodingKeys: String, CodingKey {
        case period
        case sales
        case medianPrice = "median_price"
        case percentile90 = "percentile_90"
        case top5Average = "top_5_average"
        case largestSale = "largest_sale"
    }
}

struct PropertyLargestSale: Decodable, Equatable, Identifiable {
    let period: String
    let rank: Int
    let price: Int
    let postcode: String?
    let date: String

    var id: String { "\(period)-\(rank)" }
}

struct PropertyTypeMarket: Decodable, Equatable, Identifiable {
    let period: String
    let detached: PropertyTypeMeasure
    let semiDetached: PropertyTypeMeasure
    let terraced: PropertyTypeMeasure
    let flat: PropertyTypeMeasure
    let other: PropertyTypeMeasure

    var id: String { period }

    enum CodingKeys: String, CodingKey {
        case period
        case detached
        case semiDetached = "semi_detached"
        case terraced
        case flat
        case other
    }
}

struct PropertyTypeMeasure: Decodable, Equatable {
    let sales: Int?
    let medianPrice: Int?

    enum CodingKeys: String, CodingKey {
        case sales
        case medianPrice = "median_price"
    }
}

struct PropertyStockMix: Decodable, Equatable, Identifiable {
    let period: String
    let newBuild: Int?
    let existing: Int?

    var id: String { period }

    enum CodingKeys: String, CodingKey {
        case period
        case newBuild = "new_build"
        case existing
    }
}

struct PropertyTenureMix: Decodable, Equatable, Identifiable {
    let period: String
    let freehold: Int?
    let leasehold: Int?

    var id: String { period }
}

struct PropertyMarketYearOnYear: Decodable, Equatable, Identifiable {
    let period: String
    let sales: Double?
    let medianPrice: Double?
    let percentile90: Double?
    let top5Average: Double?

    var id: String { period }

    enum CodingKeys: String, CodingKey {
        case period
        case sales
        case medianPrice = "median_price"
        case percentile90 = "percentile_90"
        case top5Average = "top_5_average"
    }
}

