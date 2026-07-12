import SwiftUI

struct ConversionListView: View {
    @Environment(AppState.self) private var state

    private let rowSpacing: CGFloat = 8

    var body: some View {
        if state.recentCurrencies.isEmpty {
            emptyState
        } else {
            currencyList
        }
    }

    // MARK: - List with native .onMove reordering

    private var currencyList: some View {
        List {
            ForEach(Array(state.recentCurrencies.enumerated()), id: \.element.id) { index, currency in
                ConversionRowView(currency: currency, index: index)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: rowSpacing / 2, leading: 16,
                        bottom: rowSpacing / 2, trailing: 16
                    ))
            }
            .onMove { indices, newOffset in
                applyMove(from: indices, to: newOffset)
            }
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
        .environment(\.editMode, .constant(.active))
        .refreshable {
            await state.refresh()
        }
    }

    // MARK: - Move handler

    private func applyMove(from source: IndexSet, to destination: Int) {
        guard let sourceIndex = source.first else { return }

        // List's .onMove destination means "insert before this index".
        // When moving down, the effective target index is destination - 1
        // because the source row is removed first, shifting indices.
        let target: Int
        if destination > sourceIndex {
            target = destination - 1
        } else {
            target = destination
        }

        guard target != sourceIndex else { return }

        let oldBase = state.baseCurrency
        state.moveCurrency(from: sourceIndex, to: target)

        let didRebase = state.baseCurrency != oldBase
        UIImpactFeedbackGenerator(style: didRebase ? .medium : .light).impactOccurred()
    }

    // MARK: - Empty state

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
