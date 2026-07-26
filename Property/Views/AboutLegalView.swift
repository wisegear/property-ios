import SwiftUI

struct AboutLegalView: View {
    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("PROPERTY RESEARCH UK", systemImage: "house.and.flag.fill")
                        .font(.caption.bold())
                        .tracking(1)
                        .foregroundStyle(.blue)

                    Text("About & Legal")
                        .font(.largeTitle.bold())

                    Text("Privacy, public-data licensing, important disclaimers and support.")
                        .foregroundStyle(.secondary)
                }

                VStack(spacing: 12) {
                    legalLink(
                        title: "Privacy Policy",
                        subtitle: "How the app handles searches and technical data",
                        icon: "hand.raised.fill",
                        color: .blue
                    ) {
                        AppPrivacyPolicyView()
                    }

                    legalLink(
                        title: "Data Sources & Licensing",
                        subtitle: "Official sources and Open Government Licence terms",
                        icon: "building.columns.fill",
                        color: .indigo
                    ) {
                        DataSourcesLicensingView()
                    }

                    legalLink(
                        title: "Terms & Disclaimers",
                        subtitle: "Important limitations of the data and calculators",
                        icon: "exclamationmark.shield.fill",
                        color: .orange
                    ) {
                        AppDisclaimersView()
                    }
                }

                ResearchCard(title: "PropertyResearch.uk", icon: "safari.fill") {
                    Text(
                        "Independent UK property research built from official public data, "
                        + "clear analysis and practical tools."
                    )
                    .font(.subheadline)
                    .foregroundStyle(.secondary)

                    if let websiteURL = URL(string: "https://propertyresearch.uk") {
                        Link(destination: websiteURL) {
                            Label("Visit PropertyResearch.uk", systemImage: "arrow.up.right")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.borderedProminent)
                    }

                    if let legalURL = URL(string: "https://propertyresearch.uk/legal") {
                        Link(destination: legalURL) {
                            Label("View legal pages online", systemImage: "doc.text")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }

                    if let supportURL = URL(string: "https://propertyresearch.uk/support") {
                        Link(destination: supportURL) {
                            Label("Support and contact", systemImage: "questionmark.circle")
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                    }
                }

                Text("App version \(appVersion)")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(maxWidth: .infinity)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("About & Legal")
        .navigationBarTitleDisplayMode(.inline)
    }

    private func legalLink<Destination: View>(
        title: String,
        subtitle: String,
        icon: String,
        color: Color,
        @ViewBuilder destination: () -> Destination
    ) -> some View {
        NavigationLink(destination: destination) {
            HStack(spacing: 14) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(color)
                    .frame(width: 44, height: 44)
                    .background(color.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                VStack(alignment: .leading, spacing: 3) {
                    Text(title)
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Text(subtitle)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }

                Spacer(minLength: 4)

                Image(systemName: "chevron.right")
                    .font(.caption.bold())
                    .foregroundStyle(.tertiary)
            }
            .padding(16)
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 18))
        }
        .buttonStyle(.plain)
    }

    private var appVersion: String {
        let version = Bundle.main.object(forInfoDictionaryKey: "CFBundleShortVersionString")
            as? String ?? "1.0"
        let build = Bundle.main.object(forInfoDictionaryKey: "CFBundleVersion") as? String
        return build.map { "\(version) (\($0))" } ?? version
    }
}

private struct AppPrivacyPolicyView: View {
    var body: some View {
        LegalDocument(
            title: "Privacy Policy",
            subtitle: "Last updated 25 July 2026"
        ) {
            LegalSection(title: "Overview") {
                Text(
                    "PropertyResearch.uk provides property research using public datasets. "
                    + "The iOS app does not require an account and does not contain advertising "
                    + "or third-party analytics SDKs."
                )
            }

            LegalSection(title: "Information you submit") {
                Text(
                    "When you search, the postcode, address or record reference you enter is sent "
                    + "securely to the PropertyResearch.uk service so the requested results can be returned."
                )
                Text(
                    "Search terms may relate to a property, but the app does not ask you to identify "
                    + "yourself as the owner, occupier or prospective buyer."
                )
            }

            LegalSection(title: "Technical information") {
                Text(
                    "Like most online services, the server may process standard request information "
                    + "such as IP address, request time and technical error details. This information "
                    + "is used to operate, secure and diagnose the service, not for advertising or sale."
                )
                Text(
                    "Operational records are retained only for as long as reasonably necessary for "
                    + "security, reliability and legal obligations."
                )
            }

            LegalSection(title: "Maps") {
                Text(
                    "When an EPC property map is displayed, the property address is sent to Apple Maps "
                    + "for geocoding. The app does not request or transmit your current location."
                )

                if let applePrivacyURL = URL(string: "https://www.apple.com/legal/privacy/") {
                    Link("Read Apple’s Privacy Policy", destination: applePrivacyURL)
                }
            }

            LegalSection(title: "Your choices and requests") {
                Text(
                    "You can avoid sending a search by not submitting it. The app stores no user "
                    + "account to delete. For privacy questions, access requests or deletion requests "
                    + "relating to service logs, contact PropertyResearch.uk through the support page."
                )

                if let supportURL = URL(string: "https://propertyresearch.uk/support") {
                    Link("Support and contact", destination: supportURL)
                }
            }

            LegalSection(title: "Online policy") {
                Text(
                    "The public version of this policy is available online for App Store "
                    + "information and access outside the app."
                )

                if let privacyURL = URL(string: "https://propertyresearch.uk/privacy/app") {
                    Link("View the App Privacy Policy online", destination: privacyURL)
                }
            }
        }
    }
}

private struct DataSourcesLicensingView: View {
    var body: some View {
        LegalDocument(
            title: "Data Sources & Licensing",
            subtitle: "Official public information used throughout the app"
        ) {
            LegalSection(title: "Open Government Licence") {
                Text(
                    "Contains public sector information licensed under the "
                    + "Open Government Licence v3.0."
                )
                .fontWeight(.semibold)

                Text(
                    "Where an information provider specifies additional attribution wording, "
                    + "that wording and the provider’s own terms also apply."
                )

                sourceLink(
                    "Open Government Licence v3.0",
                    "https://www.nationalarchives.gov.uk/doc/open-government-licence/version/3/"
                )
            }

            LegalSection(title: "Property sales and market data") {
                Text(
                    "Contains HM Land Registry data © Crown copyright and database right. "
                    + "HM Land Registry Price Paid Data is licensed under the Open Government Licence v3.0."
                )
                sourceLink(
                    "HM Land Registry Price Paid Data",
                    "https://www.gov.uk/government/collections/price-paid-data"
                )
            }

            LegalSection(title: "Energy performance certificates") {
                Text(
                    "EPC information is derived from the official registers for England and Wales "
                    + "and for Scotland. Coverage, fields and licensing conditions vary by register."
                )
                sourceLink("England & Wales EPC data", "https://epc.opendatacommunities.org/")
                sourceLink("Scottish EPC Register", "https://www.scottishepcregister.org.uk/")
            }

            LegalSection(title: "Schools and inspections") {
                Text(
                    "School information is sourced from Department for Education public data. "
                    + "Inspection ratings and outcomes are sourced from Ofsted where available."
                )
                sourceLink(
                    "Get Information about Schools",
                    "https://get-information-schools.service.gov.uk/"
                )
                sourceLink("Ofsted reports", "https://reports.ofsted.gov.uk/")
            }

            LegalSection(title: "Crime and economic indicators") {
                Text(
                    "Crime information is based on official police open data. Market-stress indicators "
                    + "use official releases including data from the Bank of England and the Office for "
                    + "National Statistics, as identified on the relevant dashboard."
                )
                sourceLink("Police open data", "https://data.police.uk/")
                sourceLink("Bank of England", "https://www.bankofengland.co.uk/")
                sourceLink("Office for National Statistics", "https://www.ons.gov.uk/")
            }

            LegalSection(title: "PropertyResearch.uk processing") {
                Text(
                    "PropertyResearch.uk cleans, combines and summarises source records and produces "
                    + "derived calculations and visualisations. These derived outputs are independent "
                    + "and are not official publications of the source organisations."
                )
            }

            LegalSection(title: "Online version") {
                if let sourcesURL = URL(string: "https://propertyresearch.uk/data-sources") {
                    Link("View Data Sources & Licensing online", destination: sourcesURL)
                }
            }
        }
    }

    private func sourceLink(_ title: String, _ address: String) -> some View {
        Group {
            if let url = URL(string: address) {
                Link(destination: url) {
                    Label(title, systemImage: "arrow.up.right")
                }
            }
        }
    }
}

private struct AppDisclaimersView: View {
    var body: some View {
        LegalDocument(
            title: "Terms & Disclaimers",
            subtitle: "Important information about using the app"
        ) {
            LegalSection(title: "Research only") {
                Text(
                    "The app is provided for general information and research. It does not provide "
                    + "financial, mortgage, investment, valuation, legal or tax advice."
                )
            }

            LegalSection(title: "Data limitations") {
                Text(
                    "Public records may be incomplete, delayed, provisional, corrected or withdrawn. "
                    + "PropertyResearch.uk cannot guarantee that every record is complete, current or error-free."
                )
                Text(
                    "Do not rely on the app as the sole basis for a purchase, lending, valuation, "
                    + "tax or other financial decision. Verify important information with the official "
                    + "source and an appropriately qualified professional."
                )
            }

            LegalSection(title: "Schools, crime and maps") {
                Text(
                    "School distances are estimates and do not indicate catchment eligibility, admission "
                    + "availability or travel distance. Crime information reflects reported and published "
                    + "records, not every incident. Map pins produced from addresses are approximate."
                )
            }

            LegalSection(title: "Calculators") {
                Text(
                    "Mortgage and property-tax results are illustrative estimates. Rates, thresholds, "
                    + "reliefs and individual circumstances can change the outcome. Confirm current "
                    + "rules and obtain professional advice before acting."
                )
            }

            LegalSection(title: "Availability") {
                Text(
                    "Features that depend on online services may be unavailable during maintenance, "
                    + "network failure or interruptions affecting an external data provider."
                )
            }

            LegalSection(title: "Online version") {
                if let termsURL = URL(string: "https://propertyresearch.uk/terms") {
                    Link("View Terms & Disclaimers online", destination: termsURL)
                }
            }
        }
    }
}

private struct LegalDocument<Content: View>: View {
    let title: String
    let subtitle: String
    @ViewBuilder let content: Content

    init(
        title: String,
        subtitle: String,
        @ViewBuilder content: () -> Content
    ) {
        self.title = title
        self.subtitle = subtitle
        self.content = content()
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(title)
                        .font(.largeTitle.bold())
                    Text(subtitle)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                content
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle(title)
        .navigationBarTitleDisplayMode(.inline)
    }
}

private struct LegalSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: Content

    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 11) {
            Text(title)
                .font(.title3.bold())
                .foregroundStyle(.blue)

            content
                .font(.subheadline)
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}
