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

    @MainActor
    var adManager: Factory<AdManager> {
        self { AdManager() }
            .singleton
    }
}
