# NowCoiner 开发运行指南

本文档说明开发阶段如何正确运行应用，以及 `swift run` 与 `.app` 运行方式的差异。

## 1. 开发常用命令

在项目根目录执行：

```bash
cd /Users/mylxsw/Workspace/codes/vibe/crypto-menubar
```

### 1.1 快速开发运行（终端前台）

```bash
make run
```

等价于：

```bash
swift run NowCoinerApp
```

特点：

- 启动快，适合高频改代码
- 进程运行在终端前台
- 资源加载环境与正式 `.app` 有差异

### 1.2 开发态“接近正式包”运行（推荐做功能验收）

```bash
make run-after-build
```

等价流程：

1. 先打包生成 `~/Downloads/NowCoiner.app`
2. 用 `open` 启动该 `.app`

特点：

- 资源路径、`Info.plist`、菜单栏行为更接近正式发布
- 适合验证本地化、图标、启动项等与 bundle 相关问题

## 2. 为什么 `make run` 和 `.app` 运行结果会不同

`swift run` 是可执行文件直接运行；正式发布是 `.app` bundle 运行。  
二者在这些方面不同：

- `Bundle.main` 的路径不同
- 本地化资源查找顺序不同
- 图标和 `Info.plist` 元信息加载方式不同

项目已做兼容处理：本地化会优先使用 `Bundle.main`，开发态会回退到 SwiftPM 资源 bundle，减少 `swift run` 与 `.app` 的行为差异。

## 3. 开发阶段建议流程

1. 日常改代码：`make run`
2. 每次涉及 UI 资源/本地化/打包行为后：`make run-after-build`
3. 提交前：`swift test`

## 4. 本地化检查步骤

1. 启动应用后进入设置页切换语言（中文/英文/跟随系统）
2. 检查菜单栏标题、设置页、搜索页、详情页文本是否都切换成功
3. 若未切换：
- 确认 `Sources/NowCoinerApp/Resources/en.lproj/Localizable.strings`
- 确认 `Sources/NowCoinerApp/Resources/zh-Hans.lproj/Localizable.strings`
- 用 `make run-after-build` 再验证一次

## 5. 常见问题

### 问题：`make run` 下语言显示不完整

处理：

1. 先用 `make run-after-build` 验证是否正常
2. 若 `.app` 正常，说明是开发运行路径差异，不影响发布
3. 若 `.app` 也异常，再检查 `Localizable.strings` key 是否缺失

### 问题：字体显示和预期不同

处理：

1. 先确认是否使用系统字体（建议）
2. 若使用自定义字体，确保字体文件被打进 bundle 并在运行时可访问
3. 优先在 `make run-after-build` 模式确认最终视觉效果

