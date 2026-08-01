import MapKit
import SwiftUI

struct EPCCertificateView: View {
    @StateObject private var viewModel: EPCCertificateViewModel

    init(apiURL: URL, client: any PropertyResearchAPIClientProtocol) {
        _viewModel = StateObject(
            wrappedValue: EPCCertificateViewModel(apiURL: apiURL, client: client)
        )
    }

    var body: some View {
        Group {
            if let certificate = viewModel.certificate {
                certificateContent(certificate)
            } else if let error = viewModel.error {
                ContentUnavailableView {
                    Label("Unable to load EPC", systemImage: "leaf.fill")
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
                    Text("Loading EPC certificate…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .navigationTitle("EPC certificate")
        .navigationBarTitleDisplayMode(.inline)
        .task { await viewModel.load() }
        .onDisappear { viewModel.cancel() }
    }

    private func certificateContent(_ certificate: EPCCertificateDetail) -> some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                ResearchPageHeader(
                    eyebrow: "Energy performance",
                    title: displayAddress(certificate.address),
                    subtitle: "Certificate ratings, estimated energy costs and property efficiency details.",
                    icon: "leaf.fill",
                    color: .green
                )
                ratingOverview(certificate)
                certificateDetails(certificate)
                propertyDetails(certificate.property)
                energyDetails(certificate.energy)
                environmentalImpact(certificate.environmentalImpact)
                estimatedCosts(certificate.estimatedCosts)
                construction(certificate.construction)
                heating(certificate.heating)
                lighting(certificate.lighting)
                renewables(certificate.renewables)

                if let websiteURL = certificate.websiteURL.flatMap(URL.init(string:)) {
                    Link(destination: websiteURL) {
                        Label("View certificate on PropertyResearch.uk", systemImage: "safari")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .controlSize(.large)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
    }

    private func ratingOverview(_ certificate: EPCCertificateDetail) -> some View {
        ResearchCard(title: "Energy performance", icon: "leaf.fill") {
            Text(displayAddress(certificate.address))
                .font(.title2.bold())

            HStack(spacing: 12) {
                ratingBadge(
                    title: "Current",
                    rating: certificate.energy?.currentRating,
                    score: certificate.energy?.currentEfficiency
                )
                ratingBadge(
                    title: "Potential",
                    rating: certificate.energy?.potentialRating,
                    score: certificate.energy?.potentialEfficiency
                )
            }

            if let mapAddress = mapAddress(certificate.address) {
                EPCPropertyMap(address: mapAddress)
            }
        }
    }

    private func ratingBadge(title: String, rating: String?, score: Int?) -> some View {
        VStack(alignment: .leading, spacing: 5) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)
            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text(rating ?? "–")
                    .font(.largeTitle.bold())
                    .foregroundStyle(ratingColor(rating))
                if let score {
                    Text("\(score)")
                        .font(.headline)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(ratingColor(rating).opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 14))
    }

    private func certificateDetails(_ value: EPCCertificateDetail) -> some View {
        ResearchCard(title: "Certificate details", icon: "doc.text.fill") {
            optionalLine("Inspection date", value.certificate?.inspectionDate.map(DateFormatting.displayDate))
            optionalLine("Lodgement date", value.certificate?.lodgementDate.map(DateFormatting.displayDate))
            optionalLine("Transaction type", value.certificate?.transactionType)
            optionalLine("Report type", value.certificate?.reportType)
        }
    }

    private func propertyDetails(_ value: EPCPropertyCharacteristics?) -> some View {
        ResearchCard(title: "Property", icon: "house.fill") {
            optionalLine("Type", value?.type)
            optionalLine("Built form", value?.builtForm)
            optionalLine("Age band", value?.constructionAgeBand)
            optionalLine("Tenure", value?.tenure)
            optionalLine("Floor area", squareFeet(value?.totalFloorAreaSquareMetres))
            optionalLine("Habitable rooms", value?.habitableRooms.map(String.init))
            optionalLine("Heated rooms", value?.heatedRooms.map(String.init))
        }
    }

    private func energyDetails(_ value: EPCEnergyPerformance?) -> some View {
        ResearchCard(title: "Energy use", icon: "bolt.fill") {
            optionalLine("Current consumption", energyUse(value?.currentConsumptionKWhPerSquareMetre))
            optionalLine("Potential consumption", energyUse(value?.potentialConsumptionKWhPerSquareMetre))
            optionalLine("Tariff", value?.tariff)
        }
    }

    private func environmentalImpact(_ value: EPCEnvironmentalImpact?) -> some View {
        ResearchCard(title: "Environmental impact", icon: "globe.europe.africa.fill") {
            optionalLine("Current score", value?.currentScore.map(String.init))
            optionalLine("Potential score", value?.potentialScore.map(String.init))
            optionalLine("Current CO₂ emissions", tonnes(value?.currentCO2EmissionsTonnes))
            optionalLine("Potential CO₂ emissions", tonnes(value?.potentialCO2EmissionsTonnes))
        }
    }

    private func estimatedCosts(_ value: EPCEstimatedCosts?) -> some View {
        ResearchCard(title: "Estimated energy costs", icon: "sterlingsign.circle.fill") {
            costLine("Lighting", value?.lighting)
            costLine("Heating", value?.heating)
            costLine("Hot water", value?.hotWater)
        }
    }

    private func construction(_ value: EPCConstruction?) -> some View {
        ResearchCard(title: "Construction", icon: "building.2.fill") {
            componentLine("Walls", value?.walls)
            componentLine("Roof", value?.roof)
            componentLine("Floor", value?.floor)
            componentLine("Windows", value?.windows)
            optionalLine("Glazing", value?.glazedType)
        }
    }

    private func heating(_ value: EPCHeating?) -> some View {
        ResearchCard(title: "Heating and hot water", icon: "flame.fill") {
            componentLine("Main heating", value?.main)
            componentLine("Controls", value?.mainControls)
            componentLine("Secondary heating", value?.secondary)
            componentLine("Hot water", value?.hotWater)
            optionalLine("Main fuel", value?.mainFuel)
        }
    }

    private func lighting(_ value: EPCLighting?) -> some View {
        ResearchCard(title: "Lighting", icon: "lightbulb.fill") {
            optionalLine("Description", value?.description)
            optionalLine("Energy efficiency", value?.energyEfficiency)
            optionalLine("Low-energy lighting", percentage(value?.lowEnergyPercentage))
        }
    }

    private func renewables(_ value: EPCRenewables?) -> some View {
        ResearchCard(title: "Renewable energy", icon: "sun.max.fill") {
            optionalLine("Solar electricity", value?.photoSupply)
            optionalLine("Solar water heating", value?.solarWaterHeating)
            optionalLine("Wind turbines", value?.windTurbines.map(String.init))
        }
    }

    @ViewBuilder
    private func optionalLine(_ label: String, _ value: String?) -> some View {
        if let value = value?.trimmingCharacters(in: .whitespacesAndNewlines), !value.isEmpty {
            DetailLine(label: label, value: value)
        }
    }

    @ViewBuilder
    private func componentLine(_ label: String, _ component: EPCComponent?) -> some View {
        if let description = component?.description?.trimmingCharacters(in: .whitespacesAndNewlines),
           !description.isEmpty {
            VStack(alignment: .leading, spacing: 3) {
                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(description)
                    .font(.subheadline)
                if let efficiency = component?.energyEfficiency, !efficiency.isEmpty {
                    Text("Energy efficiency: \(efficiency)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
        }
    }

    @ViewBuilder
    private func costLine(_ label: String, _ costs: EPCCostPair?) -> some View {
        if costs?.current != nil || costs?.potential != nil {
            DetailLine(
                label: label,
                value: "\(currency(costs?.current)) → \(currency(costs?.potential))"
            )
        }
    }

    private func squareFeet(_ squareMetres: Double?) -> String? {
        squareMetres.map {
            let value = $0 * 10.763_910_416_7
            return "\(value.formatted(.number.precision(.fractionLength(0)))) sq ft"
        }
    }

    private func displayAddress(_ address: EPCAddress?) -> String {
        let display = address?.display?.trimmingCharacters(in: .whitespacesAndNewlines)
        let postcode = address?.postcode?.trimmingCharacters(in: .whitespacesAndNewlines)

        if let display, !display.isEmpty {
            if let postcode, !postcode.isEmpty,
               display.range(of: postcode, options: [.caseInsensitive, .diacriticInsensitive]) == nil {
                return "\(display), \(postcode)"
            }
            return display
        }

        if let postcode, !postcode.isEmpty {
            return postcode
        }
        return "Address unavailable"
    }

    private func mapAddress(_ address: EPCAddress?) -> String? {
        let value = displayAddress(address)
        return value == "Address unavailable" ? nil : value
    }

    private func energyUse(_ value: Double?) -> String? {
        value.map { "\($0.formatted(.number.precision(.fractionLength(0...1)))) kWh/m²" }
    }

    private func tonnes(_ value: Double?) -> String? {
        value.map { "\($0.formatted(.number.precision(.fractionLength(0...2)))) tonnes" }
    }

    private func percentage(_ value: Double?) -> String? {
        value.map { "\($0.formatted(.number.precision(.fractionLength(0...1))))%" }
    }

    private func currency(_ value: Double?) -> String {
        value?.formatted(.currency(code: "GBP").precision(.fractionLength(0))) ?? "Unavailable"
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

private struct EPCPropertyMap: View {
    let address: String
    @State private var coordinate: CLLocationCoordinate2D?
    @State private var lookupFailed = false

    var body: some View {
        Group {
            if let coordinate {
                Map(
                    initialPosition: .region(
                        MKCoordinateRegion(
                            center: coordinate,
                            span: MKCoordinateSpan(latitudeDelta: 0.006, longitudeDelta: 0.006)
                        )
                    ),
                    interactionModes: []
                ) {
                    Marker("Property", coordinate: coordinate)
                }
                .frame(height: 180)
                .clipShape(RoundedRectangle(cornerRadius: 14))
                .allowsHitTesting(false)
                .accessibilityLabel("Map showing \(address)")
            } else if !lookupFailed {
                HStack(spacing: 10) {
                    ProgressView()
                    Text("Locating property…")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .frame(height: 100)
                .background(Color(.secondarySystemGroupedBackground))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            }
        }
        .task(id: address) {
            coordinate = nil
            lookupFailed = false

            do {
                guard let request = MKGeocodingRequest(addressString: address) else {
                    lookupFailed = true
                    return
                }
                let mapItems = try await request.mapItems
                coordinate = mapItems.first?.location.coordinate
                lookupFailed = coordinate == nil
            } catch {
                lookupFailed = true
            }
        }
    }
}
