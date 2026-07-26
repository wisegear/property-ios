import Charts
import SwiftUI

struct CalculatorsView: View {
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Label("PROPERTY TOOLS", systemImage: "function")
                        .font(.caption.bold())
                        .tracking(1)
                        .foregroundStyle(.blue)
                    Text("Calculators")
                        .font(.largeTitle.bold())
                    Text("Plan mortgage payments and estimate property transaction taxes across the UK.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }

                NavigationLink {
                    MortgageCalculatorView()
                } label: {
                    CalculatorLinkCard(
                        title: "Mortgage Calculator",
                        subtitle: "Repayment, interest-only, stress rates and annual overpayments",
                        icon: "house.and.flag.fill",
                        color: .blue
                    )
                }
                .buttonStyle(.plain)

                NavigationLink {
                    StampDutyCalculatorView()
                } label: {
                    CalculatorLinkCard(
                        title: "Stamp Duty & Land Taxes",
                        subtitle: "SDLT, LBTT and LTT including higher rates and buyer relief",
                        icon: "doc.text.fill",
                        color: .purple
                    )
                }
                .buttonStyle(.plain)
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Calculators")
        .navigationBarTitleDisplayMode(.inline)
    }
}

struct MortgageCalculatorView: View {
    @State private var amount = ""
    @State private var term = ""
    @State private var rate = ""
    @State private var annualOverpayment = ""
    @State private var result: MortgageCalculation?
    @State private var validationMessage: String?
    @FocusState private var focusedField: Field?

    private enum Field { case amount, term, rate, overpayment }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                introduction
                inputCard

                if let result {
                    results(result)
                }
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Mortgage Calculator")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("MORTGAGE PLANNING", systemImage: "house.fill")
                .font(.caption.bold())
                .tracking(1)
                .foregroundStyle(.blue)
            Text("Calculate your mortgage")
                .font(.title.bold())
            Text("Compare repayment and interest-only payments, lender stress rates and the effect of annual overpayments.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var inputCard: some View {
        CalculatorCard(title: "Mortgage details") {
            CalculatorTextField(
                title: "Mortgage amount",
                placeholder: "e.g. 250,000",
                text: $amount,
                prefix: "£",
                keyboard: .numberPad
            )
            .focused($focusedField, equals: .amount)
            .onChange(of: amount) { amount = currencyDigits(amount) }

            CalculatorTextField(
                title: "Term",
                placeholder: "e.g. 25",
                text: $term,
                suffix: "years",
                keyboard: .numberPad
            )
            .focused($focusedField, equals: .term)

            CalculatorTextField(
                title: "Interest rate",
                placeholder: "e.g. 5.5",
                text: $rate,
                suffix: "%",
                keyboard: .decimalPad
            )
            .focused($focusedField, equals: .rate)

            CalculatorTextField(
                title: "Annual overpayment (optional)",
                placeholder: "e.g. 2,500",
                text: $annualOverpayment,
                prefix: "£",
                keyboard: .numberPad
            )
            .focused($focusedField, equals: .overpayment)
            .onChange(of: annualOverpayment) {
                annualOverpayment = currencyDigits(annualOverpayment)
            }

            if let validationMessage {
                Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button("Calculate", action: calculate)
                .buttonStyle(.borderedProminent)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func results(_ result: MortgageCalculation) -> some View {
        SectionHeader(
            title: "Results",
            subtitle: "\(currency(Double(result.amount))) over \(result.termYears) years at \(percent(result.ratePercent))"
        )

        mortgageResultCard(
            title: "Repayment Mortgage",
            color: .blue,
            metrics: [
                ("Monthly payment", currency(result.repaymentMonthly)),
                ("Annual payment", currency(result.repaymentAnnual)),
                ("Total amount paid", currency(result.repaymentTotalPaid)),
                ("Total interest", currency(result.repaymentTotalInterest)),
                ("Repaid per £1 borrowed", currency(result.repaymentPerPound))
            ],
            standard: result.repaymentPoints,
            overpayment: result.repaymentOverpaymentPoints
        )

        mortgageResultCard(
            title: "Interest-Only Mortgage",
            color: .purple,
            metrics: [
                ("Monthly interest", currency(result.interestOnlyMonthly)),
                ("Annual interest", currency(result.interestOnlyAnnual)),
                ("Total interest paid", currency(result.interestOnlyTotalInterest)),
                ("Interest per £1 borrowed", currency(result.interestOnlyPerPound)),
                ("Capital due at term end", currency(Double(result.amount)))
            ],
            standard: result.interestOnlyPoints,
            overpayment: result.interestOnlyOverpaymentPoints
        )

        if let impact = result.overpaymentImpact {
            overpaymentCard(impact)
        }

        stressCard(result)
    }

    private func mortgageResultCard(
        title: String,
        color: Color,
        metrics: [(String, String)],
        standard: [MortgageBalancePoint],
        overpayment: [MortgageBalancePoint]?
    ) -> some View {
        CalculatorCard(title: title) {
            ForEach(Array(metrics.enumerated()), id: \.offset) { _, metric in
                ResultRow(title: metric.0, value: metric.1)
            }

            Divider()
            Text("Balance over term")
                .font(.subheadline.bold())

            Chart {
                ForEach(standard) { point in
                    LineMark(
                        x: .value("Year", point.year),
                        y: .value("Balance", point.balance),
                        series: .value("Schedule", "Standard")
                    )
                    .foregroundStyle(color)
                    .lineStyle(.init(lineWidth: 3))
                }

                if let overpayment {
                    ForEach(overpayment) { point in
                        LineMark(
                            x: .value("Year", point.year),
                            y: .value("Balance", point.balance),
                            series: .value("Schedule", "With overpayment")
                        )
                        .foregroundStyle(.green)
                        .lineStyle(.init(lineWidth: 2.5, dash: [6, 4]))
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) {
                    AxisGridLine()
                    AxisValueLabel(format: Decimal.FormatStyle.Currency(code: "GBP").notation(.compactName))
                }
            }
            .frame(height: 210)

            if overpayment != nil {
                HStack(spacing: 16) {
                    CalculatorLegend(label: "Standard", color: color)
                    CalculatorLegend(label: "With overpayment", color: .green)
                }
            }
        }
    }

    private func overpaymentCard(_ impact: MortgageOverpaymentImpact) -> some View {
        CalculatorCard(title: "Annual Overpayment Impact", tint: .green) {
            Text("Yearly capital overpayment: \(currency(Double(impact.annualOverpayment)))")
                .font(.subheadline)

            Text("Repayment Mortgage")
                .font(.headline)
            ResultRow(title: "Time saved", value: impact.repayment.timeSavedLabel)
            ResultRow(title: "Interest saved", value: currency(impact.repayment.interestSaved))
            ResultRow(title: "New mortgage length", value: impact.repayment.newTermLabel)
            ResultRow(title: "Interest with overpayments", value: currency(impact.repayment.totalInterest))

            Divider()
            Text("Interest-Only Mortgage")
                .font(.headline)
            ResultRow(title: "Time saved", value: impact.interestOnly.timeSavedLabel)
            ResultRow(title: "Interest saved", value: currency(impact.interestOnly.interestSaved))
            ResultRow(title: "New mortgage length", value: impact.interestOnly.newTermLabel)
            ResultRow(title: "Interest with overpayments", value: currency(impact.interestOnly.totalInterest))
        }
    }

    private func stressCard(_ result: MortgageCalculation) -> some View {
        CalculatorCard(title: "Stress Rate Impact", tint: .red) {
            Text(
                "The website applies a \(percent(result.stressRate)) lender stress rate, taking "
                + "the entered rate to \(percent(result.stressedRatePercent)). This is an affordability illustration, not the rate paid."
            )
            .font(.caption)
            .foregroundStyle(.secondary)

            ResultRow(
                title: "Stressed repayment",
                value: "\(currency(result.repaymentMonthlyStressed))/month"
            )
            ResultRow(
                title: "Repayment increase",
                value: "+\(currency(result.repaymentMonthlyExtra))/month"
            )
            ResultRow(
                title: "Stressed interest-only",
                value: "\(currency(result.interestOnlyMonthlyStressed))/month"
            )
            ResultRow(
                title: "Interest-only increase",
                value: "+\(currency(result.interestOnlyMonthlyExtra))/month"
            )
        }
    }

    private func calculate() {
        focusedField = nil
        guard let parsedAmount = parseCurrency(amount), parsedAmount > 0 else {
            validationMessage = "Please enter a valid mortgage amount."
            return
        }
        guard let parsedTerm = Int(term), (1...50).contains(parsedTerm) else {
            validationMessage = "The mortgage term must be between 1 and 50 years."
            return
        }
        guard let parsedRate = Double(rate), (0...100).contains(parsedRate) else {
            validationMessage = "The interest rate must be between 0% and 100%."
            return
        }
        let parsedOverpayment = parseCurrency(annualOverpayment) ?? 0
        guard parsedOverpayment >= 0 else {
            validationMessage = "Annual overpayment cannot be negative."
            return
        }

        validationMessage = nil
        result = MortgageCalculator.calculate(
            amount: parsedAmount,
            termYears: parsedTerm,
            ratePercent: parsedRate,
            annualOverpayment: parsedOverpayment
        )
    }
}

struct StampDutyCalculatorView: View {
    @State private var price = ""
    @State private var region: StampDutyRegion = .englandAndNorthernIreland
    @State private var buyerType: StampDutyBuyerType = .currentOwner
    @State private var isAdditional = false
    @State private var isNonResident = false
    @State private var result: StampDutyCalculation?
    @State private var validationMessage: String?
    @FocusState private var priceIsFocused: Bool

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 18) {
                introduction
                inputCard
                if let result {
                    results(result)
                }
                notes
            }
            .padding(20)
        }
        .background(Color(.systemGroupedBackground))
        .navigationTitle("Stamp Duty")
        .navigationBarTitleDisplayMode(.inline)
        .onChange(of: region) {
            if region != .englandAndNorthernIreland {
                isNonResident = false
            }
            result = nil
        }
    }

    private var introduction: some View {
        VStack(alignment: .leading, spacing: 7) {
            Label("PROPERTY TAX", systemImage: "doc.text.fill")
                .font(.caption.bold())
                .tracking(1)
                .foregroundStyle(.purple)
            Text("Stamp Duty & Land Taxes")
                .font(.title.bold())
            Text("Calculate SDLT, LBTT or LTT including first-time buyer rules and higher rates.")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
    }

    private var inputCard: some View {
        CalculatorCard(title: "Purchase details") {
            CalculatorTextField(
                title: "Property price",
                placeholder: "e.g. 350,000",
                text: $price,
                prefix: "£",
                keyboard: .numberPad
            )
            .focused($priceIsFocused)
            .onChange(of: price) { price = currencyDigits(price) }

            VStack(alignment: .leading, spacing: 6) {
                Text("Region").font(.subheadline.bold())
                Picker("Region", selection: $region) {
                    ForEach(StampDutyRegion.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.menu)
                .frame(maxWidth: .infinity, alignment: .leading)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Buyer type").font(.subheadline.bold())
                Picker("Buyer type", selection: $buyerType) {
                    ForEach(StampDutyBuyerType.allCases) { Text($0.title).tag($0) }
                }
                .pickerStyle(.segmented)
            }

            Toggle("Second home/additional property", isOn: $isAdditional)

            if region == .englandAndNorthernIreland {
                Toggle("Non-resident (SDLT Only)", isOn: $isNonResident)
            }

            if buyerType == .firstTime, isAdditional {
                Label(
                    "First-time buyer relief is ignored for an additional property.",
                    systemImage: "info.circle"
                )
                .font(.caption)
                .foregroundStyle(.orange)
            }

            if let validationMessage {
                Label(validationMessage, systemImage: "exclamationmark.triangle.fill")
                    .font(.caption)
                    .foregroundStyle(.red)
            }

            Button("Calculate", action: calculate)
                .buttonStyle(.borderedProminent)
                .tint(.purple)
                .controlSize(.large)
                .frame(maxWidth: .infinity)
        }
    }

    @ViewBuilder
    private func results(_ result: StampDutyCalculation) -> some View {
        SectionHeader(title: "Results", subtitle: result.jurisdiction)

        LazyVGrid(
            columns: [GridItem(.flexible()), GridItem(.flexible())],
            spacing: 12
        ) {
            TaxSummaryCard(title: "Total tax due", value: currency(result.totalTax), color: .purple)
            TaxSummaryCard(title: "Base tax", value: currency(result.baseTax), color: .blue)
        }

        CalculatorCard(title: "Band breakdown") {
            ForEach(result.bands) { band in
                VStack(alignment: .leading, spacing: 5) {
                    HStack {
                        Text("\(currency(band.from)) – \(band.to.isInfinite ? "∞" : currency(band.to))")
                            .font(.subheadline.bold())
                        Spacer()
                        Text(percent(band.ratePercent))
                            .font(.caption.bold())
                            .foregroundStyle(.primary)
                    }
                    ResultRow(title: "Amount in band", value: currency(band.amount))
                    ResultRow(title: "Tax", value: currency(band.tax))
                }
                if band.id != result.bands.last?.id { Divider() }
            }
        }

        if !result.surcharges.isEmpty {
            CalculatorCard(title: "Surcharges", tint: .orange) {
                ForEach(result.surcharges) { surcharge in
                    VStack(alignment: .leading, spacing: 5) {
                        Text(surcharge.label).font(.subheadline.bold())
                        ResultRow(title: "Rate", value: percent(surcharge.ratePercent))
                        ResultRow(title: "Base amount", value: currency(surcharge.amount))
                        ResultRow(title: "Tax", value: currency(surcharge.tax))
                    }
                }
            }
        }
    }

    private var notes: some View {
        CalculatorCard(title: "Notes") {
            Text("• England & NI higher rates add 5% to the full price; non-resident purchases add 2%.")
            Text("• Scotland ADS is 8% of the full price. First-time buyer nil-rate band is £175,000.")
            Text("• Wales uses separate higher-rate bands and has no first-time buyer relief.")
            Text("This calculator is a guide only and does not constitute tax or financial advice.")
                .foregroundStyle(.secondary)
        }
        .font(.caption)
    }

    private func calculate() {
        priceIsFocused = false
        guard let parsedPrice = parseCurrencyDouble(price), parsedPrice >= 0 else {
            validationMessage = "Please enter a valid property price."
            return
        }
        validationMessage = nil
        result = StampDutyCalculator.calculate(
            price: parsedPrice,
            region: region,
            buyerType: buyerType,
            isAdditional: isAdditional,
            isNonResident: isNonResident
        )
    }
}

private struct CalculatorLinkCard: View {
    let title: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)
                .frame(width: 50, height: 50)
                .background(color.opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 14))
            VStack(alignment: .leading, spacing: 4) {
                Text(title).font(.headline)
                Text(subtitle).font(.caption).foregroundStyle(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption.bold())
                .foregroundStyle(.tertiary)
        }
        .padding(17)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 18))
    }
}

private struct CalculatorCard<Content: View>: View {
    let title: String
    var tint: Color = .blue
    @ViewBuilder let content: Content

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text(title).font(.title3.bold()).foregroundStyle(tint)
            content
        }
        .padding(17)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 20))
    }
}

private struct CalculatorTextField: View {
    let title: String
    let placeholder: String
    @Binding var text: String
    var prefix: String?
    var suffix: String?
    let keyboard: UIKeyboardType

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text(title).font(.subheadline.bold())
            HStack(spacing: 8) {
                if let prefix { Text(prefix).foregroundStyle(.secondary) }
                TextField(placeholder, text: $text)
                    .keyboardType(keyboard)
                if let suffix { Text(suffix).foregroundStyle(.secondary) }
            }
            .padding(12)
            .background(Color(.secondarySystemGroupedBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }
}

private struct ResultRow: View {
    let title: String
    let value: String

    var body: some View {
        HStack(alignment: .firstTextBaseline) {
            Text(title).foregroundStyle(.secondary)
            Spacer()
            Text(value).fontWeight(.semibold).multilineTextAlignment(.trailing)
        }
        .font(.subheadline)
    }
}

private struct TaxSummaryCard: View {
    let title: String
    let value: String
    let color: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 7) {
            Text(title).font(.caption).foregroundStyle(.secondary)
            Text(value).font(.title3.bold()).foregroundStyle(color)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(15)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

private struct CalculatorLegend: View {
    let label: String
    let color: Color
    var body: some View {
        Label {
            Text(label)
        } icon: {
            Circle().fill(color).frame(width: 8, height: 8)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
    }
}

private func parseCurrency(_ value: String) -> Int? {
    Int(value.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces))
}

private func parseCurrencyDouble(_ value: String) -> Double? {
    Double(value.replacingOccurrences(of: ",", with: "").trimmingCharacters(in: .whitespaces))
}

private func currencyDigits(_ value: String) -> String {
    let digits = value.filter(\.isNumber)
    guard let number = Int(digits), !digits.isEmpty else { return "" }
    return number.formatted(.number.grouping(.automatic))
}

private func currency(_ value: Double) -> String {
    value.formatted(.currency(code: "GBP").precision(.fractionLength(2)))
}

private func percent(_ value: Double) -> String {
    "\(value.formatted(.number.precision(.fractionLength(0...2))))%"
}
