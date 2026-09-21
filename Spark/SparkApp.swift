import SwiftUI

@main
struct SparkApp: App {
    @StateObject private var gameStore = GameStore()

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(gameStore)
                .preferredColorScheme(.light)
        }
    }
}
