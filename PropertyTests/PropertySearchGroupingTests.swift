import Testing
@testable import Property

@MainActor
struct PropertySearchGroupingTests {
    @Test
    func duplicatePropertySlugsKeepNewestTransaction() {
        let older = result(
            transactionID: "older",
            price: 400000,
            date: "2020-01-01",
            slug: "sw7-5ph-10-example-road"
        )
        let newer = result(
            transactionID: "newer",
            price: 650000,
            date: "2025-06-01",
            slug: "sw7-5ph-10-example-road"
        )
        let other = result(
            transactionID: "other",
            price: 700000,
            date: "2024-03-01",
            slug: "sw7-5ph-12-example-road"
        )

        let grouped = PropertySearchResult.groupedNewest([older, other, newer])

        #expect(grouped.count == 2)
        #expect(grouped.first(where: { $0.propertySlug == newer.propertySlug })?.transactionID == "newer")
        #expect(grouped.first(where: { $0.propertySlug == newer.propertySlug })?.price == 650000)
    }

    private func result(
        transactionID: String,
        price: Int,
        date: String,
        slug: String
    ) -> PropertySearchResult {
        PropertySearchResult(
            transactionID: transactionID,
            price: price,
            date: date,
            propertyType: "T",
            newBuild: "N",
            duration: "F",
            paon: "10",
            saon: nil,
            street: "EXAMPLE ROAD",
            locality: nil,
            townCity: "LONDON",
            district: nil,
            county: nil,
            postcode: "SW7 5PH",
            category: "A",
            propertySlug: slug,
            url: nil
        )
    }
}
