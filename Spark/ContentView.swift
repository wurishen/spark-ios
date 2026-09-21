import SwiftUI

struct ContentView: View {
    @EnvironmentObject private var gameStore: GameStore

    var body: some View {
        Group {
            if !gameStore.state.hasPassedAgeGate {
                AgeGateView()
            } else if gameStore.state.character == nil {
                CharacterIntroView()
            } else {
                HomeView()
            }
        }
        .animation(.easeInOut(duration: 0.35), value: gameStore.state.hasPassedAgeGate)
        .animation(.easeInOut(duration: 0.35), value: gameStore.state.character?.id)
    }
}

#Preview {
    ContentView()
        .environmentObject(GameStore())
}
