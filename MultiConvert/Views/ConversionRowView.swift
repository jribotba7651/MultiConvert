import SwiftUI

struct ConversionRowView: View {
    @Environment(AppState.self) private var state
    let currency: Currency
    let index: Int

    var body: some View {
        HStack(spacing: 12) {
            // Position badge
            Text("\(index + 1)")
                .font(Theme.badgeFont)
                .foregroundStyle(Theme.secondaryText)
                .frame(width: 16)

            // Flag or crypto icon
            Text(currency.flag ?? currency.symbol)
                .font(.system(size: 22))
                .frame(width: 30)

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
            }

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
