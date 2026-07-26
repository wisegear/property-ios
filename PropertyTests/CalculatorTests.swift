import Testing
@testable import Property

@Suite
struct CalculatorTests {
    @Test
    func mortgageMatchesWebsiteBaselineExample() {
        let result = MortgageCalculator.calculate(
            amount: 250_000,
            termYears: 30,
            ratePercent: 4.5
        )

        #expect(abs(result.repaymentMonthly - 1_266.71) < 0.01)
        #expect(result.interestOnlyMonthly == 937.5)
        #expect(result.stressedRatePercent == 7.5)
        #expect(result.overpaymentImpact == nil)
        #expect(result.repaymentPoints.last?.balance == 0)
        #expect(result.interestOnlyPoints.last?.balance == 250_000)
    }

    @Test
    func annualOverpaymentReducesMortgageTermAndInterest() {
        let result = MortgageCalculator.calculate(
            amount: 250_000,
            termYears: 30,
            ratePercent: 4.5,
            annualOverpayment: 2_500
        )

        #expect(result.overpaymentImpact?.repayment.monthsSaved ?? 0 > 0)
        #expect(result.overpaymentImpact?.repayment.interestSaved ?? 0 > 0)
        #expect(result.overpaymentImpact?.interestOnly.interestSaved ?? 0 > 0)
        #expect(result.repaymentOverpaymentPoints?.last?.balance == 0)
    }

    @Test
    func largeOverpaymentSafelyPaysOffEarly() {
        let result = MortgageCalculator.calculate(
            amount: 10_000,
            termYears: 2,
            ratePercent: 5,
            annualOverpayment: 50_000
        )

        #expect(result.overpaymentImpact?.repayment.newTermMonths ?? 99 <= 12)
        #expect(result.overpaymentImpact?.repayment.totalInterest ?? -1 >= 0)
        #expect(result.overpaymentImpact?.interestOnly.totalInterest ?? -1 >= 0)
        #expect(result.repaymentOverpaymentPoints?.last?.balance == 0)
    }

    @Test
    func englandStampDutyMatchesWebsiteBandsAndSurcharges() {
        let standard = StampDutyCalculator.calculate(
            price: 350_000,
            region: .englandAndNorthernIreland,
            buyerType: .currentOwner,
            isAdditional: false,
            isNonResident: false
        )
        let firstTime = StampDutyCalculator.calculate(
            price: 350_000,
            region: .englandAndNorthernIreland,
            buyerType: .firstTime,
            isAdditional: false,
            isNonResident: false
        )
        let additionalNonResident = StampDutyCalculator.calculate(
            price: 350_000,
            region: .englandAndNorthernIreland,
            buyerType: .firstTime,
            isAdditional: true,
            isNonResident: true
        )

        #expect(standard.totalTax == 7_500)
        #expect(firstTime.totalTax == 2_500)
        #expect(additionalNonResident.buyerType == .currentOwner)
        #expect(additionalNonResident.baseTax == 7_500)
        #expect(additionalNonResident.totalTax == 32_000)
    }

    @Test
    func scotlandAndWalesMatchWebsiteBands() {
        let scotland = StampDutyCalculator.calculate(
            price: 350_000,
            region: .scotland,
            buyerType: .currentOwner,
            isAdditional: false,
            isNonResident: true
        )
        let scotlandFirstTime = StampDutyCalculator.calculate(
            price: 350_000,
            region: .scotland,
            buyerType: .firstTime,
            isAdditional: false,
            isNonResident: false
        )
        let wales = StampDutyCalculator.calculate(
            price: 350_000,
            region: .wales,
            buyerType: .firstTime,
            isAdditional: false,
            isNonResident: false
        )
        let walesAdditional = StampDutyCalculator.calculate(
            price: 350_000,
            region: .wales,
            buyerType: .currentOwner,
            isAdditional: true,
            isNonResident: false
        )

        #expect(scotland.totalTax == 8_350)
        #expect(scotland.isNonResident == false)
        #expect(scotlandFirstTime.totalTax == 7_750)
        #expect(wales.totalTax == 7_500)
        #expect(walesAdditional.totalTax == 24_950)
    }
}

