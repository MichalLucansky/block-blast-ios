import SwiftUI
import AdMobKit

struct GameView: View {
    @StateObject private var viewModel = Container.shared.gameViewModel()

    var body: some View {
        // A single top-level GeometryReader gives us the real, device-specific
        // screen size, so every element is sized as a fraction of the available
        // space instead of with fixed magic numbers. The VStack is pinned to the
        // full size and Spacers distribute the slack — the screen is always
        // fully used regardless of device.
        GeometryReader { geo in
            // The board is the largest square that fits the width, capped so it
            // never crowds out the header / hand / banner on shorter screens.
            let gridSide = min(geo.size.width - 32, geo.size.height * 0.52)

            VStack(spacing: 0) {
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
                .padding(.top)

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
                    .padding(.top, 8)
                }

                Spacer(minLength: 8)

                // Game grid — a responsive square sized off the available space.
                // Drag a selected block over it to preview, release to place.
                GridComponent(
                    grid: viewModel.grid,
                    selectedBlock: viewModel.selectedBlock,
                    previewPosition: viewModel.previewPosition,
                    canPlaceAtPreview: viewModel.canPlaceAtPreview,
                    linesCleared: viewModel.linesClearedThisRound,
                    showAnimation: viewModel.showLineClearAnimation,
                    onPreview: { row, col in
                        viewModel.previewAt(row: row, col: col)
                    },
                    onCommit: {
                        viewModel.commitPlacement()
                    }
                )
                .frame(width: gridSide, height: gridSide)

                Spacer(minLength: 8)

                // Rotate control — always occupies the same slot so selecting a
                // block never reflows the board. It is simply enabled and
                // brightened while a block is selected, dimmed otherwise.
                Button {
                    viewModel.rotateSelectedBlock()
                } label: {
                    Label("Rotate", systemImage: "rotate.right")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.white)
                        .padding(.horizontal, 20)
                        .padding(.vertical, 10)
                        .background(viewModel.hasSelectedBlock ? Color.blue : Color.gray.opacity(0.4), in: Capsule())
                }
                .buttonStyle(.plain)
                .disabled(!viewModel.hasSelectedBlock)
                .animation(.easeInOut(duration: 0.15), value: viewModel.hasSelectedBlock)

                // Equal spacer above (grid) and below (hand) centres the rotate
                // button in the gap between the board and the block selection.
                Spacer(minLength: 8)

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

                Spacer(minLength: 8)

                // AdMob banner (fixed 320x50 ad format). Equal spacers above
                // (hand) and below (tab bar) centre it in the gap between the
                // block selection and the floating tab bar.
                BannerAdView()
                    .frame(width: 320, height: 50)

                Spacer(minLength: 8)
            }
            .frame(width: geo.size.width, height: geo.size.height)
        }
        .overlay {
            if viewModel.showGameOver {
                GameOverOverlay(
                    score: viewModel.score,
                    newHighScore: viewModel.newHighScore,
                    canWatchAd: viewModel.canRevive && AdService.shared.isRewardedAdReady,
                    onWatchAd: {
                        AdService.shared.showRewardedAd {
                            viewModel.revive()
                        }
                    },
                    onPlayAgain: {
                        viewModel.startNewGame()
                    }
                )
            }
        }
    }
}
