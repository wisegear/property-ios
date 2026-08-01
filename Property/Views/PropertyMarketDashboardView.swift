import Charts
import SwiftUI

struct PropertyMarketDashboardView: View {
    @StateObject private var viewModel: PropertyMarketDashboardViewModel

    init(client: any PropertyResearchAPIClientProtocol) {
        _viewModel = StateObject(
            wrappedValue: PropertyMarketDashboardViewModel(client: client)
        )
    }

    var body: some View {
        Group {
            if let dashboard = viewModel.dashboard {
                dashboardContent(dashboard)
            } else if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Unable to load market data", systemImage: "chart.xyaxis.line")
                } description: {
                    Text(error.message)
                } actions: {
                    if error.canRetry {
                        Button("Try again") {
                            Task { await viewModel.retry() }
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                ProgressView("Loading property market…")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Market Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onDisappear { viewModel.cancel() }
    }

    private func dashboardContent(_ dashboard: PropertyMarketDashboard) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                introduction(dashboard.metadata)
                summaryGrid(dashboard.summary)
                monthlySalesCard(dashboard.monthlySales)
                rollingVolumeCard(dashboard.rollingMarket, metadata: dashboard.metadata)
                priceLadderCard(dashboard.rollingMarket)
                largestSalesCard(dashboard.largestSales)

                if let latestTypes = dashboard.propertyTypes.last {
                    propertyTypesCard(latestTypes)
                }

                if let stock = dashboard.stockMix.last,
                   let tenure = dashboard.tenureMix.last {
                    mixCard(stock: stock, tenure: tenure)
                }

                momentumCard(dashboard.yearOnYear)
                methodology(dashboard.metadata)

                if let websiteURL = URL(string: "https://propertyresearch.uk/property") {
                    Link(destination: websiteURL) {
                        Label(
                            "View full dashboard on PropertyResearch.uk",
                            systemImage: "arrow.up.right"
                        )
                        .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(20)
        }
        .refreshable { await viewModel.refresh() }
    }

    private func introduction(_ metadata: PropertyMarketMetadata) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            ResearchPageHeader(
                eyebrow: "National market",
                title: "England & Wales",
                subtitle: "Sales volumes, prices and market momentum from official Land Registry data.",
                icon: "house.and.flag.fill",
                color: .blue,
                detail: "\(metadata.rollingWindowMonths)-month rolling data through \(monthLabel(metadata.latestMonth))"
            )

            if metadata.isProvisional {
                Label(
                    "Recent Land Registry months are provisional and may be backfilled.",
                    systemImage: "clock.badge.exclamationmark"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }
        }
    }

    private func summaryGrid(_ summary: PropertyMarketSummary) -> some View {
        LazyVGrid(
            columns: [
                GridItem(.flexible(), spacing: 12),
                GridItem(.flexible(), spacing: 12)
            ],
            spacing: 12
        ) {
            MarketMetricCard(
                title: "12-month sales",
                value: summary.sales.map(number) ?? "Unavailable",
                icon: "house.fill",
                color: .blue
            )
            MarketMetricCard(
                title: "Median price",
                value: summary.medianPrice.map(currency) ?? "Unavailable",
                icon: "sterlingsign.circle.fill",
                color: .teal
            )
            MarketMetricCard(
                title: "Price change",
                value: percent(summary.medianPriceChange),
                icon: trendIcon(summary.medianPriceChange),
                color: trendColor(summary.medianPriceChange)
            )
            MarketMetricCard(
                title: "Volume change",
                value: percent(summary.salesVolumeChange),
                icon: trendIcon(summary.salesVolumeChange),
                color: trendColor(summary.salesVolumeChange)
            )
        }
    }

    private func monthlySalesCard(_ values: [PropertyMonthlySales]) -> some View {
        MarketChartCard(
            eyebrow: "NATIONAL TREND",
            title: "Monthly sales",
            subtitle: "Transaction flow over the latest 24 months"
        ) {
            Chart(values) { point in
                BarMark(
                    x: .value("Month", point.period),
                    y: .value("Sales", point.value)
                )
                .foregroundStyle(point.isProvisional ? Color.orange.gradient : Color.blue.gradient)
                .cornerRadius(3)
                .accessibilityLabel(monthLabel(point.period))
                .accessibilityValue(number(point.value))
            }
            .chartXAxis(.hidden)
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisValueLabel(format: Decimal.FormatStyle().notation(.compactName))
                }
            }
            .frame(height: 220)

            periodRangeLabel(values.map(\.period))

            HStack(spacing: 16) {
                ChartLegendItem(label: "Complete", color: .blue)
                ChartLegendItem(label: "Provisional", color: .orange)
            }
        }
    }

    private func rollingVolumeCard(
        _ values: [PropertyRollingMarket],
        metadata: PropertyMarketMetadata
    ) -> some View {
        MarketChartCard(
            eyebrow: "MARKET ACTIVITY",
            title: "Rolling sales volume",
            subtitle: "\(metadata.rollingWindowMonths)-month totals from \(metadata.rangeStart.map(monthLabel) ?? "first available data")"
        ) {
            Chart(values) { point in
                AreaMark(
                    x: .value("Period", point.period),
                    y: .value("Sales", point.sales)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [.green.opacity(0.35), .green.opacity(0.03)],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )

                LineMark(
                    x: .value("Period", point.period),
                    y: .value("Sales", point.sales)
                )
                .foregroundStyle(.green)
                .lineStyle(.init(lineWidth: 3, lineCap: .round, lineJoin: .round))
                .symbol(.circle)
            }
            .marketAxes()
            .frame(height: 220)

            periodRangeLabel(values.map(\.period))
        }
    }

    private func priceLadderCard(_ values: [PropertyRollingMarket]) -> some View {
        let series = values.flatMap { point in
            [
                point.medianPrice.map { MarketSeriesPoint(period: point.period, series: "Median", value: $0) },
                point.percentile90.map { MarketSeriesPoint(period: point.period, series: "90th percentile", value: $0) },
                point.top5Average.map { MarketSeriesPoint(period: point.period, series: "Top 5% average", value: $0) }
            ].compactMap { $0 }
        }

        return MarketChartCard(
            eyebrow: "PRICE LADDER",
            title: "Market price levels",
            subtitle: "Median, 90th percentile and top 5% average"
        ) {
            Chart(series) { point in
                LineMark(
                    x: .value("Period", point.period),
                    y: .value("Price", point.value)
                )
                .foregroundStyle(by: .value("Measure", point.series))
                .lineStyle(.init(lineWidth: 2.5))
                .symbol(by: .value("Measure", point.series))
            }
            .chartForegroundStyleScale([
                "Median": Color.blue,
                "90th percentile": Color.teal,
                "Top 5% average": Color.orange
            ])
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisValueLabel(format: Decimal.FormatStyle.Currency(code: "GBP").notation(.compactName))
                }
            }
            .chartXAxis(.hidden)
            .frame(height: 260)

            periodRangeLabel(series.map(\.period))
        }
    }

    private func largestSalesCard(_ sales: [PropertyLargestSale]) -> some View {
        let latestPeriod = sales.last?.period
        let latest = sales.filter { $0.period == latestPeriod }

        return MarketChartCard(
            eyebrow: "PRIME SIGNALS",
            title: "Largest recorded sales",
            subtitle: latestPeriod.map { "Top three in the rolling year ending \(monthLabel($0))" }
                ?? "No sales available"
        ) {
            ForEach(latest) { sale in
                HStack(spacing: 12) {
                    Text("\(sale.rank)")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(width: 32, height: 32)
                        .background(Color.indigo.gradient)
                        .clipShape(Circle())

                    VStack(alignment: .leading, spacing: 2) {
                        Text(currency(sale.price))
                            .font(.headline)
                        Text(
                            [sale.postcode, DateFormatting.displayDate(sale.date)]
                                .compactMap { $0?.nilIfBlank }
                                .joined(separator: " · ")
                        )
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    }

                    Spacer()
                }
            }
        }
    }

    private func propertyTypesCard(_ types: PropertyTypeMarket) -> some View {
        let values = [
            MarketCategory(name: "Detached", sales: types.detached.sales, median: types.detached.medianPrice, color: .blue),
            MarketCategory(name: "Semi-detached", sales: types.semiDetached.sales, median: types.semiDetached.medianPrice, color: .teal),
            MarketCategory(name: "Terraced", sales: types.terraced.sales, median: types.terraced.medianPrice, color: .orange),
            MarketCategory(name: "Flat", sales: types.flat.sales, median: types.flat.medianPrice, color: .pink),
            MarketCategory(name: "Other", sales: types.other.sales, median: types.other.medianPrice, color: .purple)
        ]

        return MarketChartCard(
            eyebrow: "HOUSING MIX",
            title: "Property types",
            subtitle: "Sales and median price ending \(monthLabel(types.period))"
        ) {
            Chart(values) { item in
                BarMark(
                    x: .value("Sales", item.sales ?? 0),
                    y: .value("Type", item.name)
                )
                .foregroundStyle(item.color.gradient)
                .cornerRadius(4)
            }
            .chartXAxis {
                AxisMarks {
                    AxisGridLine()
                    AxisValueLabel(format: Decimal.FormatStyle().notation(.compactName))
                }
            }
            .frame(height: 190)

            Divider()

            ForEach(values) { item in
                HStack {
                    ChartLegendItem(label: item.name, color: item.color)
                    Spacer()
                    Text(item.median.map(currency) ?? "Unavailable")
                        .font(.subheadline.bold())
                }
            }
        }
    }

    private func mixCard(stock: PropertyStockMix, tenure: PropertyTenureMix) -> some View {
        let stockValues = [
            MarketMixValue(name: "New build", value: stock.newBuild ?? 0, color: .mint),
            MarketMixValue(name: "Existing", value: stock.existing ?? 0, color: .blue)
        ]
        let tenureValues = [
            MarketMixValue(name: "Freehold", value: tenure.freehold ?? 0, color: .green),
            MarketMixValue(name: "Leasehold", value: tenure.leasehold ?? 0, color: .purple)
        ]

        return MarketChartCard(
            eyebrow: "STOCK PROFILE",
            title: "Housing mix",
            subtitle: "Share of rolling 12-month sales"
        ) {
            HStack(alignment: .top, spacing: 12) {
                DonutChart(title: "Build status", values: stockValues)
                DonutChart(title: "Tenure", values: tenureValues)
            }
        }
    }

    private func momentumCard(_ values: [PropertyMarketYearOnYear]) -> some View {
        let latest = Array(values.suffix(12))
        let series = latest.flatMap { point in
            [
                point.sales.map { MarketPercentPoint(period: point.period, series: "Sales", value: $0) },
                point.medianPrice.map { MarketPercentPoint(period: point.period, series: "Median", value: $0) },
                point.percentile90.map { MarketPercentPoint(period: point.period, series: "90th", value: $0) },
                point.top5Average.map { MarketPercentPoint(period: point.period, series: "Top 5%", value: $0) }
            ].compactMap { $0 }
        }

        return MarketChartCard(
            eyebrow: "MOMENTUM",
            title: "Year-on-year change",
            subtitle: "Change between rolling 12-month periods"
        ) {
            Chart(series) { point in
                LineMark(
                    x: .value("Period", point.period),
                    y: .value("Change", point.value)
                )
                .foregroundStyle(by: .value("Measure", point.series))
                .symbol(by: .value("Measure", point.series))

                RuleMark(y: .value("No change", 0))
                    .foregroundStyle(.secondary.opacity(0.35))
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisValueLabel(format: Decimal.FormatStyle.Percent.percent.scale(1))
                }
            }
            .chartXAxis(.hidden)
            .frame(height: 250)

            periodRangeLabel(series.map(\.period))
        }
    }

    private func methodology(_ metadata: PropertyMarketMetadata) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Label("About this data", systemImage: "info.circle.fill")
                .font(.headline)
            Text(
                "Category \(metadata.category) arm’s-length transactions supplied by "
                + "\(metadata.source). Recent periods can change as registrations are backfilled."
            )
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 4)
    }

    private func number(_ value: Int) -> String {
        value.formatted(.number)
    }

    private func currency(_ value: Int) -> String {
        value.formatted(.currency(code: "GBP").precision(.fractionLength(0)))
    }

    private func percent(_ value: Double?) -> String {
        guard let value else { return "Unavailable" }
        let prefix = value > 0 ? "+" : ""
        return "\(prefix)\(value.formatted(.number.precision(.fractionLength(1))))%"
    }

    private func trendColor(_ value: Double?) -> Color {
        guard let value else { return .secondary }
        return value >= 0 ? .green : .red
    }

    private func trendIcon(_ value: Double?) -> String {
        guard let value else { return "minus" }
        return value >= 0 ? "arrow.up.right" : "arrow.down.right"
    }

    private func monthLabel(_ period: String) -> String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "yyyy-MM"
        guard let date = formatter.date(from: period) else { return period }
        formatter.dateFormat = "MMM yyyy"
        return formatter.string(from: date)
    }

    private func periodRangeLabel(_ periods: [String]) -> some View {
        let first = periods.min()
        let last = periods.max()
        let label: String

        if let first, let last {
            label = first == last
                ? monthLabel(first)
                : "\(monthLabel(first))–\(monthLabel(last))"
        } else {
            label = ""
        }

        return Text(label)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
    }
}

private struct MarketMetricCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: icon)
                .foregroundStyle(color)
                .frame(width: 36, height: 36)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))
            Text(value)
                .font(.title3.bold())
                .minimumScaleFactor(0.7)
                .lineLimit(1)
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(15)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct MarketChartCard<Content: View>: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            VStack(alignment: .leading, spacing: 4) {
                Text(eyebrow)
                    .font(.caption2.bold())
                    .tracking(0.8)
                    .foregroundStyle(.blue)
                Text(title)
                    .font(.title3.bold())
                Text(subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            content
        }
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct ChartLegendItem: View {
    let label: String
    let color: Color

    var body: some View {
        Label {
            Text(label)
        } icon: {
            Circle()
                .fill(color)
                .frame(width: 8, height: 8)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

private struct DonutChart: View {
    let title: String
    let values: [MarketMixValue]

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(.subheadline.bold())

            Chart(values) { item in
                SectorMark(
                    angle: .value("Sales", item.value),
                    innerRadius: .ratio(0.62),
                    angularInset: 2
                )
                .foregroundStyle(item.color)
            }
            .frame(height: 130)

            ForEach(values) { item in
                HStack {
                    ChartLegendItem(label: item.name, color: item.color)
                    Spacer()
                    Text(item.value.formatted(.number.notation(.compactName)))
                        .font(.caption.bold())
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}

private struct MarketSeriesPoint: Identifiable {
    let period: String
    let series: String
    let value: Int
    var id: String { "\(period)-\(series)" }
}

private struct MarketPercentPoint: Identifiable {
    let period: String
    let series: String
    let value: Double
    var id: String { "\(period)-\(series)" }
}

private struct MarketCategory: Identifiable {
    let name: String
    let sales: Int?
    let median: Int?
    let color: Color
    var id: String { name }
}

private struct MarketMixValue: Identifiable {
    let name: String
    let value: Int
    let color: Color
    var id: String { name }
}

private extension Chart {
    func marketAxes() -> some View {
        chartXAxis(.hidden)
        .chartYAxis {
            AxisMarks(position: .leading) {
                AxisGridLine()
                AxisValueLabel(format: Decimal.FormatStyle().notation(.compactName))
            }
        }
    }
}
