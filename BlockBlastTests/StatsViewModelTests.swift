import XCTest
@testable import BlockBlast
import FactoryKit

@MainActor
final class StatsViewModelTests: XCTestCase {
    
    private var userDefaults: UserDefaults!
    private var storage: GameStorageManager!
    
    private var viewModel: StatsViewModel { Container.shared.statsViewModel() }
    
    override func setUp() {
        super.setUp()
        Container.shared.reset()
        userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        storage = GameStorageManager(userDefaults: userDefaults)
        Container.shared.gameStorageManager.register { self.storage }
        Container.shared.statsViewModel.register { StatsViewModel() }
    }
    
    override func tearDown() {
        storage = nil
        userDefaults = nil
        Container.shared.reset()
        super.tearDown()
    }
    
    func test_init_defaultState() {
        XCTAssertEqual(viewModel.highScore, 0)
        XCTAssertEqual(viewModel.gamesPlayed, 0)
        XCTAssertEqual(viewModel.totalBlocksPlaced, 0)
        XCTAssertEqual(viewModel.totalLinesCleared, 0)
        XCTAssertEqual(viewModel.maxCombo, 0)
    }
    
    func test_avgScore_noGames() {
        XCTAssertEqual(viewModel.avgScore, 0)
    }
    
    func test_avgBlocksPerGame_noGames() {
        XCTAssertEqual(viewModel.avgBlocksPerGame, 0)
    }
    
    func test_linesPerGame_noGames() {
        XCTAssertEqual(viewModel.linesPerGame, 0)
    }
    
    func test_resetStats() {
        storage.updateHighScore(100)
        storage.incrementGamesPlayed()
        
        viewModel.resetStats()
        
        RunLoop.main.run(until: Date(timeIntervalSinceNow: 0.1))
        
        XCTAssertEqual(storage.highScore, 0)
        XCTAssertEqual(storage.gamesPlayed, 0)
    }
}
