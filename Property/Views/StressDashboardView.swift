import SwiftUI

struct StressDashboardView: View {
    @StateObject private var viewModel: StressDashboardViewModel

    init(
        client: any PropertyResearchAPIClientProtocol,
        dashboard: StressDashboard? = nil
    ) {
        _viewModel = StateObject(
            wrappedValue: StressDashboardViewModel(client: client, dashboard: dashboard)
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
                statusSummary(dashboard)

                ResearchCard(title: "How statuses work", icon: "info.circle.fill") {
                    Text("Positive means the latest movement improved. Neutral means it was unchanged. Warning means one or two consecutive adverse releases, and Stress means three or more.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)

                    Text("Lower Bank Rate, inflation, unemployment, mortgage arrears and repossessions are positive. Higher mortgage approvals, house prices and wage growth are positive.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

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

    private func statusSummary(_ dashboard: StressDashboard) -> some View {
        let columns = Array(repeating: GridItem(.flexible(), spacing: 10), count: 2)

        return LazyVGrid(columns: columns, spacing: 10) {
            ForEach(StressStatus.allCases, id: \.self) { status in
                VStack(alignment: .leading, spacing: 4) {
                    Text(status.label)
                        .font(.caption.bold())
                        .foregroundStyle(color(for: status))
                    Text(dashboard.statusCounts[status, default: 0].formatted())
                        .font(.title2.bold())
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(12)
                .background(color(for: status).opacity(0.1))
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel("Indicator status summary")
    }

    private func introduction(_ dashboard: StressDashboard) -> some View {
        ResearchPageHeader(
            eyebrow: "UK property market",
            title: "Property Market Stress",
            subtitle: dashboard.description,
            icon: "gauge.with.dots.needle.67percent",
            color: .red,
            detail: dashboard.lastUpdated.map { "Last updated: \($0)" }
        )
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
                    Text(displayLabel(for: score))
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

                Text(indicator.status.label)
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

            if indicator.key == "interest_rates" {
                Text(bankRateMovement(for: indicator.status))
                    .font(.subheadline.bold())
            }

            Text(indicator.description)
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack {
                Label(
                    adverseReleaseText(for: indicator),
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

    private func adverseReleaseText(for indicator: StressIndicator) -> String {
        switch indicator.status {
        case .positive:
            return "Latest release improved"
        case .neutral:
            return "Latest release unchanged"
        case .warning, .stress:
            return "\(indicator.badStreak) adverse \(indicator.badStreak == 1 ? "release" : "releases")"
        }
    }

    private func bankRateMovement(for status: StressStatus) -> String {
        switch status {
        case .positive:
            return "Bank rate is lower than it was last month."
        case .neutral:
            return "Bank rate is unchanged from last month."
        case .warning, .stress:
            return "Bank rate is higher than it was last month."
        }
    }

    private func displayLabel(for score: StressScore) -> String {
        let legacyLabels = ["potential stress", "potential_stress"]
        return legacyLabels.contains(score.statusLabel.lowercased())
            ? StressStatus.warning.label
            : score.statusLabel
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
        case .positive:
            return .green
        case .neutral:
            return .orange
        case .warning:
            return Color(red: 0.82, green: 0.25, blue: 0.12)
        case .stress:
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

private extension StressDashboard {
    static let previewFixture = StressDashboard(
        title: "PropertyResearch Stress Indicators Dashboard",
        description: "Eight indicators combining housing demand, prices, borrowing costs, household finances and forced-sale pressure.",
        lastUpdated: "30 Jun 2026",
        score: StressScore(
            value: 42,
            maximum: 100,
            rawValue: 10,
            rawMaximum: 24,
            status: .neutral,
            statusLabel: "Elevated risk",
            description: "A single score combining all eight indicators. Higher scores mean more stress and risk."
        ),
        indicators: [
            fixture("mortgage_approvals", "Mortgage approvals", 67_250, "approvals", .positive, 0, 0),
            fixture("house_price_index", "House prices (UK average)", 292_000, "GBP", .warning, 2, 2),
            fixture("interest_rates", "Bank rate", 4.25, "percent", .neutral, 1, 0, period: "Effective since 18 Jun 2026"),
            fixture("inflation", "Inflation", 3.5, "percent", .stress, 3, 3),
            fixture("wage_growth", "Wage growth", 4.2, "percent", .positive, 0, 0, secondaryValue: 1.1),
            fixture("unemployment", "Unemployment", 4.8, "percent", .warning, 2, 1),
            fixture("mortgage_arrears", "Mortgage arrears", 1.21, "percent", .neutral, 1, 0, period: "Q2 2026"),
            fixture("repossessions", "Repossessions", 0.1, "percent", .stress, 3, 4, period: "Q2 2026"),
        ],
        websiteURL: "https://propertyresearch.uk/economic-dashboard"
    )

    static func fixture(
        _ key: String,
        _ title: String,
        _ value: Double,
        _ unit: String,
        _ status: StressStatus,
        _ score: Int,
        _ badStreak: Int,
        period: String = "Jun 2026",
        secondaryValue: Double? = nil
    ) -> StressIndicator {
        StressIndicator(
            key: key,
            title: title,
            description: "The latest published figure and its recent direction contribute to the overall stress index.",
            value: value,
            secondaryValue: secondaryValue,
            unit: unit,
            period: period,
            badStreak: badStreak,
            status: status,
            statusLabel: status.label,
            score: score,
            maximumScore: 3,
            apiURL: nil,
            websiteURL: nil
        )
    }
}

struct StressDashboardView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationStack {
            StressDashboardView(
                client: PropertyResearchAPIClient(),
                dashboard: .previewFixture
            )
        }
        .previewDisplayName("Revised stress dashboard")
    }
}
