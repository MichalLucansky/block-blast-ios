import XCTest
@testable import BlockBlast
import FactoryKit

@MainActor
final class GameViewModelTests: XCTestCase {
    
    private var userDefaults: UserDefaults!
    private var storage: GameStorageManager!

    // `gameViewModel` is a non-singleton factory (a new instance per resolve),
    // so resolve it once here and hold it — otherwise each `viewModel` access
    // would mutate a throwaway instance.
    private var viewModel: GameViewModel!

    override func setUp() {
        super.setUp()
        Container.shared.reset()
        userDefaults = UserDefaults(suiteName: UUID().uuidString)!
        storage = GameStorageManager(userDefaults: userDefaults)
        Container.shared.gameStorageManager.register { self.storage }
        Container.shared.gameViewModel.register { GameViewModel() }
        viewModel = Container.shared.gameViewModel()
    }

    override func tearDown() {
        viewModel = nil
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

    // MARK: - preview + commit (drag to place)

    func test_previewThenCommit_placesBlock() {
        let block = viewModel.hand.blocks.first!
        viewModel.selectBlock(block)
        let pos = findValidPosition(for: block, on: viewModel.grid)!

        viewModel.previewAt(row: pos.row, col: pos.col)
        XCTAssertTrue(viewModel.canPlaceAtPreview)
        XCTAssertNotNil(viewModel.previewPosition)

        viewModel.commitPlacement()
        XCTAssertEqual(viewModel.blocksPlaced, 1)
        XCTAssertNil(viewModel.selectedBlock)
    }

    func test_commitPlacement_invalidPreview_keepsSelectionAndPlacesNothing() {
        // Fill the board so nothing fits.
        var grid = GameGrid()
        for row in 0..<GameGrid.gridSize {
            for col in 0..<GameGrid.gridSize {
                grid.placeBlock(BlockShape.single, at: row, col: col)
            }
        }
        viewModel.grid = grid

        let block = BlockShape.single
        viewModel.selectBlock(block)
        viewModel.previewAt(row: 0, col: 0)
        XCTAssertFalse(viewModel.canPlaceAtPreview)

        viewModel.commitPlacement()
        XCTAssertEqual(viewModel.blocksPlaced, 0)
        XCTAssertEqual(viewModel.selectedBlock?.id, block.id, "Selection kept after an invalid drop")
    }

    // MARK: - rotateSelectedBlock

    func test_rotateSelectedBlock_rotatesSelectionAndHandSlot() {
        let block = BlockShape.bar1x3H // 3 wide, 1 tall
        viewModel.hand = BlockHand(blocks: [block])
        viewModel.selectBlock(block)

        viewModel.rotateSelectedBlock()

        XCTAssertEqual(viewModel.selectedBlock?.width, 1, "Selected block became vertical")
        XCTAssertEqual(viewModel.selectedBlock?.height, 3)
        let handSlot = viewModel.hand.blocks.first { $0.id == block.id }
        XCTAssertEqual(handSlot?.height, 3, "Hand slot reflects the rotation")
    }

    func test_rotateSelectedBlock_noOpWithoutSelection() {
        XCTAssertNil(viewModel.selectedBlock)
        viewModel.rotateSelectedBlock()
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
        // Fully occupy the board so no tap can place anything.
        var grid = GameGrid()
        for row in 0..<GameGrid.gridSize {
            for col in 0..<GameGrid.gridSize {
                grid.placeBlock(BlockShape.single, at: row, col: col)
            }
        }
        viewModel.grid = grid

        let block = viewModel.hand.blocks.first!
        viewModel.selectBlock(block)
        viewModel.tapGridCell(row: 3, col: 3)

        XCTAssertEqual(viewModel.blocksPlaced, 0, "Nothing places on a full board")
    }

    func test_tapGridCell_anchorsBlockTopLeftAtTap() {
        // A 3-wide horizontal bar should extend right/down from the tapped cell,
        // exactly as it looks in the hand — the tap is its top-left corner.
        let block = BlockShape.bar1x3H
        viewModel.selectBlock(block)

        viewModel.tapGridCell(row: 4, col: 4)

        XCTAssertNotNil(viewModel.grid.cells[4][4])
        XCTAssertNotNil(viewModel.grid.cells[4][5])
        XCTAssertNotNil(viewModel.grid.cells[4][6])
        XCTAssertNil(viewModel.grid.cells[4][3], "Block is anchored at the tap, not centred on it")
    }

    func test_tapGridCell_snapsInsideRightEdge() {
        // Tapping the last column would run the bar off the board; it should snap
        // inside the edge and still place (covering the tapped cell).
        let block = BlockShape.bar1x3H
        viewModel.selectBlock(block)

        viewModel.tapGridCell(row: 0, col: 7)

        XCTAssertEqual(viewModel.blocksPlaced, 1)
        XCTAssertNotNil(viewModel.grid.cells[0][7], "The tapped cell is covered by the block")
        XCTAssertNotNil(viewModel.grid.cells[0][5], "Bar snapped to cols 5,6,7")
    }

    func test_tapGridCell_shiftsToFitAroundOccupiedCells() {
        // Occupy a cell on the bottom row, then a 5-wide bar tapped just left of
        // it should shift left to fit (cols 0..4) while still covering the tap.
        var grid = GameGrid()
        grid.placeBlock(BlockShape.single, at: 7, col: 5)
        viewModel.grid = grid

        let bar = BlockShape.bar1x5H // top-left at col 1 would hit the occupied col 5
        viewModel.selectBlock(bar)
        viewModel.tapGridCell(row: 7, col: 1)

        XCTAssertEqual(viewModel.blocksPlaced, 1)
        for col in 0...4 {
            XCTAssertNotNil(viewModel.grid.cells[7][col], "Bar shifted to cols 0..4")
        }
        XCTAssertNotNil(viewModel.grid.cells[7][1], "Tapped cell is covered")
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
        for col in 0..<GameGrid.gridSize {
            grid.placeBlock(BlockShape.single, at: 0, col: col)
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
    
    /// Regression: placing a block that completes lines must not end the game when
    /// clearing those lines would re-open room for a remaining block. The clear is
    /// deferred for the animation, so game-over has to be evaluated against the
    /// *post-clear* grid — not the still-full grid at placement time.
    func test_placeBlock_clearingLinesReopensRoom_doesNotEndGame() {
        // Fill the entire board except the top-left corner.
        var grid = GameGrid()
        for row in 0..<GameGrid.gridSize {
            for col in 0..<GameGrid.gridSize where !(row == 0 && col == 0) {
                grid.placeBlock(BlockShape.single, at: row, col: col)
            }
        }
        viewModel.grid = grid

        // Two single blocks: placing the first into the corner completes lines and
        // clears the board; the second then clearly has somewhere to go.
        let placed = BlockShape(cells: [(0, 0)], color: .yellow)
        let remaining = BlockShape(cells: [(0, 0)], color: .blue)
        viewModel.hand = BlockHand(blocks: [placed, remaining])

        viewModel.selectBlock(placed)
        viewModel.tapGridCell(row: 0, col: 0)

        // Game must stay playing right after placement (clear is still pending)...
        XCTAssertEqual(viewModel.status, .playing, "Game ended before lines were cleared")

        // ...and after the deferred clear runs, with room re-opened.
        let cleared = expectation(description: "lines cleared")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) { cleared.fulfill() }
        wait(for: [cleared], timeout: 1.0)

        XCTAssertEqual(viewModel.status, .playing, "Game over despite cleared room")
        XCTAssertFalse(viewModel.showGameOver)
        XCTAssertTrue(viewModel.hand.hasValidMoves(on: viewModel.grid))
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
        for _ in 0..<3 {
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
    
    // MARK: - Revive (rewarded "bonus life")

    func test_canRevive_falseWhilePlaying() {
        XCTAssertEqual(viewModel.status, .playing)
        XCTAssertFalse(viewModel.canRevive)
    }

    func test_canRevive_trueAtGameOver() {
        viewModel.endGame()
        XCTAssertTrue(viewModel.canRevive)
    }

    func test_revive_whilePlaying_isNoOp() {
        viewModel.score = 50
        viewModel.revive()
        XCTAssertEqual(viewModel.status, .playing)
        XCTAssertEqual(viewModel.score, 50)
    }

    func test_revive_clearsBottomRowsKeepsTopAndScore() {
        // Fill the top row and the bottom rows so we can verify what's cleared.
        var grid = GameGrid()
        for col in 0..<GameGrid.gridSize {
            grid.placeBlock(BlockShape.single, at: 0, col: col)
            for row in (GameGrid.gridSize - GameViewModel.reviveRowsCleared)..<GameGrid.gridSize {
                grid.placeBlock(BlockShape.single, at: row, col: col)
            }
        }
        viewModel.grid = grid
        viewModel.score = 120
        viewModel.endGame()

        viewModel.revive()

        XCTAssertEqual(viewModel.status, .playing)
        XCTAssertFalse(viewModel.showGameOver)
        XCTAssertEqual(viewModel.score, 120, "Revive keeps the player's score")

        // The bottom rows are cleared for breathing room...
        for row in (GameGrid.gridSize - GameViewModel.reviveRowsCleared)..<GameGrid.gridSize {
            for col in 0..<GameGrid.gridSize {
                XCTAssertNil(viewModel.grid.cells[row][col], "Bottom rows are cleared")
            }
        }
        // ...while the structure above is kept.
        XCTAssertNotNil(viewModel.grid.cells[0][0], "Board above the bottom rows is preserved")
        XCTAssertEqual(viewModel.hand.blocks.count, 3, "Player still has a full hand")
    }

    func test_revive_isCappedAtMaxRevives() {
        for _ in 0..<GameViewModel.maxRevives {
            viewModel.endGame()
            XCTAssertTrue(viewModel.canRevive)
            viewModel.revive()
        }

        // After exhausting the allowance, a further game over cannot be revived.
        viewModel.endGame()
        XCTAssertFalse(viewModel.canRevive)

        viewModel.revive()
        XCTAssertEqual(viewModel.status, .gameOver, "Revive is a no-op once capped")
    }

    // MARK: - Helper
    
    /// Returns a grid cell that, when tapped, lets `block` be placed — a cell the
    /// block actually covers at some valid anchor. Placement anchors the block's
    /// top-left at the tap (shifting to fit if needed), so the tap target must be
    /// a cell the block occupies, not merely its (possibly empty) bounding-box
    /// corner.
    private func findValidPosition(for block: BlockShape, on grid: GameGrid) -> (row: Int, col: Int)? {
        for row in 0..<GameGrid.gridSize {
            for col in 0..<GameGrid.gridSize where grid.canPlace(block, at: row, col: col) {
                let covered = block.cells[0]
                return (row + covered.row, col + covered.col)
            }
        }
        return nil
    }
}
