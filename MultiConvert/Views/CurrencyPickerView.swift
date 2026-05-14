import SwiftUI

struct CurrencyPickerView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    let mode: PickerMode
    @State private var searchText = ""

    enum PickerMode {
        case addToList
        case setBase
    }

    var body: some View {
        NavigationStack {
            List {
                section(title: "Fiat Currencies", currencies: filteredFiat)
                section(title: "Cryptocurrencies", currencies: filteredCrypto)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.appBackground)
            .navigationTitle(mode == .setBase ? "Base Currency" : "Add Currency")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search currencies")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accentText)
                }
            }
        }
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    private func section(title: String, currencies: [Currency]) -> some View {
        Section(title) {
            ForEach(currencies) { currency in
                rowView(for: currency)
            }
        }
    }

    private func rowView(for currency: Currency) -> some View {
        Button {
            switch mode {
            case .addToList:
                state.selectCurrency(currency)
            case .setBase:
                state.setBaseCurrency(currency)
            }
            dismiss()
        } label: {
            HStack(spacing: 12) {
                Text(currency.flag ?? currency.symbol)
                    .font(.system(size: 22))
                    .frame(width: 30)

                VStack(alignment: .leading, spacing: 2) {
                    Text(currency.code)
                        .font(Theme.labelFont)
                        .foregroundStyle(Theme.primaryText)
                    Text(currency.name)
                        .font(.system(size: 12))
                        .foregroundStyle(Theme.secondaryText)
                }

                Spacer()

                if isSelected(currency) {
                    Image(systemName: "checkmark")
                        .foregroundStyle(Theme.accentText)
                }
            }
        }
        .listRowBackground(Theme.cardBackground)
    }

    // MARK: - Filtered

    private var filteredFiat: [Currency] {
        filter(Currency.allFiat)
    }

    private var filteredCrypto: [Currency] {
        filter(Currency.allCrypto)
    }

    private func filter(_ currencies: [Currency]) -> [Currency] {
        guard !searchText.isEmpty else { return currencies }
        let q = searchText.lowercased()
        return currencies.filter {
            $0.code.lowercased().contains(q) || $0.name.lowercased().contains(q)
        }
    }

    private func isSelected(_ currency: Currency) -> Bool {
        switch mode {
        case .setBase: return currency == state.baseCurrency
        case .addToList: return state.recentCurrencies.contains(currency)
        }
    }
}
