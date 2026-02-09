# NowCoiner

NowCoiner 是一个基于 macOS 菜单栏的加密货币价格追踪应用实现，按 `REQUIREMENTS.md` 的 MVVM 架构落地。

## 模块结构

```text
Sources/
  NowCoinerCore/
    Models/      # 领域模型
    Services/    # CoinGecko / Binance / WebSocket
    Storage/     # JSON 持久化仓储
    Utils/       # 格式化、搜索、URL、退避
    ViewModels/  # 核心状态与业务编排
  NowCoinerApp/
    Support/     # 应用容器、快捷键、浮动面板、开机自启
    Views/       # 主面板、搜索、设置、详情、行视图
Tests/
  NowCoinerCoreTests/
```

## 已实现功能

- 菜单栏多币种 ticker 文本展示（样式可配置）。
- 主面板币种列表、选中态、拖拽排序、Pin/Unpin、删除、置顶。
- 主面板键盘导航：`↑/↓` 选择、`Return` 打开详情、`Delete` 删除选中项。
- 搜索面板：300ms 防抖、本地过滤、添加币种。
- 币种详情页：基础信息、7 天图表、市场数据、外链、开发者数据。
- 币种详情 10 分钟 TTL 缓存（内存 + 本地落盘）。
- 行内 Sparkline（Swift Charts）。
- 右键菜单：Pin、About、Move to top、TradingView、Exchange、Remove。
- 实时更新链路：
  - Binance WebSocket `miniTicker`（支持断线重连 + 指数退避 + ping）。
  - CoinGecko `simple/price` 周期性刷新补充字段。
  - CoinGecko `coins/markets` 每 5 分钟刷新 Sparkline。
- 设置项：
  - 开机自启
  - 全局快捷键
  - 计价货币
  - 菜单栏样式
  - 外观模式（浅色/深色/系统）
  - 涨跌配色
  - 刷新间隔
  - 默认数据源
  - 默认交易所
- 全局快捷键唤起/隐藏浮动主面板。
- 本地持久化：`settings/watchlist/cache(coins/prices/sparklines/details)`。

## 测试覆盖

`NowCoinerCoreTests` 包含 13 个测试：

- `PriceFormatterTests`
- `ExchangeURLBuilderTests`
- `SearchFilterTests`
- `ExponentialBackoffTests`
- `JSONFileStoreTests`
- `TickerViewModelTests`
- `TickerRealtimeTests`
- `WebSocketMessageParserTests`
- `TickerDetailCacheTests`

## 运行与测试

```bash
swift test
swift run NowCoinerApp
```

## 环境变量

- `COINGECKO_API_KEY`（可选）：设置后自动作为 `x-cg-demo-api-key` 请求头发送。

## 数据目录

运行后会写入：

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
