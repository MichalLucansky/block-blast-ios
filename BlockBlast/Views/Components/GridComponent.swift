import SwiftUI

struct GridComponent: View {
    let grid: GameGrid
    let selectedBlock: BlockShape?
    let previewPosition: (row: Int, col: Int)?
    let canPlaceAtPreview: Bool
    let linesCleared: Set<Int>
    let showAnimation: Bool
    /// Called continuously as the finger moves over a cell (drives the ghost).
    let onPreview: (Int, Int) -> Void
    /// Called when the finger lifts (commits the placement at the preview).
    let onCommit: () -> Void

    private let inset: CGFloat = 4
    private let spacing: CGFloat = 2

    var body: some View {
        GeometryReader { geo in
            let side = min(geo.size.width, geo.size.height)
            let cell = (side - inset * 2 - spacing * CGFloat(GameGrid.gridSize - 1)) / CGFloat(GameGrid.gridSize)

            VStack(spacing: spacing) {
                ForEach(0..<GameGrid.gridSize, id: \.self) { row in
                    HStack(spacing: spacing) {
                        ForEach(0..<GameGrid.gridSize, id: \.self) { col in
                            CellView(
                                color: grid.cells[row][col],
                                isPreview: isPreviewCell(row, col),
                                canPlace: canPlaceAtPreview,
                                isCleared: linesCleared.contains(row),
                                showAnimation: showAnimation
                            )
                        }
                    }
                }
            }
            .padding(inset)
            .frame(width: side, height: side)
            .background(Color(.systemGray5))
            .cornerRadius(12)
            .contentShape(Rectangle())
            .gesture(
                // A single drag gesture handles both taps and drags: it fires a
                // live preview as the finger moves and commits on release.
                DragGesture(minimumDistance: 0)
                    .onChanged { value in
                        if let (r, c) = cellAt(value.location, cellSize: cell) {
                            onPreview(r, c)
                        }
                    }
                    .onEnded { _ in onCommit() }
            )
        }
    }

    /// Maps a touch point (in the grid's local space) to a grid cell, or nil if
    /// the point falls outside the 8x8 board.
    private func cellAt(_ point: CGPoint, cellSize: CGFloat) -> (Int, Int)? {
        let step = cellSize + spacing
        let col = Int((point.x - inset) / step)
        let row = Int((point.y - inset) / step)
        guard (0..<GameGrid.gridSize).contains(row), (0..<GameGrid.gridSize).contains(col) else { return nil }
        return (row, col)
    }

    private func isPreviewCell(_ row: Int, _ col: Int) -> Bool {
        guard let block = selectedBlock, let pos = previewPosition else { return false }
        for cell in block.cells {
            if row == pos.row + cell.row && col == pos.col + cell.col {
                return true
            }
        }
        return false
    }
}

struct CellView: View {
    let color: Color?
    let isPreview: Bool
    let canPlace: Bool
    let isCleared: Bool
    let showAnimation: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                color ?? (isPreview ? (canPlace ? Color.green.opacity(0.5) : Color.red.opacity(0.5)) : Color(.systemGray4))
            )
            .overlay {
                if isCleared && showAnimation {
                    Color.white
                        .opacity(0.8)
                        .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.easeInOut(duration: 0.2), value: showAnimation)
    }
}
