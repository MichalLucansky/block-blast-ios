import XCTest
@testable import BlockBlast
import FactoryKit

@MainActor
final class GameViewModelTests: XCTestCase {
    
    private var userDefaults: UserDefaults!
    private var storage: GameStorageManager!
    private var vm: GameViewModel!
    
    override func setUp() {
        super.setUp()
        Container.shared.reset()
        userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        storage = GameStorageManager(userDefaults: userDefaults)
        Container.shared.gameStorageManager.register { self.storage }
        Container.shared.gameViewModel.register { GameViewModel() }.shared
        vm = Container.shared.gameViewModel()
    }
    
    override func tearDown() {
        vm = nil
        storage = nil
        userDefaults = nil
        Container.shared.reset()
        super.tearDown()
    }
    
    // MARK: - Initial state
    
    func test_init_defaultState() {
        XCTAssertTrue(vm.grid.isEmpty())
        XCTAssertEqual(vm.score, 0)
        XCTAssertEqual(vm.status, .playing)
        XCTAssertEqual(vm.combo, 0)
        XCTAssertEqual(vm.blocksPlaced, 0)
        XCTAssertNil(vm.selectedBlock)
        XCTAssertFalse(vm.showGameOver)
        XCTAssertFalse(vm.newHighScore)
    }
    
    func test_init_handHasThreeBlocks() {
        XCTAssertEqual(vm.hand.blocks.count, 3)
    }
    
    // MARK: - startNewGame
    
    func test_startNewGame_resetsState() {
        vm.startNewGame()
        XCTAssertTrue(vm.grid.isEmpty())
        XCTAssertEqual(vm.score, 0)
        XCTAssertEqual(vm.status, .playing)
        XCTAssertEqual(vm.combo, 0)
        XCTAssertEqual(vm.blocksPlaced, 0)
    }
    
    // MARK: - selectBlock
    
    func test_selectBlock_setsSelected() {
        let block = vm.hand.blocks.first!
        vm.selectBlock(block)
        XCTAssertEqual(vm.selectedBlock?.id, block.id)
    }
    
    func test_selectBlock_nilCancels() {
        vm.selectBlock(vm.hand.blocks.first!)
        vm.selectBlock(nil)
        XCTAssertNil(vm.selectedBlock)
    }
    
    // MARK: - tapGridCell
    
    func test_tapGridCell_placesBlock() {
        let block = vm.hand.blocks.first!
        vm.selectBlock(block)
        
        let pos = findValidPosition(for: block, on: vm.grid)!
        vm.tapGridCell(row: pos.row, col: pos.col)
        
        XCTAssertEqual(vm.blocksPlaced, 1)
        XCTAssertNil(vm.selectedBlock)
        XCTAssertGreaterThan(vm.score, 0)
    }
    
    func test_tapGridCell_invalidTap_keepsSelection() {
        let block = vm.hand.blocks.first!
        vm.selectBlock(block)
        
        // Fill (0,0) so it's invalid
        vm.grid.placeBlock(BlockShape.single, at: 0, col: 0)
        vm.tapGridCell(row: 0, col: 0)
        
        // Selection should be preserved
        XCTAssertNotNil(vm.selectedBlock)
        XCTAssertEqual(vm.selectedBlock?.id, block.id)
    }
    
    func test_tapGridCell_noSelection_doesNothing() {
        let initialBlocksPlaced = vm.blocksPlaced
        vm.tapGridCell(row: 0, col: 0)
        XCTAssertEqual(vm.blocksPlaced, initialBlocksPlaced)
    }
    
    // MARK: - Combo and scoring
    
    func test_placeBlock_incrementsBlocksPlaced() {
        let block = vm.hand.blocks.first!
        vm.selectBlock(block)
        let pos = findValidPosition(for: block, on: vm.grid)!
        vm.tapGridCell(row: pos.row, col: pos.col)
        XCTAssertEqual(vm.blocksPlaced, 1)
    }
    
    func test_placeBlock_addsCellCountToScore() {
        let block = vm.hand.blocks.first!
        vm.selectBlock(block)
        let pos = findValidPosition(for: block, on: vm.grid)!
        vm.tapGridCell(row: pos.row, col: pos.col)
        XCTAssertGreaterThanOrEqual(vm.score, block.cellCount)
    }
    
    func test_noLinesCleared_resetsCombo() {
        let block = vm.hand.blocks.first!
        vm.combo = 5
        vm.selectBlock(block)
        let pos = findValidPosition(for: block, on: vm.grid)!
        vm.tapGridCell(row: pos.row, col: pos.col)
        XCTAssertEqual(vm.combo, 0)
    }
    
    // MARK: - Line clearing
    
    func test_completeRow_clearsAndIncrementsCombo() {
        // Fill row 0 completely
        var grid = GameGrid()
        for c in 0..<GameGrid.gridSize {
            grid.placeBlock(BlockShape.single, at: 0, col: c)
        }
        vm.grid = grid
        
        let block = vm.hand.blocks.first!
        vm.selectBlock(block)
        let pos = findValidPosition(for: block, on: vm.grid)!
        vm.tapGridCell(row: pos.row, col: pos.col)
        
        // Combo should increment (not reset) when lines are cleared
        XCTAssertGreaterThan(vm.combo, 0)
        // Grid should have the line cleared immediately (model-level)
        let linesAfter = vm.grid.completedLines()
        XCTAssertFalse(linesAfter.rows.contains(0))
    }
    
    // MARK: - Game over
    
    func test_endGame_setsGameOver() {
        vm.blocksPlaced = 1
        vm.endGame()
        XCTAssertEqual(vm.status, .gameOver)
        XCTAssertTrue(vm.showGameOver)
    }
    
    func test_endGame_incrementsGamesPlayed() {
        vm.blocksPlaced = 1
        vm.endGame()
        XCTAssertEqual(storage.gamesPlayed, 1)
    }
    
    func test_endGame_noBlocksPlaced_doesNothing() {
        vm.endGame()
        XCTAssertEqual(vm.status, .playing)
        XCTAssertFalse(vm.showGameOver)
    }
    
    func test_endGame_updatesHighScore() {
        vm.score = 100
        vm.blocksPlaced = 1
        vm.endGame()
        XCTAssertEqual(storage.highScore, 100)
    }
    
    // MARK: - Hand refresh
    
    func test_emptyHand_generatesNewHand() {
        // Place all 3 blocks
        for _ in 0..<3 {
            guard let block = vm.hand.blocks.first else { break }
            vm.selectBlock(block)
            if let pos = findValidPosition(for: block, on: vm.grid) {
                vm.tapGridCell(row: pos.row, col: pos.col)
            }
        }
        
        // Hand should be refreshed
        XCTAssertEqual(vm.hand.blocks.count, 3)
    }
    
    // MARK: - High score
    
    func test_highScore_computedFromStorage() {
        storage.updateHighScore(500)
        XCTAssertEqual(vm.highScore, 500)
    }
    
    // MARK: - Computed properties
    
    func test_isGameOver() {
        XCTAssertFalse(vm.isGameOver)
        vm.blocksPlaced = 1
        vm.endGame()
        XCTAssertTrue(vm.isGameOver)
    }
    
    func test_hasSelectedBlock() {
        XCTAssertFalse(vm.hasSelectedBlock)
        vm.selectBlock(vm.hand.blocks.first!)
        XCTAssertTrue(vm.hasSelectedBlock)
    }
    
    // MARK: - Helper
    
    private func findValidPosition(for block: BlockShape, on grid: GameGrid) -> (row: Int, col: Int)? {
        for r in 0..<GameGrid.gridSize {
            for c in 0..<GameGrid.gridSize {
                if grid.canPlace(block, at: r, col: c) {
                    return (r, c)
                }
            }
        }
        return nil
    }
}
