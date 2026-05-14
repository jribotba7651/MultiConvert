import SwiftUI

struct ConversionListView: View {
    @Environment(AppState.self) private var state

    var body: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                if state.recentCurrencies.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(state.recentCurrencies.enumerated()), id: \.element.id) { index, currency in
                        ConversionRowView(currency: currency, index: index)
                            .padding(.horizontal, 16)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .refreshable {
            await state.refresh()
        }
    }

    private var emptyState: some View {
        VStack(spacing: 12) {
            Image(systemName: "arrow.triangle.2.circlepath")
                .font(.system(size: 40))
                .foregroundStyle(Theme.secondaryText)
            Text("Add currencies using the picker above")
                .font(Theme.labelFont)
                .foregroundStyle(Theme.secondaryText)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.top, 60)
    }
}
