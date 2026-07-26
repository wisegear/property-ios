import MapKit
import SwiftUI

struct SchoolDetailView: View {
    @StateObject private var viewModel: SchoolDetailViewModel

    init(apiURL: URL, client: any PropertyResearchAPIClientProtocol) {
        _viewModel = StateObject(
            wrappedValue: SchoolDetailViewModel(apiURL: apiURL, client: client)
        )
    }

    var body: some View {
        Group {
            if let school = viewModel.school {
                schoolContent(school)
            } else if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Unable to load school", systemImage: "graduationcap.fill")
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
                VStack(spacing: 14) {
                    ProgressView()
                        .controlSize(.large)
                    Text("Loading school information…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle(viewModel.school?.name ?? "School")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onDisappear { viewModel.cancel() }
    }

    private func schoolContent(_ school: SchoolDetail) -> some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                overview(school)
                location(school)
                schoolInformation(school)
                ofsted(school)
                nearbyStreets(school.localPropertyMarket)
                recentSales(school.localPropertyMarket)
                externalLinks(school)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func overview(_ school: SchoolDetail) -> some View {
        ResearchCard(title: "School overview", icon: "graduationcap.fill") {
            Text(school.name ?? "School name unavailable")
                .font(.title2.bold())

            if let rating = school.currentOfstedRating {
                Text(rating)
                    .font(.subheadline.bold())
                    .foregroundStyle(ofstedColor(rating))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(ofstedColor(rating).opacity(0.12))
                    .clipShape(Capsule())
            }

            optionalLine("Phase", school.phase)
            optionalLine("Type", school.establishmentType)
            optionalLine("Age range", school.ageRange?.label)
            optionalLine("Pupils", school.pupilCount.map(String.init))
            optionalLine("Capacity", school.capacity.map(String.init))
        }
    }

    @ViewBuilder
    private func location(_ school: SchoolDetail) -> some View {
        ResearchCard(title: "Location", icon: "map.fill") {
            optionalLine("Address", school.address)
            optionalLine("Postcode", school.postcode)

            if let latitude = school.latitude, let longitude = school.longitude {
                let coordinate = CLLocationCoordinate2D(
                    latitude: latitude,
                    longitude: longitude
                )
                Map(
                    initialPosition: .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.012, longitudeDelta: 0.012)
                        )
                    )
                ) {
                    Marker(school.name ?? "School", coordinate: coordinate)
                }
                .frame(height: 210)
                .clipShape(RoundedRectangle(cornerRadius: 14))
            } else if school.address == nil && school.postcode == nil {
                UnavailableView()
            }
        }
    }

    private func schoolInformation(_ school: SchoolDetail) -> some View {
        ResearchCard(title: "School information", icon: "info.circle.fill") {
            optionalLine("Headteacher", school.headteacher)
            optionalLine("Local authority", school.localAuthority)
            optionalLine("Religious character", school.religiousCharacter)
            optionalLine("Admissions policy", school.admissionsPolicy)
            optionalLine("Gender", school.gender)
            optionalLine("Boarding", school.boardingStatus)
            optionalLine("Trust", school.trust)
            optionalLine("Academy sponsor", school.academySponsor)
            optionalLine("Opening date", school.openingDate.map(DateFormatting.displayDate))
            optionalLine("URN", school.urn)
        }
    }

    private func ofsted(_ school: SchoolDetail) -> some View {
        ResearchCard(title: "Ofsted", icon: "checkmark.seal.fill") {
            optionalLine("Current rating", school.currentOfstedRating)
            optionalLine(
                "Latest inspection",
                school.latestInspectionDate.map(DateFormatting.displayDate)
            )
            optionalLine("Inspection type", school.inspectionType)
            optionalLine("Outcome", school.inspectionOutcome)

            if let reportURL = school.ofstedReportURL.flatMap(URL.init(string:)) {
                Link("View Ofsted report", destination: reportURL)
                    .buttonStyle(.bordered)
            }
        }
    }

    private func nearbyStreets(_ market: SchoolLocalPropertyMarket?) -> some View {
        ResearchCard(title: "Nearby property market", icon: "building.2.fill") {
            if let streets = market?.nearbyStreets, !streets.isEmpty {
                if let outcode = market?.outcode {
                    Text("Recent activity around \(outcode)")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                ForEach(streets) { street in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(street.name ?? "Street unavailable")
                            .font(.headline)
                        HStack {
                            if let count = street.salesCount {
                                Text("\(count) sales")
                            }
                            if let price = street.averagePriceLabel {
                                Text("Average \(price)")
                            }
                        }
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    if street.id != streets.last?.id {
                        Divider()
                    }
                }
            } else {
                UnavailableView()
            }
        }
    }

    private func recentSales(_ market: SchoolLocalPropertyMarket?) -> some View {
        ResearchCard(title: "Recent local sales", icon: "sterlingsign.circle.fill") {
            if let sales = market?.recentSales, !sales.isEmpty {
                ForEach(sales) { sale in
                    VStack(alignment: .leading, spacing: 4) {
                        Text(sale.address ?? "Address unavailable")
                            .font(.headline)
                        Text(
                            [sale.priceLabel, sale.dateLabel, sale.propertyType]
                                .compactMap { $0 }
                                .joined(separator: " · ")
                        )
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    }

                    if sale.id != sales.last?.id {
                        Divider()
                    }
                }
            } else {
                UnavailableView()
            }
        }
    }

    @ViewBuilder
    private func externalLinks(_ school: SchoolDetail) -> some View {
        VStack(spacing: 12) {
            if let schoolURL = school.schoolWebsite.flatMap(URL.init(string:)) {
                Link(destination: schoolURL) {
                    Label("Visit school website", systemImage: "safari")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
            }

            if let websiteURL = school.websiteURL.flatMap(URL.init(string:)) {
                Link(destination: websiteURL) {
                    Label("View on PropertyResearch.uk", systemImage: "arrow.up.right")
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
                .controlSize(.large)
            }
        }
    }

    @ViewBuilder
    private func optionalLine(_ label: String, _ value: String?) -> some View {
        if let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
            DetailLine(label: label, value: value)
        }
    }

    private func ofstedColor(_ rating: String) -> Color {
        switch rating.lowercased() {
        case "outstanding": return .green
        case "good": return .blue
        case "requires improvement": return .orange
        case "inadequate": return .red
        default: return .secondary
        }
    }
}
