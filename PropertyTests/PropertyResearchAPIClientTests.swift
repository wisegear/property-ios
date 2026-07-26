import Foundation
import Testing
@testable import Property

@Suite(.serialized)
@MainActor
struct PropertyResearchAPIClientTests {
    private let baseURL = URL(string: "https://example.test/api/v1")!

    init() {
        MockURLProtocol.reset()
    }

    @Test
    func successfulPostcodeSearchAndPaginationMetadata() async throws {
        let client = makeClient()
        MockURLProtocol.handler = { request in
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")
            return (
                Self.response(for: request, status: 200),
                Self.data("""
                {
                  "postcode": "SW7 5PH",
                  "results": [{
                    "transaction_id": "transaction-1",
                    "price": 950000,
                    "date": "2025-05-01 00:00:00",
                    "property_type": "F",
                    "new_build": "N",
                    "duration": "L",
                    "paon": "10",
                    "saon": "FLAT 2",
                    "street": "EXAMPLE ROAD",
                    "locality": "",
                    "town_city": "LONDON",
                    "district": "KENSINGTON",
                    "county": "GREATER LONDON",
                    "postcode": "SW7 5PH",
                    "category": "A",
                    "property_slug": "sw7-5ph-10-example-road-flat-2",
                    "url": "https://example.test/api/v1/properties/sw7-5ph-10-example-road-flat-2"
                  }],
                  "meta": {
                    "current_page": 1,
                    "last_page": 3,
                    "per_page": 15,
                    "total": 31
                  }
                }
                """)
            )
        }

        let result = try await client.searchProperties(postcode: "SW7 5PH", page: 1)

        #expect(result.postcode == "SW7 5PH")
        #expect(result.results.first?.propertySlug == "sw7-5ph-10-example-road-flat-2")
        #expect(result.results.first?.price == 950000)
        #expect(result.meta?.currentPage == 1)
        #expect(result.meta?.lastPage == 3)
        #expect(result.meta?.perPage == 15)
        #expect(result.meta?.total == 31)
        #expect(result.meta?.hasNextPage == true)
    }

    @Test
    func postcodeUsesURLQueryEncoding() async throws {
        let client = makeClient()
        MockURLProtocol.handler = { request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw URLError(.badURL)
            }
            #expect(components.path == "/api/v1/properties")
            #expect(components.queryItems?.first(where: { $0.name == "postcode" })?.value == "SW7 5PH")
            #expect(components.queryItems?.first(where: { $0.name == "page" })?.value == "2")
            #expect(request.url?.absoluteString.contains("postcode=SW7%205PH") == true)

            return (
                Self.response(for: request, status: 200),
                Self.data(#"{"postcode":"SW7 5PH","results":[],"meta":{"current_page":2,"last_page":2,"per_page":15,"total":16}}"#)
            )
        }

        _ = try await client.searchProperties(postcode: "SW7 5PH", page: 2)
    }

    @Test
    func successfulPropertyDetailResponse() async throws {
        let client = makeClient()
        MockURLProtocol.handler = { request in
            #expect(request.url?.path == "/api/v1/properties/sw7-5ph-10-example-road")
            return (
                Self.response(for: request, status: 200),
                Self.data("""
                {
                  "data": {
                    "slug": "sw7-5ph-10-example-road",
                    "address": "10 Example Road, London, SW7 5PH",
                    "property_type": {"code": "T", "label": "Terraced"},
                    "location": {
                      "postcode": "SW7 5PH",
                      "latitude": 51.5,
                      "longitude": -0.17,
                      "approximate": true
                    },
                    "transactions": [{"date":"2025-05-01","price":950000}],
                    "epc_certificates": [],
                    "nearby_schools": {"primary": [], "secondary": []},
                    "crime": {"summary":"Crime is stable","direction":"flat","categories":[],"trend":[]},
                    "deprivation": {"decile": 8},
                    "deprivation_message": null,
                    "council_tax_estimate": {"band": "F"},
                    "market": {
                      "property_price_history": [],
                      "postcode": {"price_history": [], "sales_history": []},
                      "locality": {"price_history": [], "sales_history": [], "property_types": [], "url": null},
                      "town": {"price_history": [], "sales_history": [], "property_types": [], "url": null},
                      "district": {"price_history": [], "sales_history": [], "property_types": [], "url": null},
                      "county": {"price_history": [], "sales_history": [], "property_types": [], "url": null}
                    }
                  }
                }
                """)
            )
        }

        let property = try await client.propertyDetails(slug: "sw7-5ph-10-example-road")

        #expect(property.slug == "sw7-5ph-10-example-road")
        #expect(property.location?.postcode == "SW7 5PH")
        #expect(property.transactions?.first?.price == 950000)
        #expect(property.propertyType?.label == "Terraced")
    }

    @Test
    func propertyDetailAllowsMissingOptionalResearchSections() async throws {
        let client = makeClient()
        MockURLProtocol.handler = { request in
            (
                Self.response(for: request, status: 200),
                Self.data(#"{"data":{"slug":"sw7-5ph-10-example-road","address":null}}"#)
            )
        }

        let property = try await client.propertyDetails(slug: "sw7-5ph-10-example-road")

        #expect(property.address == nil)
        #expect(property.location == nil)
        #expect(property.epcCertificates == nil)
        #expect(property.nearbySchools == nil)
        #expect(property.market == nil)
    }

    @Test
    func successfulEPCCertificateResponseUsesSuppliedAPIURL() async throws {
        let client = makeClient()
        let apiURL = URL(
            string: "https://example.test/api/v1/epc/8904-2404-6929-2796-0763"
        )!

        MockURLProtocol.handler = { request in
            #expect(request.url == apiURL)
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")

            return (
                Self.response(for: request, status: 200),
                Self.data("""
                {
                  "data": {
                    "lmk_key": "8904-2404-6929-2796-0763",
                    "address": {
                      "display": "32, Laleham Court, Chobham Road",
                      "postcode": "GU21 4AX"
                    },
                    "certificate": {
                      "inspection_date": "2025-01-10",
                      "lodgement_date": "2025-01-12"
                    },
                    "property": {
                      "type": "Flat",
                      "total_floor_area_square_metres": 81
                    },
                    "energy": {
                      "current_rating": "C",
                      "potential_rating": "B",
                      "current_efficiency": 72,
                      "potential_efficiency": 80
                    },
                    "environmental_impact": {
                      "current_score": 70,
                      "potential_score": 80
                    },
                    "estimated_costs": {
                      "lighting": {"current": 120, "potential": 80}
                    },
                    "website_url": "https://propertyresearch.uk/epc/8904-2404-6929-2796-0763"
                  }
                }
                """)
            )
        }

        let certificate = try await client.epcCertificate(at: apiURL)

        #expect(certificate.lmkKey == "8904-2404-6929-2796-0763")
        #expect(certificate.energy?.currentRating == "C")
        #expect(certificate.energy?.potentialEfficiency == 80)
        #expect(certificate.property?.totalFloorAreaSquareMetres == 81)
        #expect(certificate.environmentalImpact?.potentialScore == 80)
    }

    @Test
    func epcCertificateMaps404ToCertificateNotFound() async {
        let client = makeClient()
        let apiURL = URL(string: "https://example.test/api/v1/epc/missing")!

        MockURLProtocol.handler = { request in
            (
                Self.response(for: request, status: 404),
                Self.data(#"{"message":"Not found"}"#)
            )
        }

        await #expect(throws: APIError.epcCertificateNotFound) {
            try await client.epcCertificate(at: apiURL)
        }
    }

    @Test
    func successfulEPCDashboardResponseUsesNationQuery() async throws {
        let client = makeClient()

        MockURLProtocol.handler = { request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw URLError(.badURL)
            }

            #expect(components.path == "/api/v1/epc/dashboard")
            #expect(components.queryItems?.first(where: { $0.name == "nation" })?.value == "scotland")

            return (
                Self.response(for: request, status: 200),
                Self.data("""
                {
                  "data": {
                    "nation": "scotland",
                    "nation_label": "Scotland",
                    "available_from": "2015-01-01",
                    "statistics": {
                      "total_certificates": 100,
                      "latest_lodgement_date": "2026-06-25",
                      "last_30_days": 10,
                      "last_12_months": 80
                    },
                    "certificates_by_year": [{"year":2026,"count":80}],
                    "current_ratings_by_year": [{"year":2026,"rating":"D","count":40,"percentage":50}],
                    "potential_ratings_by_year": [{"year":2026,"rating":"C","count":60,"percentage":75}],
                    "rating_distribution": [{"rating":"D","count":40,"percentage":40}],
                    "tenure_by_year": [{"year":2026,"tenure":"Rented (social)","count":20,"percentage":25}],
                    "website_url": "https://example.test/epc?nation=scotland"
                  }
                }
                """)
            )
        }

        let dashboard = try await client.epcDashboard(nation: .scotland)

        #expect(dashboard.nation == "scotland")
        #expect(dashboard.statistics.totalCertificates == 100)
        #expect(dashboard.certificatesByYear.first?.count == 80)
        #expect(dashboard.ratingDistribution.first?.rating == "D")
        #expect(dashboard.tenureByYear.first?.tenure == "Rented (social)")
    }

    @Test
    func successfulEPCSearchUsesPostcodeNationAndPagination() async throws {
        let client = makeClient()

        MockURLProtocol.handler = { request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw URLError(.badURL)
            }

            #expect(components.path == "/api/v1/epc/search")
            #expect(components.queryItems?.first(where: { $0.name == "nation" })?.value == "england-wales")
            #expect(components.queryItems?.first(where: { $0.name == "postcode" })?.value == "SW7 5PH")
            #expect(components.queryItems?.first(where: { $0.name == "page" })?.value == "2")
            #expect(url.absoluteString.contains("postcode=SW7%205PH"))

            return (
                Self.response(for: request, status: 200),
                Self.data("""
                {
                  "data": {
                    "nation": "england-wales",
                    "nation_label": "England & Wales",
                    "postcode": "SW7 5PH",
                    "results": [{
                      "reference": "EW-SEARCH-1",
                      "address": "1 Exhibition Road",
                      "postcode": "SW7 5PH",
                      "lodgement_date": "2026-01-02",
                      "current_energy_rating": "C",
                      "potential_energy_rating": "B",
                      "property_type": "Flat",
                      "total_floor_area_square_metres": 72.5,
                      "local_authority": "Kensington and Chelsea",
                      "api_url": "https://example.test/api/v1/epc/EW-SEARCH-1",
                      "website_url": "https://example.test/epc/EW-SEARCH-1"
                    }],
                    "meta": {
                      "current_page": 2,
                      "last_page": 2,
                      "per_page": 50,
                      "total": 51
                    }
                  }
                }
                """)
            )
        }

        let results = try await client.searchEPCs(
            postcode: "SW7 5PH",
            nation: .englandWales,
            page: 2
        )

        #expect(results.postcode == "SW7 5PH")
        #expect(results.results.first?.reference == "EW-SEARCH-1")
        #expect(results.results.first?.totalFloorAreaSquareMetres == 72.5)
        #expect(results.meta.currentPage == 2)
        #expect(results.meta.total == 51)
    }

    @Test
    func successfulSchoolResponseUsesSuppliedAPIURL() async throws {
        let client = makeClient()
        let apiURL = URL(
            string: "https://example.test/api/v1/schools/bousfield-primary-school"
        )!

        MockURLProtocol.handler = { request in
            #expect(request.url == apiURL)
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")

            return (
                Self.response(for: request, status: 200),
                Self.data("""
                {
                  "data": {
                    "slug": "bousfield-primary-school",
                    "urn": "100001",
                    "name": "Bousfield Primary School",
                    "phase": "Primary",
                    "establishment_type": "Community school",
                    "age_range": {
                      "minimum": 4,
                      "maximum": 11,
                      "label": "4 to 11"
                    },
                    "pupil_count": 450,
                    "capacity": 480,
                    "address": "Bolton Gardens, London",
                    "postcode": "SW5 0DJ",
                    "latitude": 51.4912,
                    "longitude": -0.1911,
                    "telephone": "02073736544",
                    "school_website": "https://bousfield.example",
                    "headteacher": "Ms Alex Example",
                    "current_ofsted_rating": "Outstanding",
                    "latest_inspection_date": "2025-02-03",
                    "inspection_type": "Graded inspection",
                    "inspection_outcome": "Inspection",
                    "ofsted_report_url": "https://reports.ofsted.gov.uk/provider/21/100001",
                    "local_property_market": {
                      "outcode": "SW5",
                      "nearby_streets": [{
                        "name": "Example Street",
                        "sales_count": 4,
                        "average_price": 900000,
                        "average_price_label": "£900,000",
                        "url": "/property/street/sw5/example-street"
                      }],
                      "recent_sales": [{
                        "address": "10 Example Street",
                        "postcode": "SW5 0DJ",
                        "price": 950000,
                        "price_label": "£950,000",
                        "date_label": "1 Jun 2026",
                        "property_type": "Flat or maisonette",
                        "url": "/property/sw5-0dj-10-example-street"
                      }],
                      "updated_label": "1 Jun 2026"
                    },
                    "website_url": "https://propertyresearch.uk/school/bousfield-primary-school"
                  }
                }
                """)
            )
        }

        let school = try await client.school(at: apiURL)

        #expect(school.slug == "bousfield-primary-school")
        #expect(school.name == "Bousfield Primary School")
        #expect(school.ageRange?.minimum == 4)
        #expect(school.pupilCount == 450)
        #expect(school.currentOfstedRating == "Outstanding")
        #expect(school.localPropertyMarket?.outcode == "SW5")
        #expect(school.localPropertyMarket?.nearbyStreets?.first?.salesCount == 4)
        #expect(school.localPropertyMarket?.recentSales?.first?.price == 950000)
    }

    @Test
    func schoolAllowsMissingOptionalFields() async throws {
        let client = makeClient()
        let apiURL = URL(string: "https://example.test/api/v1/schools/example-school")!

        MockURLProtocol.handler = { request in
            (
                Self.response(for: request, status: 200),
                Self.data(#"{"data":{"slug":"example-school","name":"Example School","telephone":null,"school_website":null,"current_ofsted_rating":null,"local_property_market":null}}"#)
            )
        }

        let school = try await client.school(at: apiURL)

        #expect(school.name == "Example School")
        #expect(school.telephone == nil)
        #expect(school.schoolWebsite == nil)
        #expect(school.currentOfstedRating == nil)
        #expect(school.localPropertyMarket == nil)
    }

    @Test
    func schoolMaps404ToSchoolNotFound() async {
        let client = makeClient()
        let apiURL = URL(string: "https://example.test/api/v1/schools/missing")!

        MockURLProtocol.handler = { request in
            (
                Self.response(for: request, status: 404),
                Self.data(#"{"message":"School not found"}"#)
            )
        }

        await #expect(throws: APIError.schoolNotFound) {
            try await client.school(at: apiURL)
        }
    }

    @Test
    func successfulSchoolPostcodeSearchUsesQueryEncoding() async throws {
        let client = makeClient()

        MockURLProtocol.handler = { request in
            guard let url = request.url,
                  let components = URLComponents(url: url, resolvingAgainstBaseURL: false) else {
                throw URLError(.badURL)
            }

            #expect(components.path == "/api/v1/schools")
            #expect(components.queryItems?.first(where: { $0.name == "postcode" })?.value == "SW7 5PH")
            #expect(url.absoluteString.contains("postcode=SW7%205PH"))
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")

            return (
                Self.response(for: request, status: 200),
                Self.data("""
                {
                  "data": {
                    "postcode": "SW7 5PH",
                    "latitude": 51.49,
                    "longitude": -0.18,
                    "primary": [{
                      "urn": "100001",
                      "name": "Near Primary",
                      "slug": "near-primary",
                      "postcode": "SW7 4AB",
                      "phase": "Primary",
                      "establishment_type": "Community school",
                      "age_range": "4-11",
                      "distance_miles": 0.4,
                      "current_ofsted_rating": "Outstanding",
                      "latest_inspection_date": "2025-02-03",
                      "api_url": "https://example.test/api/v1/schools/near-primary",
                      "website_url": "https://example.test/school/near-primary"
                    }],
                    "secondary": [{
                      "urn": "100002",
                      "name": "Near Secondary",
                      "slug": "near-secondary",
                      "postcode": "SW7 4AB",
                      "phase": "Secondary",
                      "establishment_type": null,
                      "age_range": "11-18",
                      "distance_miles": 0.7,
                      "current_ofsted_rating": null,
                      "latest_inspection_date": null,
                      "api_url": "https://example.test/api/v1/schools/near-secondary",
                      "website_url": "https://example.test/school/near-secondary"
                    }]
                  }
                }
                """)
            )
        }

        let results = try await client.searchSchools(postcode: "SW7 5PH")

        #expect(results.postcode == "SW7 5PH")
        #expect(results.primary.first?.name == "Near Primary")
        #expect(results.primary.first?.currentOfstedRating == "Outstanding")
        #expect(results.secondary.first?.slug == "near-secondary")
        #expect(results.secondary.first?.establishmentType == nil)
    }

    @Test
    func schoolPostcodeSearchMaps404ToPostcodeNotFound() async {
        let client = makeClient()

        MockURLProtocol.handler = { request in
            (
                Self.response(for: request, status: 404),
                Self.data(#"{"message":"Postcode not found"}"#)
            )
        }

        await #expect(throws: APIError.schoolPostcodeNotFound) {
            try await client.searchSchools(postcode: "ZZ1 1ZZ")
        }
    }

    @Test
    func successfulNationalCrimeDashboardResponse() async throws {
        let client = makeClient()

        MockURLProtocol.handler = { request in
            #expect(request.url?.path == "/api/v1/insights/crime")
            #expect(request.httpMethod == "GET")
            #expect(request.value(forHTTPHeaderField: "Accept") == "application/json")

            return (
                Self.response(for: request, status: 200),
                Self.data("""
                {
                  "data": {
                    "latest_month": "2026-03-01",
                    "latest_month_label": "March 2026",
                    "summary": {
                      "total_12m": 51,
                      "prev_12m": 39,
                      "pct_change": 30.8,
                      "last_3m_total": 15,
                      "prev_3m_total": 12,
                      "last_3m_change": 25
                    },
                    "chart": {
                      "labels": ["Jan", "Feb", "Mar"],
                      "current_year": [4, 5, 6],
                      "previous_year": [3, 4, 4]
                    },
                    "crime_types": [{
                      "type": "Theft",
                      "total_12m": 30,
                      "total_prev_12m": 24,
                      "yoy_change": 25,
                      "share_pct": 58.8,
                      "trend": "Up"
                    }],
                    "drivers": {
                      "overall_yoy": 30.8,
                      "increases": [{
                        "type": "Burglary",
                        "impact": 9,
                        "yoy_change": 300
                      }],
                      "decreases": []
                    },
                    "areas": [{
                      "area": "Alpha County",
                      "slug": "alpha-county",
                      "total_12m": 36,
                      "prev_12m": 27,
                      "pct_change": 33.3,
                      "trend": "Up",
                      "api_url": "https://example.test/api/v1/insights/crime/alpha-county",
                      "website_url": "https://example.test/insights/crime/alpha-county"
                    }],
                    "website_url": "https://example.test/insights/crime"
                  }
                }
                """)
            )
        }

        let dashboard = try await client.crimeDashboard()

        #expect(dashboard.summary.total12Months == 51)
        #expect(dashboard.summary.percentageChange == 30.8)
        #expect(dashboard.chart.points.count == 6)
        #expect(dashboard.crimeTypes.first?.type == "Theft")
        #expect(dashboard.drivers.increases.first?.impact == 9)
        #expect(dashboard.areas.first?.slug == "alpha-county")
    }

    @Test
    func successfulRegionalCrimeResponse() async throws {
        let client = makeClient()
        let apiURL = URL(
            string: "https://example.test/api/v1/insights/crime/alpha-county"
        )!

        MockURLProtocol.handler = { request in
            #expect(request.url == apiURL)
            return (
                Self.response(for: request, status: 200),
                Self.data("""
                {
                  "data": {
                    "area": "Alpha County",
                    "area_slug": "alpha-county",
                    "latest_month": "2026-03-01",
                    "latest_month_label": "March 2026",
                    "summary": {
                      "total_12m": 36,
                      "prev_12m": 27,
                      "pct_change": 33.3,
                      "last_3m_total": 9,
                      "prev_3m_total": 7,
                      "last_3m_change": 28.6
                    },
                    "chart": {
                      "labels": ["Jan"],
                      "current_year": [3],
                      "previous_year": [2]
                    },
                    "crime_breakdown": [{
                      "type": "Burglary",
                      "total_12m": 12,
                      "total_prev_12m": 3,
                      "yoy_change": 300,
                      "share_pct": 33.3,
                      "impact": 9,
                      "trend": "Up",
                      "national_yoy": 300,
                      "is_largest": false
                    }],
                    "drivers": {
                      "overall_yoy": 33.3,
                      "increases": [],
                      "decreases": []
                    },
                    "website_url": "https://example.test/insights/crime/alpha-county"
                  }
                }
                """)
            )
        }

        let area = try await client.crimeArea(at: apiURL)

        #expect(area.area == "Alpha County")
        #expect(area.summary.total12Months == 36)
        #expect(area.crimeBreakdown.first?.nationalYearOnYear == 300)
    }

    @Test
    func regionalCrimeMaps404ToAreaNotFound() async {
        let client = makeClient()
        let apiURL = URL(string: "https://example.test/api/v1/insights/crime/missing")!

        MockURLProtocol.handler = { request in
            (
                Self.response(for: request, status: 404),
                Self.data(#"{"message":"Not found"}"#)
            )
        }

        await #expect(throws: APIError.crimeAreaNotFound) {
            try await client.crimeArea(at: apiURL)
        }
    }

    @Test(arguments: [
        (422, APIError.validation("Enter a valid UK postcode.")),
        (404, APIError.propertyNotFound),
        (429, APIError.rateLimited),
        (500, APIError.serverUnavailable)
    ])
    func mapsHTTPErrorResponses(status: Int, expectedError: APIError) async {
        let client = makeClient()
        MockURLProtocol.handler = { request in
            let body = status == 422
                ? #"{"message":"The postcode field is invalid.","errors":{"postcode":["Enter a valid UK postcode."]}}"#
                : #"{"message":"Request failed"}"#
            return (
                Self.response(for: request, status: status),
                Self.data(body)
            )
        }

        await #expect(throws: expectedError) {
            try await client.searchProperties(postcode: "SW7 5PH", page: 1)
        }
    }

    @Test
    func malformedJSONReturnsFriendlyInvalidDataError() async {
        let client = makeClient()
        MockURLProtocol.handler = { request in
            (
                Self.response(for: request, status: 200),
                Self.data(#"{"postcode":"SW7 5PH","results":"not-an-array"}"#)
            )
        }

        await #expect(throws: APIError.invalidData) {
            try await client.searchProperties(postcode: "SW7 5PH", page: 1)
        }
    }

    @Test
    func successfulPropertyMarketDashboardDecodesAllNationalDatasets() async throws {
        let client = makeClient()
        MockURLProtocol.handler = { request in
            #expect(request.url?.path == "/api/v1/property/dashboard")

            return (
                Self.response(for: request, status: 200),
                Self.data("""
                {
                  "data": {
                    "metadata": {
                      "region": "England and Wales",
                      "latest_month": "2026-05",
                      "range_start": "1995-01",
                      "rolling_window_months": 12,
                      "category": "A",
                      "source": "HM Land Registry",
                      "is_provisional": true,
                      "generated_at": "2026-07-25T12:00:00Z"
                    },
                    "summary": {
                      "sales": 596485,
                      "median_price": 290000,
                      "median_price_change": -3.32,
                      "sales_volume_change": -27.61
                    },
                    "monthly_sales": [
                      {"period":"2026-05","value":12345,"is_provisional":true}
                    ],
                    "rolling_market": [
                      {
                        "period":"2026-05",
                        "sales":596485,
                        "median_price":290000,
                        "percentile_90":635000,
                        "top_5_average":1292747,
                        "largest_sale":53000000
                      }
                    ],
                    "largest_sales": [
                      {
                        "period":"2026-05",
                        "rank":1,
                        "price":53000000,
                        "postcode":"NW8 6JD",
                        "date":"2025-09-03"
                      }
                    ],
                    "property_types": [
                      {
                        "period":"2026-05",
                        "detached":{"sales":151222,"median_price":421000},
                        "semi_detached":{"sales":180850,"median_price":275000},
                        "terraced":{"sales":170131,"median_price":238000},
                        "flat":{"sales":94282,"median_price":225000},
                        "other":{"sales":10000,"median_price":300000}
                      }
                    ],
                    "stock_mix": [
                      {"period":"2026-05","new_build":12345,"existing":584140}
                    ],
                    "tenure_mix": [
                      {"period":"2026-05","freehold":410000,"leasehold":186485}
                    ],
                    "year_on_year": [
                      {
                        "period":"2026-05",
                        "sales":-27.61,
                        "median_price":-3.32,
                        "percentile_90":-1.55,
                        "top_5_average":-6.16
                      }
                    ]
                  }
                }
                """)
            )
        }

        let dashboard = try await client.propertyMarketDashboard()

        #expect(dashboard.metadata.latestMonth == "2026-05")
        #expect(dashboard.summary.sales == 596485)
        #expect(dashboard.monthlySales.first?.isProvisional == true)
        #expect(dashboard.rollingMarket.first?.top5Average == 1292747)
        #expect(dashboard.largestSales.first?.postcode == "NW8 6JD")
        #expect(dashboard.propertyTypes.first?.semiDetached.medianPrice == 275000)
        #expect(dashboard.stockMix.first?.newBuild == 12345)
        #expect(dashboard.tenureMix.first?.freehold == 410000)
        #expect(dashboard.yearOnYear.first?.sales == -27.61)
    }

    @Test
    func requestCancellationCancelsURLLoading() async throws {
        let client = makeClient()
        MockURLProtocol.responseDelay = 2
        MockURLProtocol.handler = { request in
            (
                Self.response(for: request, status: 200),
                Self.data(#"{"postcode":"SW7 5PH","results":[],"meta":null}"#)
            )
        }

        let task = Task {
            try await client.searchProperties(postcode: "SW7 5PH", page: 1)
        }
        try await Task.sleep(for: .milliseconds(50))
        task.cancel()

        await #expect(throws: CancellationError.self) {
            try await task.value
        }
        #expect(MockURLProtocol.requestWasCancelled)
    }

    private func makeClient() -> PropertyResearchAPIClient {
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [MockURLProtocol.self]
        return PropertyResearchAPIClient(
            session: URLSession(configuration: configuration),
            baseURL: baseURL
        )
    }

    nonisolated private static func response(for request: URLRequest, status: Int) -> HTTPURLResponse {
        HTTPURLResponse(
            url: request.url!,
            statusCode: status,
            httpVersion: nil,
            headerFields: ["Content-Type": "application/json"]
        )!
    }

    nonisolated private static func data(_ string: String) -> Data {
        Data(string.utf8)
    }
}
