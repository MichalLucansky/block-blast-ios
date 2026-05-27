import Foundation

// MARK: - Domain Color

/// Domain-safe color that doesn't depend on SwiftUI.
enum BlockColor: String, Codable, Equatable, CaseIterable {
    case yellow, blue, green, orange, red, purple, pink, cyan, mint, teal, indigo, brown
}

// MARK: - Cell Coordinate

/// A cell position within a block shape.
struct Cell: Codable, Equatable, Hashable {
    let row: Int
    let col: Int
}

// MARK: - Block Shape Definitions

/// A block shape is defined by its cells relative to a top-left anchor.
struct BlockShape: Identifiable, Codable, Equatable {
    let id: UUID
    let cells: [Cell]
    let color: BlockColor
    
    init(id: UUID = UUID(), cells: [Cell], color: BlockColor) {
        self.id = id
        self.cells = cells.sorted { $0.row < $1.row || ($0.row == $1.row && $0.col < $1.col) }
        self.color = color
    }
    
    var width: Int { cells.map(\.col).max()! + 1 }
    var height: Int { cells.map(\.row).max()! + 1 }
    var cellCount: Int { cells.count }
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
    static let single = BlockShape(cells: [Cell(row: 0, col: 0)], color: .yellow)
    
    // 1xN horizontal
    static let bar1x2H = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 0, col: 1)], color: .blue)
    static let bar1x3H = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 0, col: 1), Cell(row: 0, col: 2)], color: .blue)
    static let bar1x4H = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 0, col: 1), Cell(row: 0, col: 2), Cell(row: 0, col: 3)], color: .blue)
    static let bar1x5H = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 0, col: 1), Cell(row: 0, col: 2), Cell(row: 0, col: 3), Cell(row: 0, col: 4)], color: .blue)
    
    // 1xN vertical
    static let bar1x2V = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 1, col: 0)], color: .green)
    static let bar1x3V = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 1, col: 0), Cell(row: 2, col: 0)], color: .green)
    static let bar1x4V = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 1, col: 0), Cell(row: 2, col: 0), Cell(row: 3, col: 0)], color: .green)
    static let bar1x5V = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 1, col: 0), Cell(row: 2, col: 0), Cell(row: 3, col: 0), Cell(row: 4, col: 0)], color: .green)
    
    // 2xN
    static let bar2x2 = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 0, col: 1), Cell(row: 1, col: 0), Cell(row: 1, col: 1)], color: .orange)
    static let bar2x3 = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 0, col: 1), Cell(row: 0, col: 2), Cell(row: 1, col: 0), Cell(row: 1, col: 1), Cell(row: 1, col: 2)], color: .orange)
    static let bar3x2 = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 0, col: 1), Cell(row: 1, col: 0), Cell(row: 1, col: 1), Cell(row: 2, col: 0), Cell(row: 2, col: 1)], color: .orange)
    
    // L shapes
    static let l2x2 = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 1, col: 0), Cell(row: 1, col: 1)], color: .red)
    static let l2x2Mirror = BlockShape(cells: [Cell(row: 0, col: 1), Cell(row: 1, col: 0), Cell(row: 1, col: 1)], color: .red)
    static let l3x2 = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 1, col: 0), Cell(row: 2, col: 0), Cell(row: 2, col: 1)], color: .purple)
    static let l3x2Mirror = BlockShape(cells: [Cell(row: 0, col: 1), Cell(row: 1, col: 1), Cell(row: 2, col: 0), Cell(row: 2, col: 1)], color: .purple)
    static let l2x3 = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 1, col: 0), Cell(row: 1, col: 1), Cell(row: 1, col: 2)], color: .purple)
    static let l2x3Mirror = BlockShape(cells: [Cell(row: 0, col: 2), Cell(row: 1, col: 0), Cell(row: 1, col: 1), Cell(row: 1, col: 2)], color: .purple)
    
    // T shapes
    static let t3x2 = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 1, col: 0), Cell(row: 1, col: 1), Cell(row: 2, col: 0)], color: .pink)
    static let t2x3 = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 0, col: 1), Cell(row: 0, col: 2), Cell(row: 1, col: 1)], color: .pink)
    static let t3x2Up = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 1, col: 0), Cell(row: 1, col: 1), Cell(row: 2, col: 0)], color: .mint)
    static let t2x3Left = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 0, col: 1), Cell(row: 0, col: 2), Cell(row: 1, col: 1)], color: .mint)
    
    // S/Z shapes
    static let s3x2 = BlockShape(cells: [Cell(row: 0, col: 1), Cell(row: 1, col: 0), Cell(row: 1, col: 1), Cell(row: 2, col: 0)], color: .cyan)
    static let z3x2 = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 0, col: 1), Cell(row: 1, col: 0), Cell(row: 1, col: 1), Cell(row: 2, col: 1)], color: .cyan)
    static let s2x3 = BlockShape(cells: [Cell(row: 0, col: 1), Cell(row: 0, col: 2), Cell(row: 1, col: 0), Cell(row: 1, col: 1)], color: .teal)
    static let z2x3 = BlockShape(cells: [Cell(row: 0, col: 0), Cell(row: 0, col: 1), Cell(row: 1, col: 1), Cell(row: 1, col: 2)], color: .teal)
    
    // Square
    static let square3x3 = BlockShape(
        cells: [Cell(row: 0, col: 0), Cell(row: 0, col: 1), Cell(row: 0, col: 2), Cell(row: 1, col: 0), Cell(row: 1, col: 1), Cell(row: 1, col: 2), Cell(row: 2, col: 0), Cell(row: 2, col: 1), Cell(row: 2, col: 2)],
        color: .indigo
    )
    
    // Big L
    static let l3x3 = BlockShape(
        cells: [Cell(row: 0, col: 0), Cell(row: 1, col: 0), Cell(row: 2, col: 0), Cell(row: 2, col: 1), Cell(row: 2, col: 2)],
        color: .brown
    )
    static let l3x3Mirror = BlockShape(
        cells: [Cell(row: 0, col: 2), Cell(row: 1, col: 2), Cell(row: 2, col: 0), Cell(row: 2, col: 1), Cell(row: 2, col: 2)],
        color: .brown
    )
}

// MARK: - Grid

/// The game grid - 8x8 board.
struct GameGrid: Codable, Equatable {
    static let gridSize = 8
    
    /// nil = empty, BlockColor = filled
    var cells: [[BlockColor?]]
    
    init() {
        self.cells = Array(repeating: Array(repeating: BlockColor?.none, count: gridSize), count: gridSize)
    }
    
    mutating func placeBlock(_ shape: BlockShape, at row: Int, col: Int) {
        for cell in shape.cells {
            cells[row + cell.row][col + cell.col] = shape.color
        }
    }
    
    func canPlace(_ shape: BlockShape, at row: Int, col: Int) -> Bool {
        for cell in shape.cells {
            let r = row + cell.row
            let c = col + cell.col
            guard r >= 0 && r < gridSize && c >= 0 && c < gridSize else { return false }
            guard cells[r][c] == nil else { return false }
        }
        return true
    }
    
    /// Returns rows and columns that are completely filled.
    func completedLines() -> (rows: [Int], cols: [Int]) {
        var rows: [Int] = []
        var cols: [Int] = []
        
        for r in 0..<gridSize {
            if cells[r].allSatisfy({ $0 != nil }) {
                rows.append(r)
            }
        }
        
        for c in 0..<gridSize {
            var complete = true
            for r in 0..<gridSize {
                if cells[r][c] == nil {
                    complete = false
                    break
                }
            }
            if complete { cols.append(c) }
        }
        
        return (rows, cols)
    }
    
    mutating func clearLines(_ lines: (rows: [Int], cols: [Int])) {
        for r in lines.rows {
            cells[r] = Array(repeating: nil, count: gridSize)
        }
        for c in lines.cols {
            for r in 0..<gridSize {
                cells[r][c] = nil
            }
        }
    }
    
    func isEmpty() -> Bool {
        cells.allSatisfy { row in row.allSatisfy { $0 == nil } }
    }
    
    func clear() {
        cells = Array(repeating: Array(repeating: BlockColor?.none, count: gridSize), count: gridSize)
    }
}

// MARK: - Game State

enum GameStatus: String, Codable {
    case playing
    case gameOver
}

struct GameState: Codable, Equatable {
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

struct BlockHand: Identifiable, Codable, Equatable {
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
    
    private func canPlaceAnywhere(_ block: BlockShape, on grid: GameGrid) -> Bool {
        for r in 0..<GameGrid.gridSize {
            for c in 0..<GameGrid.gridSize {
                if grid.canPlace(block, at: r, col: c) {
                    return true
                }
            }
        }
        return false
    }
}
