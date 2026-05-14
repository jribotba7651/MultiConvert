import SwiftUI

struct SettingsView: View {
    @Environment(AppState.self) private var state
    @Environment(\.dismiss) private var dismiss

    @State private var showClearCacheConfirm = false
    @State private var showWidgetPicker = false

    var body: some View {
        NavigationStack {
            List {
                displaySection
                widgetSection
                cacheSection
                aboutSection
            }
            .listStyle(.insetGrouped)
            .scrollContentBackground(.hidden)
            .background(Theme.appBackground)
            .navigationTitle("Settings")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                        .foregroundStyle(Theme.accentText)
                }
            }
        }
        .preferredColorScheme(.dark)
        .sheet(isPresented: $showWidgetPicker) {
            CurrencyPickerView(mode: .setBase)
        }
        .confirmationDialog(
            "Clear rate cache?",
            isPresented: $showClearCacheConfirm,
            titleVisibility: .visible
        ) {
            Button("Clear Cache", role: .destructive) {
                state.clearCache()
            }
        } message: {
            Text("The app will re-fetch rates on next launch or refresh.")
        }
    }

    // MARK: - Sections

    @ViewBuilder
    private var displaySection: some View {
        Section("Display") {
            Picker("Decimal Places", selection: Binding(
                get: { state.decimalPlaces },
                set: { state.decimalPlaces = $0; state.saveDecimalPlaces() }
            )) {
                Text("2 places").tag(2)
                Text("4 places").tag(4)
            }
            .pickerStyle(.segmented)
            .listRowBackground(Theme.cardBackground)
        }
    }

    @ViewBuilder
    private var widgetSection: some View {
        Section("Widget") {
            HStack {
                Text("Base Amount")
                    .foregroundStyle(Theme.primaryText)
                Spacer()
                TextField("Amount", text: Binding(
                    get: { state.widgetBaseAmount },
                    set: { state.widgetBaseAmount = $0; state.saveWidgetSettings() }
                ))
                .keyboardType(.decimalPad)
                .multilineTextAlignment(.trailing)
                .foregroundStyle(Theme.accentText)
                .frame(width: 80)
            }
            .listRowBackground(Theme.cardBackground)

            Button {
                showWidgetPicker = true
            } label: {
                HStack {
                    Text("Widget Currency")
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Text(state.widgetBaseCurrency.code)
                        .foregroundStyle(Theme.accentText)
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundStyle(Theme.secondaryText)
                }
            }
            .listRowBackground(Theme.cardBackground)
        }
    }

    @ViewBuilder
    private var cacheSection: some View {
        Section("Data") {
            if let lastUpdated = state.lastUpdated {
                HStack {
                    Text("Last Updated")
                        .foregroundStyle(Theme.primaryText)
                    Spacer()
                    Text(lastUpdated, style: .relative)
                        .foregroundStyle(state.isStale ? Theme.staleWarning : Theme.secondaryText)
                        .font(.system(size: 13))
                }
                .listRowBackground(Theme.cardBackground)
            }

            Button(role: .destructive) {
                showClearCacheConfirm = true
            } label: {
                Text("Clear Rate Cache")
            }
            .listRowBackground(Theme.cardBackground)
        }
    }

    @ViewBuilder
    private var aboutSection: some View {
        Section("About") {
            labelRow("Version", value: "1.0.0")
            labelRow("Bundle ID", value: "com.jibaroenlaluna.multiconvert")
            labelRow("API — Fiat", value: "frankfurter.app")
            labelRow("API — Crypto", value: "coingecko.com")

            // IAP placeholder — not activated
            HStack {
                Text("Remove Ads (coming soon)")
                    .foregroundStyle(Theme.secondaryText)
                Spacer()
                Text("$1.99")
                    .foregroundStyle(Theme.secondaryText)
            }
            .listRowBackground(Theme.cardBackground)
        }
    }

    private func labelRow(_ label: String, value: String) -> some View {
        HStack {
            Text(label)
                .foregroundStyle(Theme.primaryText)
            Spacer()
            Text(value)
                .foregroundStyle(Theme.secondaryText)
                .font(.system(size: 13, design: .monospaced))
        }
        .listRowBackground(Theme.cardBackground)
    }
}
