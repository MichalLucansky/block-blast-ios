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
    }

    @MainActor
    var statsViewModel: Factory<StatsViewModel> {
        self { StatsViewModel() }
            .singleton
    }
}
