import SwiftUI

struct BlockHandComponent: View {
    let hand: BlockHand
    let selectedBlock: BlockShape?
    let rotationAngle: Int
    let onSelect: (BlockShape) -> Void
    
    var body: some View {
        HStack(spacing: 20) {
            ForEach(hand.blocks) { block in
                let isSel = selectedBlock?.id == block.id
                let display = isSel ? block.rotated(by: rotationAngle) : block
                BlockPreview(block: display, isSelected: isSel)
                    .frame(maxWidth: .infinity, maxHeight: 80)
                    .onTapGesture {
                        onSelect(block)
                    }
            }
        }
        .padding(.vertical, 8)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}

struct BlockPreview: View {
    let block: BlockShape
    let isSelected: Bool
    
    var body: some View {
        ZStack {
            if isSelected {
                RoundedRectangle(cornerRadius: 8)
                    .fill(Color.white.opacity(0.3))
                    .shadow(radius: 2)
            }
            
            VStack(spacing: 1) {
                ForEach(0..<block.height, id: \.self) { row in
                    HStack(spacing: 1) {
                        ForEach(0..<block.width, id: \.self) { col in
                            if block.cells.contains(where: { $0.row == row && $0.col == col }) {
                                RoundedRectangle(cornerRadius: 2)
                                    .fill(block.color.swiftUIColor)
                                    .frame(width: cellSize, height: cellSize)
                            } else {
                                Color.clear
                                    .frame(width: cellSize, height: cellSize)
                            }
                        }
                    }
                }
            }
        }
    }
    
    private var cellSize: CGFloat {
        min(12.0, 60.0 / CGFloat(max(block.width, block.height)))
    }
}
