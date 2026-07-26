import Charts
import SwiftUI

struct EPCDashboardView: View {
    @StateObject private var viewModel: EPCDashboardViewModel
    @State private var nation: EPCNation = .englandWales
    @State private var postcode = ""
    @State private var showsSearchResults = false
    @FocusState private var postcodeIsFocused: Bool

    init(client: any PropertyResearchAPIClientProtocol) {
        _viewModel = StateObject(wrappedValue: EPCDashboardViewModel(client: client))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                header
                nationPicker
                searchPanel

                if viewModel.isLoadingDashboard {
                    ProgressView("Loading EPC dashboard…")
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 32)
                } else if let dashboard = viewModel.dashboard {
                    statistics(dashboard)
                    certificatesChart(dashboard.certificatesByYear)
                    ratingsChart(
                        title: "Current energy ratings",
                        values: dashboard.ratingDistribution
                    )

                    if let websiteURL = dashboard.websiteURL.flatMap(URL.init(string:)) {
                        Link(destination: websiteURL) {
                            Label("View dashboard on PropertyResearch.uk", systemImage: "arrow.up.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .controlSize(.large)
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("EPC Dashboard")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(isPresented: $showsSearchResults) {
            EPCSearchResultsView(viewModel: viewModel, nation: nation)
        }
        .task(id: nation) {
            await viewModel.loadDashboard(nation: nation)
        }
        .onDisappear { viewModel.cancel() }
    }

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label("ENERGY PERFORMANCE", systemImage: "leaf.fill")
                .font(.caption.bold())
                .tracking(1.1)
                .foregroundStyle(.green)
            Text("EPC dashboard")
                .font(.title.bold())
            Text("Explore certificate trends and search for an individual property by postcode.")
                .foregroundStyle(.secondary)
        }
    }

    private var nationPicker: some View {
        Picker("Nation", selection: $nation) {
            ForEach(EPCNation.allCases) { nation in
                Text(nation.label).tag(nation)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: nation) {
            postcode = ""
            viewModel.dismissError()
        }
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Search \(nation.label)")
                .font(.headline)

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(.secondary)
                TextField("Enter full postcode", text: $postcode)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .textContentType(.postalCode)
                    .submitLabel(.search)
                    .focused($postcodeIsFocused)
                    .onSubmit(startSearch)
                    .disabled(viewModel.isSearching)

                if !postcode.isEmpty && !viewModel.isSearching {
                    Button {
                        postcode = ""
                        viewModel.dismissError()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(15)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            if let error = viewModel.error {
                ErrorMessageView(error: error) {
                    startSearch()
                }
            }

            Button(action: startSearch) {
                Group {
                    if viewModel.isSearching && viewModel.pagination == nil {
                        ProgressView().tint(.white)
                    } else {
                        Label("Search EPC certificates", systemImage: "arrow.right")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 22)
                .padding(.vertical, 15)
            }
            .buttonStyle(.borderedProminent)
            .tint(.green)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .disabled(viewModel.isSearching)
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func statistics(_ dashboard: EPCDashboard) -> some View {
        ResearchCard(title: dashboard.nationLabel, icon: "doc.text.fill") {
            HStack(spacing: 10) {
                metric("Total certificates", dashboard.statistics.totalCertificates.formatted())
                metric("Last 12 months", dashboard.statistics.last12Months.formatted())
            }
            HStack(spacing: 10) {
                metric("Last 30 days", dashboard.statistics.last30Days.formatted())
                metric(
                    "Latest lodgement",
                    DateFormatting.displayDate(dashboard.statistics.latestLodgementDate)
                )
            }
        }
    }

    private func metric(_ label: String, _ value: String) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(value)
                .font(.headline)
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(12)
        .background(Color(.secondarySystemGroupedBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private func certificatesChart(_ values: [EPCCertificateYear]) -> some View {
        let orderedValues = values.sorted { $0.year < $1.year }
        let yearRange = orderedValues.first.flatMap { first in
            orderedValues.last.map { last in "\(first.year)–\(last.year)" }
        }

        return ResearchCard(title: "Certificates issued each year", icon: "chart.xyaxis.line") {
            if orderedValues.isEmpty {
                UnavailableView()
            } else {
                VStack(spacing: 7) {
                    Chart(orderedValues) { value in
                        LineMark(
                            x: .value("Year", String(value.year)),
                            y: .value("Certificates", value.count)
                        )
                        .foregroundStyle(.green)
                        .interpolationMethod(.catmullRom)
                        AreaMark(
                            x: .value("Year", String(value.year)),
                            y: .value("Certificates", value.count)
                        )
                        .foregroundStyle(.green.opacity(0.12))
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis {
                        AxisMarks(position: .trailing) { value in
                            AxisGridLine()
                            AxisTick()
                            AxisValueLabel {
                                if let count = value.as(Int.self) {
                                    Text(count.formatted(.number.notation(.compactName)))
                                }
                            }
                        }
                    }
                    .frame(height: 205)

                    if let yearRange {
                        Text(yearRange)
                            .font(.caption.weight(.semibold))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity)
                    }
                }
            }
        }
    }

    private func ratingsChart(
        title: String,
        values: [EPCRatingDistribution]
    ) -> some View {
        ResearchCard(title: title, icon: "chart.bar.fill") {
            if values.isEmpty {
                UnavailableView()
            } else {
                Chart(values) { value in
                    BarMark(
                        x: .value("Rating", value.rating ?? "Unknown"),
                        y: .value("Percentage", value.percentage)
                    )
                    .foregroundStyle(ratingColor(value.rating))
                }
                .chartYAxisLabel("%")
                .frame(height: 210)
            }
        }
    }

    private func ratingColor(_ rating: String?) -> Color {
        switch rating?.uppercased() {
        case "A": return Color(red: 0 / 255, green: 132 / 255, blue: 61 / 255)
        case "B": return Color(red: 45 / 255, green: 171 / 255, blue: 75 / 255)
        case "C": return Color(red: 167 / 255, green: 209 / 255, blue: 41 / 255)
        case "D": return Color(red: 247 / 255, green: 230 / 255, blue: 0 / 255)
        case "E": return Color(red: 249 / 255, green: 196 / 255, blue: 0 / 255)
        case "F": return Color(red: 233 / 255, green: 118 / 255, blue: 34 / 255)
        case "G": return Color(red: 221 / 255, green: 0 / 255, blue: 42 / 255)
        default: return .secondary
        }
    }

    private func startSearch() {
        postcodeIsFocused = false
        Task {
            await viewModel.search(postcode: postcode, nation: nation)
            if viewModel.searchPostcode != nil, viewModel.error == nil {
                showsSearchResults = true
            }
        }
    }
}

private struct EPCSearchResultsView: View {
    @ObservedObject var viewModel: EPCDashboardViewModel
    let nation: EPCNation

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(viewModel.searchPostcode ?? "Postcode")
                        .font(.title.bold())
                    Text(resultCountText)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ResearchCard(title: "EPC certificates", icon: "list.bullet") {
                    if viewModel.searchResults.isEmpty {
                        ContentUnavailableView(
                            "No certificates found",
                            systemImage: "doc.text.magnifyingglass",
                            description: Text(
                                "No EPC certificates were found for this postcode in \(nation.label)."
                            )
                        )
                    } else {
                        ForEach(viewModel.searchResults) { result in
                            if let apiURL = result.apiURL.flatMap(URL.init(string:)) {
                                NavigationLink {
                                    EPCCertificateView(
                                        apiURL: apiURL,
                                        client: viewModel.client
                                    )
                                } label: {
                                    resultRow(result, showsChevron: true)
                                }
                                .buttonStyle(.plain)
                            } else {
                                resultRow(result, showsChevron: false)
                            }

                            if result.id != viewModel.searchResults.last?.id {
                                Divider()
                            }
                        }

                        if viewModel.pagination?.hasNextPage == true {
                            Button {
                                Task {
                                    await viewModel.loadNextPage(nation: nation)
                                }
                            } label: {
                                if viewModel.isSearching {
                                    ProgressView()
                                } else {
                                    Text("Load more certificates")
                                }
                            }
                            .frame(maxWidth: .infinity)
                            .disabled(viewModel.isSearching)
                        }
                    }
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Search Results")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var resultCountText: String {
        let total = viewModel.pagination?.total ?? viewModel.searchResults.count
        return "\(total.formatted()) certificate\(total == 1 ? "" : "s") in \(nation.label)"
    }

    private func resultRow(_ result: EPCSearchResult, showsChevron: Bool) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Text(result.currentEnergyRating ?? "–")
                .font(.title2.bold())
                .foregroundStyle(ratingColor(result.currentEnergyRating))
                .frame(width: 44, height: 44)
                .background(ratingColor(result.currentEnergyRating).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 10))

            VStack(alignment: .leading, spacing: 4) {
                Text(result.address ?? "Address unavailable")
                    .font(.headline)
                Text(
                    [result.propertyType, result.lodgementDate.map(DateFormatting.displayDate)]
                        .compactMap { $0 }
                        .joined(separator: " · ")
                )
                .font(.subheadline)
                .foregroundStyle(.secondary)

                if let area = result.totalFloorAreaSquareMetres {
                    Text("\(area.formatted(.number.precision(.fractionLength(0...1)))) m²")
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

    private func ratingColor(_ rating: String?) -> Color {
        switch rating?.uppercased() {
        case "A": return Color(red: 0 / 255, green: 132 / 255, blue: 61 / 255)
        case "B": return Color(red: 45 / 255, green: 171 / 255, blue: 75 / 255)
        case "C": return Color(red: 167 / 255, green: 209 / 255, blue: 41 / 255)
        case "D": return Color(red: 247 / 255, green: 230 / 255, blue: 0 / 255)
        case "E": return Color(red: 249 / 255, green: 196 / 255, blue: 0 / 255)
        case "F": return Color(red: 233 / 255, green: 118 / 255, blue: 34 / 255)
        case "G": return Color(red: 221 / 255, green: 0 / 255, blue: 42 / 255)
        default: return .secondary
        }
    }
}
