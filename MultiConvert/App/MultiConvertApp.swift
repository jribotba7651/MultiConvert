import SwiftUI

@main
struct MultiConvertApp: App {
    @State private var appState = AppState()
    @State private var purchase = PurchaseManager()

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
        }
    }
}
