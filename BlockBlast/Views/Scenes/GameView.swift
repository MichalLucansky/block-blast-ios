import SwiftUI
import FactoryKit

struct GameView: View {
    @StateObject private var viewModel = Container.shared.gameViewModel()
    @InjectedObject(\.adManager) private var adManager: AdManager

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
                GridComponent(
                    grid: viewModel.grid,
                    selectedBlock: viewModel.selectedBlock,
                    previewPosition: viewModel.previewPosition,
                    canPlaceAtPreview: viewModel.canPlaceAtPreview,
                    linesCleared: viewModel.linesClearedThisRound,
                    showAnimation: viewModel.showLineClearAnimation,
                    onTap: { row, col in
                        viewModel.tapGridCell(row: row, col: col)
                    }
                )
                .frame(width: gridSide, height: gridSide)

                Spacer(minLength: 8)

                // Rotate control — turn the selected block 90° before placing.
                if viewModel.hasSelectedBlock {
                    Button {
                        viewModel.rotateSelectedBlock()
                    } label: {
                        Label("Rotate", systemImage: "rotate.right")
                            .font(.subheadline.weight(.semibold))
                            .foregroundColor(.white)
                            .padding(.horizontal, 20)
                            .padding(.vertical, 10)
                            .background(Color.blue, in: Capsule())
                    }
                    .buttonStyle(.plain)
                    .padding(.bottom, 4)
                    .transition(.scale.combined(with: .opacity))
                }

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

                // AdMob banner near the bottom (fixed 320x50 ad format), with
                // breathing room above the floating tab bar.
                BannerAdView()
                    .frame(width: 320, height: 50)
                    .padding(.bottom, 16)
            }
            .frame(width: geo.size.width, height: geo.size.height)
            .animation(.spring(response: 0.3), value: viewModel.hasSelectedBlock)
        }
        .overlay {
            if viewModel.showGameOver {
                GameOverOverlay(
                    score: viewModel.score,
                    newHighScore: viewModel.newHighScore,
                    canWatchAd: viewModel.canRevive && adManager.isRewardedAdReady,
                    onWatchAd: {
                        adManager.showRewardedAd {
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
