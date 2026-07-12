import SwiftUI

struct ConversionRowView: View {
    @Environment(AppState.self) private var state
    let currency: Currency
    let index: Int
    let isDragging: Bool
    let onDragChanged: (CGFloat) -> Void
    let onDragEnded: () -> Void

    @State private var showCurrencyPicker = false

    private var isBase: Bool { currency == state.baseCurrency }

    var body: some View {
        HStack(spacing: 12) {
            dragHandle

            currencyTapZone

            Spacer()

            // Converted value
            if let value = state.convertedValue(for: currency) {
                Text(CurrencyFormatter.format(value, currency: currency, decimalPlaces: state.decimalPlaces))
                    .font(Theme.conversionFont)
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
            } else {
                Text("—")
                    .font(Theme.conversionFont)
                    .foregroundStyle(Theme.secondaryText)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(Theme.cardBackground)
        .clipShape(RoundedRectangle(cornerRadius: 14))
        .overlay(
            RoundedRectangle(cornerRadius: 14)
                .stroke(Theme.accentText, lineWidth: isBase ? 2 : 0)
        )
        .shadow(color: .black.opacity(isDragging ? 0.35 : 0), radius: isDragging ? 10 : 0, y: isDragging ? 4 : 0)
        .scaleEffect(isDragging ? 1.03 : 1.0)
        .opacity(isDragging ? 0.92 : 1.0)
        .zIndex(isDragging ? 1 : 0)
        .animation(.easeOut(duration: 0.15), value: isDragging)
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(currentSelection: currency) { newCurrency in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                state.replaceCurrency(at: index, with: newCurrency)
            }
        }
    }

    // MARK: - Drag handle

    private var dragHandle: some View {
        Image(systemName: "line.3.horizontal")
            .font(.system(size: 14, weight: .semibold))
            .foregroundStyle(Theme.secondaryText)
            .frame(width: 28, height: 28)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 2)
                    .onChanged { value in onDragChanged(value.translation.height) }
                    .onEnded { _ in onDragEnded() }
            )
            .accessibilityLabel("Reorder \(currency.code)")
            .accessibilityHint("Drag to reorder the list, or drop at the top to make this the base currency")
    }

    // MARK: - Currency tap zone (flag + code + name) — opens the quick picker

    private var currencyTapZone: some View {
        HStack(spacing: 12) {
            // Flag or crypto icon — sized up now that the position badge is gone
            Text(currency.flag ?? currency.symbol)
                .font(.system(size: 30))
                .frame(width: 38)

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 6) {
                    Text(currency.code)
                        .font(Theme.labelFont)
                        .foregroundStyle(Theme.primaryText)

                    typeBadge
                }
                Text(currency.name)
                    .font(.system(size: 11, weight: .regular, design: .rounded))
                    .foregroundStyle(Theme.secondaryText)
                    .lineLimit(1)
            }
        }
        .contentShape(Rectangle())
        // `.highPriorityGesture` — a plain `.onTapGesture` here lost the
        // first tap to the drag handle's low-`minimumDistance` DragGesture
        // sitting in the same row, requiring a second tap to register.
        // High priority makes this tap win outright instead of getting
        // caught up in that gesture's recognition window.
        .highPriorityGesture(
            TapGesture().onEnded {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                showCurrencyPicker = true
            }
        )
        .accessibilityAddTraits(.isButton)
        .accessibilityLabel("\(currency.code), \(currency.name)")
        .accessibilityHint("Double tap to change the currency for this row")
    }

    private var typeBadge: some View {
        Text(currency.isCrypto ? "CRYPTO" : "FIAT")
            .font(Theme.badgeFont)
            .foregroundStyle(.white)
            .padding(.horizontal, 5)
            .padding(.vertical, 2)
            .background(
                Capsule()
                    .fill(currency.isCrypto ? Theme.cryptoBadge : Theme.fiatBadge)
            )
    }
}
