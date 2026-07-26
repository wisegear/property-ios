import Charts
import SwiftUI

struct CrimeDashboardView: View {
    @StateObject private var viewModel: CrimeDashboardViewModel

    init(client: any PropertyResearchAPIClientProtocol) {
        _viewModel = StateObject(wrappedValue: CrimeDashboardViewModel(client: client))
    }

    var body: some View {
        Group {
            if let dashboard = viewModel.dashboard {
                dashboardContent(dashboard)
            } else if let error = viewModel.error {
                CrimeErrorView(title: "Unable to load crime insights", error: error) {
                    await viewModel.retry()
                }
            } else {
                CrimeLoadingView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("Crime Insights")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onDisappear { viewModel.cancel() }
    }

    private func dashboardContent(_ dashboard: CrimeDashboard) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                CrimeSummaryCard(
                    title: "National crime dashboard",
                    latestMonth: dashboard.latestMonthLabel,
                    summary: dashboard.summary
                )
                CrimeTrendCard(chart: dashboard.chart)
                CrimeDriversCard(drivers: dashboard.drivers)
                crimeTypes(dashboard.crimeTypes)
                areas(dashboard.areas)

                if let websiteURL = dashboard.websiteURL.flatMap(URL.init(string:)) {
                    Link(destination: websiteURL) {
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

    private func crimeTypes(_ types: [CrimeTypeSummary]) -> some View {
        ResearchCard(title: "Crime composition", icon: "chart.bar.fill") {
            if types.isEmpty {
                UnavailableView()
            } else {
                ForEach(types) { type in
                    CrimeBreakdownRow(
                        title: type.type,
                        total: type.total12Months,
                        change: type.yearOnYearChange,
                        share: type.sharePercentage
                    )
                    if type.id != types.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private func areas(_ areas: [CrimeAreaSummary]) -> some View {
        ResearchCard(title: "Regional crime", icon: "map.fill") {
            if areas.isEmpty {
                UnavailableView()
            } else {
                ForEach(areas) { area in
                    if let apiURL = area.apiURL.flatMap(URL.init(string:)) {
                        NavigationLink {
                            CrimeAreaView(apiURL: apiURL, client: viewModel.client)
                        } label: {
                            areaRow(area, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        areaRow(area, showsChevron: false)
                    }

                    if area.id != areas.last?.id {
                        Divider()
                    }
                }
            }
        }
    }

    private func areaRow(_ area: CrimeAreaSummary, showsChevron: Bool) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(area.area)
                    .font(.headline)
                Text("\(area.total12Months.formatted()) crimes · \(CrimeFormatting.change(area.percentageChange))")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            if showsChevron {
                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
        }
        .contentShape(Rectangle())
    }
}

struct CrimeAreaView: View {
    @StateObject private var viewModel: CrimeAreaViewModel

    init(apiURL: URL, client: any PropertyResearchAPIClientProtocol) {
        _viewModel = StateObject(
            wrappedValue: CrimeAreaViewModel(apiURL: apiURL, client: client)
        )
    }

    var body: some View {
        Group {
            if let area = viewModel.area {
                areaContent(area)
            } else if let error = viewModel.error {
                CrimeErrorView(title: "Unable to load area", error: error) {
                    await viewModel.retry()
                }
            } else {
                CrimeLoadingView()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(viewModel.area?.area ?? "Regional Crime")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onDisappear { viewModel.cancel() }
    }

    private func areaContent(_ area: CrimeAreaDetail) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                CrimeSummaryCard(
                    title: area.area ?? "Regional crime",
                    latestMonth: area.latestMonthLabel,
                    summary: area.summary
                )
                CrimeTrendCard(chart: area.chart)
                CrimeDriversCard(drivers: area.drivers)
                breakdown(area.crimeBreakdown)

                if let websiteURL = area.websiteURL.flatMap(URL.init(string:)) {
                    Link(destination: websiteURL) {
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

    private func breakdown(_ values: [CrimeAreaBreakdown]) -> some View {
        ResearchCard(title: "Crime breakdown", icon: "chart.bar.fill") {
            if values.isEmpty {
                UnavailableView()
            } else {
                ForEach(values) { value in
                    CrimeBreakdownRow(
                        title: value.type,
                        total: value.total12Months,
                        change: value.yearOnYearChange,
                        share: value.sharePercentage
                    )
                    if value.id != values.last?.id {
                        Divider()
                    }
                }
            }
        }
    }
}

private struct CrimeSummaryCard: View {
    let title: String
    let latestMonth: String?
    let summary: CrimePeriodSummary

    var body: some View {
        ResearchCard(title: title, icon: "shield.lefthalf.filled") {
            if let latestMonth {
                Text("Latest data: \(latestMonth)")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            HStack(spacing: 10) {
                metric("12-month total", summary.total12Months.formatted())
                metric("Year-on-year", CrimeFormatting.change(summary.percentageChange))
            }
            HStack(spacing: 10) {
                metric("Last 3 months", summary.last3MonthsTotal.formatted())
                metric("3-month change", CrimeFormatting.change(summary.last3MonthsChange))
            }
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.title3.bold())
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

private struct CrimeTrendCard: View {
    let chart: CrimeChart

    var body: some View {
        ResearchCard(title: "Monthly trend", icon: "chart.xyaxis.line") {
            if chart.points.isEmpty {
                UnavailableView()
            } else {
                Chart(chart.points) { point in
                    LineMark(
                        x: .value("Month", point.index),
                        y: .value("Crime", point.value)
                    )
                    .foregroundStyle(by: .value("Period", point.series))
                    .interpolationMethod(.catmullRom)
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: 2)) { value in
                        AxisGridLine()
                        AxisTick()
                        AxisValueLabel {
                            if let index = value.as(Int.self),
                               chart.labels.indices.contains(index) {
                                Text(chart.labels[index])
                            }
                        }
                    }
                }
                .frame(height: 220)
            }
        }
    }
}

private struct CrimeDriversCard: View {
    let drivers: CrimeDrivers

    var body: some View {
        ResearchCard(title: "What’s driving change", icon: "arrow.up.arrow.down") {
            driverGroup("Increases", values: drivers.increases, color: .red)
            driverGroup("Decreases", values: drivers.decreases, color: .green)
        }
    }

    @ViewBuilder
    private func driverGroup(_ title: String, values: [CrimeDriver], color: Color) -> some View {
        if !values.isEmpty {
            Text(title)
                .font(.subheadline.bold())
                .foregroundStyle(color)
            ForEach(values) { driver in
                DetailLine(
                    label: driver.type,
                    value: CrimeFormatting.change(driver.yearOnYearChange)
                )
            }
        }
    }
}

private struct CrimeBreakdownRow: View {
    let title: String
    let total: Int
    let change: Double
    let share: Double

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack {
                Text(title)
                    .font(.headline)
                Spacer()
                Text(total.formatted())
                    .font(.subheadline.bold())
            }
            ProgressView(value: min(max(share, 0), 100), total: 100)
                .tint(.orange)
            Text("\(share.formatted(.number.precision(.fractionLength(1))))% of crime · \(CrimeFormatting.change(change)) YoY")
                .font(.caption)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CrimeLoadingView: View {
    var body: some View {
        VStack(spacing: 14) {
            ProgressView()
                .controlSize(.large)
            Text("Loading crime insights…")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

private struct CrimeErrorView: View {
    let title: String
    let error: APIError
    let retry: () async -> Void

    var body: some View {
        ContentUnavailableView {
            Label(title, systemImage: "shield.slash.fill")
        } description: {
            Text(error.message)
        } actions: {
            if error.canRetry {
                Button("Try again") {
                    Task { await retry() }
                }
                .buttonStyle(.borderedProminent)
            }
        }
    }
}

private enum CrimeFormatting {
    nonisolated static func change(_ value: Double) -> String {
        let prefix = value > 0 ? "+" : ""
        return "\(prefix)\(value.formatted(.number.precision(.fractionLength(1))))%"
    }
}
