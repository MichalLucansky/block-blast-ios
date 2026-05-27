import Foundation
import Combine

@MainActor
final class StatsViewModel: ObservableObject {
    // MARK: - Published state
    @Published var highScore: Int = 0
    @Published var gamesPlayed: Int = 0
    @Published var totalBlocksPlaced: Int = 0
    @Published var totalLinesCleared: Int = 0
    @Published var maxCombo: Int = 0
    
    // MARK: - Dependencies
    @Injected(\.gameStorageManager) private var storage: GameStorageManager
    
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        observeStorage()
    }
    
    // MARK: - Computed
    var avgScore: Int {
        guard gamesPlayed > 0 else { return 0 }
        return highScore / max(gamesPlayed, 1)
    }
    
    var avgBlocksPerGame: Int {
        guard gamesPlayed > 0 else { return 0 }
        return totalBlocksPlaced / gamesPlayed
    }
    
    var linesPerGame: Int {
        guard gamesPlayed > 0 else { return 0 }
        return totalLinesCleared / gamesPlayed
    }
    
    // MARK: - Actions
    func resetStats() {
        storage.resetStats()
    }
    
    // MARK: - Private
    private func observeStorage() {
        storage.$highScore
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.highScore = value
            }
            .store(in: &cancellables)
        
        storage.$gamesPlayed
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.gamesPlayed = value
            }
            .store(in: &cancellables)
        
        storage.$totalBlocksPlaced
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.totalBlocksPlaced = value
            }
            .store(in: &cancellables)
        
        storage.$totalLinesCleared
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.totalLinesCleared = value
            }
            .store(in: &cancellables)
        
        storage.$maxCombo
            .receive(on: DispatchQueue.main)
            .sink { [weak self] value in
                self?.maxCombo = value
            }
            .store(in: &cancellables)
    }
}
