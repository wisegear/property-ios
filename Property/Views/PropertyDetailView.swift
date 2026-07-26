import Charts
import MapKit
import SwiftUI

struct PropertyDetailView: View {
    @StateObject private var viewModel: PropertyDetailViewModel

    init(slug: String, client: any PropertyResearchAPIClientProtocol) {
        _viewModel = StateObject(
            wrappedValue: PropertyDetailViewModel(slug: slug, client: client)
        )
    }

    var body: some View {
        Group {
            if let property = viewModel.property {
                detailContent(property)
            } else if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Unable to load property", systemImage: "wifi.exclamationmark")
                } description: {
                    Text(error.message)
                } actions: {
                    if error.canRetry {
                        Button("Try again") {
                            Task {
                                await viewModel.retry()
                            }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading property research…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(viewModel.property?.address ?? "Property")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await viewModel.load()
        }
        .onDisappear {
            viewModel.cancel()
        }
    }

    private func detailContent(_ property: PropertyDetail) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                overview(property)
                location(property.location)
                salesHistory(property.transactions)
                epcCertificates(property.epcCertificates)
                schools(title: "Nearby primary schools", schools: property.nearbySchools?.primary)
                schools(title: "Nearby secondary schools", schools: property.nearbySchools?.secondary)
                crime(property.crime)
                deprivation(property.deprivation, fallback: property.deprivationMessage)
                councilTax(property.councilTaxEstimate)
                marketSection(
                    title: "\(property.location?.postcode?.nilIfBlank ?? "Postcode") Market History",
                    priceHistory: property.market?.postcode?.priceHistory,
                    salesHistory: property.market?.postcode?.salesHistory
                )
                marketArea(
                    title: marketAreaTitle(
                        property.market?.locality,
                        field: "locality",
                        fallback: "Locality"
                    ),
                    area: property.market?.locality
                )
                marketArea(
                    title: marketAreaTitle(
                        property.market?.town,
                        field: "town",
                        fallback: "Town"
                    ),
                    area: property.market?.town
                )
                marketArea(
                    title: marketAreaTitle(
                        property.market?.district,
                        field: "district",
                        fallback: "District",
                        usesAmpersand: true
                    ),
                    area: property.market?.district
                )
                marketArea(
                    title: marketAreaTitle(
                        property.market?.county,
                        field: "county",
                        fallback: "County"
                    ),
                    area: property.market?.county
                )
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func overview(_ property: PropertyDetail) -> some View {
        ResearchCard(title: "Property overview", icon: "house.fill") {
            Text(property.address ?? "Address unavailable")
                .font(.title2.bold())

            DetailLine(
                label: "Property type",
                value: property.propertyType?.label ?? "Data unavailable"
            )
            DetailLine(
                label: "Postcode",
                value: property.location?.postcode ?? "Data unavailable"
            )
        }
    }

    @ViewBuilder
    private func location(_ location: PropertyLocation?) -> some View {
        ResearchCard(title: "Approximate location", icon: "map.fill") {
            if let latitude = location?.latitude, let longitude = location?.longitude {
                let coordinate = CLLocationCoordinate2D(
                    latitude: latitude,
                    longitude: longitude
                )
                Map(
                    initialPosition: .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.01, longitudeDelta: 0.01)
                        )
                    )
                ) {
                    Marker(location?.postcode ?? "Property", coordinate: coordinate)
                }
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .allowsHitTesting(false)

                Text("Location is approximate and based on the postcode centroid.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                UnavailableView()
            }
        }
    }

    private func salesHistory(_ transactions: [PropertyTransaction]?) -> some View {
        ResearchCard(title: "Sales history", icon: "sterlingsign.circle.fill") {
            if let transactions, !transactions.isEmpty {
                ForEach(transactions) { transaction in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(transaction.price?.formatted(.currency(code: "GBP").precision(.fractionLength(0))) ?? "Price unavailable")
                            .font(.headline)
                        Text(DateFormatting.displayDate(transaction.date))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        HStack {
                            Text(tenureLabel(transaction.tenure))
                            if transaction.newBuild == "Y" {
                                Text("New build")
                            }
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    if transaction.id != transactions.last?.id {
                        Divider()
                    }
                }
            } else {
                UnavailableView()
            }
        }
    }

    private func epcCertificates(_ certificates: [EPCCertificate]?) -> some View {
        ResearchCard(title: "EPC certificates", icon: "leaf.fill") {
            if let certificates, !certificates.isEmpty {
                ForEach(certificates) { certificate in
                    if let apiURL = certificate.apiURL.flatMap(URL.init(string:)) {
                        NavigationLink {
                            EPCCertificateView(apiURL: apiURL, client: viewModel.client)
                        } label: {
                            epcCertificateRow(certificate, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        epcCertificateRow(certificate, showsChevron: false)
                    }
                }
            } else {
                UnavailableView()
            }
        }
    }

    private func epcCertificateRow(
        _ certificate: EPCCertificate,
        showsChevron: Bool
    ) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(certificate.currentEnergyRating ?? "–")
                .font(.title2.bold())
                .foregroundStyle(.green)
                .frame(width: 44, height: 44)
                .background(Color.green.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(certificate.address ?? "Address unavailable")
                    .font(.headline)
                Text("Potential rating: \(certificate.potentialEnergyRating ?? "Unavailable")")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                if let area = certificate.totalFloorAreaSquareMetres {
                    Text("\(area.formatted(.number.precision(.fractionLength(0)))) m²")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 4)

            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
                    .padding(.top, 14)
            }
        }
        .contentShape(Rectangle())
    }

    private func schools(title: String, schools: [NearbySchool]?) -> some View {
        let orderedSchools = schools?.sorted(by: schoolComesBefore)

        return ResearchCard(title: title, icon: "graduationcap.fill") {
            if let orderedSchools, !orderedSchools.isEmpty {
                ForEach(orderedSchools) { school in
                    if let apiURL = school.apiURL.flatMap(URL.init(string:)) {
                        NavigationLink {
                            SchoolDetailView(apiURL: apiURL, client: viewModel.client)
                        } label: {
                            schoolRow(school, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        schoolRow(school, showsChevron: false)
                    }

                    if school.id != orderedSchools.last?.id {
                        Divider()
                    }
                }
            } else {
                UnavailableView()
            }
        }
    }

    private func schoolRow(_ school: NearbySchool, showsChevron: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 4) {
                Text(school.name ?? "School name unavailable")
                    .font(.headline)

                if let distance = school.distanceMiles {
                    Text("\(distance.formatted(.number.precision(.fractionLength(1)))) miles")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            Spacer(minLength: 4)

            HStack(spacing: 7) {
                OfstedRatingBadge(rating: school.latestOfstedRating)

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .contentShape(Rectangle())
    }

    private func schoolComesBefore(_ lhs: NearbySchool, _ rhs: NearbySchool) -> Bool {
        let lhsPriority = OfstedRatingBadge.priority(for: lhs.latestOfstedRating)
        let rhsPriority = OfstedRatingBadge.priority(for: rhs.latestOfstedRating)

        if lhsPriority != rhsPriority {
            return lhsPriority < rhsPriority
        }

        let lhsDistance = lhs.distanceMiles ?? .greatestFiniteMagnitude
        let rhsDistance = rhs.distanceMiles ?? .greatestFiniteMagnitude
        if lhsDistance != rhsDistance {
            return lhsDistance < rhsDistance
        }

        return (lhs.name ?? "").localizedCaseInsensitiveCompare(rhs.name ?? "") == .orderedAscending
    }

    private func crime(_ crime: CrimeResearch?) -> some View {
        ResearchCard(title: "Crime summary and trends", icon: "shield.lefthalf.filled") {
            if let crime,
               crime.summary?.nilIfBlank != nil
                || crime.direction?.nilIfBlank != nil
                || crime.totalChangePercent != nil {
                Text(crime.summary ?? "Summary unavailable")
                    .font(.body)
                DetailLine(label: "Trend", value: crime.direction ?? "Data unavailable")
                if let change = crime.totalChangePercent {
                    DetailLine(
                        label: "Total change",
                        value: "\(change.formatted(.number.precision(.fractionLength(1))))%"
                    )
                }
            } else {
                UnavailableView()
            }
        }
    }

    private func flexibleResearch(
        title: String,
        value: JSONValue?,
        fallback: String? = nil
    ) -> some View {
        ResearchCard(title: title, icon: "chart.bar.doc.horizontal") {
            if let value, !summaryRows(value).isEmpty {
                ForEach(summaryRows(value), id: \.label) { row in
                    DetailLine(label: row.label, value: row.value)
                }
            } else if let fallback = fallback?.nilIfBlank {
                Text(fallback)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                UnavailableView()
            }
        }
    }

    private func deprivation(_ value: JSONValue?, fallback: String?) -> some View {
        ResearchCard(title: "Deprivation information", icon: "chart.bar.doc.horizontal") {
            if case .object(let fields) = value {
                Text("Higher deciles and ranks indicate a better rating.")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                if let decile = deprivationInteger("decile", in: fields) {
                    HStack {
                        Text("Decile")
                            .foregroundStyle(.secondary)
                        Spacer()
                        DeprivationDecileBadge(decile: decile)
                    }
                    .font(.subheadline)
                }

                if let name = deprivationText("name", in: fields) {
                    DetailLine(label: "Area", value: name)
                }

                let rank = deprivationInteger("rank", in: fields)
                let total = deprivationInteger("total", in: fields)
                if let rank, let total {
                    DetailLine(
                        label: "Rank",
                        value: "\(rank.formatted()) out of \(total.formatted())"
                    )
                } else if let rank {
                    DetailLine(label: "Rank", value: rank.formatted())
                }

                if let url = deprivationURL(in: fields) {
                    Link(destination: url) {
                        Label(
                            "View more deprivation information",
                            systemImage: "arrow.up.right.square"
                        )
                        .font(.subheadline.weight(.semibold))
                    }
                }
            } else if let fallback = fallback?.nilIfBlank {
                Text(fallback)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
                UnavailableView()
            }

            Divider()

            Text(
                "Note: “Deprivation” is a statistical term about access to resources "
                    + "and services; it is not a label on people or places."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
    }

    private func deprivationText(_ key: String, in fields: [String: JSONValue]) -> String? {
        fields.first { $0.key.caseInsensitiveCompare(key) == .orderedSame }?.value.displayText
    }

    private func deprivationInteger(_ key: String, in fields: [String: JSONValue]) -> Int? {
        guard let text = deprivationText(key, in: fields) else {
            return nil
        }
        guard let number = Double(text), number.isFinite else {
            return nil
        }
        return Int(number)
    }

    private func deprivationURL(in fields: [String: JSONValue]) -> URL? {
        guard let areaCode = deprivationText("lsoa21", in: fields)?
            .trimmingCharacters(in: .whitespacesAndNewlines),
            !areaCode.isEmpty
        else {
            return nil
        }

        return URL(string: "https://propertyresearch.uk/deprivation/\(areaCode)")
    }

    private func councilTax(_ value: JSONValue?) -> some View {
        ResearchCard(title: "Council-tax estimate", icon: "sterlingsign.circle.fill") {
            if case .object(let fields) = value,
               let annualEstimate = councilTaxAnnualEstimate(in: fields)
            {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Estimated council tax")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Text("£\(annualEstimate.formatted()) per year")
                        .font(.title2.bold())
                }

                if let likelyBand = deprivationText("band_label", in: fields) {
                    DetailLine(label: "Likely band", value: likelyBand)
                }

                Divider()

                let authority = deprivationText("authority", in: fields)
                    ?? "local authority"
                Text(
                    "This is an estimate, not the property's official band or bill. "
                        + "It uses \(authority) average Council Tax charges; the actual "
                        + "amount can vary by parish, local levy, discounts, premiums "
                        + "and exemptions."
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            } else {
                UnavailableView()
            }
        }
    }

    private func councilTaxAnnualEstimate(in fields: [String: JSONValue]) -> Int? {
        let low = deprivationInteger("low_annual", in: fields)
        let high = deprivationInteger("high_annual", in: fields)

        switch (low, high) {
        case let (low?, high?):
            return Int((Double(low) + Double(high)) / 2)
        case let (low?, nil):
            return low
        case let (nil, high?):
            return high
        case (nil, nil):
            return nil
        }
    }

    private func marketSection(
        title: String,
        priceHistory: [JSONValue]?,
        salesHistory: [JSONValue]? = nil
    ) -> some View {
        let prices = marketPoints(priceHistory, valueKey: "avg_price")
        let sales = marketPoints(salesHistory, valueKey: "total_sales")

        return Group {
            if !prices.isEmpty || !sales.isEmpty {
                ResearchCard(title: title, icon: "chart.xyaxis.line") {
                    MarketHistoryCharts(prices: prices, sales: sales)
                }
            }
        }
    }

    private func marketArea(title: String, area: MarketArea?) -> some View {
        let prices = marketPoints(area?.priceHistory, valueKey: "avg_price")
        let sales = marketPoints(area?.salesHistory, valueKey: "total_sales")
        let propertyTypes = propertyTypePoints(area?.propertyTypes)

        return Group {
            if !prices.isEmpty || !sales.isEmpty || !propertyTypes.isEmpty {
                ResearchCard(title: title, icon: "building.2.fill") {
                    MarketHistoryCharts(prices: prices, sales: sales)

                    if !propertyTypes.isEmpty {
                        PropertyTypeChart(points: propertyTypes)
                    }
                }
            }
        }
    }

    private func marketPoints(
        _ values: [JSONValue]?,
        valueKey: String
    ) -> [MarketChartPoint] {
        (values ?? []).compactMap { value in
            guard case .object(let fields) = value,
                  let year = numericValue("year", in: fields),
                  let amount = numericValue(valueKey, in: fields)
            else {
                return nil
            }
            return MarketChartPoint(year: Int(year), value: amount)
        }
        .sorted { $0.year < $1.year }
    }

    private func propertyTypePoints(_ values: [JSONValue]?) -> [PropertyTypeChartPoint] {
        (values ?? []).compactMap { value in
            guard case .object(let fields) = value,
                  let label = deprivationText("label", in: fields),
                  let amount = numericValue("value", in: fields)
            else {
                return nil
            }
            return PropertyTypeChartPoint(label: label, value: amount)
        }
        .sorted { $0.value > $1.value }
    }

    private func numericValue(_ key: String, in fields: [String: JSONValue]) -> Double? {
        guard let text = deprivationText(key, in: fields) else {
            return nil
        }
        return Double(text)
    }

    private func marketAreaTitle(
        _ area: MarketArea?,
        field: String,
        fallback: String,
        usesAmpersand: Bool = false
    ) -> String {
        let recordName = area?.salesHistory?.lazy.compactMap { value -> String? in
            guard case .object(let fields) = value else {
                return nil
            }
            return deprivationText(field, in: fields)
        }.first

        let urlName = area?.url?
            .split(separator: "/")
            .last
            .map(String.init)?
            .replacingOccurrences(of: "-", with: " ")

        var name = (recordName ?? urlName ?? fallback)
            .lowercased()
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")

        if usesAmpersand {
            name = name.replacingOccurrences(of: " And ", with: " & ")
        }

        return "\(name) Market Data"
    }

    private func tenureLabel(_ value: String?) -> String {
        switch value?.uppercased() {
        case "F": return "Freehold"
        case "L": return "Leasehold"
        default: return value?.nilIfBlank ?? "Tenure unavailable"
        }
    }

    private func summaryRows(_ value: JSONValue) -> [(label: String, value: String)] {
        switch value {
        case .object(let object):
            return object
                .compactMap { key, value in
                    guard let text = value.displayText else {
                        return nil
                    }
                    return (key.humanized, text)
                }
                .sorted { $0.label < $1.label }
        default:
            guard let text = value.displayText else {
                return []
            }
            return [("Value", text)]
        }
    }
}

private struct MarketChartPoint: Identifiable {
    let year: Int
    let value: Double

    var id: Int { year }

    var date: Date {
        Calendar(identifier: .gregorian).date(
            from: DateComponents(year: year, month: 1, day: 1)
        ) ?? .distantPast
    }
}

private struct PropertyTypeChartPoint: Identifiable {
    let label: String
    let value: Double

    var id: String { label }
}

private struct MarketHistoryCharts: View {
    let prices: [MarketChartPoint]
    let sales: [MarketChartPoint]

    var body: some View {
        if !prices.isEmpty {
            chartTitle("Median price history")

            Chart(prices) { point in
                LineMark(
                    x: .value("Year", point.date),
                    y: .value("Median price", point.value)
                )
                .interpolationMethod(.catmullRom)
                .foregroundStyle(.blue)

                PointMark(
                    x: .value("Year", point.date),
                    y: .value("Median price", point.value)
                )
                .foregroundStyle(.blue)
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let amount = value.as(Double.self) {
                            Text(
                                amount,
                                format: .currency(code: "GBP")
                                    .notation(.compactName)
                                    .precision(.fractionLength(0))
                            )
                        }
                    }
                }
            }
            .frame(height: 190)
            .accessibilityLabel("Median property price by year")

            dateRange(for: prices)
        }

        if !sales.isEmpty {
            chartTitle("Annual sales")

            Chart(sales) { point in
                LineMark(
                    x: .value("Year", point.date),
                    y: .value("Sales", point.value)
                )
                .interpolationMethod(.linear)
                .foregroundStyle(.indigo)

                PointMark(
                    x: .value("Year", point.date),
                    y: .value("Sales", point.value)
                )
                .foregroundStyle(.indigo)
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading)
            }
            .frame(height: 170)
            .accessibilityLabel("Number of property sales by year")

            dateRange(for: sales)
        }
    }

    private func chartTitle(_ title: String) -> some View {
        Text(title)
            .font(.subheadline.weight(.semibold))
    }

    private func dateRange(for points: [MarketChartPoint]) -> some View {
        let firstYear = points.first?.year
        let lastYear = points.last?.year
        let rangeText: String
        let accessibilityText: String

        if let firstYear, let lastYear {
            rangeText = "\(firstYear) – \(lastYear)"
            accessibilityText = "Date range \(firstYear) to \(lastYear)"
        } else {
            rangeText = "Date range unavailable"
            accessibilityText = rangeText
        }

        return Text(rangeText)
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, alignment: .center)
        .accessibilityLabel(accessibilityText)
    }
}

private struct PropertyTypeChart: View {
    let points: [PropertyTypeChartPoint]

    var body: some View {
        Text("Median price by property type")
            .font(.subheadline.weight(.semibold))

        Chart(points) { point in
            BarMark(
                x: .value("Median price", point.value),
                y: .value("Property type", point.label)
            )
            .foregroundStyle(.teal.gradient)
            .annotation(position: .trailing) {
                Text(
                    point.value,
                    format: .currency(code: "GBP")
                        .notation(.compactName)
                        .precision(.fractionLength(0))
                )
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .chartXAxis {
            AxisMarks(position: .bottom) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let amount = value.as(Double.self) {
                        Text(
                            amount,
                            format: .currency(code: "GBP")
                                .notation(.compactName)
                                .precision(.fractionLength(0))
                        )
                    }
                }
            }
        }
        .frame(height: 170)
        .accessibilityLabel("Median price by property type")
    }
}

struct ResearchCard<Content: View>: View {
    let title: String
    let icon: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Label(title, systemImage: icon)
                .font(.title3.bold())
                .foregroundStyle(.blue)

            content
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

struct DetailLine: View {
    let label: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(label)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

struct DeprivationDecileBadge: View {
    let decile: Int

    private var color: Color {
        switch decile {
        case 1...3:
            .red
        case 4...7:
            .orange
        case 8...10:
            .green
        default:
            .secondary
        }
    }

    var body: some View {
        Text("\(decile)/10")
            .font(.caption.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(color.opacity(0.22), lineWidth: 1)
            }
    }
}

struct UnavailableView: View {
    var body: some View {
        Text("Data unavailable")
            .font(.subheadline)
            .foregroundStyle(.secondary)
    }
}

private extension String {
    var humanized: String {
        replacingOccurrences(of: "_", with: " ")
            .split(separator: " ")
            .map { $0.capitalized }
            .joined(separator: " ")
    }
}
