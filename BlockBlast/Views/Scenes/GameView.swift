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
                selectedBlock: viewModel.selectedBlock,
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
                onSelect: { block in
                    if viewModel.selectedBlock?.id == block.id {
                        viewModel.cancelPlacement()
                    } else {
                        viewModel.selectBlock(block)
                    }
                }
            )
            .padding(.horizontal)
            
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
