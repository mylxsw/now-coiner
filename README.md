# TickerPad

TickerPad 是一个基于 macOS 菜单栏的加密货币价格追踪应用实现，按 `REQUIREMENTS.md` 的 MVVM 架构落地：

- `TickerPadCore`：领域模型、服务层、存储层、ViewModel、纯逻辑工具。
- `TickerPadApp`：SwiftUI 菜单栏 UI（主面板、搜索面板、设置面板、右键菜单）。

## 目录结构

```text
Sources/
  TickerPadCore/
    Models/
    Services/
    Storage/
    Utils/
    ViewModels/
  TickerPadApp/
    Support/
    Views/
Tests/
  TickerPadCoreTests/
```

## 已实现功能

- 菜单栏多币种 ticker 文本展示（样式可配置）。
- 主面板币种列表与选中态。
- 右键上下文操作：Pin/Unpin、Move to top、TradingView 跳转、Remove。
- 搜索面板 + 300ms 防抖本地过滤 + 添加币种。
- 设置页：计价货币、菜单栏样式、涨跌颜色、刷新间隔、默认交易所。
- CoinGecko REST：`coins/list`、`coins/markets`、`simple/price`、`coins/{id}`。
- Binance REST：`ticker/price`。
- 本地持久化：`settings/watchlist/cache(coins/prices/sparklines)`。
- 默认 watchlist 种子数据（BTC/ETH/BNB/SOL/UNI/ATOM/ALGO）。

## 测试覆盖

`Tests/TickerPadCoreTests` 包含：

- `PriceFormatterTests`
- `ExchangeURLBuilderTests`
- `SearchFilterTests`
- `ExponentialBackoffTests`
- `JSONFileStoreTests`
- `TickerViewModelTests`

## 运行与测试

```bash
swift test
swift run TickerPadApp
```

## 环境变量

- `COINGECKO_API_KEY`：可选。若设置，会自动作为 `x-cg-demo-api-key` 请求头发送。

## 后续建议（对齐 PRD 进阶阶段）

- 接入 Binance WebSocket 实时流与断线重连（目前为 REST + 定时刷新）。
- 增加 Sparkline 图表（Swift Charts）与详情页 UI。
- 增加全局快捷键与开机自启。
- 增加浅色模式细节和更完整的可访问性支持。
