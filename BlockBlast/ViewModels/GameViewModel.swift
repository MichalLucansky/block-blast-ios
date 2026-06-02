import Foundation
import Combine
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
    @Published var previewPosition: (row: Int, col: Int)?
    @Published var canPlaceAtPreview: Bool = false
    @Published var showGameOver = false
    @Published var newHighScore = false
    @Published var linesClearedThisRound: Set<Int> = []
    @Published var showLineClearAnimation = false
    @Published private(set) var revivesUsed = 0

    /// Max number of rewarded "bonus life" revives allowed per game.
    static let maxRevives = 1
    
    // MARK: - Dependencies
    @Injected(\.gameStorageManager) private var storage: GameStorageManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        observeStorage()
    }
    
    // MARK: - Computed
    
    var highScore: Int { storage.highScore }
    var isGameOver: Bool { status == .gameOver }
    var hasSelectedBlock: Bool { selectedBlock != nil }

    /// Whether the player is eligible to spend a rewarded "bonus life" right now.
    var canRevive: Bool { status == .gameOver && revivesUsed < Self.maxRevives }
    
    // MARK: - Actions
    
    func startNewGame() {
        grid = GameGrid()
        hand = BlockHand.generate()
        score = 0
        combo = 0
        blocksPlaced = 0
        status = .playing
        selectedBlock = nil
        previewPosition = nil
        showGameOver = false
        newHighScore = false
        linesClearedThisRound = []
        showLineClearAnimation = false
        revivesUsed = 0
    }

    /// Grants a "bonus life" after watching a rewarded ad: clears the board and
    /// deals a fresh hand so the player can keep their score and continue.
    /// No-op if the player is not currently eligible (see `canRevive`).
    func revive() {
        guard canRevive else { return }
        revivesUsed += 1
        grid = GameGrid()
        hand = BlockHand.generate()
        status = .playing
        combo = 0
        selectedBlock = nil
        previewPosition = nil
        canPlaceAtPreview = false
        showGameOver = false
        linesClearedThisRound = []
        showLineClearAnimation = false
    }
    
    func selectBlock(_ block: BlockShape?) {
        selectedBlock = block
        previewPosition = nil
        canPlaceAtPreview = false
    }

    /// Rotates the currently selected block 90° clockwise. The matching hand
    /// slot is updated too (same id) so the hand preview reflects the rotation,
    /// and any active placement preview is re-evaluated. No-op if nothing is
    /// selected.
    func rotateSelectedBlock() {
        guard status == .playing, let block = selectedBlock else { return }
        let rotated = block.rotated()
        selectedBlock = rotated
        hand = BlockHand(blocks: hand.blocks.map { $0.id == rotated.id ? rotated : $0 })
        if let pos = previewPosition {
            canPlaceAtPreview = grid.canPlace(rotated, at: pos.row, col: pos.col)
        }
    }
    
    func previewAt(row: Int, col: Int) {
        guard let block = selectedBlock else { return }
        if let anchor = bestAnchor(for: block, tapRow: row, tapCol: col) {
            previewPosition = anchor
            canPlaceAtPreview = true
        } else {
            previewPosition = (row, col)
            canPlaceAtPreview = false
        }
    }

    /// Resolves where to drop `block` when the player taps `(tapRow, tapCol)`.
    /// Preference is to anchor the block's top-left at the tapped cell — exactly
    /// how it looks in the hand (WYSIWYG). If that exact spot is blocked or runs
    /// off the board, the block is nudged just enough to fit while still covering
    /// the tapped cell: each of its cells (in top-left-first reading order, which
    /// is how `cells` is stored) is tried under the tap and the first placement
    /// that fits wins. Returns `nil` if nothing covering the tap fits.
    func bestAnchor(for block: BlockShape, tapRow: Int, tapCol: Int) -> (row: Int, col: Int)? {
        block.cells
            .map { (row: tapRow - $0.row, col: tapCol - $0.col) }
            .first { grid.canPlace(block, at: $0.row, col: $0.col) }
    }
    
    func placeBlock() {
        guard let block = selectedBlock,
              let pos = previewPosition,
              grid.canPlace(block, at: pos.row, col: pos.col) else { return }
        
        // Place the block
        grid.placeBlock(block, at: pos.row, col: pos.col)
        blocksPlaced += 1
        storage.incrementBlocksPlaced()
        
        // Score for placing
        score += block.cellCount
        combo = 0
        
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
            
            // Trigger line clear animation
            linesClearedThisRound = Set(lines.rows + lines.cols.map { $0 + 100 })
            showLineClearAnimation = true
            
            // Clear lines after animation
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) { [weak self] in
                self?.grid.clearLines(lines)
                self?.showLineClearAnimation = false
                self?.linesClearedThisRound = []
            }
        }
        
        // Remove placed block from hand
        hand = BlockHand(blocks: hand.blocks.filter { $0.id != block.id })
        selectedBlock = nil
        previewPosition = nil
        
        // If hand is empty, generate new hand
        if hand.blocks.isEmpty {
            hand = BlockHand.generate()
            // Check if any new blocks can be placed
            if !hand.hasValidMoves(on: grid) {
                endGame()
            }
        } else {
            // Check if remaining blocks can be placed
            if !hand.hasValidMoves(on: grid) {
                endGame()
            }
        }
        
        // Update high score
        if score > storage.highScore {
            newHighScore = true
        }
        storage.updateHighScore(score)
    }
    
    func cancelPlacement() {
        selectedBlock = nil
        previewPosition = nil
        canPlaceAtPreview = false
    }
    
    func tapGridCell(row: Int, col: Int) {
        guard status == .playing else { return }
        
        if let block = selectedBlock {
            // If we have a selected block, drop it centred on the tapped cell.
            if let anchor = bestAnchor(for: block, tapRow: row, tapCol: col) {
                previewPosition = anchor
                canPlaceAtPreview = true
                placeBlock()
            } else {
                cancelPlacement()
            }
        } else {
            // Try to find a hand block that can be dropped over the tapped cell.
            for block in hand.blocks {
                if let anchor = bestAnchor(for: block, tapRow: row, tapCol: col) {
                    selectedBlock = block
                    previewPosition = anchor
                    canPlaceAtPreview = true
                    placeBlock()
                    return
                }
            }
        }
    }
    
    func endGame() {
        status = .gameOver
        storage.incrementGamesPlayed()
        if score > storage.highScore {
            newHighScore = true
        }
        storage.updateHighScore(score)
        showGameOver = true
    }
    
    // MARK: - Private
    
    private func observeStorage() {
        storage.$highScore
            .sink { [weak self] _ in
                // High score updated externally
            }
            .store(in: &cancellables)
    }
}
