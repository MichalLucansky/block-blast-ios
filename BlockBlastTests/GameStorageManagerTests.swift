import XCTest
@testable import BlockBlast
import FactoryKit

@MainActor
final class GameStorageManagerTests: XCTestCase {
    
    private var userDefaults: UserDefaults!
    private var storage: GameStorageManager!
    
    override func setUp() {
        super.setUp()
        userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        storage = GameStorageManager(userDefaults: userDefaults)
    }
    
    override func tearDown() {
        storage = nil
        userDefaults = nil
        super.tearDown()
    }
    
    func test_init_defaults() {
        XCTAssertEqual(storage.highScore, 0)
        XCTAssertEqual(storage.gamesPlayed, 0)
        XCTAssertEqual(storage.totalBlocksPlaced, 0)
        XCTAssertEqual(storage.totalLinesCleared, 0)
        XCTAssertEqual(storage.maxCombo, 0)
    }
    
    func test_updateHighScore_increases() {
        storage.updateHighScore(100)
        XCTAssertEqual(storage.highScore, 100)
    }
    
    func test_updateHighScore_doesNotDecrease() {
        storage.updateHighScore(100)
        storage.updateHighScore(50)
        XCTAssertEqual(storage.highScore, 100)
    }
    
    func test_incrementGamesPlayed() {
        storage.incrementGamesPlayed()
        storage.incrementGamesPlayed()
        XCTAssertEqual(storage.gamesPlayed, 2)
    }
    
    func test_incrementBlocksPlaced() {
        storage.incrementBlocksPlaced(5)
        XCTAssertEqual(storage.totalBlocksPlaced, 5)
    }
    
    func test_incrementLinesCleared() {
        storage.incrementLinesCleared(10)
        XCTAssertEqual(storage.totalLinesCleared, 10)
    }
    
    func test_updateMaxCombo_increases() {
        storage.updateMaxCombo(3)
        XCTAssertEqual(storage.maxCombo, 3)
    }
    
    func test_updateMaxCombo_doesNotDecrease() {
        storage.updateMaxCombo(5)
        storage.updateMaxCombo(2)
        XCTAssertEqual(storage.maxCombo, 5)
    }
    
    func test_resetStats() {
        storage.updateHighScore(100)
        storage.incrementGamesPlayed()
        storage.incrementBlocksPlaced(10)
        storage.incrementLinesCleared(5)
        storage.updateMaxCombo(3)
        
        storage.resetStats()
        
        XCTAssertEqual(storage.highScore, 0)
        XCTAssertEqual(storage.gamesPlayed, 0)
        XCTAssertEqual(storage.totalBlocksPlaced, 0)
        XCTAssertEqual(storage.totalLinesCleared, 0)
        XCTAssertEqual(storage.maxCombo, 0)
    }
}
