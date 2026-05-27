import Foundation
import Combine

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
    }
    
    func selectBlock(_ block: BlockShape?) {
        selectedBlock = block
        previewPosition = nil
        canPlaceAtPreview = false
    }
    
    func previewAt(row: Int, col: Int) {
        guard let block = selectedBlock else { return }
        previewPosition = (row, col)
        canPlaceAtPreview = grid.canPlace(block, at: row, col)
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
            // If we have a selected block, try to place it
            if grid.canPlace(block, at: row, col) {
                previewPosition = (row, col)
                canPlaceAtPreview = true
                placeBlock()
            } else {
                cancelPlacement()
            }
        } else {
            // Try to find a block from hand that fits here
            for block in hand.blocks {
                if grid.canPlace(block, at: row, col) {
                    selectedBlock = block
                    previewPosition = (row, col)
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
