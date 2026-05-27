import SwiftUI

struct GridComponent: View {
    let grid: GameGrid
    let selectedBlock: BlockShape?
    let previewPosition: (row: Int, col: Int)?
    let canPlaceAtPreview: Bool
    let linesClearedRows: Set<Int>
    let linesClearedCols: Set<Int>
    let showAnimation: Bool
    let onTap: (Int, Int) -> Void
    
    var body: some View {
        VStack(spacing: 2) {
            ForEach(0..<GameGrid.gridSize, id: \.self) { row in
                HStack(spacing: 2) {
                    ForEach(0..<GameGrid.gridSize, id: \.self) { col in
                        CellView(
                            color: grid.cells[row][col],
                            isPreview: isPreviewCell(row, col),
                            canPlace: canPlaceAtPreview,
                            isCleared: linesClearedRows.contains(row) || linesClearedCols.contains(col),
                            showAnimation: showAnimation
                        )
                        .aspectRatio(1, contentMode: .fit)
                        .onTapGesture {
                            onTap(row, col)
                        }
                    }
                }
            }
        }
        .padding(4)
        .background(Color(.systemGray5))
        .cornerRadius(12)
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
    let color: BlockColor?
    let isPreview: Bool
    let canPlace: Bool
    let isCleared: Bool
    let showAnimation: Bool
    
    var body: some View {
        RoundedRectangle(cornerRadius: 4)
            .fill(
                color?.swiftUIColor ?? (isPreview ? (canPlace ? Color.green.opacity(0.5) : Color.red.opacity(0.5)) : Color(.systemGray4))
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
