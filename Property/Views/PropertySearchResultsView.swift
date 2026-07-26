import SwiftUI

struct PropertySearchResultsView: View {
    @ObservedObject var viewModel: PropertySearchViewModel

    var body: some View {
        Group {
            if viewModel.properties.isEmpty {
                ContentUnavailableView(
                    "No properties found",
                    systemImage: "house.slash",
                    description: Text("No Land Registry sales were found for \(viewModel.postcode).")
                )
            } else {
                List {
                    Section {
                        ForEach(viewModel.properties) { property in
                            NavigationLink {
                                PropertyDetailView(
                                    slug: property.propertySlug,
                                    client: viewModel.client
                                )
                            } label: {
                                PropertyResultRow(property: property)
                            }
                            .task {
                                await viewModel.loadNextPageIfNeeded(currentProperty: property)
                            }
                        }

                        if viewModel.isLoadingMore {
                            HStack {
                                Spacer()
                                ProgressView("Loading more properties…")
                                Spacer()
                            }
                        }
                    } header: {
                        VStack(alignment: .leading, spacing: 3) {
                            Text("\(viewModel.meta?.total ?? viewModel.properties.count) sale records")
                            Text("Most recent sale first")
                                .font(.caption)
                                .textCase(nil)
                        }
                    } footer: {
                        Text("Multiple sales for the same address are combined. The latest sale is shown here.")
                    }

                    if let error = viewModel.error, error.canRetry {
                        Section {
                            ErrorMessageView(error: error) {
                                Task {
                                    _ = await viewModel.retry()
                                }
                            }
                        }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle(viewModel.postcode)
        .navigationBarTitleDisplayMode(.inline)
        .onDisappear {
            viewModel.cancelRequests()
        }
    }
}

private struct PropertyResultRow: View {
    let property: PropertySearchResult

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(property.formattedAddress)
                .font(.headline)
                .foregroundStyle(.primary)

            Text(property.postcode ?? "Postcode unavailable")
                .font(.subheadline)
                .foregroundStyle(.secondary)

            HStack(spacing: 16) {
                ResultFact(
                    icon: "sterlingsign.circle",
                    value: property.price?.formatted(.currency(code: "GBP").precision(.fractionLength(0))) ?? "Price unavailable"
                )
                ResultFact(
                    icon: "calendar",
                    value: DateFormatting.displayDate(property.date)
                )
            }

            Text(property.propertyTypeLabel)
                .font(.caption.weight(.semibold))
                .foregroundStyle(.blue)
                .padding(.horizontal, 9)
                .padding(.vertical, 5)
                .background(Color.blue.opacity(0.1))
                .clipShape(Capsule())
        }
        .padding(.vertical, 6)
    }
}

private struct ResultFact: View {
    let icon: String
    let value: String

    var body: some View {
        Label(value, systemImage: icon)
            .font(.caption)
            .foregroundStyle(.secondary)
            .lineLimit(1)
    }
}

enum DateFormatting {
    nonisolated static func displayDate(_ value: String?) -> String {
        guard let value, !value.isEmpty else {
            return "Date unavailable"
        }

        let datePart = String(value.prefix(10))
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "yyyy-MM-dd"

        guard let date = formatter.date(from: datePart) else {
            return datePart
        }

        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: date)
    }
}
