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
        for index in 1..<shape.cells.count {
            XCTAssert(
                shape.cells[index - 1].row < shape.cells[index].row ||
                (shape.cells[index - 1].row == shape.cells[index].row && shape.cells[index - 1].col <= shape.cells[index].col),
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

    // MARK: - Rotation

    func test_rotated_swapsWidthAndHeight() {
        let rotated = BlockShape.bar1x3H.rotated() // 3 wide, 1 tall -> 1 wide, 3 tall
        XCTAssertEqual(rotated.width, 1)
        XCTAssertEqual(rotated.height, 3)
    }

    func test_rotated_preservesIdColorAndCellCount() {
        let original = BlockShape.l3x2
        let rotated = original.rotated()
        XCTAssertEqual(rotated.id, original.id, "Rotation keeps the same hand slot id")
        XCTAssertEqual(rotated.color, original.color)
        XCTAssertEqual(rotated.cellCount, original.cellCount)
    }

    func test_rotated_isNormalizedToTopLeftOrigin() {
        let rotated = BlockShape.l3x2.rotated()
        XCTAssertEqual(rotated.cells.map(\.row).min(), 0, "Rotated cells start at row 0")
        XCTAssertEqual(rotated.cells.map(\.col).min(), 0, "Rotated cells start at col 0")
    }

    func test_rotated_fourTimesReturnsToOriginal() {
        for shape in BlockShape.allShapes {
            let fourTimes = shape.rotated().rotated().rotated().rotated()
            XCTAssertEqual(
                fourTimes.cells.map { [$0.row, $0.col] },
                shape.cells.map { [$0.row, $0.col] },
                "Four 90° rotations should return to the original cells"
            )
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
        for row in 0..<3 {
            for col in 0..<3 {
                XCTAssertNotNil(grid.cells[row][col])
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
        for col in 0..<GameGrid.gridSize {
            grid.placeBlock(BlockShape.single, at: 0, col: col)
        }
        let lines = grid.completedLines()
        XCTAssertEqual(lines.rows, [0])
        XCTAssertTrue(lines.cols.isEmpty)
    }
    
    func test_grid_completedColumn() {
        var grid = GameGrid()
        for row in 0..<GameGrid.gridSize {
            grid.placeBlock(BlockShape.single, at: row, col: 0)
        }
        let lines = grid.completedLines()
        XCTAssertEqual(lines.cols, [0])
        XCTAssertTrue(lines.rows.isEmpty)
    }
    
    func test_grid_clearLines() {
        var grid = GameGrid()
        for col in 0..<GameGrid.gridSize {
            grid.placeBlock(BlockShape.single, at: 0, col: col)
        }
        let lines = grid.completedLines()
        grid.clearLines(lines)
        XCTAssertTrue(grid.completedLines().rows.isEmpty)
    }
    
    func test_grid_clearDoesNotAffectOtherRows() {
        var grid = GameGrid()
        for col in 0..<GameGrid.gridSize {
            grid.placeBlock(BlockShape.single, at: 0, col: col)
            grid.placeBlock(BlockShape.single, at: 4, col: col)
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
        for row in 0..<GameGrid.gridSize {
            for col in 0..<GameGrid.gridSize {
                grid.placeBlock(BlockShape.single, at: row, col: col)
            }
        }
        XCTAssertFalse(hand.hasValidMoves(on: grid))
    }
    
    func test_hand_differentIDs() {
        let hand = BlockHand.generate()
        let ids = Set(hand.blocks.map(\.id))
        XCTAssertEqual(ids.count, 3, "All blocks should have unique IDs")
    }

    /// Regression: a piece that fits only after rotation must keep the game
    /// alive, since the player can rotate before placing. The board below has
    /// no 3-wide horizontal gap, but a vertical 3-cell gap in column 0; a
    /// horizontal 1x3 bar is unplaceable as-is but fits when rotated.
    func test_hand_hasValidMoves_whenOnlyRotatedPlacementFits() {
        var grid = GameGrid()
        for row in 0..<GameGrid.gridSize {
            for col in 0..<GameGrid.gridSize {
                grid.placeBlock(BlockShape.single, at: row, col: col)
            }
        }
        // Carve a vertical 3-cell gap in column 0 (rows 0-2).
        grid.cells[0][0] = nil
        grid.cells[1][0] = nil
        grid.cells[2][0] = nil

        let horizontalBar = BlockShape.bar1x3H // 3 wide, 1 tall
        XCTAssertFalse(
            grid.canPlace(horizontalBar, at: 0, col: 0),
            "Horizontal bar must not fit as-is — there is no 3-wide gap"
        )
        let hand = BlockHand(blocks: [horizontalBar])
        XCTAssertTrue(
            hand.hasValidMoves(on: grid),
            "Game must stay alive: the bar fits in the vertical gap once rotated"
        )
    }
}
