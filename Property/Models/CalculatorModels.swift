import Foundation

struct MortgageCalculation: Equatable {
    let amount: Int
    let termYears: Int
    let ratePercent: Double
    let annualOverpayment: Int
    let repaymentMonthly: Double
    let repaymentAnnual: Double
    let repaymentTotalPaid: Double
    let repaymentTotalInterest: Double
    let repaymentPerPound: Double
    let repaymentPoints: [MortgageBalancePoint]
    let repaymentOverpaymentPoints: [MortgageBalancePoint]?
    let interestOnlyMonthly: Double
    let interestOnlyAnnual: Double
    let interestOnlyTotalInterest: Double
    let interestOnlyPerPound: Double
    let interestOnlyPoints: [MortgageBalancePoint]
    let interestOnlyOverpaymentPoints: [MortgageBalancePoint]?
    let overpaymentImpact: MortgageOverpaymentImpact?
    let stressRate: Double
    let stressedRatePercent: Double
    let repaymentMonthlyStressed: Double
    let repaymentMonthlyExtra: Double
    let interestOnlyMonthlyStressed: Double
    let interestOnlyMonthlyExtra: Double
}

struct MortgageBalancePoint: Equatable, Identifiable {
    let year: Double
    let balance: Double
    var id: String { "\(year)-\(balance)" }
}

struct MortgageOverpaymentImpact: Equatable {
    let annualOverpayment: Int
    let repayment: MortgageOverpaymentResult
    let interestOnly: MortgageOverpaymentResult
}

struct MortgageOverpaymentResult: Equatable {
    let newTermMonths: Int
    let monthsSaved: Int
    let totalInterest: Double
    let interestSaved: Double

    var newTermLabel: String { MortgageCalculator.formatMonths(newTermMonths) }
    var timeSavedLabel: String { MortgageCalculator.formatMonths(monthsSaved) }
}

enum MortgageCalculator {
    static func calculate(
        amount: Int,
        termYears: Int,
        ratePercent: Double,
        annualOverpayment: Int = 0
    ) -> MortgageCalculation {
        let termMonths = termYears * 12
        let monthlyRate = ratePercent / 100 / 12
        let monthly = monthlyPayment(
            amount: amount,
            monthlyRate: monthlyRate,
            months: termMonths
        )
        let standard = repaymentSchedule(
            amount: amount,
            monthlyRate: monthlyRate,
            scheduledPayment: monthly,
            scheduledMonths: termMonths
        )
        let interestOnlyMonthly = Double(amount) * (ratePercent / 100) / 12
        let interestOnlyTotal = interestOnlyMonthly * Double(termMonths)
        let stressRate = 3.0
        let stressedRate = ratePercent + stressRate
        let stressedMonthlyRate = stressedRate / 100 / 12
        let repaymentStressed = monthlyPayment(
            amount: amount,
            monthlyRate: stressedMonthlyRate,
            months: termMonths
        )
        let interestOnlyStressed = Double(amount) * (stressedRate / 100) / 12

        var impact: MortgageOverpaymentImpact?
        var repaymentOverpaymentPoints: [MortgageBalancePoint]?
        var interestOnlyOverpaymentPoints: [MortgageBalancePoint]?

        if annualOverpayment > 0 {
            let overpaid = repaymentSchedule(
                amount: amount,
                monthlyRate: monthlyRate,
                scheduledPayment: monthly,
                scheduledMonths: termMonths,
                annualOverpayment: annualOverpayment
            )
            let interestOnlyOverpaid = interestOnlyOverpaymentSchedule(
                amount: amount,
                monthlyRate: monthlyRate,
                scheduledMonths: termMonths,
                annualOverpayment: annualOverpayment
            )
            impact = MortgageOverpaymentImpact(
                annualOverpayment: annualOverpayment,
                repayment: MortgageOverpaymentResult(
                    newTermMonths: overpaid.months,
                    monthsSaved: max(0, standard.months - overpaid.months),
                    totalInterest: overpaid.totalInterest,
                    interestSaved: max(0, standard.totalInterest - overpaid.totalInterest)
                ),
                interestOnly: MortgageOverpaymentResult(
                    newTermMonths: interestOnlyOverpaid.months,
                    monthsSaved: max(0, termMonths - interestOnlyOverpaid.months),
                    totalInterest: interestOnlyOverpaid.totalInterest,
                    interestSaved: max(0, interestOnlyTotal - interestOnlyOverpaid.totalInterest)
                )
            )
            repaymentOverpaymentPoints = overpaid.points
            interestOnlyOverpaymentPoints = interestOnlyChart(
                amount: amount,
                termYears: termYears,
                annualOverpayment: annualOverpayment
            )
        }

        return MortgageCalculation(
            amount: amount,
            termYears: termYears,
            ratePercent: ratePercent,
            annualOverpayment: annualOverpayment,
            repaymentMonthly: monthly,
            repaymentAnnual: monthly * 12,
            repaymentTotalPaid: standard.totalPaid,
            repaymentTotalInterest: standard.totalInterest,
            repaymentPerPound: amount > 0 ? standard.totalPaid / Double(amount) : 0,
            repaymentPoints: standard.points,
            repaymentOverpaymentPoints: repaymentOverpaymentPoints,
            interestOnlyMonthly: interestOnlyMonthly,
            interestOnlyAnnual: interestOnlyMonthly * 12,
            interestOnlyTotalInterest: interestOnlyTotal,
            interestOnlyPerPound: amount > 0 ? interestOnlyTotal / Double(amount) : 0,
            interestOnlyPoints: interestOnlyChart(amount: amount, termYears: termYears),
            interestOnlyOverpaymentPoints: interestOnlyOverpaymentPoints,
            overpaymentImpact: impact,
            stressRate: stressRate,
            stressedRatePercent: stressedRate,
            repaymentMonthlyStressed: repaymentStressed,
            repaymentMonthlyExtra: max(0, repaymentStressed - monthly),
            interestOnlyMonthlyStressed: interestOnlyStressed,
            interestOnlyMonthlyExtra: max(0, interestOnlyStressed - interestOnlyMonthly)
        )
    }

    static func formatMonths(_ months: Int) -> String {
        let years = months / 12
        let remainder = months % 12
        if years == 0 { return remainder == 1 ? "1 month" : "\(remainder) months" }
        if remainder == 0 { return years == 1 ? "1 year" : "\(years) years" }
        let yearLabel = years == 1 ? "1 year" : "\(years) years"
        let monthLabel = remainder == 1 ? "1 month" : "\(remainder) months"
        return "\(yearLabel), \(monthLabel)"
    }

    private static func monthlyPayment(amount: Int, monthlyRate: Double, months: Int) -> Double {
        guard monthlyRate != 0 else {
            return Double(amount) / Double(max(months, 1))
        }
        return (Double(amount) * monthlyRate) / (1 - pow(1 + monthlyRate, -Double(months)))
    }

    private static func repaymentSchedule(
        amount: Int,
        monthlyRate: Double,
        scheduledPayment: Double,
        scheduledMonths: Int,
        annualOverpayment: Int = 0
    ) -> (months: Int, totalInterest: Double, totalPaid: Double, points: [MortgageBalancePoint]) {
        var balance = Double(amount)
        var month = 0
        var totalInterest = 0.0
        var totalPaid = 0.0
        var points = [MortgageBalancePoint(year: 0, balance: rounded(balance))]

        while balance > 0, month < scheduledMonths {
            month += 1
            let interest = monthlyRate == 0 ? 0 : balance * monthlyRate
            let actualPayment = min(scheduledPayment, balance + interest)
            balance = max(0, balance - max(0, actualPayment - interest))
            totalInterest += interest
            totalPaid += actualPayment

            if annualOverpayment > 0, balance > 0, month.isMultiple(of: 12) {
                let applied = min(Double(annualOverpayment), balance)
                balance -= applied
                totalPaid += applied
            }

            if month.isMultiple(of: 12) {
                points.append(
                    MortgageBalancePoint(
                        year: rounded(Double(month) / 12),
                        balance: rounded(balance)
                    )
                )
            }

            if balance <= 0 {
                let payoffYear = rounded(Double(month) / 12)
                if points.last?.year == payoffYear {
                    points[points.count - 1] = MortgageBalancePoint(year: payoffYear, balance: 0)
                } else {
                    points.append(MortgageBalancePoint(year: payoffYear, balance: 0))
                }
                break
            }
        }

        return (month, rounded(totalInterest), rounded(totalPaid), points)
    }

    private static func interestOnlyChart(
        amount: Int,
        termYears: Int,
        annualOverpayment: Int = 0
    ) -> [MortgageBalancePoint] {
        var points = [MortgageBalancePoint(year: 0, balance: Double(amount))]
        var balance = Double(amount)
        for year in 1...termYears {
            if annualOverpayment > 0, balance > 0 {
                balance = max(0, balance - Double(annualOverpayment))
            }
            points.append(MortgageBalancePoint(year: Double(year), balance: rounded(balance)))
            if balance <= 0 { break }
        }
        return points
    }

    private static func interestOnlyOverpaymentSchedule(
        amount: Int,
        monthlyRate: Double,
        scheduledMonths: Int,
        annualOverpayment: Int
    ) -> (months: Int, totalInterest: Double) {
        var balance = Double(amount)
        var month = 0
        var totalInterest = 0.0
        while balance > 0, month < scheduledMonths {
            month += 1
            totalInterest += monthlyRate == 0 ? 0 : balance * monthlyRate
            if month.isMultiple(of: 12) {
                balance = max(0, balance - Double(annualOverpayment))
            }
        }
        return (month, rounded(totalInterest))
    }

    private static func rounded(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}

enum StampDutyRegion: String, CaseIterable, Identifiable {
    case englandAndNorthernIreland
    case scotland
    case wales

    var id: Self { self }
    var title: String {
        switch self {
        case .englandAndNorthernIreland: "England & NI (SDLT)"
        case .scotland: "Scotland (LBTT)"
        case .wales: "Wales (LTT)"
        }
    }
}

enum StampDutyBuyerType: String, CaseIterable, Identifiable {
    case currentOwner
    case firstTime

    var id: Self { self }
    var title: String {
        switch self {
        case .currentOwner: "Currently own a property"
        case .firstTime: "First-time buyer"
        }
    }
}

struct StampDutyCalculation: Equatable {
    let jurisdiction: String
    let buyerType: StampDutyBuyerType
    let isAdditional: Bool
    let isNonResident: Bool
    let baseTax: Double
    let bands: [StampDutyBandResult]
    let surcharges: [StampDutySurcharge]
    let totalTax: Double
}

struct StampDutyBandResult: Equatable, Identifiable {
    let from: Double
    let to: Double
    let ratePercent: Double
    let amount: Double
    let tax: Double
    var id: String { "\(from)-\(to)-\(ratePercent)" }
}

struct StampDutySurcharge: Equatable, Identifiable {
    let label: String
    let ratePercent: Double
    let amount: Double
    let tax: Double
    var id: String { label }
}

enum StampDutyCalculator {
    static func calculate(
        price: Double,
        region: StampDutyRegion,
        buyerType requestedBuyerType: StampDutyBuyerType,
        isAdditional: Bool,
        isNonResident: Bool
    ) -> StampDutyCalculation {
        let buyerType: StampDutyBuyerType =
            requestedBuyerType == .firstTime && isAdditional ? .currentOwner : requestedBuyerType

        switch region {
        case .englandAndNorthernIreland:
            let bands = buyerType == .firstTime && price <= 500_000
                ? [(300_000.0, 0.0), (500_000, 5), (925_000, 5), (1_500_000, 10), (.infinity, 12)]
                : [(125_000.0, 0.0), (250_000, 2), (925_000, 5), (1_500_000, 10), (.infinity, 12)]
            let base = progressive(price: price, bands: bands)
            var surcharges: [StampDutySurcharge] = []
            if isAdditional {
                surcharges.append(surcharge("Higher rates (additional property)", 5, price))
            }
            if isNonResident {
                surcharges.append(surcharge("Non-resident surcharge", 2, price))
            }
            return result(
                "SDLT (England & Northern Ireland)",
                buyerType,
                isAdditional,
                isNonResident,
                base,
                surcharges
            )

        case .scotland:
            let bands = buyerType == .firstTime
                ? [(175_000.0, 0.0), (250_000, 2), (325_000, 5), (750_000, 10), (.infinity, 12)]
                : [(145_000.0, 0.0), (250_000, 2), (325_000, 5), (750_000, 10), (.infinity, 12)]
            let base = progressive(price: price, bands: bands)
            let surcharges = isAdditional
                ? [surcharge("Additional Dwelling Supplement (ADS)", 8, price)]
                : []
            return result("LBTT (Scotland)", buyerType, isAdditional, false, base, surcharges)

        case .wales:
            let bands = isAdditional
                ? [(180_000.0, 5.0), (250_000, 8.5), (400_000, 10), (750_000, 12.5), (1_500_000, 15), (.infinity, 17)]
                : [(225_000.0, 0.0), (400_000, 6), (750_000, 7.5), (1_500_000, 10), (.infinity, 12)]
            let base = progressive(price: price, bands: bands)
            return result("LTT (Wales)", buyerType, isAdditional, false, base, [])
        }
    }

    private static func progressive(
        price: Double,
        bands: [(Double, Double)]
    ) -> (tax: Double, bands: [StampDutyBandResult]) {
        var lower = 0.0
        var tax = 0.0
        var results: [StampDutyBandResult] = []
        for (upper, rate) in bands {
            let portion = max(0, min(price, upper) - lower)
            if portion > 0 {
                let bandTax = portion * rate / 100
                tax += bandTax
                results.append(
                    StampDutyBandResult(
                        from: lower,
                        to: upper,
                        ratePercent: rate,
                        amount: portion,
                        tax: rounded(bandTax)
                    )
                )
            }
            lower = upper
            if lower >= price { break }
        }
        return (rounded(tax), results)
    }

    private static func surcharge(
        _ label: String,
        _ rate: Double,
        _ amount: Double
    ) -> StampDutySurcharge {
        StampDutySurcharge(
            label: label,
            ratePercent: rate,
            amount: amount,
            tax: rounded(amount * rate / 100)
        )
    }

    private static func result(
        _ jurisdiction: String,
        _ buyerType: StampDutyBuyerType,
        _ additional: Bool,
        _ nonResident: Bool,
        _ base: (tax: Double, bands: [StampDutyBandResult]),
        _ surcharges: [StampDutySurcharge]
    ) -> StampDutyCalculation {
        StampDutyCalculation(
            jurisdiction: jurisdiction,
            buyerType: buyerType,
            isAdditional: additional,
            isNonResident: nonResident,
            baseTax: base.tax,
            bands: base.bands,
            surcharges: surcharges,
            totalTax: rounded(base.tax + surcharges.reduce(0) { $0 + $1.tax })
        )
    }

    private static func rounded(_ value: Double) -> Double {
        (value * 100).rounded() / 100
    }
}

