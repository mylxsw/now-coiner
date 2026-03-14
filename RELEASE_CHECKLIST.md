# NowCoiner 发布打包清单（macOS）

## 1) 应用元信息

- 设定 `CFBundleIdentifier`（例如 `com.yourorg.nowcoiner`）。
- 设定版本号：`CFBundleShortVersionString`（如 `1.0.0`）和 `CFBundleVersion`（如 `100`）。
- 设定 `LSApplicationCategoryType`（例如 `public.app-category.finance`）。
- 确认 `LSUIElement = true`（菜单栏应用，无 Dock 图标）。
- 准备 `Info.plist` 并在最终 `.app` 的 `Contents/Info.plist` 生效。

## 2) 图标资源

- 准备 1024x1024 主图，生成 `AppIcon.iconset` 与 `AppIcon.icns`。
- 图标文件放入 `.app/Contents/Resources/AppIcon.icns`。
- `Info.plist` 设置 `CFBundleIconFile = AppIcon`。
- 已提供脚本：`scripts/generate_app_icon.sh`。

## 3) 构建产物

- 用 Release 配置构建可执行文件。
- 组装标准 macOS bundle 结构：
  - `NowCoiner.app/Contents/MacOS/NowCoinerApp`
  - `NowCoiner.app/Contents/Resources/...`
  - `NowCoiner.app/Contents/Info.plist`

## 4) 签名与公证

- Developer ID Application 证书签名：`codesign --deep --force --options runtime ...`
- 用 `notarytool` 提交公证并 `stapler staple`。
- 本机验证：
  - `codesign --verify --deep --strict --verbose=2 NowCoiner.app`
  - `spctl -a -t exec -vv NowCoiner.app`

## 5) 分发包

- 产出 `.dmg` 或 `.pkg`。
- 安装前后验证：首次启动、网络权限、开机自启、全局快捷键、缓存读写路径。

## 6) 回归测试（最少）

- `swift test`
- `swift run NowCoinerApp`
- 验证核心流程：添加币种、排序、删除、WebSocket 实时更新、设置持久化。
