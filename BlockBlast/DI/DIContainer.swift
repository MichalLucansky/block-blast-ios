import FactoryKit

extension Container {
    @MainActor
    var gameStorageManager: Factory<GameStorageManager> {
        self { GameStorageManager() }
            .singleton
    }
    
    @MainActor
    var gameViewModel: Factory<GameViewModel> {
        self { GameViewModel() }
            .singleton // persistent game state — survives view lifecycle
    }
    
    @MainActor
    var statsViewModel: Factory<StatsViewModel> {
        self { StatsViewModel() }
            .singleton
    }
}
