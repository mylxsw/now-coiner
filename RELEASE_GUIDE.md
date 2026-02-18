# NowCoiner 正式发布指南（macOS）

本文档基于当前项目脚本，给出一套从本地打包到签名、公证、产出 DMG 的完整流程。

## 0. 先决条件

- 系统：macOS（已安装 Xcode Command Line Tools）
- Apple 开发者账号：已加入 Apple Developer Program
- 证书：Keychain 中已有 `Developer ID Application` 证书
- 公证工具：`xcrun notarytool` 可用
- Entitlements：项目根目录已有 `NowCoiner.entitlements`（已内置，按需修改）

可用命令检查：

```bash
security find-identity -v -p codesigning
xcrun notarytool --help
```

## 1. 生成 App 图标（可选）

如果你要更新图标，先执行：

```bash
cd <项目根目录>
make icon SOURCE="/绝对路径/你的大图.png"
```

产物会放在：

- `Sources/NowCoinerApp/Resources/AppIcon-1024.png`
- `Sources/NowCoinerApp/Resources/AppIcon.iconset`
- `Sources/NowCoinerApp/Resources/AppIcon.icns`

## 2. 本地打包 App

```bash
cd <项目根目录>
make package
```

默认输出：

- `~/Downloads/NowCoiner.app`

可选参数示例：

```bash
cd <项目根目录>
APP_NAME="NowCoiner" \
BUNDLE_ID="com.yourcompany.nowcoiner" \
VERSION="1.0.0" \
BUILD_NUMBER="100" \
SIGN_MODE=adhoc \
make package
```

说明：

- `SIGN_MODE=none`：仅打包，不签名（默认）
- `SIGN_MODE=adhoc`：本地 ad-hoc 签名，便于验证包结构

## 3. 发布前预检（可选单独运行）

```bash
cd <项目根目录>
make preflight
```

预检项包括：

- `.app` 基本结构
- `Info.plist` 合法性与关键字段
- `AppIcon.icns` 是否存在
- 是否存在阻塞签名的根目录 `.bundle`
- `codesign` 验证
- `spctl` 评估（未公证前失败是常见现象）

> **注意**：`make release`（Step 5）内部会自动运行一次预检，此步骤可用于提前排查问题，不是必须单独执行的步骤。如果预检失败，先修复再进入发布。

## 4. 配置 notarytool 凭据（一次性）

先在本机保存 notary profile：

```bash
xcrun notarytool store-credentials "notary-profile" \
  --apple-id "you@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

## 5. 正式签名 + 公证 + 生成 DMG

执行：

```bash
cd <项目根目录>
DEVELOPER_ID_APP="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="notary-profile" \
make release
```

`DEVELOPER_ID_APP` 的完整字符串可通过以下命令查看：

```bash
security find-identity -v -p codesigning
```

该步骤会自动：

1. 运行发布门禁预检
2. 从内到外对 `.app` 做 Developer ID 签名（Hardened Runtime + entitlements + timestamp）
3. 生成 DMG
4. 对 DMG 签名
5. 提交公证并等待结果
6. 对 `.app` 和 `.dmg` 做 `staple`
7. 验证 `staple` 结果

> **关于 Entitlements**：签名时自动使用项目根目录的 `NowCoiner.entitlements`。当前 app 仅需出站网络连接（WebSocket/HTTPS），Hardened Runtime 默认允许，无需额外权限声明。若将来新增麦克风、位置等系统权限，在该文件中补充对应 key 即可。

默认产物：

- `~/Downloads/NowCoiner.app`
- `~/Downloads/NowCoiner.dmg`

## 6. 发布前最终检查清单

- `swift test` 全部通过
- `make preflight` 通过
- 在非开发机安装并启动正常
- 首次启动网络权限、开机自启、快捷键正常
- 关键功能验证：添加/删除币种、排序、实时价格更新、设置持久化

## 7. 常见问题排查

### 问题：启动崩溃，提示找不到 resource bundle

原因：

- 旧打包结构把资源放错位置，或仍依赖非标准路径

处理：

1. 使用当前 `scripts/package_app.sh` 重新打包  
2. 确认 `Localizable.strings` 在 `Contents/Resources/*.lproj`  
3. 重新运行 `make preflight`

### 问题：`codesign` 失败，提示 bundle 根目录内容未封装

原因：

- `.app` 根目录存在不规范资源（例如根目录 `.bundle`）

处理：

1. 删除非标准根目录资源  
2. 资源统一放入 `Contents/Resources`  
3. 重新打包并预检

### 问题：`spctl` 失败

说明：

- 未公证前常见，公证 + staple 后应通过

## 8. 相关脚本

- 打包：`scripts/package_app.sh`
- 预检：`scripts/release_preflight.sh`
- 发布：`scripts/release_notarize.sh`
- 图标：`scripts/generate_app_icon.sh`

