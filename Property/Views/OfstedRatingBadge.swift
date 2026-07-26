import SwiftUI

struct OfstedRatingBadge: View {
    let rating: String?

    static func priority(for rating: String?) -> Int {
        switch rating?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "outstanding":
            0
        case "2", "good":
            1
        case "3", "requires improvement":
            2
        case "4", "inadequate":
            3
        default:
            4
        }
    }

    private var displayRating: String {
        switch rating?.trimmingCharacters(in: .whitespacesAndNewlines).lowercased() {
        case "1", "outstanding":
            "Outstanding"
        case "2", "good":
            "Good"
        case "3", "requires improvement":
            "Requires improvement"
        case "4", "inadequate":
            "Inadequate"
        default:
            "No current Ofsted rating"
        }
    }

    private var color: Color {
        switch displayRating {
        case "Outstanding":
            .green
        case "Good":
            .blue
        case "Requires improvement":
            .orange
        case "Inadequate":
            .red
        default:
            .secondary
        }
    }

    var body: some View {
        Text(displayRating)
            .font(.caption2.weight(.semibold))
            .foregroundStyle(color)
            .padding(.horizontal, 9)
            .padding(.vertical, 5)
            .background(color.opacity(0.12))
            .clipShape(Capsule())
            .overlay {
                Capsule()
                    .stroke(color.opacity(0.22), lineWidth: 1)
            }
            .fixedSize(horizontal: true, vertical: false)
    }
}
