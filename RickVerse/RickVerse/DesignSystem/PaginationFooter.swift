import Domain
import Presentation
import SwiftUI

struct PaginationFooter: View {
    let state: PaginationPhase
    var endMessage: LocalizedStringKey = "That's everyone 👽"
    let retry: () -> Void

    var body: some View {
        Group {
            switch state {
            case .idle:
                Color.clear.frame(height: 1)
            case .loading:
                HStack(spacing: 8) {
                    ProgressView()
                    Text("Loading more…")
                }
            case .failed:
                VStack(spacing: 8) {
                    Text("Couldn't load more")
                    Button("Retry", action: retry)
                        .buttonStyle(.bordered)
                }
            case .exhausted:
                Text(endMessage)
            }
        }
        .font(.footnote)
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }
}

#Preview {
    List {
        PaginationFooter(state: .loading) {}
        PaginationFooter(state: .failed(.offline)) {}
        PaginationFooter(state: .exhausted) {}
    }
}
