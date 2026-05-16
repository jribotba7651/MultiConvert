import SwiftUI

struct ContentView: View {
    @Environment(AppState.self) private var state
    @State private var showCurrencyPicker = false
    @State private var showBasePicker = false
    @State private var showSettings = false

    var body: some View {
        ZStack(alignment: .bottom) {
            Theme.appBackground.ignoresSafeArea()

            VStack(spacing: 0) {
                headerBar
                displayPanel
                stalenessBar
                Divider().background(Theme.cardBackground)
                ConversionListView()
                    .frame(maxHeight: .infinity)
                keypadPanel
            }
        }
        .sheet(isPresented: $showCurrencyPicker) {
            CurrencyPickerView(mode: .addToList)
        }
        .sheet(isPresented: $showBasePicker) {
            CurrencyPickerView(mode: .setBase)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView()
        }
    }

    // MARK: - Header

    private var headerBar: some View {
        HStack {
            Text("MultiConvert")
                .font(.system(size: 17, weight: .semibold, design: .rounded))
                .foregroundStyle(Theme.primaryText)

            Spacer()

            if state.isLoading {
                ProgressView()
                    .tint(Theme.accentText)
            }

            Button {
                showCurrencyPicker = true
            } label: {
                Label("Add Currency", systemImage: "plus.circle")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.accentText)
            }
            .accessibilityIdentifier("addCurrencyButton")

            Button {
                showSettings = true
            } label: {
                Label("Settings", systemImage: "gearshape")
                    .labelStyle(.iconOnly)
                    .font(.system(size: 22))
                    .foregroundStyle(Theme.accentText)
            }
        }
        .padding(.horizontal, 20)
        .padding(.vertical, 12)
    }

    // MARK: - Display

    private var displayPanel: some View {
        ZStack(alignment: .topLeading) {
            VStack(alignment: .trailing, spacing: 4) {
                Button {
                    showBasePicker = true
                } label: {
                    HStack(spacing: 6) {
                        Text(state.baseCurrency.flag ?? state.baseCurrency.symbol)
                            .font(.system(size: 20))
                        Text(state.baseCurrency.code)
                            .font(.system(size: 18, weight: .semibold, design: .rounded))
                            .foregroundStyle(Theme.accentText)
                        Image(systemName: "chevron.down")
                            .font(.system(size: 12, weight: .semibold))
                            .foregroundStyle(Theme.accentText)
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(Theme.cardBackground, in: Capsule())
                }
                .accessibilityIdentifier("baseCurrencyButton")

                Text(displayAmount)
                    .font(Theme.displayFont)
                    .foregroundStyle(Theme.primaryText)
                    .lineLimit(1)
                    .minimumScaleFactor(0.4)
                    .frame(maxWidth: .infinity, alignment: .trailing)
                    .contentTransition(.numericText())
                    .animation(.snappy, value: state.inputString)
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)

            // Arrows sit in the top-left of the display panel, clear of the
            // conversion list and the currency selector (which is trailing-aligned).
            VStack(spacing: 8) {
                arrowButton(direction: .up,
                            icon: "chevron.up",
                            label: "Previous base currency")
                arrowButton(direction: .down,
                            icon: "chevron.down",
                            label: "Next base currency")
            }
            .padding(.leading, 12)
            .padding(.top, 8)
            .shadow(color: .black.opacity(0.3), radius: 4, y: 2)
        }
        .background(Theme.displayBg)
    }

    private var displayAmount: String {
        let raw = state.inputString
        if raw == "0" { return "0" }
        return raw
    }

    // MARK: - Staleness bar

    @ViewBuilder
    private var stalenessBar: some View {
        if state.isStale, let updated = state.lastUpdated {
            HStack(spacing: 6) {
                Image(systemName: "exclamationmark.triangle.fill")
                    .font(.system(size: 11))
                Text("Rates from \(updated, style: .relative) ago — pull to refresh")
                    .font(.system(size: 11, weight: .medium, design: .rounded))
                Spacer()
            }
            .foregroundStyle(Theme.staleWarning)
            .padding(.horizontal, 16)
            .padding(.vertical, 6)
            .background(Theme.staleWarning.opacity(0.12))
        } else if let updated = state.lastUpdated {
            HStack(spacing: 6) {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 11))
                Text("Updated \(updated, style: .relative) ago")
                    .font(.system(size: 11, design: .rounded))
                Spacer()
            }
            .foregroundStyle(Theme.fiatBadge)
            .padding(.horizontal, 16)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Base Cycler Arrows

    private func arrowButton(
        direction: AppState.CycleDirection,
        icon: String,
        label: String
    ) -> some View {
        Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            state.cycleBase(direction)
        } label: {
            Image(systemName: icon)
                .font(.system(size: 18, weight: .semibold))
                .foregroundStyle(Theme.accentText)
                .frame(width: 44, height: 44)
                .background(Color(hex: "#2A2A2C").opacity(0.9), in: Circle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
        .accessibilityHint("Cycles through your recent currencies")
    }

    // MARK: - Keypad

    private var keypadPanel: some View {
        VStack(spacing: 0) {
            Divider().background(Theme.cardBackground)
            NumericKeypad()
                .padding(.top, 8)
        }
        .background(Theme.appBackground)
    }
}

#Preview {
    let state = AppState()
    state.snapshot = RateSnapshot(
        ratesPerUSD: [
            "USD": 1.0, "EUR": 0.926, "JPY": 149.2,
            "MXN": 17.1, "GBP": 0.789, "CAD": 1.36,
            "AUD": 1.53, "BTC": 1.0/65000, "ETH": 1.0/3500
        ],
        fetchedAt: Date()
    )
    state.recentCurrencies = [.eur, .btc] + Array(Currency.allFiat.prefix(5))
    return ContentView()
        .environment(state)
}
