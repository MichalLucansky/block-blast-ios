import SwiftUI
import FactoryKit

struct StatsView: View {
    @StateObject private var viewModel = Container.shared.statsViewModel()
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // High score card
                    StatCard(title: "HIGH SCORE", value: "\(viewModel.highScore)", icon: "trophy.fill", color: .orange)
                    
                    // Stats grid
                    LazyVGrid(columns: [
                        GridItem(.flexible()),
                        GridItem(.flexible())
                    ], spacing: 16) {
                        StatCard(title: "GAMES PLAYED", value: "\(viewModel.gamesPlayed)", icon: "gamecontroller.fill", color: .blue)
                        StatCard(title: "BLOCKS PLACED", value: "\(viewModel.totalBlocksPlaced)", icon: "square.fill", color: .green)
                        StatCard(title: "LINES CLEARED", value: "\(viewModel.totalLinesCleared)", icon: "sparkles", color: .purple)
                        StatCard(title: "MAX COMBO", value: "x\(viewModel.maxCombo)", icon: "flame.fill", color: .red)
                    }
                    
                    // Averages
                    if viewModel.gamesPlayed > 0 {
                        VStack(spacing: 12) {
                            Text("AVERAGES")
                                .font(.headline)
                                .foregroundColor(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            HStack(spacing: 16) {
                                StatCard(title: "AVG BLOCKS", value: "\(viewModel.avgBlocksPerGame)", icon: "chart.bar.fill", color: .cyan)
                                StatCard(title: "LINES/GAME", value: "\(viewModel.linesPerGame)", icon: "arrow.up.right.circle.fill", color: .mint)
                            }
                        }
                    }
                    
                    // Reset button
                    Button {
                        viewModel.resetStats()
                    } label: {
                        Text("RESET STATS")
                            .font(.subheadline)
                            .foregroundColor(.red)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red.opacity(0.1))
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                }
                .padding()
            }
            .navigationTitle("Statistics")
        }
    }
}

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(color)
            
            Text(value)
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(.primary)
            
            Text(title)
                .font(.caption2)
                .fontWeight(.semibold)
                .foregroundColor(.secondary)
                .lineLimit(1)
        }
        .frame(maxWidth: .infinity)
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
}
