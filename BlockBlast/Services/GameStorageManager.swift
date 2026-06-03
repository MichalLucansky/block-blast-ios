import Foundation
import Combine

enum UserDefaultsKey: String {
    case highScore = "blockblast.highscore"
    case gamesPlayed = "blockblast.gamesplayed"
    case blocksPlaced = "blockblast.blocksplaced"
    case linesCleared = "blockblast.linescleared"
    case maxCombo = "blockblast.maxcombo"
    case bestScore = "blockblast.bestsore"
}

final class GameStorageManager: ObservableObject {
    @Published private(set) var highScore: Int = 0
    @Published private(set) var gamesPlayed: Int = 0
    @Published private(set) var totalBlocksPlaced: Int = 0
    @Published private(set) var totalLinesCleared: Int = 0
    @Published private(set) var maxCombo: Int = 0
    
    private let userDefaults: UserDefaults
    
    convenience init() {
        self.init(userDefaults: .standard)
    }
    
    init(userDefaults: UserDefaults) {
        self.userDefaults = userDefaults
        load()
    }
    
    func updateHighScore(_ score: Int) {
        if score > highScore {
            highScore = score
            persist()
        }
    }
    
    func incrementGamesPlayed() {
        gamesPlayed += 1
        persist()
    }
    
    func incrementBlocksPlaced(_ count: Int = 1) {
        totalBlocksPlaced += count
        persist()
    }
    
    func incrementLinesCleared(_ count: Int) {
        totalLinesCleared += count
        persist()
    }
    
    func updateMaxCombo(_ combo: Int) {
        if combo > maxCombo {
            maxCombo = combo
            persist()
        }
    }
    
    func resetStats() {
        highScore = 0
        gamesPlayed = 0
        totalBlocksPlaced = 0
        totalLinesCleared = 0
        maxCombo = 0
        persist()
    }
    
    private func load() {
        highScore = userDefaults.integer(forKey: UserDefaultsKey.highScore.rawValue)
        gamesPlayed = userDefaults.integer(forKey: UserDefaultsKey.gamesPlayed.rawValue)
        totalBlocksPlaced = userDefaults.integer(forKey: UserDefaultsKey.blocksPlaced.rawValue)
        totalLinesCleared = userDefaults.integer(forKey: UserDefaultsKey.linesCleared.rawValue)
        maxCombo = userDefaults.integer(forKey: UserDefaultsKey.maxCombo.rawValue)
    }
    
    private func persist() {
        userDefaults.set(highScore, forKey: UserDefaultsKey.highScore.rawValue)
        userDefaults.set(gamesPlayed, forKey: UserDefaultsKey.gamesPlayed.rawValue)
        userDefaults.set(totalBlocksPlaced, forKey: UserDefaultsKey.blocksPlaced.rawValue)
        userDefaults.set(totalLinesCleared, forKey: UserDefaultsKey.linesCleared.rawValue)
        userDefaults.set(maxCombo, forKey: UserDefaultsKey.maxCombo.rawValue)
    }
}
