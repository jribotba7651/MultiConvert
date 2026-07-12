import SwiftUI

/// Quick currency picker sheet, shared by two distinct call sites:
///   - `ConversionRowView` (flag/code/name tap) — changes just that row.
///   - `ContentView`'s header ("USD ▾") — changes the app's base currency.
/// The two behave differently (row swap vs. base swap-and-reconcile-list),
/// but the picker itself doesn't know which one it's driving — the caller
/// supplies `currentSelection` (for the checkmark) and `onSelect`, including
/// whatever haptic matches its own semantics (light for a row, medium for
/// the base).
struct CurrencyPickerSheet: View {
    @Environment(\.dismiss) private var dismiss

    let currentSelection: Currency
    var title: String = "Change Currency"
    let onSelect: (Currency) -> Void

    @State private var searchText = ""

    var body: some View {
        NavigationStack {
            List {
                section(title: "FIAT", currencies: filteredFiat)
                section(title: "CRYPTO", currencies: filteredCrypto)
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.appBackground)
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search currencies")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                        .foregroundStyle(Theme.accentText)
                }
            }
        }
        // A single fixed detent avoids the medium->large auto-expand that
        // happens when the searchable field grabs the keyboard — that detent
        // swap mid-focus is what caused the flash / lost keyboard focus.
        .presentationDetents([.large])
        .presentationDragIndicator(.visible)
        .preferredColorScheme(.dark)
    }

    // MARK: - Sections

    @ViewBuilder
    private func section(title: String, currencies: [Currency]) -> some View {
        if !currencies.isEmpty {
            Section(title) {
                ForEach(currencies) { currency in
                    rowView(for: currency)
                }
            }
        }
    }

    private func rowView(for currency: Currency) -> some View {
        Button {
            onSelect(currency)
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

                if currency == currentSelection {
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
}
