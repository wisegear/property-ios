import SwiftUI

struct SchoolSearchView: View {
    @StateObject private var viewModel: SchoolSearchViewModel
    @State private var postcode = ""
    @FocusState private var postcodeIsFocused: Bool

    init(client: any PropertyResearchAPIClientProtocol) {
        _viewModel = StateObject(wrappedValue: SchoolSearchViewModel(client: client))
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                introduction
                searchPanel

                if let results = viewModel.results {
                    resultSummary(results)
                    schoolSection(title: "Primary schools", schools: results.primary)
                    schoolSection(title: "Secondary schools", schools: results.secondary)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Find Schools")
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear { viewModel.cancel() }
    }

    private var introduction: some View {
        ResearchPageHeader(
            eyebrow: "Schools near you",
            title: "Find nearby schools",
            subtitle: "Enter a full postcode to see the nearest primary and secondary schools.",
            icon: "graduationcap.fill",
            color: .indigo
        )
    }

    private var searchPanel: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Search by postcode")
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
                    .accessibilityLabel("Clear postcode")
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
                    if viewModel.isSearching {
                        ProgressView()
                            .tint(.white)
                    } else {
                        Label("Find schools", systemImage: "arrow.right")
                    }
                }
                .font(.headline)
                .frame(maxWidth: .infinity)
                .frame(height: 22)
                .padding(.vertical, 15)
            }
            .buttonStyle(.borderedProminent)
            .tint(.indigo)
            .buttonBorderShape(.roundedRectangle(radius: 14))
            .disabled(viewModel.isSearching)
        }
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }

    private func resultSummary(_ results: SchoolPostcodeSearch) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 3) {
                Text(results.postcode)
                    .font(.title3.bold())
                Text("\(results.primary.count) primary · \(results.secondary.count) secondary")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "mappin.and.ellipse")
                .font(.title2)
                .foregroundStyle(.indigo)
        }
    }

    private func schoolSection(title: String, schools: [SchoolSearchResult]) -> some View {
        let orderedSchools = schools.sorted(by: schoolComesBefore)

        return ResearchCard(title: title, icon: "graduationcap.fill") {
            if orderedSchools.isEmpty {
                Text("No nearby \(title.lowercased()) were found.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            } else {
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
            }
        }
    }

    private func schoolRow(_ school: SchoolSearchResult, showsChevron: Bool) -> some View {
        HStack(alignment: .top, spacing: 10) {
            VStack(alignment: .leading, spacing: 5) {
                Text(school.name ?? "School name unavailable")
                    .font(.headline)

                if let distance = school.distanceMiles {
                    Text("\(distance.formatted(.number.precision(.fractionLength(1)))) miles")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                Text(
                    [school.establishmentType, school.ageRange.map { "Ages \($0)" }]
                        .compactMap { $0 }
                        .joined(separator: " · ")
                )
                .font(.caption)
                .foregroundStyle(.secondary)
            }

            Spacer(minLength: 4)

            HStack(spacing: 7) {
                OfstedRatingBadge(rating: school.currentOfstedRating)

                if showsChevron {
                    Image(systemName: "chevron.right")
                        .font(.caption.bold())
                        .foregroundStyle(.tertiary)
                }
            }
        }
        .contentShape(Rectangle())
    }

    private func schoolComesBefore(_ lhs: SchoolSearchResult, _ rhs: SchoolSearchResult) -> Bool {
        let lhsPriority = OfstedRatingBadge.priority(for: lhs.currentOfstedRating)
        let rhsPriority = OfstedRatingBadge.priority(for: rhs.currentOfstedRating)

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

    private func startSearch() {
        postcodeIsFocused = false
        Task {
            _ = await viewModel.search(postcode: postcode)
        }
    }
}
