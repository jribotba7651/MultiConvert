import SwiftUI

struct ConversionRowView: View {
    @Environment(AppState.self) private var state
    let currency: Currency
    let index: Int

    @State private var showCurrencyPicker = false

    private var isBase: Bool { currency == state.baseCurrency }

    var body: some View {
        HStack(spacing: 12) {
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
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerSheet(currentSelection: currency) { newCurrency in
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                state.replaceCurrency(at: index, with: newCurrency)
            }
        }
    }

    // MARK: - Currency tap zone (flag + code + name) — opens the quick picker

    private var currencyTapZone: some View {
        HStack(spacing: 12) {
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
        .onTapGesture {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            showCurrencyPicker = true
        }
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
