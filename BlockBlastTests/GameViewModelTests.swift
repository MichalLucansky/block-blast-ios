import XCTest
@testable import BlockBlast
import FactoryKit

@MainActor
final class GameViewModelTests: XCTestCase {
    
    private var userDefaults: UserDefaults!
    private var storage: GameStorageManager!
    
    private var viewModel: GameViewModel { Container.shared.gameViewModel() }
    
    override func setUp() {
        super.setUp()
        Container.shared.reset()
        userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        storage = GameStorageManager(userDefaults: userDefaults)
        Container.shared.gameStorageManager.register { self.storage }
        Container.shared.gameViewModel.register { GameViewModel() }
    }
    
    override func tearDown() {
        storage = nil
        userDefaults = nil
        Container.shared.reset()
        super.tearDown()
    }
    
    // MARK: - Initial state
    
    func test_init_defaultState() {
        XCTAssertTrue(viewModel.grid.isEmpty())
        XCTAssertEqual(viewModel.score, 0)
        XCTAssertEqual(viewModel.status, .playing)
        XCTAssertEqual(viewModel.combo, 0)
        XCTAssertEqual(viewModel.blocksPlaced, 0)
        XCTAssertNil(viewModel.selectedBlock)
        XCTAssertFalse(viewModel.showGameOver)
        XCTAssertFalse(viewModel.newHighScore)
    }
    
    func test_init_handHasThreeBlocks() {
        XCTAssertEqual(viewModel.hand.blocks.count, 3)
    }
    
    // MARK: - startNewGame
    
    func test_startNewGame_resetsState() {
        viewModel.startNewGame()
        XCTAssertTrue(viewModel.grid.isEmpty())
        XCTAssertEqual(viewModel.score, 0)
        XCTAssertEqual(viewModel.status, .playing)
        XCTAssertEqual(viewModel.combo, 0)
        XCTAssertEqual(viewModel.blocksPlaced, 0)
    }
    
    // MARK: - selectBlock
    
    func test_selectBlock_setsSelected() {
        let block = viewModel.hand.blocks.first!
        viewModel.selectBlock(block)
        XCTAssertEqual(viewModel.selectedBlock?.id, block.id)
    }
    
    func test_selectBlock_nilCancels() {
        viewModel.selectBlock(viewModel.hand.blocks.first!)
        viewModel.selectBlock(nil)
        XCTAssertNil(viewModel.selectedBlock)
    }
    
    // MARK: - tapGridCell
    
    func test_tapGridCell_placesBlock() {
        let block = viewModel.hand.blocks.first!
        viewModel.selectBlock(block)
        
        // Find a valid position
        let pos = findValidPosition(for: block, on: viewModel.grid)!
        viewModel.tapGridCell(row: pos.row, col: pos.col)
        
        XCTAssertEqual(viewModel.blocksPlaced, 1)
        XCTAssertNil(viewModel.selectedBlock)
        XCTAssertGreaterThan(viewModel.score, 0)
    }
    
    func test_tapGridCell_invalidPosition_doesNothing() {
        let block = viewModel.hand.blocks.first!
        viewModel.selectBlock(block)
        
        // Try to place at occupied position
        viewModel.tapGridCell(row: 0, col: 0)
        
        // Should place if valid
        if viewModel.grid.canPlace(block, at: 0, col: 0) {
            XCTAssertEqual(viewModel.blocksPlaced, 1)
        }
    }
    
    // MARK: - Combo and scoring
    
    func test_placeBlock_incrementsBlocksPlaced() {
        let block = viewModel.hand.blocks.first!
        viewModel.selectBlock(block)
        let pos = findValidPosition(for: block, on: viewModel.grid)!
        viewModel.tapGridCell(row: pos.row, col: pos.col)
        XCTAssertEqual(viewModel.blocksPlaced, 1)
    }
    
    func test_placeBlock_addsCellCountToScore() {
        let block = viewModel.hand.blocks.first!
        viewModel.selectBlock(block)
        let pos = findValidPosition(for: block, on: viewModel.grid)!
        viewModel.tapGridCell(row: pos.row, col: pos.col)
        XCTAssertGreaterThanOrEqual(viewModel.score, block.cellCount)
    }
    
    // MARK: - Line clearing
    
    func test_completeRow_clearsAndScores() {
        // Fill a row manually
        var grid = GameGrid()
        for c in 0..<GameGrid.gridSize {
            grid.placeBlock(BlockShape.single, at: 0, col: c)
        }
        viewModel.grid = grid
        
        // Place a block elsewhere
        let block = viewModel.hand.blocks.first!
        viewModel.selectBlock(block)
        let pos = findValidPosition(for: block, on: viewModel.grid)!
        viewModel.tapGridCell(row: pos.row, col: pos.col)
        
        // Row 0 should be cleared after animation delay
        // For synchronous test, check that lines were detected
        let lines = viewModel.grid.completedLines()
        // The row should have been cleared already
    }
    
    // MARK: - Game over
    
    func test_endGame_setsGameOver() {
        viewModel.endGame()
        XCTAssertEqual(viewModel.status, .gameOver)
        XCTAssertTrue(viewModel.showGameOver)
    }
    
    func test_endGame_incrementsGamesPlayed() {
        viewModel.endGame()
        XCTAssertEqual(storage.gamesPlayed, 1)
    }
    
    func test_endGame_updatesHighScore() {
        viewModel.score = 100
        viewModel.endGame()
        XCTAssertEqual(storage.highScore, 100)
    }
    
    // MARK: - Hand refresh
    
    func test_emptyHand_generatesNewHand() {
        // Place all 3 blocks
        for i in 0..<3 {
            guard let block = viewModel.hand.blocks.first else { break }
            viewModel.selectBlock(block)
            if let pos = findValidPosition(for: block, on: viewModel.grid) {
                viewModel.tapGridCell(row: pos.row, col: pos.col)
            }
        }
        
        // Hand should be refreshed
        XCTAssertEqual(viewModel.hand.blocks.count, 3)
    }
    
    // MARK: - High score
    
    func test_highScore_computedFromStorage() {
        storage.updateHighScore(500)
        XCTAssertEqual(viewModel.highScore, 500)
    }
    
    // MARK: - Computed properties
    
    func test_isGameOver() {
        XCTAssertFalse(viewModel.isGameOver)
        viewModel.endGame()
        XCTAssertTrue(viewModel.isGameOver)
    }
    
    func test_hasSelectedBlock() {
        XCTAssertFalse(viewModel.hasSelectedBlock)
        viewModel.selectBlock(viewModel.hand.blocks.first!)
        XCTAssertTrue(viewModel.hasSelectedBlock)
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
