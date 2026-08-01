import Foundation

struct HPIDashboardResponse: Decodable, Equatable {
    let data: HPIDashboard
}

struct HPIDashboard: Decodable, Equatable {
    let title: String
    let description: String
    let sourceNote: String
    let latestDate: String?
    let nations: [HPINationSnapshot]
    let annualChangeSeries: [HPIAnnualSeries]
    let propertyTypeSeries: [HPIPropertyTypeSeries]
    let movers: [HPIRegionChange]
    let losers: [HPIRegionChange]
    let websiteURL: String?

    enum CodingKeys: String, CodingKey {
        case title, description, nations, movers, losers
        case sourceNote = "source_note"
        case latestDate = "latest_date"
        case annualChangeSeries = "annual_change_series"
        case propertyTypeSeries = "property_type_series"
        case websiteURL = "website_url"
    }
}

struct HPINationSnapshot: Decodable, Equatable, Identifiable {
    let name: String
    let code: String
    let date: String?
    let averagePrice: Double?
    let oneMonthChange: Double?
    let twelveMonthChange: Double?
    let salesVolume: Int?

    var id: String { code }

    enum CodingKeys: String, CodingKey {
        case name, code, date
        case averagePrice = "average_price"
        case oneMonthChange = "one_month_change"
        case twelveMonthChange = "twelve_month_change"
        case salesVolume = "sales_volume"
    }
}

struct HPIAnnualSeries: Decodable, Equatable, Identifiable {
    let name: String
    let code: String
    let dates: [String]
    let twelveMonthChange: [Double?]

    var id: String { code }

    enum CodingKeys: String, CodingKey {
        case name, code, dates
        case twelveMonthChange = "twelve_m_change"
    }

    var annualPoints: [HPIChartPoint] {
        var latestByYear: [Int: HPIChartPoint] = [:]
        for index in dates.indices {
            guard let year = Int(dates[index].prefix(4)),
                  twelveMonthChange.indices.contains(index),
                  let value = twelveMonthChange[index] else {
                continue
            }
            latestByYear[year] = HPIChartPoint(
                id: "\(code)-\(year)",
                date: DateComponents(calendar: .current, year: year).date ?? .distantPast,
                series: "12-month change",
                value: value
            )
        }
        return latestByYear.values.sorted { $0.date < $1.date }
    }
}

struct HPIPropertyTypeSeries: Decodable, Equatable, Identifiable {
    let name: String
    let code: String
    let dates: [String]
    let types: HPIPropertyTypes

    var id: String { code }

    func points(for selection: HPIPropertyTypeSelection) -> [HPIChartPoint] {
        selection.series.flatMap { series in
            dates.indices.compactMap { index in
                guard let date = HPIDateParser.date(dates[index]),
                      let value = series.values(types).value(at: index) else {
                    return nil
                }
                return HPIChartPoint(
                    id: "\(code)-\(series.rawValue)-\(dates[index])",
                    date: date,
                    series: series.label,
                    value: value
                )
            }
        }
    }
}

struct HPIPropertyTypes: Decodable, Equatable {
    let detached: [Double?]
    let semiDetached: [Double?]
    let terraced: [Double?]
    let flat: [Double?]

    enum CodingKeys: String, CodingKey {
        case detached = "Detached"
        case semiDetached = "SemiDetached"
        case terraced = "Terraced"
        case flat = "Flat"
    }
}

enum HPIPropertyTypeSelection: String, CaseIterable, Identifiable {
    case all = "All"
    case detached = "Detached"
    case semiDetached = "Semi"
    case terraced = "Terraced"
    case flat = "Flat"

    var id: String { rawValue }

    var series: [HPIPropertyType] {
        switch self {
        case .all: HPIPropertyType.allCases
        case .detached: [.detached]
        case .semiDetached: [.semiDetached]
        case .terraced: [.terraced]
        case .flat: [.flat]
        }
    }
}

enum HPIPropertyType: String, CaseIterable {
    case detached, semiDetached, terraced, flat

    var label: String {
        switch self {
        case .detached: "Detached"
        case .semiDetached: "Semi-detached"
        case .terraced: "Terraced"
        case .flat: "Flat"
        }
    }

    func values(_ types: HPIPropertyTypes) -> [Double?] {
        switch self {
        case .detached: types.detached
        case .semiDetached: types.semiDetached
        case .terraced: types.terraced
        case .flat: types.flat
        }
    }
}

struct HPIRegionChange: Decodable, Equatable, Identifiable {
    let name: String
    let code: String
    let averagePrice: Double?
    let twelveMonthChange: Double?

    var id: String { code }

    enum CodingKeys: String, CodingKey {
        case name, code
        case averagePrice = "average_price"
        case twelveMonthChange = "twelve_month_change"
    }
}

struct HPIChartPoint: Identifiable, Equatable {
    let id: String
    let date: Date
    let series: String
    let value: Double
}

private extension Array where Element == Double? {
    func value(at index: Int) -> Double? {
        indices.contains(index) ? self[index] : nil
    }
}

enum HPIDateParser {
    nonisolated static func date(_ value: String) -> Date? {
        let formatter = DateFormatter()
        formatter.calendar = Calendar(identifier: .gregorian)
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = value.count == 7 ? "yyyy-MM" : "yyyy-MM-dd"
        return formatter.date(from: value)
    }

    nonisolated static func display(_ value: String?) -> String {
        guard let value, let date = date(value) else { return "Unavailable" }
        return date.formatted(.dateTime.month(.wide).year())
    }
}
