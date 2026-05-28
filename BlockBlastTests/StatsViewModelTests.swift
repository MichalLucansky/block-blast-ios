import XCTest
@testable import BlockBlast
import FactoryKit

@MainActor
final class StatsViewModelTests: XCTestCase {
    
    private var userDefaults: UserDefaults!
    private var storage: GameStorageManager!
    private var vm: StatsViewModel!
    
    override func setUp() {
        super.setUp()
        Container.shared.reset()
        userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        storage = GameStorageManager(userDefaults: userDefaults)
        Container.shared.gameStorageManager.register { self.storage }
        Container.shared.statsViewModel.register { StatsViewModel() }.singleton
        vm = Container.shared.statsViewModel()
    }
    
    override func tearDown() {
        vm = nil
        storage = nil
        userDefaults = nil
        Container.shared.reset()
        super.tearDown()
    }
    
    func test_init_defaultState() {
        XCTAssertEqual(vm.highScore, 0)
        XCTAssertEqual(vm.gamesPlayed, 0)
        XCTAssertEqual(vm.totalBlocksPlaced, 0)
        XCTAssertEqual(vm.totalLinesCleared, 0)
        XCTAssertEqual(vm.maxCombo, 0)
    }
    
    func test_avgBlocksPerGame_noGames() {
        XCTAssertEqual(vm.avgBlocksPerGame, 0)
    }
    
    func test_linesPerGame_noGames() {
        XCTAssertEqual(vm.linesPerGame, 0)
    }
    
    func test_storageUpdates_propagateToViewModel() {
        storage.updateHighScore(100)
        storage.incrementGamesPlayed()
        storage.incrementBlocksPlaced(10)
        storage.incrementLinesCleared(5)
        storage.updateMaxCombo(3)
        
        XCTAssertEqual(vm.highScore, 100)
        XCTAssertEqual(vm.gamesPlayed, 1)
        XCTAssertEqual(vm.totalBlocksPlaced, 10)
        XCTAssertEqual(vm.totalLinesCleared, 5)
        XCTAssertEqual(vm.maxCombo, 3)
    }
    
    func test_resetStats() {
        storage.updateHighScore(100)
        storage.incrementGamesPlayed()
        
        vm.resetStats()
        
        XCTAssertEqual(storage.highScore, 0)
        XCTAssertEqual(storage.gamesPlayed, 0)
        XCTAssertEqual(vm.highScore, 0)
        XCTAssertEqual(vm.gamesPlayed, 0)
    }
}
