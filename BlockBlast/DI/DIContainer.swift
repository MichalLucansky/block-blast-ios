import FactoryKit

extension Container {
    @MainActor
    var gameStorageManager: Factory {
        self { GameStorageManager() }
            .singleton
    }
    
    @MainActor
    var gameViewModel: Factory {
        self { GameViewModel() }
    }
    
    @MainActor
    var statsViewModel: Factory {
        self { StatsViewModel() }
            .singleton
    }
}
