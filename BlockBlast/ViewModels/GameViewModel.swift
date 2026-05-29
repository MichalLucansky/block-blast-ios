import Foundation
import FactoryKit

@MainActor
final class GameViewModel: ObservableObject {
    // MARK: - Published state
    @Published var grid: GameGrid = GameGrid()
    @Published var hand: BlockHand = BlockHand.generate()
    @Published var score: Int = 0
    @Published var status: GameStatus = .playing
    @Published var combo: Int = 0
    @Published var blocksPlaced: Int = 0
    @Published var selectedBlock: BlockShape?
    @Published var rotationAngle: Int = 0 // 0, 90, 180, 270
    @Published var previewPosition: (row: Int, col: Int)?
    @Published var canPlaceAtPreview: Bool = false
    @Published var showGameOver = false
    @Published var newHighScore = false
    @Published var linesClearedRows: Set<Int> = []
    @Published var linesClearedCols: Set<Int> = []
    @Published var showLineClearAnimation = false
    
    // MARK: - Dependencies
    @Injected(\.gameStorageManager) private var storage: GameStorageManager
    
    /// Token to cancel stale animation timers.
    private var animationToken: UUID?
    
    init() {
        // No subscriptions needed — highScore accessed via computed property
    }
    
    // MARK: - Computed
    
    /// The currently selected block with rotation applied.
    var activeBlock: BlockShape? {
        selectedBlock?.rotated(by: rotationAngle)
    }
    
    var highScore: Int { storage.highScore }
    var isGameOver: Bool { status == .gameOver }
    var hasSelectedBlock: Bool { selectedBlock != nil }
    
    // MARK: - Actions
    
    func startNewGame() {
        grid = GameGrid()
        hand = BlockHand.generate()
        score = 0
        combo = 0
        blocksPlaced = 0
        status = .playing
        selectedBlock = nil
        rotationAngle = 0
        previewPosition = nil
        showGameOver = false
        newHighScore = false
        linesClearedRows = []
        linesClearedCols = []
        showLineClearAnimation = false
        animationToken = nil
    }
    
    func selectBlock(_ block: BlockShape?) {
        selectedBlock = block
        rotationAngle = 0
        previewPosition = nil
        canPlaceAtPreview = false
    }
    
    /// Rotate the selected block 90° clockwise.
    func rotateBlock() {
        guard selectedBlock != nil else { return }
        rotationAngle = (rotationAngle + 90) % 360
        previewPosition = nil
        canPlaceAtPreview = false
    }
    
    func placeBlock() {
        guard let selectedBlock,
              let pos = previewPosition else { return }
        let block = selectedBlock.rotated(by: rotationAngle)
        guard grid.canPlace(block, at: pos.row, col: pos.col) else { return }
        
        // Place the block — assign new grid so @Published fires
        grid = grid.placingBlock(block, at: pos.row, col: pos.col)
        blocksPlaced += 1
        storage.incrementBlocksPlaced()
        
        // Score for placing
        score += block.cellCount
        
        // Check for completed lines
        let lines = grid.completedLines()
        let totalLines = lines.rows.count + lines.cols.count
        
        if totalLines > 0 {
            combo += 1
            let lineScore = totalLines * GameGrid.gridSize + (combo > 1 ? combo * 5 : 0)
            score += lineScore
            storage.incrementLinesCleared(totalLines)
            if combo > 1 {
                storage.updateMaxCombo(combo)
            }
            
            // Clear lines immediately in the model — assign new grid so @Published fires
            grid = grid.clearingLines(lines)
            
            // Trigger line clear animation (visual only) — cancellable
            let token = UUID()
            animationToken = token
            linesClearedRows = Set(lines.rows)
            linesClearedCols = Set(lines.cols)
            showLineClearAnimation = true
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                guard let self, self.animationToken == token else { return }
                self.showLineClearAnimation = false
                self.linesClearedRows = []
                self.linesClearedCols = []
            }
        } else {
            // No lines cleared — reset combo
            combo = 0
        }
        
        // Remove placed block from hand
        hand = BlockHand(blocks: hand.blocks.filter { $0.id != selectedBlock.id })
        selectedBlock = nil
        rotationAngle = 0
        previewPosition = nil
        
        // If hand is empty, generate new hand
        if hand.blocks.isEmpty {
            hand = BlockHand.generate()
        }
        
        // Check if remaining blocks can be placed (after hand refresh)
        if !hand.hasValidMoves(on: grid) {
            endGame()
        }
        
        // Update high score (only when game is still active)
        if status == .playing {
            if score > storage.highScore {
                newHighScore = true
            }
            storage.updateHighScore(score)
        }
    }
    
    func cancelPlacement() {
        selectedBlock = nil
        rotationAngle = 0
        previewPosition = nil
        canPlaceAtPreview = false
    }
    
    func tapGridCell(row: Int, col: Int) {
        guard status == .playing else { return }
        guard let block = activeBlock else { return }
        
        // Try each cell in the block shape as the anchor for the tapped position
        // This lets the user tap any cell within the block's footprint
        var placed = false
        for cell in block.cells {
            let anchorRow = row - cell.row
            let anchorCol = col - cell.col
            if grid.canPlace(block, at: anchorRow, col: anchorCol) {
                previewPosition = (anchorRow, anchorCol)
                canPlaceAtPreview = true
                placeBlock()
                placed = true
                break
            }
        }
        
        // If we couldn't place, only show preview if the block actually fits
        if !placed {
            let valid = grid.canPlace(block, at: row, col: col)
            if valid {
                previewPosition = (row, col)
                canPlaceAtPreview = true
            } else {
                // Block doesn't fit anywhere near this tap — clear preview
                previewPosition = nil
                canPlaceAtPreview = false
            }
        }
    }
    
    func endGame() {
        guard blocksPlaced > 0 else { return }
        status = .gameOver
        storage.incrementGamesPlayed()
        if score > storage.highScore {
            newHighScore = true
        }
        storage.updateHighScore(score)
        showGameOver = true
    }
}
