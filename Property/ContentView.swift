import SwiftUI

struct ContentView: View {
    @StateObject private var viewModel: PropertySearchViewModel
    @State private var searchText = ""
    @State private var showsResults = false
    @FocusState private var searchFieldIsFocused: Bool

    private let quickLinks = [
        QuickLink(title: "Market Dashboard", subtitle: "Property market trends", icon: "chart.xyaxis.line", color: .blue),
        QuickLink(title: "Stress Dashboard", subtitle: "Track market stress", icon: "gauge.with.dots.needle.67percent", color: .red),
        QuickLink(title: "Calculators", subtitle: "Mortgage & Stamp Duty tools", icon: "function", color: .purple),
        QuickLink(title: "EPC", subtitle: "Search EPC records for the whole country", icon: "leaf.fill", color: .green),
        QuickLink(title: "Schools", subtitle: "Explore nearby schools", icon: "graduationcap.fill", color: .indigo),
        QuickLink(title: "Crime", subtitle: "View local crime data", icon: "shield.lefthalf.filled", color: .orange)
    ]

    init(client: any PropertyResearchAPIClientProtocol = PropertyResearchAPIClient()) {
        _viewModel = StateObject(wrappedValue: PropertySearchViewModel(client: client))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    heroSearchSection

                    quickLinksSection
                        .padding(.horizontal, 20)
                        .padding(.bottom, 24)
                }
            }
            .ignoresSafeArea(edges: .top)
            .scrollDismissesKeyboard(.interactively)
            .background(Color(.systemGroupedBackground))
            .toolbar(.hidden, for: .navigationBar)
            .navigationDestination(isPresented: $showsResults) {
                PropertySearchResultsView(viewModel: viewModel)
            }
            .safeAreaInset(edge: .bottom, spacing: 0) {
                AppFooter()
            }
        }
        .tint(.blue)
    }

    private var heroSearchSection: some View {
        ZStack(alignment: .bottom) {
            ZStack {
                LinearGradient(
                    colors: [
                        Color(red: 0.015, green: 0.08, blue: 0.22),
                        Color(red: 0.02, green: 0.25, blue: 0.72),
                        Color(red: 0.02, green: 0.42, blue: 0.96)
                    ],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )

                PropertyHeroIllustration()
                    .foregroundStyle(.white.opacity(0.075))
                    .accessibilityHidden(true)

                Circle()
                    .stroke(.white.opacity(0.055), lineWidth: 34)
                    .frame(width: 230, height: 230)
                    .offset(x: 180, y: -100)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 9) {
                        Image(systemName: "house.and.flag.fill")
                            .font(.title3.weight(.semibold))

                        Text("PROPERTY RESEARCH UK")
                            .font(.caption.bold())
                            .tracking(1.25)
                    }
                    .foregroundStyle(.white)

                    VStack(alignment: .leading, spacing: 9) {
                        Text("Search sales data in England & Wales")
                            .font(.system(.largeTitle, design: .rounded, weight: .bold))
                            .foregroundStyle(.white)
                            .fixedSize(horizontal: false, vertical: true)

                        Text("Sales history, EPC, schools, crime and local market insights.")
                            .font(.subheadline)
                            .foregroundStyle(.white.opacity(0.82))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, 20)
                .padding(.top, 70)
                .padding(.bottom, 90)
            }
            .frame(minHeight: 330)

            searchCard
                .padding(.horizontal, 20)
                .offset(y: 140)
        }
        .padding(.bottom, 168)
        .accessibilityElement(children: .contain)
    }

    private var searchCard: some View {
        VStack(alignment: .leading, spacing: 13) {
            Text("Find a property")
                .font(.headline)

            HStack(spacing: 12) {
                Image(systemName: "magnifyingglass")
                    .font(.body.weight(.semibold))
                    .foregroundStyle(.blue)

                TextField("Enter a full postcode", text: $searchText)
                    .textInputAutocapitalization(.characters)
                    .autocorrectionDisabled()
                    .textContentType(.postalCode)
                    .submitLabel(.search)
                    .focused($searchFieldIsFocused)
                    .onSubmit(startSearch)
                    .disabled(viewModel.isSearching)

                if !searchText.isEmpty && !viewModel.isSearching {
                    Button {
                        searchText = ""
                        viewModel.dismissError()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundStyle(.secondary)
                    }
                    .accessibilityLabel("Clear search")
                }
            }
            .padding(14)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 14))

            if let error = viewModel.error {
                ErrorMessageView(error: error) {
                    startSearch()
                }
            }

            Button(action: startSearch) {
                Group {
                    if viewModel.isSearching {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Text("Search properties")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 22)
                .padding(.vertical, 14)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .disabled(viewModel.isSearching)

            Text("Sold prices • EPC • Schools • Crime • Market insights")
                .font(.caption2)
                .foregroundStyle(.secondary)
                .frame(maxWidth: .infinity)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 22))
        .shadow(color: .black.opacity(0.14), radius: 20, y: 9)
    }

    private var quickLinksSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader(title: "Explore", subtitle: "Property insights included in each result")

            LazyVGrid(
                columns: [
                    GridItem(.flexible(), spacing: 12),
                    GridItem(.flexible(), spacing: 12)
                ],
                spacing: 12
            ) {
                ForEach(quickLinks) { link in
                    if link.title == "Market Dashboard" {
                        NavigationLink {
                            PropertyMarketDashboardView(client: viewModel.client)
                        } label: {
                            QuickLinkCard(link: link, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    } else if link.title == "Calculators" {
                        NavigationLink {
                            CalculatorsView()
                        } label: {
                            QuickLinkCard(link: link, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    } else if link.title == "EPC" {
                        NavigationLink {
                            EPCDashboardView(client: viewModel.client)
                        } label: {
                            QuickLinkCard(link: link, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    } else if link.title == "Schools" {
                        NavigationLink {
                            SchoolSearchView(client: viewModel.client)
                        } label: {
                            QuickLinkCard(link: link, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    } else if link.title == "Crime" {
                        NavigationLink {
                            CrimeDashboardView(client: viewModel.client)
                        } label: {
                            QuickLinkCard(link: link, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    } else if link.title == "Stress Dashboard" {
                        NavigationLink {
                            StressDashboardView(client: viewModel.client)
                        } label: {
                            QuickLinkCard(link: link, showsChevron: true)
                        }
                        .buttonStyle(.plain)
                    } else {
                        QuickLinkCard(link: link)
                    }
                }
            }
        }
    }

    private func startSearch() {
        searchFieldIsFocused = false

        Task {
            if await viewModel.search(postcode: searchText) {
                showsResults = true
            }
        }
    }
}

struct SectionHeader: View {
    let title: String
    let subtitle: String

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            Text(title)
                .font(.title3.bold())

            Text(subtitle)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }
}

struct ErrorMessageView: View {
    let error: APIError
    let retry: (() -> Void)?

    init(error: APIError, retry: (() -> Void)? = nil) {
        self.error = error
        self.retry = retry
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Label(error.message, systemImage: "exclamationmark.triangle.fill")
                .font(.subheadline)
                .foregroundStyle(.red)

            if error.canRetry, let retry {
                Button("Try again", action: retry)
                    .font(.subheadline.weight(.semibold))
            }
        }
        .accessibilityElement(children: .combine)
    }
}

private struct PropertyHeroIllustration: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        path.move(to: CGPoint(x: rect.minX - 30, y: rect.maxY - 42))
        path.addLine(to: CGPoint(x: rect.width * 0.17, y: rect.height * 0.52))
        path.addLine(to: CGPoint(x: rect.width * 0.38, y: rect.maxY - 42))
        path.addLine(to: CGPoint(x: rect.width * 0.58, y: rect.height * 0.6))
        path.addLine(to: CGPoint(x: rect.width * 0.78, y: rect.maxY - 42))
        path.addLine(to: CGPoint(x: rect.maxX + 30, y: rect.height * 0.51))

        path.move(to: CGPoint(x: rect.width * 0.04, y: rect.height * 0.67))
        path.addLine(to: CGPoint(x: rect.width * 0.04, y: rect.maxY))
        path.move(to: CGPoint(x: rect.width * 0.3, y: rect.height * 0.67))
        path.addLine(to: CGPoint(x: rect.width * 0.3, y: rect.maxY))
        path.move(to: CGPoint(x: rect.width * 0.66, y: rect.height * 0.7))
        path.addLine(to: CGPoint(x: rect.width * 0.66, y: rect.maxY))
        path.move(to: CGPoint(x: rect.width * 0.91, y: rect.height * 0.63))
        path.addLine(to: CGPoint(x: rect.width * 0.91, y: rect.maxY))

        path.move(to: CGPoint(x: rect.width * 0.08, y: rect.height * 0.3))
        path.addCurve(
            to: CGPoint(x: rect.width * 0.94, y: rect.height * 0.22),
            control1: CGPoint(x: rect.width * 0.35, y: rect.height * 0.13),
            control2: CGPoint(x: rect.width * 0.63, y: rect.height * 0.4)
        )

        return path.strokedPath(
            StrokeStyle(lineWidth: 2, lineCap: .round, lineJoin: .round)
        )
    }
}

private struct QuickLinkCard: View {
    let link: QuickLink
    var showsChevron = false

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack {
                Image(systemName: link.icon)
                    .font(.title2)
                    .foregroundStyle(link.color)
                    .frame(width: 42, height: 42)
                    .background(link.color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                Spacer()

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(link.title)
                    .font(.headline)

                Text(link.subtitle)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.leading)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 124, alignment: .leading)
        .padding(16)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct QuickLink: Identifiable {
    let id = UUID()
    let title: String
    let subtitle: String
    let icon: String
    let color: Color
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
