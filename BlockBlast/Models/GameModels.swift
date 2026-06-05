import Foundation
import SwiftUI

// MARK: - Block Shape Definitions

/// A block shape is defined by its cells relative to a top-left anchor.
struct BlockShape: Identifiable {
    let id: UUID
    let cells: [(row: Int, col: Int)]
    let color: Color
    
    init(id: UUID = UUID(), cells: [(row: Int, col: Int)], color: Color) {
        self.id = id
        self.cells = cells.sorted { $0.row < $1.row || ($0.row == $1.row && $0.col < $1.col) }
        self.color = color
    }
    
    var width: Int { cells.map(\.col).max()! + 1 }
    var height: Int { cells.map(\.row).max()! + 1 }
    var cellCount: Int { cells.count }

    /// Returns the same block rotated 90° clockwise, re-normalized so its cells
    /// are still anchored at a (0, 0) top-left origin. Keeps the same `id` and
    /// `color` so it remains the same hand slot after rotation.
    func rotated() -> BlockShape {
        let maxRow = cells.map(\.row).max() ?? 0
        // 90° clockwise: (row, col) -> (col, maxRow - row).
        let rotated = cells.map { (row: $0.col, col: maxRow - $0.row) }
        let minRow = rotated.map(\.row).min() ?? 0
        let minCol = rotated.map(\.col).min() ?? 0
        let normalized = rotated.map { (row: $0.row - minRow, col: $0.col - minCol) }
        return BlockShape(id: id, cells: normalized, color: color)
    }

    /// The unique orientations reachable by rotating this block (1 to 4 of
    /// them — symmetric shapes like squares or single cells collapse to fewer).
    /// Used so move-availability checks match what the player can actually do
    /// with the rotate control.
    var distinctRotations: [BlockShape] {
        var result: [BlockShape] = []
        var current = self
        for _ in 0..<4 {
            let key = current.cells.map { "\($0.row),\($0.col)" }.joined(separator: ";")
            if !result.contains(where: { $0.cells.map { "\($0.row),\($0.col)" }.joined(separator: ";") == key }) {
                result.append(current)
            }
            current = current.rotated()
        }
        return result
    }
}

// MARK: - Predefined Block Shapes

extension BlockShape {
    static let allShapes: [BlockShape] = [
        // Single cell
        .single,
        
        // 1xN bars
        .bar1x2H, .bar1x2V,
        .bar1x3H, .bar1x3V,
        .bar1x4H, .bar1x4V,
        .bar1x5H, .bar1x5V,
        
        // 2xN bars
        .bar2x2, .bar2x3, .bar3x2,
        
        // L shapes
        .l2x2, .l2x2Mirror,
        .l3x2, .l3x2Mirror, .l2x3, .l2x3Mirror,
        
        // T shapes
        .t3x2, .t2x3, .t3x2Up, .t2x3Left,
        
        // S/Z shapes
        .s3x2, .z3x2, .s2x3, .z2x3,
        
        // Square
        .square3x3,
        
        // Big L
        .l3x3, .l3x3Mirror,
    ]
    
    // Single
    static let single = BlockShape(cells: [(0, 0)], color: .yellow)
    
    // 1xN horizontal
    static let bar1x2H = BlockShape(cells: [(0, 0), (0, 1)], color: .blue)
    static let bar1x3H = BlockShape(cells: [(0, 0), (0, 1), (0, 2)], color: .blue)
    static let bar1x4H = BlockShape(cells: [(0, 0), (0, 1), (0, 2), (0, 3)], color: .blue)
    static let bar1x5H = BlockShape(cells: [(0, 0), (0, 1), (0, 2), (0, 3), (0, 4)], color: .blue)
    
    // 1xN vertical
    static let bar1x2V = BlockShape(cells: [(0, 0), (1, 0)], color: .green)
    static let bar1x3V = BlockShape(cells: [(0, 0), (1, 0), (2, 0)], color: .green)
    static let bar1x4V = BlockShape(cells: [(0, 0), (1, 0), (2, 0), (3, 0)], color: .green)
    static let bar1x5V = BlockShape(cells: [(0, 0), (1, 0), (2, 0), (3, 0), (4, 0)], color: .green)
    
    // 2xN
    static let bar2x2 = BlockShape(cells: [(0, 0), (0, 1), (1, 0), (1, 1)], color: .orange)
    static let bar2x3 = BlockShape(cells: [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2)], color: .orange)
    static let bar3x2 = BlockShape(cells: [(0, 0), (0, 1), (1, 0), (1, 1), (2, 0), (2, 1)], color: .orange)
    
    // L shapes
    static let l2x2 = BlockShape(cells: [(0, 0), (1, 0), (1, 1)], color: .red)
    static let l2x2Mirror = BlockShape(cells: [(0, 1), (1, 0), (1, 1)], color: .red)
    static let l3x2 = BlockShape(cells: [(0, 0), (1, 0), (2, 0), (2, 1)], color: .purple)
    static let l3x2Mirror = BlockShape(cells: [(0, 1), (1, 1), (2, 0), (2, 1)], color: .purple)
    static let l2x3 = BlockShape(cells: [(0, 0), (1, 0), (1, 1), (1, 2)], color: .purple)
    static let l2x3Mirror = BlockShape(cells: [(0, 2), (1, 0), (1, 1), (1, 2)], color: .purple)
    
    // T shapes
    static let t3x2 = BlockShape(cells: [(0, 0), (1, 0), (1, 1), (2, 0)], color: .pink)
    static let t2x3 = BlockShape(cells: [(0, 0), (0, 1), (0, 2), (1, 1)], color: .pink)
    static let t3x2Up = BlockShape(cells: [(0, 0), (1, 0), (1, 1), (2, 0)], color: .mint)
    static let t2x3Left = BlockShape(cells: [(0, 0), (0, 1), (0, 2), (1, 1)], color: .mint)
    
    // S/Z shapes
    static let s3x2 = BlockShape(cells: [(0, 1), (1, 0), (1, 1), (2, 0)], color: .cyan)
    static let z3x2 = BlockShape(cells: [(0, 0), (0, 1), (1, 0), (1, 1), (2, 1)], color: .cyan)
    static let s2x3 = BlockShape(cells: [(0, 1), (0, 2), (1, 0), (1, 1)], color: .teal)
    static let z2x3 = BlockShape(cells: [(0, 0), (0, 1), (1, 1), (1, 2)], color: .teal)
    
    // Square
    static let square3x3 = BlockShape(
        cells: [(0, 0), (0, 1), (0, 2), (1, 0), (1, 1), (1, 2), (2, 0), (2, 1), (2, 2)],
        color: .indigo
    )
    
    // Big L
    static let l3x3 = BlockShape(
        cells: [(0, 0), (1, 0), (2, 0), (2, 1), (2, 2)],
        color: .brown
    )
    static let l3x3Mirror = BlockShape(
        cells: [(0, 2), (1, 2), (2, 0), (2, 1), (2, 2)],
        color: .brown
    )
}

// MARK: - Grid

/// The game grid - 8x8 board.
struct GameGrid: Equatable {
    static let gridSize = 8
    
    /// nil = empty, Color = filled
    var cells: [[Color?]]
    
    init() {
        self.cells = Array(repeating: Array(repeating: Color?.none, count: Self.gridSize), count: Self.gridSize)
    }

    mutating func placeBlock(_ shape: BlockShape, at row: Int, col: Int) {
        for cell in shape.cells {
            cells[row + cell.row][col + cell.col] = shape.color
        }
    }
    
    func canPlace(_ shape: BlockShape, at row: Int, col: Int) -> Bool {
        for cell in shape.cells {
            let targetRow = row + cell.row
            let targetCol = col + cell.col
            guard targetRow >= 0 && targetRow < Self.gridSize && targetCol >= 0 && targetCol < Self.gridSize else { return false }
            guard cells[targetRow][targetCol] == nil else { return false }
        }
        return true
    }
    
    /// Returns rows and columns that are completely filled.
    func completedLines() -> (rows: [Int], cols: [Int]) {
        var rows: [Int] = []
        var cols: [Int] = []
        
        for row in 0..<Self.gridSize {
            if cells[row].allSatisfy({ $0 != nil }) {
                rows.append(row)
            }
        }

        for col in 0..<Self.gridSize {
            var complete = true
            for row in 0..<Self.gridSize {
                if cells[row][col] == nil {
                    complete = false
                    break
                }
            }
            if complete { cols.append(col) }
        }
        
        return (rows, cols)
    }
    
    mutating func clearLines(_ lines: (rows: [Int], cols: [Int])) {
        for row in lines.rows {
            cells[row] = Array(repeating: nil, count: Self.gridSize)
        }
        for col in lines.cols {
            for row in 0..<Self.gridSize {
                cells[row][col] = nil
            }
        }
    }
    
    func isEmpty() -> Bool {
        cells.allSatisfy { row in row.allSatisfy { $0 == nil } }
    }
    
    mutating func clear() {
        cells = Array(repeating: Array(repeating: Color?.none, count: Self.gridSize), count: Self.gridSize)
    }
}

// MARK: - Game State

enum GameStatus: String, Codable {
    case playing
    case gameOver
}

struct GameState: Equatable {
    var grid: GameGrid
    var score: Int
    var highScore: Int
    var status: GameStatus
    var combo: Int
    var blocksPlaced: Int
    
    init() {
        self.grid = GameGrid()
        self.score = 0
        self.highScore = 0
        self.status = .playing
        self.combo = 0
        self.blocksPlaced = 0
    }
}

// MARK: - Hand (3 blocks offered to player)

struct BlockHand: Identifiable {
    let id: UUID
    var blocks: [BlockShape]
    
    init(id: UUID = UUID(), blocks: [BlockShape]) {
        self.id = id
        self.blocks = blocks
    }
    
    static func generate() -> BlockHand {
        let shapes = BlockShape.allShapes
        var blocks: [BlockShape] = []
        for _ in 0..<3 {
            let randomShape = shapes.randomElement()!
            // Create a new instance with a new ID so each hand slot is unique
            blocks.append(BlockShape(id: UUID(), cells: randomShape.cells, color: randomShape.color))
        }
        return BlockHand(blocks: blocks)
    }
    
    func hasValidMoves(on grid: GameGrid) -> Bool {
        for block in blocks {
            if canPlaceAnywhere(block, on: grid) {
                return true
            }
        }
        return false
    }
    
    /// A block counts as placeable if it fits in *any* of its rotations, since
    /// the player can rotate a piece before placing it. Checking only the
    /// current orientation would end the game while a rotated move is still
    /// available.
    private func canPlaceAnywhere(_ block: BlockShape, on grid: GameGrid) -> Bool {
        for rotation in block.distinctRotations {
            for row in 0..<GameGrid.gridSize {
                for col in 0..<GameGrid.gridSize {
                    if grid.canPlace(rotation, at: row, col: col) {
                        return true
                    }
                }
            }
        }
        return false
    }
}
