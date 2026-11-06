import SwiftUI

@main
struct BoleReaderApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .tint(.appBlue)
        }
    }
}
