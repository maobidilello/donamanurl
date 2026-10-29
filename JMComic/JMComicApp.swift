import SwiftUI

@main
struct JMComicApp: App {
    @StateObject private var state = AppState()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(state)
                .tint(.appBlue)
        }
    }
}
