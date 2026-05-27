import SwiftUI

struct GameOverOverlay: View {
    let score: Int
    let newHighScore: Bool
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
