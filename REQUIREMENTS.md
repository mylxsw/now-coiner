# NowCoiner 产品需求文档 (PRD)

> macOS 菜单栏加密货币实时价格追踪应用

---

## 目录

1. [产品概述](#1-产品概述)
2. [技术栈与架构](#2-技术栈与架构)
3. [界面与交互设计](#3-界面与交互设计)
4. [功能模块详细描述](#4-功能模块详细描述)
5. [数据源 API 详细说明](#5-数据源-api-详细说明)
6. [数据模型定义](#6-数据模型定义)
7. [本地持久化方案](#7-本地持久化方案)
8. [非功能性需求](#8-非功能性需求)
9. [设计规范](#9-设计规范)
10. [功能优先级与开发阶段](#10-功能优先级与开发阶段)

---

## 1. 产品概述

### 1.1 产品名称

**NowCoiner**

### 1.2 产品定位

一款生活在 macOS 菜单栏中的加密货币实时价格追踪工具。用户无需打开浏览器或切换应用，即可在菜单栏和弹出面板中实时查看加密货币的价格、涨跌幅、迷你趋势图等关键信息。

### 1.3 核心价值

- **实时性**：通过 Binance WebSocket 实现秒级价格更新，菜单栏价格始终保持最新
- **无干扰**：常驻菜单栏，不占用 Dock 和任务切换空间，不打断用户工作流
- **全面性**：基于 CoinGecko 数据支持 9,000+ 加密货币，覆盖主流及长尾币种
- **原生体验**：使用 Swift 原生开发，完美适配 macOS 深色/浅色模式，性能优异

### 1.4 目标用户

- 加密货币投资者和交易者
- 需要在工作中随时关注币价的专业人士
- 对加密货币感兴趣的普通 macOS 用户

---

## 2. 技术栈与架构

### 2.1 技术栈

| 项目 | 选型 |
|------|------|
| 开发语言 | Swift 5.9+ |
| UI 框架 | SwiftUI（弹出面板、搜索、设置等）+ AppKit（NSStatusItem 菜单栏） |
| 最低系统版本 | macOS 14.0 (Sonoma) |
| 网络层 | URLSession（REST API）+ URLSessionWebSocketTask（Binance WebSocket） |
| 数据持久化 | UserDefaults（用户偏好）+ SwiftData 或文件存储（币种列表、缓存） |
| 图表绘制 | Swift Charts（7 天 Sparkline 迷你图） |
| 并发模型 | Swift Concurrency（async/await、Actor） |
| 包管理 | Swift Package Manager |

### 2.2 应用架构

采用 **MVVM** 架构模式：

```
┌─────────────────────────────────────────────┐
│                   Views                      │
│  MenuBarView / MainPanelView / SearchView   │
│  ContextMenu / SettingsView / DetailView    │
├─────────────────────────────────────────────┤
│               ViewModels                     │
│  TickerViewModel / SearchViewModel          │
│  CoinDetailViewModel / SettingsViewModel    │
├─────────────────────────────────────────────┤
│                Services                      │
│  CoinGeckoService / BinanceService          │
│  WebSocketManager / PriceAggregator         │
├─────────────────────────────────────────────┤
│              Data Layer                      │
│  Models / LocalStorage / CacheManager       │
└─────────────────────────────────────────────┘
```

### 2.3 应用类型

- **LSUIElement 应用**（无 Dock 图标、无主窗口）
- 使用 `NSStatusItem` 在菜单栏显示价格信息
- 点击菜单栏图标弹出 `NSPopover` 或 `NSPanel` 显示主面板

---

## 3. 界面与交互设计

> 设计稿文件：`crypto-menubar.pen`，包含 5 个界面。

### 3.1 菜单栏 Ticker 显示

**设计稿节点**：`MacOS Menu Bar` (ID: `CznBv`)

**布局描述**：
- 位于 macOS 系统菜单栏右侧区域（系统托盘图标左侧）
- 高度：24px（与系统菜单栏一致）
- 背景：半透明深色 `#1C1C1ECC`

**显示内容**：
- 以「符号 + 价格」格式显示用户选中的币种，例如 `BTC $16,903.83`
- 多个币种之间以 `|` 分隔，例如 `BTC $16,903.83 | ETH $1,223.83`
- 字体：Inter, 12px, Regular（与系统菜单栏匹配）
- 文字颜色：白色 `#FFFFFF`
- 分隔符颜色：灰色 `#8E8E93`

**交互行为**：
- **左键点击**：打开/关闭主面板（Popover）
- **右键点击**：打开应用级菜单（退出、设置等）
- 价格实时更新，平滑过渡（无闪烁）

**可配置项**：
- 菜单栏显示样式可选：仅价格 / 符号+价格 / 符号+涨跌幅 / 符号+价格+涨跌幅
- 可选择在菜单栏中显示哪些币种（通过「Pin」功能）
- 最多显示 3-5 个币种（根据菜单栏可用空间自适应）

### 3.2 主面板（币种列表）

**设计稿节点**：`NowCoiner - Main Panel` (ID: `MjDfi`)

**尺寸与布局**：
- 宽度：320px
- 高度：自适应（根据币种数量），最大高度受屏幕限制，超出时可滚动
- 圆角：12px
- 背景色：`#1C1C1E`（深色模式）
- 从菜单栏图标正下方弹出

**头部 (Header)**：
- 左侧：应用名称 "NowCoiner"，Inter 14px SemiBold，白色
- 右侧：两个操作按钮
  - `+` 按钮（Lucide `plus` 图标，18×18px，`#8E8E93`）：打开搜索面板添加币种
  - 设置按钮（Lucide `settings` 图标，18×18px，`#8E8E93`）：打开设置页面
- 内边距：垂直 12px，水平 16px
- 底部分割线：`#2C2C2E`，1px

**币种列表区域 (Crypto List)**：
- 垂直排列，列表区域上下内边距 8px
- 支持滚动

**单个币种行 (Coin Row)**：
- 高度：约 52px（内边距 10px 垂直 + 内容）
- 水平内边距：16px
- 三列布局，间距 12px：

| 列 | 内容 | 样式 |
|----|------|------|
| 左列 - 币种图标 | 圆形图标，32×32px，圆角 16px | 背景色使用币种品牌色，居中显示币种符号文字 |
| 中列 - 币种信息 | 第一行：币种代号（如 "BTC"），Inter 14px SemiBold 白色 | 第二行：币种全名（如 "Bitcoin"），Inter 11px Regular `#8E8E93` |
| 右列 - 价格信息 | 第一行：当前价格（如 "$16,903.83"），Inter 14px SemiBold 白色，右对齐 | 第二行：涨跌幅（如 "▲ 1.68%"），Inter 11px Medium，上涨绿色 `#34C759` / 下跌红色（推断为 `#FF453A`），带三角箭头图标 |

**设计稿中展示的默认币种**（7 个）：

| 币种 | 图标背景色 | 图标文字 |
|------|-----------|---------|
| BTC (Bitcoin) | `#F7931A` | ₿ |
| ETH (Ethereum) | `#627EEA` | Ξ |
| BNB | `#F3BA2F` | B |
| SOL (Solana) | 渐变 `#9945FF → #14F195`（45°线性） | S |
| UNI (Uniswap) | `#FF007A` | U |
| ATOM (Cosmos Hub) | `#2E3148` | A |
| ALGO (Algorand) | `#000000` | A |

**交互行为**：
- **左键点击**币种行：选中该币种，高亮显示（见 3.5 选中状态）
- **右键点击**币种行：弹出上下文菜单（见 3.4）
- **拖拽排序**：支持长按拖拽调整币种顺序
- 列表可上下滚动

### 3.3 搜索面板

**设计稿节点**：`NowCoiner - Search Panel` (ID: `Y2daw`)

**尺寸与布局**：
- 宽度：280px
- 圆角：12px
- 背景色：`#1C1C1E`

**搜索栏 (Search Header)**：
- 背景色：`#2C2C2E`
- 内边距：垂直 10px，水平 12px
- 左侧：搜索图标（Lucide `search`，16×16px，`#8E8E93`）
- 右侧：文本输入框，Inter 14px Regular 白色
- 间距：8px
- 支持输入币种名称或代号进行模糊搜索

**搜索结果列表 (Search Results)**：
- 垂直排列，上下内边距 8px

**单条搜索结果行**：
- 内边距：垂直 10px，水平 12px
- 三列布局，间距 12px：

| 列 | 内容 | 样式 |
|----|------|------|
| 左列 - 图标 | 圆形，32×32px，币种品牌色背景 | 同主面板图标样式 |
| 中列 - 信息 | 第一行：币种全名（如 "Bitcoin"），Inter 14px Medium 白色 | 第二行：币种代号（如 "BTC"），Inter 11px Regular `#8E8E93` |
| 右列 - 添加按钮 | "Add" 文字，Inter 12px Medium 白色 | 背景色 `#007AFF`（系统蓝），圆角 6px，内边距 6px/12px |

**交互行为**：
- 输入时实时过滤搜索结果（防抖 300ms）
- 点击 "Add" 按钮将币种添加到主列表
- 已添加的币种显示为「已添加」状态（按钮变灰或变为对勾）
- 点击搜索面板外部或按 Esc 关闭搜索
- 搜索数据来源：CoinGecko `/coins/list` API，本地缓存全量币种列表

### 3.4 右键上下文菜单

**设计稿节点**：`NowCoiner - Context Menu` (ID: `SCGKb`)

**尺寸与布局**：
- 宽度：180px
- 圆角：8px
- 背景色：`#2C2C2E`
- 内边距：垂直 6px

**菜单项列表**：

| 顺序 | 图标 | 文字 | 颜色 | 功能 |
|------|------|------|------|------|
| 1 | `pin` (Lucide) | Pin | 白色 | 将该币种固定到菜单栏 Ticker 显示 |
| 2 | `info` (Lucide) | About {CoinName} | 白色 | 打开币种详情页 |
| — | 分割线 | — | `#3C3C3E` | — |
| 3 | `arrow-up` (Lucide) | Move to top | 白色 | 将该币种移动到列表顶部 |
| 4 | `external-link` (Lucide) | View on TradingView | 白色 | 在浏览器中打开 TradingView 对应图表 |
| — | 分割线 | — | `#3C3C3E` | — |
| 5 | `trash-2` (Lucide) | Remove from List | 红色 `#FF453A` | 从列表中删除该币种 |

**单个菜单项样式**：
- 内边距：垂直 8px，水平 12px
- 图标：14×14px
- 文字：Inter 13px Regular
- 图标与文字间距：10px
- 全宽可点击区域

**分割线**：
- 颜色：`#3C3C3E`
- 高度：1px
- 全宽

### 3.5 选中状态

**设计稿节点**：`NowCoiner - With Selection` (ID: `ycICH`)

**选中行样式**（以 BNB 为例）：
- 背景色：`#9333EA33`（紫色，约 20% 透明度）
- 边框：1px `#9333EA`（紫色）
- 圆角：8px
- 其余内容布局与未选中状态一致

**交互行为**：
- 点击某一行时该行变为选中状态
- 同一时刻只有一行处于选中状态
- 再次点击已选中行或点击其他区域可取消选中
- 选中状态可用于后续操作（如查看详情、快捷键操作等）

### 3.6 设置页面（从产品描述推导）

> 设计稿中未直接体现，基于产品描述和功能需求推导。

**设置项**：

| 分组 | 设置项 | 类型 | 默认值 | 说明 |
|------|--------|------|--------|------|
| 通用 | 开机自启动 | Toggle | 关 | 系统登录时自动启动应用 |
| 通用 | 全局快捷键 | 快捷键输入 | ⌘⇧C | 按下快捷键切换主面板显示/隐藏 |
| 通用 | 计价货币 | 下拉选择 | USD | 支持 USD, EUR, GBP, CNY, JPY 等 |
| 显示 | 菜单栏显示样式 | 单选 | 符号+价格 | 可选：仅价格 / 符号+价格 / 符号+涨跌幅 / 全部显示 |
| 显示 | 外观模式 | 单选 | 跟随系统 | 可选：浅色 / 深色 / 跟随系统 |
| 显示 | 涨跌颜色方案 | 单选 | 绿涨红跌 | 可选：绿涨红跌 / 红涨绿跌 |
| 数据 | 数据刷新间隔 | 下拉选择 | 实时（WebSocket） | 可选：实时 / 10秒 / 30秒 / 1分钟 / 5分钟 |
| 数据 | 默认数据源 | 单选 | CoinGecko | 可选：CoinGecko / Binance |
| 数据 | 默认交易所（外链） | 下拉选择 | Binance | 用于"一键跳转交易所"功能 |

### 3.7 币种详情页（从产品描述推导）

> 对应右键菜单 "About {CoinName}" 功能和产品描述中的 "Detailed coin info"。

**显示信息**：

| 区域 | 字段 | 数据来源 |
|------|------|---------|
| 基本信息 | 币种名称、代号、图标、当前价格、24h涨跌幅 | CoinGecko `/coins/markets` |
| 价格图表 | 7 天 Sparkline 迷你折线图 | CoinGecko sparkline 或 Binance Klines |
| 市场数据 | 市值 (Market Cap)、市值排名、24h交易量 | CoinGecko `/coins/{id}` |
| 供应量 | 流通供应量、总供应量、最大供应量 | CoinGecko `/coins/{id}` |
| 价格统计 | 24h最高/最低、历史最高(ATH)、历史最低(ATL) | CoinGecko `/coins/{id}` |
| 外部链接 | 官网、白皮书、区块链浏览器 | CoinGecko `/coins/{id}` → `links` |
| 社区链接 | GitHub、Twitter/X、Reddit、Telegram | CoinGecko `/coins/{id}` → `links` |
| 开发者数据 | GitHub Stars、Forks、近 4 周提交数 | CoinGecko `/coins/{id}` → `developer_data` |

**交互行为**：
- 点击外部链接在默认浏览器中打开
- 支持返回主列表
- 价格信息保持实时更新

### 3.8 7 天 Sparkline 迷你图

> 产品描述中提到 "7-day sparkline charts at a glance"。

**显示位置**：
- 主面板每个币种行内（嵌入到价格信息区域或作为行展开区域）
- 币种详情页（更大尺寸的完整图表）

**图表规格**：

| 属性 | 主面板迷你版 | 详情页完整版 |
|------|-------------|-------------|
| 尺寸 | 约 50×20px | 约 280×120px |
| 数据点 | ~168 个（7天×24小时） | ~168 个 |
| 线条颜色 | 上涨绿色 `#34C759` / 下跌红色 | 同左 |
| 填充 | 线条下方半透明渐变填充 | 同左 |
| 坐标轴 | 不显示 | 可选显示 |
| 交互 | 无 | 悬停显示具体价格和时间 |

---

## 4. 功能模块详细描述

### 4.1 菜单栏实时价格显示

**功能描述**：在 macOS 菜单栏中实时显示用户关注的加密货币价格。

**详细需求**：
- 使用 `NSStatusItem` 创建菜单栏项
- 通过 `NSAttributedString` 设置富文本显示（支持不同颜色区分币种和分隔符）
- 被 Pin 的币种显示在菜单栏中
- 价格更新时平滑过渡，避免文字闪烁或跳动
- 当菜单栏空间不足时，自动截断或减少显示的币种数量
- 菜单栏文字应适配系统深色/浅色模式

### 4.2 币种管理

**添加币种**：
- 通过主面板头部 `+` 按钮打开搜索面板
- 搜索支持按名称和代号模糊匹配
- 币种列表来自 CoinGecko，本地缓存并定期更新（每天一次）
- 点击 "Add" 添加到关注列表

**删除币种**：
- 右键菜单 → "Remove from List"
- 删除前无需确认（可通过重新搜索添加回来）

**排序**：
- 右键菜单 → "Move to top" 将币种移至列表顶部
- 支持拖拽排序调整任意位置
- 排序顺序持久化存储

**Pin 到菜单栏**：
- 右键菜单 → "Pin" 将币种固定到菜单栏显示
- 已 Pin 的币种在右键菜单中显示 "Unpin" 选项
- Pin 状态持久化存储

### 4.3 实时价格更新机制

**更新策略（混合方案）**：

```
┌──────────────────────────────────────────────────┐
│           价格更新流程                              │
│                                                    │
│  启动应用                                          │
│    ├─→ CoinGecko /coins/markets 获取初始市场数据    │
│    │     (含价格、涨跌幅、sparkline)                │
│    │                                               │
│    └─→ Binance WebSocket 建立连接                   │
│          订阅所有关注币种的 miniTicker 流             │
│          实时更新价格 (每秒)                         │
│                                                    │
│  定时任务 (每 60 秒)                                │
│    └─→ CoinGecko /simple/price 刷新涨跌幅等数据     │
│                                                    │
│  定时任务 (每 5 分钟)                               │
│    └─→ CoinGecko /coins/markets?sparkline=true      │
│          刷新 sparkline 图表数据                     │
│                                                    │
│  WebSocket 断线重连                                 │
│    └─→ 指数退避重试: 1s → 2s → 4s → ... → 60s max  │
│                                                    │
│  WebSocket 不可用时                                 │
│    └─→ 降级为 Binance REST 轮询 (每 10 秒)          │
└──────────────────────────────────────────────────┘
```

**Binance 符号映射**：
- CoinGecko 使用 coin ID（如 `bitcoin`）、Binance 使用交易对（如 `BTCUSDT`）
- 需要维护一个映射表，将 CoinGecko coin ID 映射为 Binance 交易对符号
- 对于 Binance 不支持的币种，仅使用 CoinGecko 数据（定时轮询）

### 4.4 全局快捷键

**功能描述**：用户可通过全局快捷键在任何应用中快速唤起/隐藏 NowCoiner 主面板。

**实现要求**：
- 默认快捷键：`⌘⇧C`（Command + Shift + C）
- 可在设置中自定义
- 使用系统级快捷键注册（`NSEvent.addGlobalMonitorForEvents` 或 `CGEvent`）
- 快捷键冲突时提示用户
- 按下快捷键切换主面板显示/隐藏（Toggle）

### 4.5 一键跳转 TradingView

**功能描述**：从右键菜单快速在浏览器中打开 TradingView 对应币种的图表页面。

**URL 格式**：
```
https://www.tradingview.com/chart/?symbol=BINANCE:{SYMBOL}USDT
```
例如：`https://www.tradingview.com/chart/?symbol=BINANCE:BTCUSDT`

**实现要求**：
- 使用 `NSWorkspace.shared.open(url)` 在默认浏览器中打开
- 交易所前缀可配置（默认 BINANCE，可选 COINBASE 等）

### 4.6 一键跳转交易所

**功能描述**：快速跳转到用户偏好的交易所查看/交易该币种。

**支持的交易所及 URL 格式**：

| 交易所 | URL 格式 |
|--------|---------|
| Binance | `https://www.binance.com/trade/{SYMBOL}_USDT` |
| Coinbase | `https://www.coinbase.com/price/{coin-id}` |
| OKX | `https://www.okx.com/trade-spot/{symbol}-usdt` |

### 4.7 深色 / 浅色模式支持

**深色模式**（设计稿默认）：
- 主背景：`#1C1C1E`
- 次级背景：`#2C2C2E`
- 主文字：`#FFFFFF`
- 次级文字：`#8E8E93`
- 分割线：`#2C2C2E` / `#3C3C3E`

**浅色模式**（需要设计但可推导）：
- 主背景：`#FFFFFF`
- 次级背景：`#F2F2F7`
- 主文字：`#000000`
- 次级文字：`#8E8E93`
- 分割线：`#E5E5EA`

**实现要求**：
- 使用 SwiftUI 的 `@Environment(\.colorScheme)` 监听系统主题变化
- 支持三种模式：浅色 / 深色 / 跟随系统
- 主题切换时所有 UI 元素平滑过渡

---

## 5. 数据源 API 详细说明

### 5.1 CoinGecko API

**基础信息**：

| 项目 | 值 |
|------|-----|
| Base URL | `https://api.coingecko.com/api/v3` |
| 认证方式 | Demo API Key（免费）— 通过 query 参数 `x_cg_demo_api_key` 或 Header `x-cg-demo-api-key` |
| 频率限制 | 30 次/分钟（可能在高负载时降至 10 次/分钟）|
| 月度限额 | 10,000 次 API 调用 |
| 超限响应 | HTTP 429 |

#### 5.1.1 获取币种列表

**用途**：获取全部支持的币种列表，用于搜索功能。

```
GET /api/v3/coins/list
```

**Query 参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `include_platform` | boolean | 否 | 是否包含平台合约地址，默认 `false` |

**响应示例**：
```json
[
  { "id": "bitcoin", "symbol": "btc", "name": "Bitcoin" },
  { "id": "ethereum", "symbol": "eth", "name": "Ethereum" },
  { "id": "solana", "symbol": "sol", "name": "Solana" }
]
```

**注意**：返回 15,000+ 条数据，应本地缓存并每天更新一次。

#### 5.1.2 获取市场数据（含 Sparkline）

**用途**：获取关注币种的价格、涨跌幅、市值、Sparkline 等批量数据。

```
GET /api/v3/coins/markets
```

**Query 参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `vs_currency` | string | **是** | 计价货币，如 `usd` |
| `ids` | string | 否 | 逗号分隔的 coin ID，如 `bitcoin,ethereum,solana` |
| `order` | string | 否 | 排序，默认 `market_cap_desc` |
| `per_page` | integer | 否 | 每页数量 1-250，默认 100 |
| `page` | integer | 否 | 页码，默认 1 |
| `sparkline` | boolean | 否 | 包含 7 天 sparkline，默认 `false` |
| `price_change_percentage` | string | 否 | 涨跌幅时段，如 `1h,24h,7d` |

**响应关键字段**：
```json
{
  "id": "bitcoin",
  "symbol": "btc",
  "name": "Bitcoin",
  "image": "https://assets.coingecko.com/coins/images/1/large/bitcoin.png",
  "current_price": 97150.00,
  "market_cap": 1923456789012,
  "market_cap_rank": 1,
  "total_volume": 31260929299,
  "high_24h": 98200.00,
  "low_24h": 95800.00,
  "price_change_percentage_24h": 1.30,
  "circulating_supply": 19800000,
  "total_supply": 21000000,
  "max_supply": 21000000,
  "ath": 108000.00,
  "atl": 67.81,
  "sparkline_in_7d": {
    "price": [92500.12, 92800.45, 93100.78, ...]
  }
}
```

**sparkline 数据**：约 168 个数据点（7天 × 24小时），每个为该小时的价格浮点数。

#### 5.1.3 获取简单价格（轻量级）

**用途**：高频轮询价格变化，消耗最低配额。

```
GET /api/v3/simple/price
```

**Query 参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `ids` | string | **是** | 逗号分隔的 coin ID |
| `vs_currencies` | string | **是** | 计价货币 |
| `include_market_cap` | boolean | 否 | 包含市值 |
| `include_24hr_vol` | boolean | 否 | 包含24h交易量 |
| `include_24hr_change` | boolean | 否 | 包含24h涨跌幅 |
| `include_last_updated_at` | boolean | 否 | 包含最后更新时间戳 |

**响应示例**：
```json
{
  "bitcoin": {
    "usd": 97150.00,
    "usd_market_cap": 1923456789012,
    "usd_24h_vol": 31260929299,
    "usd_24h_change": 1.30,
    "last_updated_at": 1705312800
  }
}
```

#### 5.1.4 获取币种详细信息

**用途**：币种详情页展示完整信息（市场数据、链接、开发者数据等）。

```
GET /api/v3/coins/{id}
```

**Path 参数**：`id` — 币种 ID（如 `bitcoin`）

**Query 参数**：

| 参数 | 类型 | 必填 | 建议值 | 说明 |
|------|------|------|--------|------|
| `localization` | string | 否 | `false` | 关闭多语言以减小响应体积 |
| `tickers` | boolean | 否 | `false` | 关闭交易所 ticker 数据 |
| `market_data` | boolean | 否 | `true` | 包含市场数据 |
| `community_data` | boolean | 否 | `true` | 包含社区数据 |
| `developer_data` | boolean | 否 | `true` | 包含开发者数据 |
| `sparkline` | boolean | 否 | `true` | 包含 sparkline |

**响应关键字段**：
```json
{
  "id": "bitcoin",
  "symbol": "btc",
  "name": "Bitcoin",
  "description": { "en": "Bitcoin is the first..." },
  "links": {
    "homepage": ["https://bitcoin.org"],
    "whitepaper": "https://bitcoin.org/bitcoin.pdf",
    "blockchain_site": ["https://mempool.space/"],
    "subreddit_url": "https://www.reddit.com/r/Bitcoin/",
    "repos_url": { "github": ["https://github.com/bitcoin/bitcoin"] },
    "twitter_screen_name": "bitcoin"
  },
  "image": {
    "thumb": "...",
    "small": "...",
    "large": "..."
  },
  "market_data": {
    "current_price": { "usd": 97150.00 },
    "market_cap": { "usd": 1923456789012 },
    "total_volume": { "usd": 31260929299 },
    "high_24h": { "usd": 98200.00 },
    "low_24h": { "usd": 95800.00 },
    "price_change_percentage_24h": 1.30,
    "price_change_percentage_7d": 5.20,
    "circulating_supply": 19800000,
    "total_supply": 21000000,
    "max_supply": 21000000,
    "sparkline_7d": { "price": [...] }
  },
  "community_data": {
    "twitter_followers": 6800000,
    "reddit_subscribers": 5200000
  },
  "developer_data": {
    "forks": 36000,
    "stars": 78000,
    "commit_count_4_weeks": 150
  }
}
```

### 5.2 Binance API

**基础信息**：

| 项目 | 值 |
|------|-----|
| REST Base URL | `https://api.binance.com` |
| WebSocket URL | `wss://stream.binance.com:9443` |
| 认证方式 | 公开端点，无需认证 |
| REST 频率限制 | 6,000 request weight / 分钟 / IP |
| WebSocket 限制 | 300 连接 / 5分钟 / IP，单连接最多 1,024 流 |
| 超限响应 | HTTP 429，严重超限 HTTP 418（临时封禁 2分钟~3天） |

**符号规则**：
- REST API：大写交易对，如 `BTCUSDT`
- WebSocket：小写交易对，如 `btcusdt`

#### 5.2.1 获取实时价格

```
GET /api/v3/ticker/price
```

**Weight**: 2（单符号）/ 4（全部符号）

**Query 参数**：

| 参数 | 类型 | 说明 |
|------|------|------|
| `symbol` | string | 单个交易对，如 `BTCUSDT` |
| `symbols` | string | JSON 数组，如 `["BTCUSDT","ETHUSDT"]` |

**响应示例**：
```json
[
  { "symbol": "BTCUSDT", "price": "97150.23000000" },
  { "symbol": "ETHUSDT", "price": "3250.45000000" }
]
```

#### 5.2.2 获取 24 小时统计

```
GET /api/v3/ticker/24hr
```

**Weight**: 2（单符号）/ 40（最多 100 符号）

**响应关键字段**：
```json
{
  "symbol": "BTCUSDT",
  "lastPrice": "97150.23000000",
  "priceChange": "1250.50000000",
  "priceChangePercent": "1.305",
  "highPrice": "98200.00000000",
  "lowPrice": "95100.00000000",
  "volume": "25000.50000000",
  "quoteVolume": "2421537825.00000000"
}
```

#### 5.2.3 获取 K 线数据（用于 Sparkline）

```
GET /api/v3/klines
```

**Weight**: 2

**Query 参数**：

| 参数 | 类型 | 必填 | 说明 |
|------|------|------|------|
| `symbol` | string | **是** | 交易对，如 `BTCUSDT` |
| `interval` | enum | **是** | K 线周期，建议 `1h` |
| `limit` | integer | 否 | 数据条数，7天 sparkline 使用 `168` |

**响应格式**（每条为数组）：
```json
[
  [
    1705017600000,        // 开盘时间 (ms)
    "95200.10000000",     // 开盘价
    "95450.00000000",     // 最高价
    "95100.50000000",     // 最低价
    "95380.00000000",     // 收盘价 ← 用于 sparkline
    "1250.50000000",      // 成交量
    1705021199999,        // 收盘时间 (ms)
    "119228975.00000000", // 成交额
    15230,                // 成交笔数
    "625.30000000",       // 主动买入成交量
    "59614500.00000000",  // 主动买入成交额
    "0"                   // 忽略
  ]
]
```

提取每条数据的第 5 个字段（索引 4，收盘价）用于绘制 sparkline。

#### 5.2.4 WebSocket 实时价格流

**用途**：主面板和菜单栏的秒级实时价格更新。

**连接方式（合并多流）**：
```
wss://stream.binance.com:9443/stream?streams=btcusdt@miniTicker/ethusdt@miniTicker/solusdt@miniTicker
```

**miniTicker 推送数据**：
```json
{
  "e": "24hrMiniTicker",
  "E": 1705312800123,
  "s": "BTCUSDT",
  "c": "97150.23000000",
  "o": "95899.73000000",
  "h": "98200.00000000",
  "l": "95100.00000000",
  "v": "25000.50000000",
  "q": "2421537825.00000000"
}
```

**关键字段说明**：

| 字段 | 说明 |
|------|------|
| `s` | 交易对符号 |
| `c` | 当前价格（收盘价） |
| `o` | 24h 开盘价 |
| `h` | 24h 最高价 |
| `l` | 24h 最低价 |
| `v` | 24h 基础资产成交量 |
| `q` | 24h 计价资产成交额 |

**动态订阅/取消订阅**：
```json
// 订阅
{ "method": "SUBSCRIBE", "params": ["btcusdt@miniTicker"], "id": 1 }

// 取消订阅
{ "method": "UNSUBSCRIBE", "params": ["solusdt@miniTicker"], "id": 2 }
```

**连接管理要点**：
- 最长连接时间 24 小时，需要定时重连
- 服务端每 20 秒发送 ping，需在 60 秒内回复 pong
- 断线后指数退避重连：1s → 2s → 4s → 8s → ... → 60s（上限）
- 入站消息频率限制：5 条/秒

### 5.3 推荐的混合使用策略

| 使用场景 | 推荐 API | 端点 | 频率 |
|---------|---------|------|------|
| 币种搜索列表 | CoinGecko | `GET /coins/list` | 每天缓存一次 |
| 初始加载市场数据 | CoinGecko | `GET /coins/markets?sparkline=true` | 启动时 |
| 实时价格推送 | Binance WebSocket | `miniTicker` 流 | 实时（每秒） |
| 涨跌幅等补充数据 | CoinGecko | `GET /simple/price` | 每 60 秒 |
| Sparkline 更新 | CoinGecko | `GET /coins/markets?sparkline=true` | 每 5 分钟 |
| 币种详情 | CoinGecko | `GET /coins/{id}` | 按需 |
| Binance 不支持的币种 | CoinGecko | `GET /simple/price` | 每 30 秒 |
| 24h 统计（备用） | Binance REST | `GET /ticker/24hr` | 按需 |
| K 线数据（备用 sparkline） | Binance REST | `GET /klines?interval=1h&limit=168` | 按需 |

---

## 6. 数据模型定义

### 6.1 币种基础信息模型

```swift
struct Coin: Identifiable, Codable {
    let id: String              // CoinGecko coin ID, e.g. "bitcoin"
    let symbol: String          // 代号, e.g. "btc"
    let name: String            // 全名, e.g. "Bitcoin"
    var imageURL: String?       // 图标 URL
    var binanceSymbol: String?  // Binance 交易对, e.g. "BTCUSDT"
}
```

### 6.2 价格数据模型

```swift
struct CoinPrice: Codable {
    let coinId: String
    var currentPrice: Double        // 当前价格
    var priceChange24h: Double      // 24h 价格变动
    var priceChangePercent24h: Double // 24h 涨跌幅百分比
    var high24h: Double?            // 24h 最高
    var low24h: Double?             // 24h 最低
    var marketCap: Double?          // 市值
    var marketCapRank: Int?         // 市值排名
    var totalVolume: Double?        // 24h 交易量
    var lastUpdated: Date           // 最后更新时间
}
```

### 6.3 Sparkline 数据模型

```swift
struct SparklineData: Codable {
    let coinId: String
    let prices: [Double]        // 7天×24小时 ≈ 168 个价格点
    let fetchedAt: Date         // 获取时间
}
```

### 6.4 币种详情模型

```swift
struct CoinDetail: Codable {
    let id: String
    let symbol: String
    let name: String
    let description: String
    let imageURL: String

    // 市场数据
    let currentPrice: Double
    let marketCap: Double
    let marketCapRank: Int
    let totalVolume: Double
    let high24h: Double
    let low24h: Double
    let priceChangePercentage24h: Double
    let priceChangePercentage7d: Double
    let priceChangePercentage30d: Double
    let circulatingSupply: Double
    let totalSupply: Double?
    let maxSupply: Double?
    let ath: Double
    let athDate: Date
    let atl: Double
    let atlDate: Date

    // 外部链接
    let homepage: String?
    let whitepaper: String?
    let blockchainSites: [String]
    let subredditURL: String?
    let twitterHandle: String?
    let githubRepos: [String]

    // 开发者数据
    let githubStars: Int?
    let githubForks: Int?
    let commitCount4Weeks: Int?

    // 社区数据
    let twitterFollowers: Int?
    let redditSubscribers: Int?
}
```

### 6.5 用户关注列表项模型

```swift
struct WatchlistItem: Identifiable, Codable {
    let id: UUID
    let coinId: String          // CoinGecko coin ID
    var sortOrder: Int           // 排序权重
    var isPinned: Bool           // 是否 Pin 到菜单栏
    let addedAt: Date           // 添加时间
}
```

### 6.6 用户设置模型

```swift
struct AppSettings: Codable {
    var launchAtLogin: Bool = false
    var globalShortcut: String = "⌘⇧C"
    var vsCurrency: String = "usd"
    var menuBarDisplayStyle: MenuBarStyle = .symbolAndPrice
    var appearanceMode: AppearanceMode = .system
    var priceColorScheme: PriceColorScheme = .greenUpRedDown
    var refreshInterval: RefreshInterval = .realtime
    var defaultDataSource: DataSource = .coinGecko
    var defaultExchange: Exchange = .binance
}

enum MenuBarStyle: String, Codable {
    case priceOnly           // "$16,903.83"
    case symbolAndPrice      // "BTC $16,903.83"
    case symbolAndChange     // "BTC ▲1.68%"
    case full                // "BTC $16,903.83 ▲1.68%"
}

enum AppearanceMode: String, Codable {
    case light, dark, system
}

enum PriceColorScheme: String, Codable {
    case greenUpRedDown      // 绿涨红跌（国际惯例）
    case redUpGreenDown      // 红涨绿跌（中国大陆惯例）
}

enum RefreshInterval: String, Codable {
    case realtime            // WebSocket
    case seconds10           // 10 秒
    case seconds30           // 30 秒
    case minute1             // 1 分钟
    case minutes5            // 5 分钟
}

enum DataSource: String, Codable {
    case coinGecko, binance
}

enum Exchange: String, Codable {
    case binance, coinbase, okx
}
```

---

## 7. 本地持久化方案

### 7.1 存储方案

| 数据类型 | 存储方式 | 说明 |
|---------|---------|------|
| 用户设置 (`AppSettings`) | `UserDefaults` | 小量键值对，读写频繁 |
| 关注列表 (`[WatchlistItem]`) | JSON 文件 / `UserDefaults` | 数组，需持久化排序和 Pin 状态 |
| 币种列表缓存 (`[Coin]`) | JSON 文件 | 约 15,000 条，每天更新 |
| 最近价格缓存 | 内存 + JSON 文件 | 应用退出时持久化，启动时恢复 |
| Sparkline 缓存 | JSON 文件 | 每 5 分钟更新，应用退出时持久化 |

### 7.2 存储路径

使用 `Application Support` 目录：
```
~/Library/Application Support/NowCoiner/
├── settings.json            // 或使用 UserDefaults
├── watchlist.json           // 关注列表
├── cache/
│   ├── coins_list.json      // 币种列表缓存
│   ├── prices.json          // 价格缓存
│   └── sparklines.json      // Sparkline 缓存
```

### 7.3 缓存策略

| 缓存项 | 过期时间 | 更新策略 |
|--------|---------|---------|
| 币种列表 | 24 小时 | 首次启动时加载，之后每天检查更新 |
| 价格数据 | 无过期（实时更新） | WebSocket 推送 + 定时轮询覆盖 |
| Sparkline | 5 分钟 | 定时重新获取 |
| 币种详情 | 10 分钟 | 打开详情页时获取，缓存复用 |
| 币种图标 | 7 天 | 使用 URL 缓存或本地下载 |

---

## 8. 非功能性需求

### 8.1 性能要求

| 指标 | 要求 |
|------|------|
| 菜单栏价格更新延迟 | < 2 秒（从交易所到显示） |
| 主面板弹出响应时间 | < 200ms |
| 搜索过滤响应时间 | < 100ms（本地过滤） |
| 内存占用 | 常驻 < 50MB |
| CPU 占用 | 空闲时 < 1%，更新时瞬时 < 5% |
| 冷启动时间 | < 3 秒显示缓存价格 |
| WebSocket 重连时间 | 断线后 < 5 秒内尝试首次重连 |

### 8.2 稳定性要求

- WebSocket 断线自动重连（指数退避）
- API 请求失败自动重试（最多 3 次）
- 网络不可用时显示缓存数据，并展示离线状态指示
- 应用不应崩溃，所有错误需要优雅处理

### 8.3 安全性要求

- CoinGecko API Key 不应硬编码在源码中，应使用 Keychain 或环境变量
- 所有网络请求使用 HTTPS
- 不收集或上传任何用户数据
- 本地存储数据无敏感信息

### 8.4 兼容性要求

- macOS 14.0 (Sonoma) 及以上
- 支持 Apple Silicon (M1/M2/M3/M4) 和 Intel Mac
- 支持多显示器环境（菜单栏始终在主屏幕）
- 支持系统深色/浅色模式切换

### 8.5 可访问性

- 支持 VoiceOver 辅助功能
- 关键元素添加 Accessibility Label
- 支持键盘导航（在面板内可用 ↑↓ 键选择币种）

---

## 9. 设计规范

### 9.1 颜色系统

**深色模式**：

| 用途 | 颜色值 | 说明 |
|------|--------|------|
| 主背景 | `#1C1C1E` | 面板主体背景 |
| 次级背景 | `#2C2C2E` | 搜索栏、上下文菜单背景 |
| 分割线 | `#2C2C2E` | Header 底部分割线 |
| 分割线（强调） | `#3C3C3E` | 上下文菜单分割线 |
| 主文字 | `#FFFFFF` | 标题、币种名、价格 |
| 次级文字 | `#8E8E93` | 副标题、全名、图标 |
| 上涨色 | `#34C759` | 涨幅百分比和箭头 |
| 下跌色 | `#FF453A` | 跌幅百分比和箭头（删除操作文字也用此色） |
| 系统蓝 | `#007AFF` | "Add" 按钮背景 |
| 选中高亮 | `#9333EA` (border) / `#9333EA33` (fill) | 选中行 |
| 菜单栏背景 | `#1C1C1ECC` | 半透明 |

**币种品牌色**：

| 币种 | 颜色 |
|------|------|
| BTC | `#F7931A` |
| ETH | `#627EEA` |
| BNB | `#F3BA2F` |
| SOL | 线性渐变 `#9945FF → #14F195`（45°） |
| UNI | `#FF007A` |
| ATOM | `#2E3148` |
| ALGO | `#000000` |

### 9.2 字体规范

| 用途 | 字体 | 字号 | 字重 |
|------|------|------|------|
| 面板标题 "NowCoiner" | Inter | 14px | SemiBold (600) |
| 币种代号 (BTC) | Inter | 14px | SemiBold (600) |
| 币种全名 (Bitcoin) | Inter | 11px | Regular (400) |
| 当前价格 ($16,903.83) | Inter | 14px | SemiBold (600) |
| 涨跌幅 (1.68%) | Inter | 11px | Medium (500) |
| 菜单栏 Ticker | Inter | 12px | Regular (400) |
| 搜索输入 | Inter | 14px | Regular (400) |
| 搜索结果名称 | Inter | 14px | Medium (500) |
| 搜索结果代号 | Inter | 11px | Regular (400) |
| "Add" 按钮 | Inter | 12px | Medium (500) |
| 右键菜单文字 | Inter | 13px | Regular (400) |
| 币种图标文字 | Inter | 14-16px | Bold/SemiBold |

> **注意**：Inter 字体需内嵌到应用中，或使用系统 `.systemFont` 作为 fallback。建议优先使用 macOS 系统字体 SF Pro（与 Inter 视觉效果接近），避免额外的字体资源打包。

### 9.3 尺寸与间距

| 元素 | 尺寸 |
|------|------|
| 主面板宽度 | 320px |
| 搜索面板宽度 | 280px |
| 上下文菜单宽度 | 180px |
| 面板圆角 | 12px |
| 上下文菜单圆角 | 8px |
| 选中行圆角 | 8px |
| "Add" 按钮圆角 | 6px |
| 币种图标尺寸 | 32×32px |
| 币种图标圆角 | 16px（圆形） |
| Header 内边距 | 12px (垂直) × 16px (水平) |
| 币种行内边距 | 10px (垂直) × 16px (水平) |
| 搜索结果行内边距 | 10px (垂直) × 12px (水平) |
| 菜单项内边距 | 8px (垂直) × 12px (水平) |
| 行内三列间距 | 12px |
| 名称/全名行间距 | 2px |
| Header 按钮间距 | 8px |
| 菜单项图标与文字间距 | 10px |
| 搜索栏图标与输入框间距 | 8px |

### 9.4 图标

使用 **Lucide** 图标库，以下为设计稿中使用的图标：

| 图标名 | 用途 | 尺寸 |
|--------|------|------|
| `plus` | 添加币种按钮 | 18×18px |
| `settings` | 设置按钮 | 18×18px |
| `search` | 搜索栏图标 | 16×16px |
| `triangle` | 涨跌箭头 | 10×10px |
| `pin` | Pin 到菜单栏 | 14×14px |
| `info` | 查看币种详情 | 14×14px |
| `arrow-up` | 移至顶部 | 14×14px |
| `external-link` | 外部链接（TradingView） | 14×14px |
| `trash-2` | 删除 | 14×14px |

---

## 10. 功能优先级与开发阶段

### Phase 1：核心 MVP

> 实现基本的菜单栏价格显示和主面板功能。

| 功能 | 优先级 | 说明 |
|------|--------|------|
| macOS 菜单栏 NSStatusItem 搭建 | P0 | 应用骨架 |
| 主面板 Popover UI（币种列表） | P0 | 核心界面 |
| CoinGecko API 集成（市场数据） | P0 | 价格数据来源 |
| 币种列表本地持久化 | P0 | 记住用户的关注列表 |
| 深色模式 UI | P0 | 设计稿默认主题 |
| 价格定时轮询更新 | P0 | 基础数据更新 |

### Phase 2：搜索与管理

> 完善币种搜索、添加/删除、排序功能。

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 搜索面板 UI 及搜索逻辑 | P0 | 添加新币种的唯一入口 |
| 右键上下文菜单 | P1 | Pin、删除、排序、外链 |
| 币种拖拽排序 | P1 | 自定义列表顺序 |
| Pin 到菜单栏 | P1 | 选择显示在菜单栏的币种 |
| 菜单栏多币种显示 | P1 | 菜单栏 Ticker 展示多个币种 |

### Phase 3：实时数据与图表

> 接入 WebSocket 实现秒级更新，添加 Sparkline 图表。

| 功能 | 优先级 | 说明 |
|------|--------|------|
| Binance WebSocket 实时价格 | P1 | 秒级价格更新 |
| WebSocket 断线重连机制 | P1 | 保证数据连续性 |
| 7 天 Sparkline 迷你图（列表内） | P1 | 价格趋势一目了然 |
| 选中状态高亮 UI | P2 | 交互细节 |

### Phase 4：详情与设置

> 添加币种详情页、设置页面和更多个性化选项。

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 币种详情页 | P2 | 完整的市场数据、链接、开发者信息 |
| 设置页面 | P2 | 显示样式、刷新频率、外观等 |
| 浅色模式支持 | P2 | 跟随系统 / 手动切换 |
| 涨跌颜色方案切换 | P2 | 绿涨红跌 / 红涨绿跌 |
| 菜单栏显示样式自定义 | P2 | 符号+价格、仅价格等 |

### Phase 5：高级功能

> 添加全局快捷键、开机自启等高级功能。

| 功能 | 优先级 | 说明 |
|------|--------|------|
| 全局快捷键 | P2 | 全局唤起/隐藏面板 |
| 开机自启动 | P2 | `SMAppService` / `ServiceManagement` |
| 一键跳转 TradingView | P2 | 右键菜单外部链接 |
| 一键跳转交易所 | P3 | 设置中配置默认交易所 |
| 计价货币切换 | P3 | 支持 USD/EUR/CNY 等 |
| Sparkline 详情图表（可交互） | P3 | 详情页完整图表 |
| 键盘导航与 VoiceOver | P3 | 可访问性 |

---

## 附录

### A. CoinGecko ID → Binance Symbol 映射示例

| CoinGecko ID | Symbol | Binance Trading Pair |
|--------------|--------|---------------------|
| bitcoin | BTC | BTCUSDT |
| ethereum | ETH | ETHUSDT |
| binancecoin | BNB | BNBUSDT |
| solana | SOL | SOLUSDT |
| uniswap | UNI | UNIUSDT |
| cosmos | ATOM | ATOMUSDT |
| algorand | ALGO | ALGOUSDT |
| dogecoin | DOGE | DOGEUSDT |
| cardano | ADA | ADAUSDT |
| ripple | XRP | XRPUSDT |

> 完整映射表需在运行时通过 Binance `GET /api/v3/exchangeInfo` 获取所有交易对，并与 CoinGecko symbol 自动匹配。

### B. TradingView URL 构建规则

```
基础格式: https://www.tradingview.com/chart/?symbol={EXCHANGE}:{SYMBOL}{QUOTE}
示例:     https://www.tradingview.com/chart/?symbol=BINANCE:BTCUSDT

支持的交易所前缀:
- BINANCE
- COINBASE
- BITSTAMP
- KRAKEN
```

### C. 参考资料

- [CoinGecko API 文档](https://docs.coingecko.com/v3.0.1/reference/endpoint-overview)
- [Binance Spot API 文档](https://developers.binance.com/docs/binance-spot-api-docs/rest-api)
- [Binance WebSocket 文档](https://developers.binance.com/docs/binance-spot-api-docs/web-socket-streams)
- [Apple NSStatusItem 文档](https://developer.apple.com/documentation/appkit/nsstatusitem)
- [Swift Charts 框架](https://developer.apple.com/documentation/charts)
- [Lucide 图标库](https://lucide.dev)
