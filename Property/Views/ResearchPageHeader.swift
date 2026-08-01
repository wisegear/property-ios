import SwiftUI

struct ResearchPageHeader: View {
    let eyebrow: String
    let title: String
    let subtitle: String
    let icon: String
    var color: Color = .blue
    var detail: String?

    var body: some View {
        ZStack(alignment: .topTrailing) {
            LinearGradient(
                colors: [color.opacity(0.95), color.opacity(0.68)],
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )

            Circle()
                .stroke(.white.opacity(0.1), lineWidth: 24)
                .frame(width: 150, height: 150)
                .offset(x: 45, y: -65)
                .accessibilityHidden(true)

            Image(systemName: icon)
                .font(.system(size: 88, weight: .bold))
                .foregroundStyle(.white.opacity(0.08))
                .offset(x: 20, y: 65)
                .accessibilityHidden(true)

            VStack(alignment: .leading, spacing: 10) {
                Label(eyebrow.uppercased(), systemImage: icon)
                    .font(.caption.bold())
                    .tracking(1.1)

                Text(title)
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .fixedSize(horizontal: false, vertical: true)

                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.white.opacity(0.84))
                    .fixedSize(horizontal: false, vertical: true)

                if let detail {
                    Text(detail)
                        .font(.caption.bold())
                        .foregroundStyle(.white.opacity(0.75))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(22)
        }
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: color.opacity(0.18), radius: 14, y: 7)
        .accessibilityElement(children: .contain)
    }
}
