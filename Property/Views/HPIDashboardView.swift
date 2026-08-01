import Charts
import SwiftUI

struct HPIDashboardView: View {
    @StateObject private var viewModel: HPIDashboardViewModel

    init(client: any PropertyResearchAPIClientProtocol) {
        _viewModel = StateObject(wrappedValue: HPIDashboardViewModel(client: client))
    }

    var body: some View {
        Group {
            if let dashboard = viewModel.dashboard {
                dashboardContent(dashboard)
            } else if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Unable to load HPI", systemImage: "house.slash.fill")
                } description: {
                    Text(error.message)
                } actions: {
                    if error.canRetry {
                        Button("Try again") { Task { await viewModel.retry() } }
                            .buttonStyle(.borderedProminent)
                    }
                }
            } else {
                ProgressView("Loading House Price Index…")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("House Price Index")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onDisappear { viewModel.cancel() }
    }

    private func dashboardContent(_ dashboard: HPIDashboard) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ResearchPageHeader(
                    eyebrow: "Official house prices",
                    title: dashboard.title,
                    subtitle: dashboard.description,
                    icon: "house.and.flag.fill",
                    color: .mint,
                    detail: "Latest data: \(HPIDateParser.display(dashboard.latestDate))"
                )

                nationCards(dashboard.nations)
                HPIAnnualChangeCard(series: dashboard.annualChangeSeries)
                HPIPropertyTypesCard(series: dashboard.propertyTypeSeries)
                HPIMoversCard(movers: dashboard.movers, losers: dashboard.losers)

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

    private func nationCards(_ nations: [HPINationSnapshot]) -> some View {
        ResearchCard(title: "UK and nations", icon: "map.fill") {
            if nations.isEmpty {
                Text("HPI data is not available yet.").foregroundStyle(.secondary)
            } else {
                ForEach(nations) { nation in
                    VStack(alignment: .leading, spacing: 6) {
                        HStack(alignment: .firstTextBaseline) {
                            Text(nation.name).font(.headline)
                            Spacer()
                            Text(HPIFormatting.currency(nation.averagePrice))
                                .font(.title3.bold())
                        }
                        HStack {
                            Text("12m change")
                            Spacer()
                            Text(HPIFormatting.percentage(nation.twelveMonthChange))
                                .fontWeight(.semibold)
                                .foregroundStyle(HPIFormatting.changeColor(nation.twelveMonthChange))
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }
                    if nation.id != nations.last?.id { Divider() }
                }
            }
        }
    }
}

private struct HPIAnnualChangeCard: View {
    let series: [HPIAnnualSeries]
    @State private var selectedCode = "K02000001"

    var body: some View {
        ResearchCard(title: "12-Month Change by Nation & UK", icon: "chart.xyaxis.line") {
            if series.isEmpty {
                unavailable
            } else {
                Picker("Area", selection: $selectedCode) {
                    ForEach(series) { Text($0.name).tag($0.code) }
                }
                .pickerStyle(.menu)

                let points = selected?.annualPoints ?? []
                if points.isEmpty {
                    unavailable
                } else {
                    Chart(points) { point in
                        LineMark(x: .value("Year", point.date), y: .value("12-month change", point.value))
                            .foregroundStyle(point.value >= 0 ? .green : .red)
                        PointMark(x: .value("Year", point.date), y: .value("12-month change", point.value))
                            .foregroundStyle(point.value >= 0 ? .green : .red)
                        RuleMark(y: .value("Zero", 0))
                            .foregroundStyle(.secondary.opacity(0.4))
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let number = value.as(Double.self) {
                                    Text("\(number.formatted(.number.precision(.fractionLength(0))))%")
                                }
                            }
                        }
                    }
                    .frame(height: 260)
                }
                Text("Annual points showing the change in average house prices.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var selected: HPIAnnualSeries? {
        series.first(where: { $0.code == selectedCode }) ?? series.first
    }

    private var unavailable: some View {
        Text("Annual change data is not available yet.").foregroundStyle(.secondary)
    }
}

private struct HPIPropertyTypesCard: View {
    let series: [HPIPropertyTypeSeries]
    @State private var selectedCode = "K02000001"
    @State private var selectedType: HPIPropertyTypeSelection = .all

    var body: some View {
        ResearchCard(title: "Property Type – Average Price", icon: "house.lodge.fill") {
            if series.isEmpty {
                unavailable
            } else {
                Picker("Area", selection: $selectedCode) {
                    ForEach(series) { Text($0.name).tag($0.code) }
                }
                .pickerStyle(.menu)
                Picker("Property type", selection: $selectedType) {
                    ForEach(HPIPropertyTypeSelection.allCases) { Text($0.rawValue).tag($0) }
                }
                .pickerStyle(.segmented)

                let points = selected?.points(for: selectedType) ?? []
                if points.isEmpty {
                    unavailable
                } else {
                    Chart(points) { point in
                        LineMark(x: .value("Date", point.date), y: .value("Average price", point.value))
                            .foregroundStyle(by: .value("Type", point.series))
                            .interpolationMethod(.catmullRom)
                    }
                    .chartYAxis {
                        AxisMarks { value in
                            AxisGridLine()
                            AxisValueLabel {
                                if let number = value.as(Double.self) {
                                    Text(number, format: .currency(code: "GBP").precision(.fractionLength(0)))
                                }
                            }
                        }
                    }
                    .frame(height: 280)
                }
                Text("Recording start dates differ by nation; the UK series begins when comparable data is available for all nations.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var selected: HPIPropertyTypeSeries? {
        series.first(where: { $0.code == selectedCode }) ?? series.first
    }

    private var unavailable: some View {
        Text("Property-type data is not available yet.").foregroundStyle(.secondary)
    }
}

private struct HPIMoversCard: View {
    enum ListType: String, CaseIterable, Identifiable {
        case movers = "Movers"
        case losers = "Losers"
        var id: String { rawValue }
    }

    let movers: [HPIRegionChange]
    let losers: [HPIRegionChange]
    @State private var listType: ListType = .movers

    var body: some View {
        ResearchCard(title: "Top Movers & Losers", icon: "arrow.up.arrow.down") {
            Picker("List", selection: $listType) {
                ForEach(ListType.allCases) { Text($0.rawValue).tag($0) }
            }
            .pickerStyle(.segmented)

            if values.isEmpty {
                Text("Regional movement data is not available yet.").foregroundStyle(.secondary)
            } else {
                ForEach(Array(values.enumerated()), id: \.element.id) { index, region in
                    HStack {
                        Text("\(index + 1)")
                            .font(.caption.monospacedDigit())
                            .foregroundStyle(.secondary)
                            .frame(width: 22, alignment: .leading)
                        VStack(alignment: .leading, spacing: 3) {
                            Text(region.name).font(.subheadline.bold())
                            Text(HPIFormatting.currency(region.averagePrice))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                        Text(HPIFormatting.percentage(region.twelveMonthChange))
                            .font(.subheadline.bold())
                            .foregroundStyle(HPIFormatting.changeColor(region.twelveMonthChange))
                    }
                    if region.id != values.last?.id { Divider() }
                }
            }
            Text("Top 30 regions by 12-month price change in the latest month.")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }

    private var values: [HPIRegionChange] {
        listType == .movers ? movers : losers
    }
}

private enum HPIFormatting {
    nonisolated static func currency(_ value: Double?) -> String {
        guard let value else { return "—" }
        return value.formatted(.currency(code: "GBP").precision(.fractionLength(0)))
    }

    nonisolated static func percentage(_ value: Double?) -> String {
        guard let value else { return "—" }
        let prefix = value > 0 ? "+" : ""
        return "\(prefix)\(value.formatted(.number.precision(.fractionLength(2))))%"
    }

    static func changeColor(_ value: Double?) -> Color {
        guard let value else { return .secondary }
        if value > 0 { return .green }
        if value < 0 { return .red }
        return .secondary
    }
}
