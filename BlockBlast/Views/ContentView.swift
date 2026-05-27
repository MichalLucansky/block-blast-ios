import SwiftUI

struct ContentView: View {
    @StateObject private var gameVM = Container.shared.gameViewModel()
    @StateObject private var statsVM = Container.shared.statsViewModel()
    
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
            if gameVM.status == .playing && gameVM.grid.isEmpty() {
                gameVM.startNewGame()
            }
        }
    }
}

// MARK: - BlockColor to SwiftUI.Color mapping

extension BlockColor {
    var swiftUIColor: Color {
        switch self {
        case .yellow: return .yellow
        case .blue: return .blue
        case .green: return .green
        case .orange: return .orange
        case .red: return .red
        case .purple: return .purple
        case .pink: return .pink
        case .cyan: return .cyan
        case .mint: return .mint
        case .teal: return .teal
        case .indigo: return .indigo
        case .brown: return .brown
        }
    }
}
