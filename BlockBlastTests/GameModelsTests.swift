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
    
    func test_blockShape_codable() throws {
        let shape = BlockShape.l3x2
        let data = try JSONEncoder().encode(shape)
        let decoded = try JSONDecoder().decode(BlockShape.self, from: data)
        XCTAssertEqual(decoded.cells, shape.cells)
        XCTAssertEqual(decoded.color, shape.color)
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
        grid = grid.placingBlock(BlockShape.single, at: 3, col: 3)
        XCTAssertNotNil(grid.cells[3][3])
    }
    
    func test_grid_cannotPlaceOnOccupied() {
        var grid = GameGrid()
        grid = grid.placingBlock(BlockShape.single, at: 0, col: 0)
        XCTAssertFalse(grid.canPlace(BlockShape.single, at: 0, col: 0))
    }
    
    func test_grid_placeLargeShape() {
        var grid = GameGrid()
        XCTAssertTrue(grid.canPlace(BlockShape.square3x3, at: 0, col: 0))
        grid = grid.placingBlock(BlockShape.square3x3, at: 0, col: 0)
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
            grid = grid.placingBlock(BlockShape.single, at: 0, col: c)
        }
        let lines = grid.completedLines()
        XCTAssertEqual(lines.rows, [0])
        XCTAssertTrue(lines.cols.isEmpty)
    }
    
    func test_grid_completedColumn() {
        var grid = GameGrid()
        for r in 0..<GameGrid.gridSize {
            grid = grid.placingBlock(BlockShape.single, at: r, col: 0)
        }
        let lines = grid.completedLines()
        XCTAssertEqual(lines.cols, [0])
        XCTAssertTrue(lines.rows.isEmpty)
    }
    
    func test_grid_clearLines() {
        var grid = GameGrid()
        for c in 0..<GameGrid.gridSize {
            grid = grid.placingBlock(BlockShape.single, at: 0, col: c)
        }
        let lines = grid.completedLines()
        grid = grid.clearingLines(lines)
        XCTAssertTrue(grid.completedLines().rows.isEmpty)
    }
    
    func test_grid_clearDoesNotAffectOtherRows() {
        var grid = GameGrid()
        for c in 0..<GameGrid.gridSize {
            grid = grid.placingBlock(BlockShape.single, at: 0, col: c)
            grid = grid.placingBlock(BlockShape.single, at: 4, col: c)
        }
        let lines = grid.completedLines()
        grid = grid.clearingLines(lines)
        let remaining = grid.completedLines()
        XCTAssertTrue(remaining.rows.isEmpty)
    }
    
    func test_grid_clear() {
        var grid = GameGrid()
        grid = grid.placingBlock(BlockShape.single, at: 0, col: 0)
        grid = grid.cleared()
        XCTAssertTrue(grid.isEmpty())
    }
    
    func test_grid_codable() throws {
        var grid = GameGrid()
        grid = grid.placingBlock(BlockShape.single, at: 3, col: 3)
        let data = try JSONEncoder().encode(grid)
        let decoded = try JSONDecoder().decode(GameGrid.self, from: data)
        XCTAssertEqual(decoded.cells, grid.cells)
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
                grid = grid.placingBlock(BlockShape.single, at: r, col: c)
            }
        }
        XCTAssertFalse(hand.hasValidMoves(on: grid))
    }
    
    func test_hand_differentIDs() {
        let hand = BlockHand.generate()
        let ids = Set(hand.blocks.map(\.id))
        XCTAssertEqual(ids.count, 3, "All blocks should have unique IDs")
    }
    
    // MARK: - BlockColor
    
    func test_blockColor_codable() throws {
        let color = BlockColor.purple
        let data = try JSONEncoder().encode(color)
        let decoded = try JSONDecoder().decode(BlockColor.self, from: data)
        XCTAssertEqual(decoded, color)
    }
    
    // MARK: - Rotation
    
    func test_rotate90_preservesCellCount() {
        let shape = BlockShape.bar1x3H
        let rotated = shape.rotated90Clockwise()
        XCTAssertEqual(shape.cellCount, rotated.cellCount)
    }
    
    func test_rotate90_horizontalToVertical() {
        let shape = BlockShape.bar1x3H // 3 cells in a row
        let rotated = shape.rotated90Clockwise()
        XCTAssertEqual(rotated.width, 1)
        XCTAssertEqual(rotated.height, 3)
    }
    
    func test_rotate90_verticalToHorizontal() {
        let shape = BlockShape.bar1x2V // 2 cells in a column
        let rotated = shape.rotated90Clockwise()
        XCTAssertEqual(rotated.width, 2)
        XCTAssertEqual(rotated.height, 1)
    }
    
    func test_rotate360_returnsToOriginal() {
        let shape = BlockShape.l3x2
        let full = shape
            .rotated90Clockwise()
            .rotated90Clockwise()
            .rotated90Clockwise()
            .rotated90Clockwise()
        XCTAssertEqual(full.cells, shape.cells)
    }
    
    func test_rotate180_symmetric() {
        let shape = BlockShape.bar2x2
        let rotated = shape.rotated90Clockwise().rotated90Clockwise()
        XCTAssertEqual(rotated.cells, shape.cells)
    }
    
    func test_rotate_preservesColor() {
        let shape = BlockShape.l3x3
        let rotated = shape.rotated90Clockwise()
        XCTAssertEqual(rotated.color, shape.color)
    }
    
    // MARK: - hasValidMoves with rotation
    
    func test_hasValidMoves_considersRotation() {
        // Fill grid leaving only a 1x2 horizontal gap at row 0, cols 0-1
        var grid = GameGrid()
        for r in 0..<GameGrid.gridSize {
            for c in 0..<GameGrid.gridSize {
                if !(r == 0 && c < 2) {
                    grid = grid.placingBlock(BlockShape.single, at: r, col: c)
                }
            }
        }
        // bar1x2V (vertical) doesn't fit unrotated, but fits rotated 90°
        let hand = BlockHand(blocks: [BlockShape(id: UUID(), cells: BlockShape.bar1x2V.cells, color: .green)])
        XCTAssertTrue(hand.hasValidMoves(on: grid), "Should find valid move when block fits rotated")
    }
    
    func test_hasValidMoves_noRotationFits() {
        // Full grid — nothing fits in any orientation
        var grid = GameGrid()
        for r in 0..<GameGrid.gridSize {
            for c in 0..<GameGrid.gridSize {
                grid = grid.placingBlock(BlockShape.single, at: r, col: c)
            }
        }
        let hand = BlockHand.generate()
        XCTAssertFalse(hand.hasValidMoves(on: grid))
    }
}
