# NowCoiner

NowCoiner 是一个 macOS 菜单栏加密货币价格追踪应用，基于 SwiftUI 和 AppKit 构建。它以 `LSUIElement` 方式运行，通过 Binance WebSocket 实时接收价格更新，并结合 CoinGecko 轮询补充市场数据。

English README: [README.md](README.md)

## 功能亮点

- 支持可配置样式的菜单栏实时 ticker
- 支持拖拽排序、置顶、移除和 Pin 的自选列表管理
- 主面板支持 `↑` / `↓`、`Return`、`Delete` 键盘操作
- 搜索面板支持 300 ms 防抖和本地过滤
- 币种详情页包含市场数据、外部链接、开发者信息和 7 天图表
- 使用 Swift Charts 渲染行内 sparkline
- 支持通过全局快捷键呼出浮动面板
- 支持设置、自选列表、价格、sparkline 和详情缓存的本地持久化

## 项目结构

```text
Sources/
  NowCoinerCore/
    Models/      # 领域模型
    Services/    # CoinGecko / Binance / WebSocket 集成
    Storage/     # 基于 JSON 的持久化
    Utils/       # 格式化、搜索、URL、退避、解析
    ViewModels/  # 核心状态与运行时编排
  NowCoinerApp/
    Support/     # 应用容器、快捷键、浮动面板、开机自启
    Views/       # 主面板、搜索、设置、详情、行视图
Tests/
  NowCoinerCoreTests/
```

## 架构说明

项目由两个 Swift Package target 组成：

- `NowCoinerCore`：模型、服务、存储、工具类和 ViewModel
- `NowCoinerApp`：菜单栏应用所需的 SwiftUI 视图和 AppKit 集成

`TickerViewModel` 是整个应用的核心协调者，统一管理应用状态、WebSocket 与轮询任务，并向 UI 暴露用户操作入口。

## 数据流

- Binance WebSocket `miniTicker` 提供亚秒级价格更新
- CoinGecko `simple/price` 轮询补充 24 小时涨跌幅等字段
- CoinGecko `coins/markets` 每 5 分钟刷新一次 sparkline 数据
- 币种详情会同时缓存到内存和磁盘，TTL 为 10 分钟

## 构建与运行

```bash
swift build
swift run NowCoinerApp
```

## 测试

```bash
swift test
```

`NowCoinerCoreTests` 覆盖了价格格式化、URL 构建、搜索过滤、指数退避、JSON 存储、WebSocket 解析、详情缓存以及核心 ViewModel 流程。

## 环境变量

- `COINGECKO_API_KEY`（可选）：会作为 `x-cg-demo-api-key` 请求头发送到 CoinGecko

## 本地数据目录

NowCoiner 会将应用数据写入：

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

## 许可证

本项目采用 GNU Affero General Public License v3.0 or later（AGPL-3.0-or-later）许可证。你可以自由使用、编译、修改和再发布 NowCoiner，也可以基于它开发衍生产品；但只要你分发了修改版本，就必须继续以相同许可证公开源代码。

完整条款见 [LICENSE](LICENSE)。
