import SwiftUI

struct AppFooter: View {
    var body: some View {
        NavigationLink {
            AboutLegalView()
        } label: {
            HStack(spacing: 5) {
                Text("PropertyResearch.uk · About & Legal")
                Image(systemName: "info.circle")
                    .font(.caption2.weight(.semibold))
            }
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .contentShape(Rectangle())
        }
        .background(.ultraThinMaterial)
        .accessibilityHint("Opens privacy, data licensing and support information")
    }
}
