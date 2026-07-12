import SwiftUI
import GoogleMobileAds
import AppTrackingTransparency

@main
struct MultiConvertApp: App {
    @State private var appState = AppState()
    @State private var purchase = PurchaseManager()

    init() {
        MobileAds.shared.start(completionHandler: nil)
    }

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .environment(purchase)
                .preferredColorScheme(.dark)
                .task {
                    await appState.refresh()
                    await purchase.loadProducts()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.didBecomeActiveNotification)) { _ in
                    requestTrackingIfNeeded()
                }
        }
    }

    private func requestTrackingIfNeeded() {
        guard ATTrackingManager.trackingAuthorizationStatus == .notDetermined else { return }
        // Small delay so the prompt doesn't appear before the UI is fully loaded
        // (Apple rejects if it shows too early).
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            ATTrackingManager.requestTrackingAuthorization { _ in }
        }
    }
}
