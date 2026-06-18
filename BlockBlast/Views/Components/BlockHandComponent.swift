import SwiftUI

struct BlockHandComponent: View {
    let hand: BlockHand
    let selectedBlock: BlockShape?
    let onSelect: (BlockShape) -> Void

    /// Height of the slot row; also caps each preview so they stay aligned.
    private let slotHeight: CGFloat = 80

    var body: some View {
        HStack(spacing: 20) {
            ForEach(hand.blocks) { block in
                BlockPreview(block: block, isSelected: selectedBlock?.id == block.id)
                    .frame(maxWidth: .infinity, maxHeight: slotHeight)
                    .onTapGesture {
                        onSelect(block)
                    }
            }
        }
        // Fixed footprint so the surrounding layout (board included) never
        // reflows with the hand's contents — even if the hand were ever empty.
        .frame(maxWidth: .infinity)
        .frame(height: slotHeight)
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
                                    .fill(block.color)
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
        min(12, 60 / CGFloat(max(block.width, block.height)))
    }
}
