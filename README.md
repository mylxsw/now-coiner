# NowCoiner

NowCoiner is a macOS menu bar app for tracking cryptocurrency prices in real time. It is built with SwiftUI and AppKit, runs as an `LSUIElement` app, and keeps market data current through Binance WebSocket streams and CoinGecko polling.

中文文档: [README.zh-CN.md](README.zh-CN.md)

## Highlights

- Real-time menu bar ticker with configurable display styles
- Watchlist management with drag-and-drop sorting, pinning, removal, and move-to-top actions
- Keyboard navigation in the main panel with `↑` / `↓`, `Return`, and `Delete`
- Search panel with 300 ms debounce and local filtering
- Coin detail view with market data, links, developer information, and a 7-day chart
- Inline sparklines powered by Swift Charts
- Floating panel support with a global shortcut
- Persistent local storage for settings, watchlist data, prices, sparklines, and detail cache

## Project Structure

```text
Sources/
  NowCoinerCore/
    Models/      # Domain models
    Services/    # CoinGecko / Binance / WebSocket integrations
    Storage/     # JSON-backed persistence
    Utils/       # Formatting, search, URLs, backoff, parsing
    ViewModels/  # Core state and runtime orchestration
  NowCoinerApp/
    Support/     # App container, shortcuts, floating panels, launch-at-login
    Views/       # Main panel, search, settings, details, row views
Tests/
  NowCoinerCoreTests/
```

## Architecture

The project is split into two Swift Package targets:

- `NowCoinerCore`: models, services, storage, utilities, and view models
- `NowCoinerApp`: SwiftUI views and AppKit integration for the menu bar experience

`TickerViewModel` is the central coordinator. It owns app state, manages runtime tasks such as WebSocket connections and polling, and exposes user-facing actions to the UI.

## Data Flow

- Binance WebSocket `miniTicker` provides sub-second price updates
- CoinGecko `simple/price` polling fills in supplemental fields such as 24-hour change and market data
- CoinGecko `coins/markets` refreshes sparkline data every five minutes
- Coin details are cached for 10 minutes in memory and on disk

## Build and Run

```bash
swift build
swift run NowCoinerApp
```

Swift tools version: 6.2  
Minimum deployment target: macOS 14.0

## Testing

```bash
swift test
```

The `NowCoinerCoreTests` target covers formatting, URL building, search filtering, backoff behavior, JSON storage, WebSocket parsing, detail caching, and the main view model flows.

## Environment Variable

- `COINGECKO_API_KEY` (optional): sent as the `x-cg-demo-api-key` header on CoinGecko requests

## Local Data Directory

NowCoiner stores application data under:

```text
~/Library/Application Support/NowCoiner/
  settings.json
  watchlist.json
  cache/
    coins_list.json
    prices.json
    sparklines.json
    details.json
```

## License

This project is licensed under the GNU Affero General Public License v3.0 or later. That means people can use, modify, compile, and redistribute NowCoiner, including in derivative products, but any distributed modified version must also remain open source under the same license terms.

See [LICENSE](LICENSE) for the full text.
