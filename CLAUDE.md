# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

A Block Blast-style hyper-casual puzzle game for iOS (SwiftUI, iOS 18+). Drag block shapes onto an 8x8 grid; clear full rows/columns for points; build combos; game ends when no offered block fits.

## Build / Test

The Xcode project is **not** checked in — it is generated from `project.yml` by [XcodeGen](https://github.com/yonaskolb/XcodeGen). Always regenerate after editing `project.yml`, adding/removing/renaming source files, or changing build settings:

```bash
xcodegen generate          # produces BlockBlast.xcodeproj
```

Build and test from the CLI (a `BlockBlast` scheme is generated; `xcbeautify` is installed for readable output):

```bash
# Build
xcodebuild -scheme BlockBlast -destination 'platform=iOS Simulator,name=iPhone 16 Pro' build | xcbeautify

# Run all tests
xcodebuild -scheme BlockBlast -destination 'platform=iOS Simulator,name=iPhone 16 Pro' test | xcbeautify

# Run a single test class or method
xcodebuild -scheme BlockBlast -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:BlockBlastTests/GameViewModelTests test | xcbeautify
xcodebuild -scheme BlockBlast -destination 'platform=iOS Simulator,name=iPhone 16 Pro' \
  -only-testing:BlockBlastTests/GameViewModelTests/testPlaceBlock test | xcbeautify
```

## Architecture

MVVM with [Factory](https://github.com/hmlongco/Factory) (FactoryKit) for dependency injection. Reactive state via Combine `@Published` / `ObservableObject`. Persistence via `UserDefaults`.

**DI graph (`DI/DIContainer.swift`)** — registration scope matters and is the main source of subtle bugs:
- `gameStorageManager` — **singleton**. The single source of truth for all persisted stats.
- `statsViewModel` — **singleton**.
- `gameViewModel` — **not** a singleton: every `Container.shared.gameViewModel()` resolve creates a *new* instance. `ContentView` and `GameView` each resolve their own, so they hold **separate** game states. Keep this in mind when wiring game state across views.

**Layers:**
- `Services/GameStorageManager` — owns all persisted stats (`highScore`, `gamesPlayed`, `totalBlocksPlaced`, `totalLinesCleared`, `maxCombo`) as `@Published` read-only properties, backed by `UserDefaults` keys in the `UserDefaultsKey` enum. Mutated only through its increment/update methods, which persist immediately. Has a `init(userDefaults:)` for injecting a test double.
- `ViewModels/GameViewModel` — the gameplay engine. `@Injected` the storage manager. `placeBlock()` is the core loop: place → score by cell count → detect `completedLines()` → award line/combo bonus → trigger a 0.3s clear animation (`showLineClearAnimation`, then `clearLines` via `asyncAfter`) → refill `BlockHand` when empty → call `endGame()` if no remaining block has a valid move. All `@MainActor`.
- `ViewModels/StatsViewModel` — read/derive layer over the storage manager; mirrors its `@Published` values and computes per-game averages. `resetStats()` delegates to storage.
- `Models/GameModels.swift` — all domain types live here: `BlockShape` (cells + color, with the full catalog of predefined shapes in `allShapes`), `GameGrid` (8x8 `[[Color?]]`, `gridSize = 8`, with `canPlace`/`placeBlock`/`completedLines`/`clearLines`), `BlockHand` (3 randomly generated blocks; `generate()` assigns a fresh `UUID` per slot; `hasValidMoves(on:)` drives game-over detection), and `GameState`/`GameStatus`.
- `Views/` — `ContentView` (TabView: Play / Stats), `Scenes/GameView` & `StatsView`, and `Components/` (`GridComponent`, `BlockHandComponent`, `GameOverOverlay`).

## Conventions

- New source files must live under `BlockBlast/` (or `BlockBlastTests/`) and require a `xcodegen generate` to appear in the project.
- Register new dependencies as a `Factory` computed property in the `Container` extension; mark `@MainActor` and choose `.singleton` deliberately (see DI note above).
- Never read/write `UserDefaults` outside `GameStorageManager`; go through its methods so persistence and `@Published` updates stay consistent.
