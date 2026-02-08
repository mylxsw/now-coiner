# Architecture

## 1. View Layer (`TickerPadApp`)

- `TickerPadApp.swift`
  - 菜单栏入口与生命周期。
  - 启动加载、设置同步、全局快捷键注册。
- `MainPanelView.swift`
  - watchlist 列表、上下文菜单、详情入口、键盘导航。
- `SearchPanelView.swift`
  - 本地币种检索与添加。
- `SettingsView.swift`
  - 用户配置读写。
- `CoinDetailView.swift`
  - 详情展示与图表。

## 2. ViewModel Layer (`TickerPadCore/ViewModels`)

- `TickerViewModel`
  - 聚合应用状态（coins/watchlist/prices/sparklines/settings）。
  - 编排运行时任务：WebSocket、轮询、缓存。
  - 提供 UI 操作命令：add/remove/move/pin/settings/detail/keyboard-selection。
- `SearchViewModel`
  - 300ms 防抖 + 过滤。

## 3. Service Layer (`TickerPadCore/Services`)

- `CoinGeckoService`
  - `coins/list`
  - `coins/markets`
  - `simple/price`
  - `coins/{id}`
- `BinanceService`
  - `ticker/price`
- `BinanceWebSocketManager`
  - `miniTicker` 流接收
  - ping 保活
  - 断线指数退避重连
- `WebSocketMessageParser`
  - 统一解析合并流/直连流 payload。

## 4. Storage Layer (`TickerPadCore/Storage`)

- `AppStoragePaths`
  - 管理 Application Support 路径。
- `JSONFileStore<T>`
  - 通用 JSON 读写。
- `SettingsStore / WatchlistStore / CoinCacheStore`
  - 领域仓储。
  - 详情缓存使用 `DetailCacheEntry`，TTL 10 分钟。

## 5. Key Design Decisions

- 协议解耦：`CoinGeckoServicing` / `BinanceServicing` / `WebSocketManaging` 便于替换与测试。
- 状态单向流动：网络/存储 -> ViewModel -> SwiftUI 视图。
- 运行时任务统一收敛到 ViewModel，避免视图层重复轮询。
- 易测逻辑下沉到 `TickerPadCore`（格式化、过滤、URL 构建、退避、解析器）。
