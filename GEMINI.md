# NowCoiner

NowCoiner is a macOS menu bar cryptocurrency price tracker built with Swift, SwiftUI, and AppKit. It uses a clean MVVM architecture with protocol-driven services for testability.

## Project Overview

*   **Type:** macOS Menu Bar App (LSUIElement)
*   **Language:** Swift 6.2
*   **Frameworks:** SwiftUI, AppKit, Combine (implicitly via ObservableObject/Async)
*   **Build System:** Swift Package Manager (SPM) - *No .xcodeproj file*
*   **Data Sources:**
    *   **Binance WebSocket:** Real-time sub-second price updates (`miniTicker`).
    *   **CoinGecko API:** Historical data, market cap, sparklines, and list of coins.

## Directory Structure

*   `Sources/NowCoinerCore/`: The core logic library. Contains Models, Services, Storage, Utils, and ViewModels. All business logic resides here.
*   `Sources/NowCoinerApp/`: The executable target. Contains SwiftUI Views, AppKit integration (Menu Bar, Panels), and the App entry point.
*   `Tests/NowCoinerCoreTests/`: Unit tests for the core logic.

## Build and Run

This project uses Swift Package Manager directly.

*   **Build:** `swift build`
*   **Run:** `swift run NowCoinerApp` (or `make run`)
*   **Test:** `swift test`
*   **Test Specific Suite:** `swift test --filter PriceFormatter`

## Architecture & Conventions

### MVVM Pattern
*   **ViewModel:** `TickerViewModel` (`NowCoinerCore`) is the central source of truth, managing `watchlist`, `prices`, `settings`, and runtime tasks. It is `@MainActor`.
*   **Views:** SwiftUI views (`NowCoinerApp`) observe the ViewModel.
*   **Services:** Logic is decoupled via protocols (`CoinGeckoServicing`, `BinanceServicing`, `WebSocketManaging`) to allow dependency injection and mocking.

### Data Flow
1.  **Real-time:** Binance WebSocket stream updates prices in `TickerViewModel`.
2.  **Polling:** CoinGecko API is polled periodically (60s for prices, 5m for sparklines) to fill in data missing from the WebSocket stream.
3.  **Storage:** Data is persisted to JSON files in `~/Library/Application Support/NowCoiner/` using `JSONFileStore<T>`.

### Key Coding Conventions
*   **Concurrency:** Strict Swift 6 concurrency. Use `Sendable` for models/services and `@MainActor` for ViewModels.
*   **Models:** All models are `Codable`, `Equatable`, and `Sendable`.
*   **Symbols:**
    *   **Binance:** Uppercase (e.g., `BTCUSDT`).
    *   **WebSocket:** Lowercase (e.g., `btcusdt`).
    *   **CoinGecko:** Slugs (e.g., `bitcoin`).
    *   Mapping logic handles these differences (see `Coin.binanceSymbol`).
*   **UI:** The app uses `MenuBarExtra` but also custom `NSPanel` implementations (`AnchoredPanelController`, `FloatingPanelController`) for more control over window behavior than standard SwiftUI menu bar apps.

## Environment Variables
*   `COINGECKO_API_KEY`: Optional. If set, it's sent as the `x-cg-demo-api-key` header in CoinGecko requests.
