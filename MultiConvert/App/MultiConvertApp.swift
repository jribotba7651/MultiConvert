import SwiftUI

@main
struct MultiConvertApp: App {
    @State private var appState: AppState
    @State private var purchase = PurchaseManager()
    @State private var consent = AdsConsentManager()

    init() {
        // Move pre-1.0.2 data into the App Group before AppState reads it.
        AppGroup.migrateLegacyDataIfNeeded()
        _appState = State(initialValue: AppState())
        // The Mobile Ads SDK is started by AdsConsentManager, only after
        // UMP consent and ATT, and never for premium users.
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(purchase)
                .environment(consent)
                .preferredColorScheme(.dark)
                .task {
                    async let rates: Void = appState.refresh()
                    async let store: Void = purchase.loadProducts()
                    async let ads: Void = startAdsFlow()
                    _ = await (rates, store, ads)
                }
                .onChange(of: purchase.isPremium) { _, isPremium in
                    // e.g. a refund revoked premium during this session.
                    if !isPremium {
                        Task { await consent.startIfNeeded(isPremium: false) }
                    }
                }
        }
    }

    /// Confirms the entitlement first so premium users never see the
    /// consent form or the ATT prompt.
    private func startAdsFlow() async {
        await purchase.refreshEntitlements()
        await consent.startIfNeeded(isPremium: purchase.isPremium)
    }
}
