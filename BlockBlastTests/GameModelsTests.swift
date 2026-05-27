import XCTest
@testable import BlockBlast
import FactoryKit

@MainActor
final class GameModelsTests: XCTestCase {
    
    // MARK: - BlockShape
    
    func test_blockShape_width() {
        let shape = BlockShape.bar1x3H
        XCTAssertEqual(shape.width, 3)
        XCTAssertEqual(shape.height, 1)
    }
    
    func test_blockShape_vertical() {
        let shape = BlockShape.bar1x3V
        XCTAssertEqual(shape.width, 1)
        XCTAssertEqual(shape.height, 3)
    }
    
    func test_blockShape_cellCount() {
        XCTAssertEqual(BlockShape.single.cellCount, 1)
        XCTAssertEqual(BlockShape.bar2x2.cellCount, 4)
        XCTAssertEqual(BlockShape.square3x3.cellCount, 9)
    }
    
    func test_blockShape_cellsSorted() {
        let shape = BlockShape.l3x2
        for i in 1..<shape.cells.count {
            XCTAssert(
                shape.cells[i - 1].row < shape.cells[i].row ||
                (shape.cells[i - 1].row == shape.cells[i].row && shape.cells[i - 1].col <= shape.cells[i].col),
                "Cells should be sorted"
            )
        }
    }
    
    func test_blockShape_allShapesHaveValidCells() {
        for shape in BlockShape.allShapes {
            XCTAssertGreaterThan(shape.cellCount, 0, "Shape should have at least 1 cell")
            XCTAssertLessThanOrEqual(shape.cellCount, 9, "Shape should have at most 9 cells")
            XCTAssertLessThanOrEqual(shape.width, 5, "Shape width should be <= 5")
            XCTAssertLessThanOrEqual(shape.height, 5, "Shape height should be <= 5")
        }
    }
    
    // MARK: - GameGrid
    
    func test_grid_init_empty() {
        var grid = GameGrid()
        XCTAssertTrue(grid.isEmpty())
    }
    
    func test_grid_canPlace_single() {
        var grid = GameGrid()
        XCTAssertTrue(grid.canPlace(BlockShape.single, at: 0, col: 0))
        XCTAssertTrue(grid.canPlace(BlockShape.single, at: 7, col: 7))
    }
    
    func test_grid_canPlace_outOfBounds() {
        var grid = GameGrid()
        XCTAssertFalse(grid.canPlace(BlockShape.single, at: -1, col: 0))
        XCTAssertFalse(grid.canPlace(BlockShape.single, at: 8, col: 0))
        XCTAssertFalse(grid.canPlace(BlockShape.single, at: 0, col: -1))
        XCTAssertFalse(grid.canPlace(BlockShape.single, at: 0, col: 8))
    }
    
    func test_grid_placeBlock() {
        var grid = GameGrid()
        grid.placeBlock(BlockShape.single, at: 3, col: 3)
        XCTAssertNotNil(grid.cells[3][3])
    }
    
    func test_grid_cannotPlaceOnOccupied() {
        var grid = GameGrid()
        grid.placeBlock(BlockShape.single, at: 0, col: 0)
        XCTAssertFalse(grid.canPlace(BlockShape.single, at: 0, col: 0))
    }
    
    func test_grid_placeLargeShape() {
        var grid = GameGrid()
        XCTAssertTrue(grid.canPlace(BlockShape.square3x3, at: 0, col: 0))
        grid.placeBlock(BlockShape.square3x3, at: 0, col: 0)
        for r in 0..<3 {
            for c in 0..<3 {
                XCTAssertNotNil(grid.cells[r][c])
            }
        }
    }
    
    func test_grid_shapeOutOfBounds() {
        var grid = GameGrid()
        XCTAssertFalse(grid.canPlace(BlockShape.square3x3, at: 6, col: 0))
        XCTAssertFalse(grid.canPlace(BlockShape.square3x3, at: 0, col: 6))
    }
    
    func test_grid_completedRow() {
        var grid = GameGrid()
        for c in 0..<GameGrid.gridSize {
            grid.placeBlock(BlockShape.single, at: 0, col: c)
        }
        let lines = grid.completedLines()
        XCTAssertEqual(lines.rows, [0])
        XCTAssertTrue(lines.cols.isEmpty)
    }
    
    func test_grid_completedColumn() {
        var grid = GameGrid()
        for r in 0..<GameGrid.gridSize {
            grid.placeBlock(BlockShape.single, at: r, col: 0)
        }
        let lines = grid.completedLines()
        XCTAssertEqual(lines.cols, [0])
        XCTAssertTrue(lines.rows.isEmpty)
    }
    
    func test_grid_clearLines() {
        var grid = GameGrid()
        for c in 0..<GameGrid.gridSize {
            grid.placeBlock(BlockShape.single, at: 0, col: c)
        }
        let lines = grid.completedLines()
        grid.clearLines(lines)
        XCTAssertTrue(grid.completedLines().rows.isEmpty)
    }
    
    func test_grid_clearDoesNotAffectOtherRows() {
        var grid = GameGrid()
        for c in 0..<GameGrid.gridSize {
            grid.placeBlock(BlockShape.single, at: 0, col: c)
            grid.placeBlock(BlockShape.single, at: 4, col: c)
        }
        let lines = grid.completedLines()
        grid.clearLines(lines)
        let remaining = grid.completedLines()
        XCTAssertTrue(remaining.rows.isEmpty)
    }
    
    func test_grid_clear() {
        var grid = GameGrid()
        grid.placeBlock(BlockShape.single, at: 0, col: 0)
        grid.clear()
        XCTAssertTrue(grid.isEmpty())
    }
    
    // MARK: - BlockHand
    
    func test_hand_generate_hasThreeBlocks() {
        let hand = BlockHand.generate()
        XCTAssertEqual(hand.blocks.count, 3)
    }
    
    func test_hand_hasValidMoves_emptyGrid() {
        let hand = BlockHand.generate()
        let grid = GameGrid()
        XCTAssertTrue(hand.hasValidMoves(on: grid))
    }
    
    func test_hand_noValidMoves_fullGrid() {
        let hand = BlockHand.generate()
        var grid = GameGrid()
        for r in 0..<GameGrid.gridSize {
            for c in 0..<GameGrid.gridSize {
                grid.placeBlock(BlockShape.single, at: r, col: c)
            }
        }
        XCTAssertFalse(hand.hasValidMoves(on: grid))
    }
    
    func test_hand_differentIDs() {
        let hand = BlockHand.generate()
        let ids = Set(hand.blocks.map(\.id))
        XCTAssertEqual(ids.count, 3, "All blocks should have unique IDs")
    }
}
