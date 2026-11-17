import Domain
import SwiftUI

struct ErrorStateView: View {
    let error: DomainError
    let retry: () async -> Void

    @State private var isRetrying = false

    var body: some View {
        let message = error.userMessage
        ContentUnavailableView {
            Label(message.title, systemImage: message.systemImage)
        } description: {
            Text(message.message)
        } actions: {
            Button {
                Task {
                    isRetrying = true
                    await retry()
                    isRetrying = false
                }
            } label: {
                Text("Retry")
            }
            .buttonStyle(.borderedProminent)
            .disabled(isRetrying)
        }
    }
}

#Preview {
    ErrorStateView(error: .offline) {}
}
