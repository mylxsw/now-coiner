# Architecture

## Layers

1. Views (`TickerPadApp`)
- `TickerPadApp.swift`: MenuBarExtra 入口。
- `MainPanelView.swift`: 币种列表主面板。
- `SearchPanelView.swift`: 本地缓存币种搜索与添加。
- `SettingsView.swift`: 设置项编辑。

2. ViewModels (`TickerPadCore/ViewModels`)
- `TickerViewModel`: 统一协调网络数据、watchlist、缓存与用户操作。
- `SearchViewModel`: 搜索输入防抖与结果过滤。

3. Services (`TickerPadCore/Services`)
- `CoinGeckoService` / `BinanceService`: API 访问实现。
- `HTTPClient` 协议抽象，便于测试替换。

4. Storage (`TickerPadCore/Storage`)
- `AppStoragePaths`: 应用数据路径约定。
- `JSONFileStore`: 泛型 JSON 存储。
- `SettingsStore` / `WatchlistStore` / `CoinCacheStore`: 业务仓储。

5. Domain + Utils
- `Models/*`: PRD 对应实体。
- `PriceFormatter` / `SearchFilter` / `ExchangeURLBuilder` / `ExponentialBackoff`。

## Design Principles

- 协议优先：服务层通过协议解耦，ViewModel 不依赖具体网络实现。
- 可测试：核心逻辑集中在 `TickerPadCore`，UI 层只做展示和事件转发。
- 持久化边界清晰：`Store` 负责 I/O，ViewModel 仅组合调用。
- 低耦合模块：格式化、URL 拼装、搜索过滤都独立成纯函数模块。
