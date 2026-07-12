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
    // Only two stored values drive the whole gesture: which row is being
    // dragged, and how far the finger has moved since grabbing it.
    // `state.recentCurrencies` itself is never touched until the gesture
    // ends. `targetIndex` below is deliberately NOT @State — it's a pure
    // function of these two values (plus the row count), so it can never
    // drift out of sync with `dragTranslation` the way a separately-stored
    // value updated from the same callback theoretically could.
    @State private var draggingIndex: Int?
    @State private var dragTranslation: CGFloat = 0
    @State private var rowHeight: CGFloat = 60

    private let rowSpacing: CGFloat = 8

    /// Which slot the dragged row would land in if released right now.
    /// Pure arithmetic on the translation delta — never on `location`,
    /// which is relative to the row's own (currently shifting) frame and
    /// would feed back into itself as the list rearranges.
    private var targetIndex: Int? {
        guard let source = draggingIndex else { return nil }
        let stride = rowHeight + rowSpacing
        guard stride > 0 else { return source }
        let rowsCrossed = Int((dragTranslation / stride).rounded())
        return min(max(source + rowsCrossed, 0), state.recentCurrencies.count - 1)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: rowSpacing) {
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
                        // The dragged row gets NO animation at all — it must
                        // track the finger every pixel. Every other row
                        // springs into its new slot when `targetIndex`
                        // changes. Putting the nil-vs-spring choice directly
                        // in the `.animation` call (rather than overriding it
                        // afterwards via `.transaction`) is the one form
                        // SwiftUI is guaranteed to honor consistently.
                        .animation(
                            draggingIndex == index ? nil : .spring(response: 0.3, dampingFraction: 0.8),
                            value: targetIndex
                        )
                    }
                }
            }
            .padding(.top, 8)
            .padding(.bottom, 24)
        }
        // A row-drag and a list-scroll are two different gestures reaching
        // for the same touch; letting both stay armed is exactly the kind
        // of arbitration that produces intermittent stutter. Off for the
        // duration of the drag removes the contention outright.
        .scrollDisabled(draggingIndex != nil)
        .onPreferenceChange(RowHeightKey.self) { height in
            guard height > 0, abs(height - rowHeight) > 0.5 else { return }
            rowHeight = height
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
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
        }
        dragTranslation = translation
    }

    private func handleDragEnded() {
        guard let source = draggingIndex, let target = targetIndex, source != target else {
            resetDrag()
            return
        }

        let oldBase = state.baseCurrency
        withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
            state.moveCurrency(from: source, to: target)
        }

        let didRebase = state.baseCurrency != oldBase
        UIImpactFeedbackGenerator(style: didRebase ? .medium : .light).impactOccurred()

        resetDrag()
    }

    private func resetDrag() {
        draggingIndex = nil
        dragTranslation = 0
    }
}
