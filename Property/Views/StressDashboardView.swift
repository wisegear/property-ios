import SwiftUI

struct StressDashboardView: View {
    @StateObject private var viewModel: StressDashboardViewModel

    init(client: any PropertyResearchAPIClientProtocol) {
        _viewModel = StateObject(
            wrappedValue: StressDashboardViewModel(client: client)
        )
    }

    var body: some View {
        Group {
            if let dashboard = viewModel.dashboard {
                dashboardContent(dashboard)
            } else if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Unable to load stress indicators", systemImage: "gauge.with.dots.needle.67percent")
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
                ProgressView("Loading stress dashboard…")
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Stress Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onDisappear { viewModel.cancel() }
    }

    private func dashboardContent(_ dashboard: StressDashboard) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                introduction(dashboard)
                scoreCard(dashboard.score)

                SectionHeader(
                    title: "Stress indicators",
                    subtitle: "The eight signals used to calculate the index"
                )

                ForEach(dashboard.indicators) { indicator in
                    indicatorCard(indicator)
                }

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
    }

    private func introduction(_ dashboard: StressDashboard) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("UK PROPERTY MARKET", systemImage: "chart.line.uptrend.xyaxis")
                .font(.caption.bold())
                .tracking(1)
                .foregroundStyle(.blue)

            Text("Property Market Stress")
                .font(.largeTitle.bold())

            Text(dashboard.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            if let lastUpdated = dashboard.lastUpdated {
                Text("Last updated: \(lastUpdated)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func scoreCard(_ score: StressScore) -> some View {
        let color = color(for: score.status)

        return ResearchCard(title: "Overall stress index", icon: "gauge.with.dots.needle.67percent") {
            HStack(spacing: 20) {
                ZStack {
                    Circle()
                        .stroke(color.opacity(0.15), lineWidth: 12)

                    Circle()
                        .trim(
                            from: 0,
                            to: min(
                                max(Double(score.value) / Double(max(score.maximum, 1)), 0),
                                1
                            )
                        )
                        .stroke(
                            color,
                            style: StrokeStyle(lineWidth: 12, lineCap: .round)
                        )
                        .rotationEffect(.degrees(-90))

                    VStack(spacing: 0) {
                        Text(score.value.formatted())
                            .font(.title.bold())
                        Text("/ \(score.maximum)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 108, height: 108)

                VStack(alignment: .leading, spacing: 7) {
                    Text(score.statusLabel)
                        .font(.title3.bold())
                        .foregroundStyle(color)
                    Text(score.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("Raw score: \(score.rawValue)/\(score.rawMaximum)")
                        .font(.caption.bold())
                }
            }
        }
    }

    private func indicatorCard(_ indicator: StressIndicator) -> some View {
        let color = color(for: indicator.status)

        return ResearchCard(
            title: indicator.title,
            icon: icon(for: indicator.key)
        ) {
            HStack(alignment: .firstTextBaseline) {
                Text(formattedValue(indicator))
                    .font(.title2.bold())

                Spacer()

                Text(indicator.statusLabel)
                    .font(.caption.bold())
                    .foregroundStyle(color)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(color.opacity(0.12))
                    .clipShape(Capsule())
            }

            if indicator.key == "wage_growth",
               let realGrowth = indicator.secondaryValue {
                Text("Real wage growth: \(formatted(realGrowth, unit: "percent"))")
                    .font(.subheadline.bold())
            }

            if let period = indicator.period {
                Text(period)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Text(indicator.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Label(
                    "\(indicator.badStreak) bad \(indicator.badStreak == 1 ? "period" : "periods")",
                    systemImage: "clock.arrow.circlepath"
                )
                Spacer()
                Text("Score \(indicator.score)/\(indicator.maximumScore)")
            }
            .font(.caption)
            .foregroundStyle(.secondary)

            if let websiteURL = indicator.websiteURL.flatMap(URL.init(string:)) {
                Link("More information", destination: websiteURL)
                    .font(.subheadline.bold())
            }
        }
    }

    private func formattedValue(_ indicator: StressIndicator) -> String {
        guard let value = indicator.value else {
            return "Data unavailable"
        }
        return formatted(value, unit: indicator.unit)
    }

    private func formatted(_ value: Double, unit: String) -> String {
        switch unit {
        case "GBP":
            return value.formatted(
                .currency(code: "GBP").precision(.fractionLength(0))
            )
        case "percent":
            return "\(value.formatted(.number.precision(.fractionLength(1...3))))%"
        case "approvals":
            return value.formatted(.number.precision(.fractionLength(0)))
        default:
            return value.formatted()
        }
    }

    private func color(for status: StressStatus) -> Color {
        switch status {
        case .low:
            return .green
        case .amber:
            return .orange
        case .red:
            return .red
        case .darkRed:
            return Color(red: 0.55, green: 0.04, blue: 0.08)
        }
    }

    private func icon(for key: String) -> String {
        switch key {
        case "mortgage_approvals": return "checkmark.seal.fill"
        case "house_price_index": return "house.fill"
        case "interest_rates": return "percent"
        case "inflation": return "cart.fill"
        case "wage_growth": return "sterlingsign.circle.fill"
        case "unemployment": return "person.2.slash.fill"
        case "mortgage_arrears": return "exclamationmark.house.fill"
        case "repossessions": return "key.slash.fill"
        default: return "chart.bar.fill"
        }
    }
}
