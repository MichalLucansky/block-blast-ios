import SwiftUI
import FactoryKit

struct GameView: View {
    @StateObject private var viewModel = Container.shared.gameViewModel()
    
    var body: some View {
        VStack(spacing: 16) {
            // Score header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("SCORE")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.score)")
                        .font(.system(size: 32, weight: .bold, design: .rounded))
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("BEST")
                        .font(.caption2)
                        .fontWeight(.semibold)
                        .foregroundColor(.secondary)
                    Text("\(viewModel.highScore)")
                        .font(.system(size: 20, weight: .bold, design: .rounded))
                        .foregroundColor(.orange)
                }
            }
            .padding(.horizontal)
            
            // Combo indicator
            if viewModel.combo > 1 {
                HStack(spacing: 4) {
                    Text("COMBO")
                        .font(.caption)
                        .fontWeight(.bold)
                    Text("x\(viewModel.combo)")
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                }
                .padding(.vertical, 4)
                .padding(.horizontal, 12)
                .background(Color.orange.opacity(0.2))
                .cornerRadius(8)
                .transition(.scale.combined(with: .opacity))
            } else {
                Spacer()
                    .frame(height: 32)
            }
            
            // Game grid
            GridComponent(
                grid: viewModel.grid,
                activeBlock: viewModel.activeBlock,
                previewPosition: viewModel.previewPosition,
                canPlaceAtPreview: viewModel.canPlaceAtPreview,
                linesClearedRows: viewModel.linesClearedRows,
                linesClearedCols: viewModel.linesClearedCols,
                showAnimation: viewModel.showLineClearAnimation,
                onTap: { row, col in
                    viewModel.tapGridCell(row: row, col: col)
                }
            )
            .padding(.horizontal)
            
            // Block hand
            BlockHandComponent(
                hand: viewModel.hand,
                selectedBlock: viewModel.selectedBlock,
                rotationAngle: viewModel.rotationAngle,
                onSelect: { block in
                    if viewModel.selectedBlock?.id == block.id {
                        viewModel.cancelPlacement()
                    } else {
                        viewModel.selectBlock(block)
                    }
                }
            )
            .padding(.horizontal)
            
            // Rotate button
            if viewModel.hasSelectedBlock {
                Button(action: {
                    viewModel.rotateBlock()
                }) {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.clockwise")
                        Text("ROTATE")
                            .font(.caption)
                            .fontWeight(.semibold)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
                .padding(.horizontal)
                .transition(.opacity.combined(with: .scale))
            }
            
            Spacer()
        }
        .overlay {
            if viewModel.showGameOver {
                GameOverOverlay(
                    score: viewModel.score,
                    newHighScore: viewModel.newHighScore,
                    onPlayAgain: {
                        viewModel.startNewGame()
                    }
                )
            }
        }
    }
}
