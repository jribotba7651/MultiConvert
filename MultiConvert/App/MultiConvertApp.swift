import SwiftUI

@main
struct MultiConvertApp: App {
    @State private var appState = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environment(appState)
                .preferredColorScheme(.dark)
                .task {
                    await appState.refresh()
                }
        }
    }
}
