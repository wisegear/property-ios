import Charts
import SwiftUI

struct SwapRatesView: View {
    @StateObject private var viewModel: SwapRatesViewModel

    init(client: any PropertyResearchAPIClientProtocol) {
        _viewModel = StateObject(wrappedValue: SwapRatesViewModel(client: client))
    }

    var body: some View {
        Group {
            if let dashboard = viewModel.dashboard {
                content(dashboard)
            } else if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Unable to load swap rates", systemImage: "chart.line.downtrend.xyaxis")
                } description: {
                    Text(error.message)
                } actions: {
                    if error.canRetry {
                        Button("Try again") { Task { await viewModel.retry() } }
                            .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                ProgressView("Loading swap rates…")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Swap Rates")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onDisappear { viewModel.cancel() }
    }

    private func content(_ dashboard: SwapRatesDashboard) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                header(dashboard)

                if let summary = dashboard.mortgageMarketSummary {
                    marketSummary(summary, movement: dashboard.latestMovementSummary)
                }

                ForEach(dashboard.rates) { rate in
                    SwapRateCard(rate: rate)
                }

                contentSection(dashboard.mortgageContext, icon: "house.fill")
                contentSection(dashboard.understandingSwaps, icon: "banknote.fill")
                SwapChartCard(title: "UK swap rates over time", chart: dashboard.rateChart, allowsRangeSelection: true)

                if let comparison = dashboard.bankRateComparisonChart {
                    SwapChartCard(title: "Bank Rate vs swap rates", chart: comparison, allowsRangeSelection: false)
                }

                currentRates(dashboard.currentRates, updateNote: dashboard.updateNote)
                faq(dashboard.faq)

                if let url = dashboard.websiteURL.flatMap(URL.init(string:)) {
                    Link(destination: url) {
                        Label("View on PropertyResearch.uk", systemImage: "arrow.up.right")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .controlSize(.large)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func header(_ dashboard: SwapRatesDashboard) -> some View {
        ResearchPageHeader(
            eyebrow: "Mortgage pricing signals",
            title: dashboard.title,
            subtitle: dashboard.description,
            icon: "arrow.left.arrow.right",
            color: .teal,
            detail: "Latest available: \(SwapDateParser.display(dashboard.latestAvailableDate))"
        )
    }

    private func marketSummary(
        _ summary: SwapMarketSummary,
        movement: SwapMovementSummary?
    ) -> some View {
        ResearchCard(title: "Mortgage Market Summary", icon: "gauge.with.dots.needle.50percent") {
            HStack {
                Text("Overall signal")
                    .foregroundStyle(.secondary)
                Spacer()
                Text(summary.signal)
                    .font(.headline)
                    .foregroundStyle(signalColor(summary.signalDirection))
            }
            if let movement {
                Text(movement.text)
                    .font(.subheadline.bold())
            }
            Text(summary.explanation)
                .foregroundStyle(.secondary)
        }
    }

    private func contentSection(_ section: SwapContentSection, icon: String) -> some View {
        ResearchCard(title: section.title, icon: icon) {
            ForEach(Array(section.paragraphs.enumerated()), id: \.offset) { _, paragraph in
                Text(paragraph)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func currentRates(_ rates: [CurrentSwapRate], updateNote: String) -> some View {
        ResearchCard(title: "Current UK Swap Rates", icon: "tablecells") {
            if rates.isEmpty {
                Text("Current rates are not available yet.")
                    .foregroundStyle(.secondary)
            } else {
                ForEach(rates) { rate in
                    VStack(alignment: .leading, spacing: 7) {
                        HStack {
                            Text(rate.term).font(.headline)
                            Spacer()
                            Text(SwapFormatting.rate(rate.rate)).font(.headline)
                        }
                        HStack {
                            Text("Latest: \(SwapFormatting.basisPoints(rate.dailyChange))")
                            Spacer()
                            Text("5 day: \(SwapFormatting.basisPoints(rate.fiveDayChange))")
                        }
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        Text("As at \(SwapDateParser.display(rate.rateDate))")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    if rate.id != rates.last?.id { Divider() }
                }
            }
            Text(updateNote)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private func faq(_ items: [SwapFAQ]) -> some View {
        ResearchCard(title: "Swap rate questions", icon: "questionmark.circle.fill") {
            ForEach(items) { item in
                DisclosureGroup(item.question) {
                    Text(item.answer)
                        .foregroundStyle(.secondary)
                        .padding(.top, 8)
                }
                if item.id != items.last?.id { Divider() }
            }
        }
    }

    private func signalColor(_ direction: String) -> Color {
        switch direction {
        case "improving": .green
        case "worsening": .red
        default: .orange
        }
    }
}

private struct SwapRateCard: View {
    let rate: SwapRateSnapshot

    var body: some View {
        ResearchCard(title: rate.label, icon: "percent") {
            HStack(alignment: .firstTextBaseline) {
                Text(SwapFormatting.rate(rate.latestRate))
                    .font(.largeTitle.bold())
                Spacer()
                if let trend = rate.trend {
                    Text(trend.label)
                        .font(.caption.bold())
                        .foregroundStyle(trendColor(trend.direction))
                }
            }
            HStack {
                metric("Latest move", SwapFormatting.basisPoints(rate.latestMovement))
                metric("5-day change", SwapFormatting.points(rate.fiveDayChange))
            }
            if !rate.sparkline.isEmpty {
                Chart(Array(rate.sparkline.enumerated()), id: \.offset) { index, value in
                    LineMark(x: .value("Point", index), y: .value("Rate", value))
                        .interpolationMethod(.catmullRom)
                        .foregroundStyle(.teal)
                    AreaMark(x: .value("Point", index), y: .value("Rate", value))
                        .foregroundStyle(.teal.opacity(0.12))
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 70)
            }
            HStack {
                Text("52 week range")
                Spacer()
                Text("\(SwapFormatting.rate(rate.range52Week.low)) – \(SwapFormatting.rate(rate.range52Week.high))")
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            Text("As at \(SwapDateParser.display(rate.latestRateDate))")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(value).font(.headline)
            Text(label).font(.caption).foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(10)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 11))
    }

    private func trendColor(_ direction: String) -> Color {
        switch direction {
        case "falling": .green
        case "rising": .red
        default: .secondary
        }
    }
}

private struct SwapChartCard: View {
    enum RangeOption: String, CaseIterable, Identifiable {
        case oneYear = "1Y"
        case fiveYears = "5Y"
        case tenYears = "10Y"
        case all = "All"

        var id: String { rawValue }
        var years: Int? {
            switch self {
            case .oneYear: 1
            case .fiveYears: 5
            case .tenYears: 10
            case .all: nil
            }
        }
    }

    let title: String
    let chart: SwapRateChart
    let allowsRangeSelection: Bool
    @State private var range: RangeOption = .fiveYears

    var body: some View {
        ResearchCard(title: title, icon: "chart.xyaxis.line") {
            if allowsRangeSelection {
                Picker("Chart range", selection: $range) {
                    ForEach(RangeOption.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            let points = chart.points(since: cutoff)
            if points.isEmpty {
                Text("Chart data is not available yet.")
                    .foregroundStyle(.secondary)
            } else {
                Chart(points) { point in
                    LineMark(
                        x: .value("Date", point.date),
                        y: .value("Percent per annum", point.value)
                    )
                    .foregroundStyle(by: .value("Series", point.series))
                    .interpolationMethod(.linear)
                }
                .chartYAxis {
                    AxisMarks { value in
                        AxisGridLine()
                        AxisValueLabel {
                            if let rate = value.as(Double.self) {
                                Text("\(rate.formatted(.number.precision(.fractionLength(1))))%")
                            }
                        }
                    }
                }
                .frame(height: 260)
            }
        }
    }

    private var cutoff: Date? {
        guard allowsRangeSelection, let years = range.years else { return nil }
        return Calendar.current.date(byAdding: .year, value: -years, to: Date())
    }
}

private enum SwapFormatting {
    nonisolated static func rate(_ value: Double?) -> String {
        guard let value else { return "—" }
        return "\(value.formatted(.number.precision(.fractionLength(2))))%"
    }

    nonisolated static func basisPoints(_ value: Double?) -> String {
        guard let value else { return "—" }
        let basisPoints = value * 100
        let prefix = basisPoints > 0 ? "+" : ""
        return "\(prefix)\(basisPoints.formatted(.number.precision(.fractionLength(1)))) bps"
    }

    nonisolated static func points(_ value: Double?) -> String {
        guard let value else { return "—" }
        let prefix = value > 0 ? "+" : ""
        return "\(prefix)\(value.formatted(.number.precision(.fractionLength(2)))) pts"
    }
}
