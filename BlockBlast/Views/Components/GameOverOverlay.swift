import SwiftUI

struct GameOverOverlay: View {
    let score: Int
    let newHighScore: Bool
    /// Whether a rewarded "bonus life" is currently available to offer.
    var canWatchAd: Bool = false
    var onWatchAd: () -> Void = {}
    let onPlayAgain: () -> Void
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.6)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                if newHighScore {
                    Text("🏆 NEW HIGH SCORE!")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(.orange)
                        .transition(.scale.combined(with: .opacity))
                }
                
                VStack(spacing: 8) {
                    Text("GAME OVER")
                        .font(.title)
                        .fontWeight(.bold)
                    
                    Text("\(score)")
                        .font(.system(size: 48, weight: .heavy, design: .rounded))
                        .foregroundColor(.blue)
                }
                
                if canWatchAd {
                    Button {
                        onWatchAd()
                    } label: {
                        Label("BONUS LIFE", systemImage: "play.rectangle.fill")
                            .font(.headline)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .padding(.horizontal, 32)
                            .padding(.vertical, 16)
                            .background(Color.green)
                            .cornerRadius(12)
                    }
                    .buttonStyle(.plain)
                    .shadow(radius: 4)
                    .transition(.scale.combined(with: .opacity))
                }

                Button {
                    onPlayAgain()
                } label: {
                    Text("PLAY AGAIN")
                        .font(.headline)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .padding(.horizontal, 40)
                        .padding(.vertical, 16)
                        .background(Color.blue)
                        .cornerRadius(12)
                }
                .buttonStyle(.plain)
                .shadow(radius: 4)
            }
            .padding(40)
            .background(Color(.systemBackground))
            .cornerRadius(20)
            .shadow(radius: 10)
        }
    }
}
