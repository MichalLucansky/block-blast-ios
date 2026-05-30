import SwiftUI
import FactoryKit

struct ContentView: View {
    @StateObject private var gameVM = Container.shared.gameViewModel()
    
    var body: some View {
        TabView {
            GameView()
                .tabItem {
                    Label("Play", systemImage: "gamecontroller")
                }
            
            StatsView()
                .tabItem {
                    Label("Stats", systemImage: "chart.bar")
                }
        }
        .onAppear {
            if gameVM.status == .playing && gameVM.grid.isEmpty() && gameVM.blocksPlaced == 0 {
                gameVM.startNewGame()
            }
        }
    }
}
