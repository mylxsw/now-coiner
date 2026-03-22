# [CLAUDE.md](http://CLAUDE.md)

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**NowCoiner** — a macOS menu bar cryptocurrency price tracker. It's an LSUIElement app (no Dock icon, no main window) built with SwiftUI + AppKit. Prices update in real-time via Binance WebSocket, supplemented by CoinGecko REST polling.

## Build & Run Commands

```bash
swift build                          # Build all targets
swift run NowCoinerApp               # Run the app
swift test                           # Run all tests
swift test --filter PriceFormatter   # Run a single test suite
```

Swift tools version: 6.2, minimum deployment target: macOS 14.0 (Sonoma).

## Environment Variables

- `COINGECKO_API_KEY` (optional) — sent as `x-cg-demo-api-key` header on CoinGecko requests.

## Architecture

Two-target Swift Package (no Xcode project file):

- **NowCoinerCore** (library) — models, services, storage, utils, view models. All testable logic lives here.
- **NowCoinerApp** (executable) — SwiftUI views, AppKit integration (menu bar, floating panels, global shortcuts).

### MVVM + Protocol-Driven Services

```
Views (NowCoinerApp)
  └─ TickerViewModel (NowCoinerCore) — single @MainActor ObservableObject, owns all app state
       ├─ CoinGeckoServicing (protocol) → CoinGeckoService
       ├─ BinanceServicing (protocol) → BinanceService
       ├─ WebSocketManaging (protocol) → BinanceWebSocketManager
       └─ Storage: SettingsStore / WatchlistStore / CoinCacheStore
```

- **TickerViewModel** is the central orchestrator: watchlist, prices, sparklines, settings, runtime tasks (WebSocket, polling timers). All UI operations route through it.
- **AppContainer** (`NowCoinerApp/Support/AppContainer.swift`) wires dependencies via `makeDefault()`.
- Service protocols (`CoinGeckoServicing`, `BinanceServicing`, `WebSocketManaging`) enable mock injection in tests.

### Real-time Data Flow

1. **Binance WebSocket** `miniTicker` stream → `TickerViewModel.applyWebSocketTick()` (sub-second updates)
2. **CoinGecko** `simple/price` polling every 60s → supplements 24h change, market cap
3. **CoinGecko** `coins/markets` every 5 min → refreshes sparkline data
4. WebSocket reconnects with exponential backoff (`ExponentialBackoff` util)

### Storage

JSON files under `~/Library/Application Support/NowCoiner/`. The `JSONFileStore<T>` generic handles serialization. Domain repositories: `SettingsStore`, `WatchlistStore`, `CoinCacheStore`. Detail cache uses 10-minute TTL via `DetailCacheEntry`.

### UI Panels

- **MenuBarExtra** (`.window` style) — main coin list
- **AnchoredPanelController** — search and settings panels anchored to menu bar position
- **FloatingPanelController** — global shortcut-triggered floating panel
- **MenuAnchorResolver** — resolves menu bar anchor point for panel placement

## Testing Patterns

Tests are in `NowCoinerCoreTests`. Each test creates mock services implementing the service protocols and temporary file-backed stores. Example mocks: `MockCoinGeckoService`, `MockBinanceService`, `StubWebSocketManager`. ViewModel tests use `@MainActor` and are async.

## Key Conventions

- Swift 6 strict concurrency: `Sendable` conformance on models/services, `@MainActor` on ViewModel.
- All models are `Codable` + `Equatable` + `Sendable`.
- Binance uses uppercase symbols (`BTCUSDT`), WebSocket uses lowercase (`btcusdt`). CoinGecko uses slug IDs (`bitcoin`). Mapping happens via `Coin.binanceSymbol`.
- Price formatting centralized in `PriceFormatter`; exchange URL building in `ExchangeURLBuilder`.