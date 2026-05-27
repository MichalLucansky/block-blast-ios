# Block Blast - Hyper-Casual Block Puzzle Game

A Block Blast-style hyper-casual puzzle game for iOS built with SwiftUI.

## Gameplay

- Drag and drop block shapes onto an 8x8 grid
- Clear complete rows and columns to score points
- Build combos for bonus points
- Game ends when no more blocks can be placed

## Architecture

- **MVVM** with Factory DI
- **Models**: GameGrid, BlockShape, BlockHand, GameState
- **ViewModels**: GameViewModel (gameplay), StatsViewModel (persistent stats)
- **Views**: GameView, StatsView, GridComponent, BlockHandComponent

## Tech Stack

- SwiftUI (iOS 18.0+)
- Swift 5.9+
- Factory DI (FactoryKit)
- Combine for reactive state
- UserDefaults for persistence

## Project Structure

```
BlockBlast/
├── BlockBlastApp.swift
├── Info.plist
├── DI/DIContainer.swift
├── Models/GameModels.swift
├── Services/GameStorageManager.swift
├── ViewModels/GameViewModel.swift
├── ViewModels/StatsViewModel.swift
├── Views/ContentView.swift
└── Views/Scenes/GameView.swift, StatsView.swift
└── Views/Components/GridComponent.swift, BlockHandComponent.swift, GameOverOverlay.swift
BlockBlastTests/
├── GameModelsTests.swift
├── GameStorageManagerTests.swift
├── GameViewModelTests.swift
└── StatsViewModelTests.swift
```

## Building

1. Open `project.yml` with xcodegen on Mac: `xcodegen generate`
2. Open `BlockBlast.xcodeproj` in Xcode
3. Build and run on iOS 18.0+ simulator or device

## Ad Monetization (Planned)

- **Phase 1**: MVP with core gameplay (current)
- **Phase 2**: AdMob integration (interstitial between games, rewarded video for undo/revive)
- **Phase 3**: AppLovin MAX mediation for real-time bidding

## License

MIT
