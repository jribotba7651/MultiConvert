import SwiftUI

private struct RowHeightKey: PreferenceKey {
    static var defaultValue: CGFloat = 0
    static func reduce(value: inout CGFloat, nextValue: () -> CGFloat) {
        value = max(value, nextValue())
    }
}

struct ConversionListView: View {
    @Environment(AppState.self) private var state

    // MARK: - Drag state
    //
    // Purely visual — `state.recentCurrencies` is never touched until the
    // gesture ends. Every row's on-screen offset is a pure function of
    // (index, draggingIndex, targetIndex), so there's no live array mutation
    // to flip-flop at stride boundaries the way a repeated remove/insert on
    // a shadow array could.
    @State private var draggingIndex: Int?
    @State private var dragTranslation: CGFloat = 0
    @State private var targetIndex: Int?
    @State private var rowHeight: CGFloat = 60

    private let rowSpacing: CGFloat = 8

    var body: some View {
        ScrollView {
            LazyVStack(spacing: rowSpacing) {
                if state.recentCurrencies.isEmpty {
                    emptyState
                } else {
                    ForEach(Array(state.recentCurrencies.enumerated()), id: \.element.id) { index, currency in
                        ConversionRowView(
                            currency: currency,
                            index: index,
                            isDragging: draggingIndex == index,
                            onDragChanged: { translation in
                                handleDragChanged(index: index, translation: translation)
                            },
                            onDragEnded: {
                                handleDragEnded()
                            }
                        )
                        .padding(.horizontal, 16)
                        .background(
                            GeometryReader { geo in
                                Color.clear.preference(key: RowHeightKey.self, value: geo.size.height)
                            }
                        )
                        .offset(y: rowOffset(for: index))
                        .zIndex(draggingIndex == index ? 1 : 0)
                        .animation(.spring(response: 0.3, dampingFraction: 0.8), value: targetIndex)
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        .onPreferenceChange(RowHeightKey.self) { height in
            if height > 0 { rowHeight = height }
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

    // MARK: - Drag reordering (visual preview only — the model updates once,
    // in `handleDragEnded`)

    /// Every row's vertical offset while a drag is active, computed fresh on
    /// every render — never stored, never mutated. The dragged row tracks
    /// the raw translation directly (no lag); every other row either sits
    /// still or slides by exactly one row-height to make room.
    private func rowOffset(for index: Int) -> CGFloat {
        guard let source = draggingIndex else { return 0 }
        if index == source { return dragTranslation }

        let target = targetIndex ?? source
        let stride = rowHeight + rowSpacing

        if source < target, index > source, index <= target {
            return -stride // slides up to fill the gap the dragged row left
        }
        if target < source, index >= target, index < source {
            return stride // slides down to make room for the dragged row
        }
        return 0
    }

    private func handleDragChanged(index: Int, translation: CGFloat) {
        if draggingIndex == nil {
            draggingIndex = index
            targetIndex = index
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        dragTranslation = translation

        guard let source = draggingIndex else { return }
        let stride = rowHeight + rowSpacing
        guard stride > 0 else { return }

        // Target index is always derived from the fixed drag-start index
        // plus the full cumulative translation, never from a previously
        // computed target — otherwise crossed rows get double-counted.
        let rowsCrossed = Int((translation / stride).rounded())
        let proposed = source + rowsCrossed
        targetIndex = min(max(proposed, 0), state.recentCurrencies.count - 1)
    }

    private func handleDragEnded() {
        defer {
            draggingIndex = nil
            targetIndex = nil
            dragTranslation = 0
        }

        guard let source = draggingIndex,
              let target = targetIndex,
              source != target else { return }

        let oldBase = state.baseCurrency
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            state.moveCurrency(from: source, to: target)
        }

        let didRebase = state.baseCurrency != oldBase
        UIImpactFeedbackGenerator(style: didRebase ? .medium : .light).impactOccurred()
    }
}
