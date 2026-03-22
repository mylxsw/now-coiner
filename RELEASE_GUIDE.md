# NowCoiner 正式发布指南（macOS）

本文档涵盖两种发布渠道：**直接分发（Developer ID + DMG）** 和 **Mac App Store**。

---

## 渠道一：Developer ID 直接分发（DMG）

适合从官网/GitHub 下载安装的场景，无 Apple 审核。

### 先决条件

- 系统：macOS（已安装 Xcode Command Line Tools）
- Apple 开发者账号：已加入 Apple Developer Program
- 证书：Keychain 中已有 `Developer ID Application` 证书
- 公证工具：`xcrun notarytool` 可用
- Entitlements：项目根目录已有 `NowCoiner.entitlements`（已内置，按需修改）

```bash
security find-identity -v -p codesigning
xcrun notarytool --help
```

### 1. 生成 App 图标（可选）

```bash
cd <项目根目录>
make icon SOURCE="/绝对路径/你的大图.png"
```

产物：`Sources/NowCoinerApp/Resources/AppIcon.icns`

### 2. 本地打包 App

```bash
cd <项目根目录>
make package
```

默认输出 `~/Downloads/NowCoiner.app`。可选参数：

```bash
APP_NAME="NowCoiner" \
BUNDLE_ID="ai.gulu.app.nowcoiner" \
VERSION="1.0.0" \
BUILD_NUMBER="100" \
SIGN_MODE=adhoc \
make package
```

说明：
- `SIGN_MODE=none`：仅打包，不签名（默认）
- `SIGN_MODE=adhoc`：本地 ad-hoc 签名，便于验证包结构

### 3. 发布前预检（可选单独运行）

```bash
cd <项目根目录>
make preflight
```

> `make release` 内部会自动运行预检，此步骤可用于提前排查问题。

### 4. 配置 notarytool 凭据（一次性）

```bash
xcrun notarytool store-credentials "notary-profile" \
  --apple-id "you@example.com" \
  --team-id "YOUR_TEAM_ID" \
  --password "APP_SPECIFIC_PASSWORD"
```

`APP_SPECIFIC_PASSWORD` 是 App 专用密码，在 [appleid.apple.com](https://appleid.apple.com) → 登录和安全性 → App 专用密码 中生成。

### 5. 正式签名 + 公证 + 生成 DMG

```bash
cd <项目根目录>
DEVELOPER_ID_APP="Developer ID Application: Your Name (TEAMID)" \
NOTARY_PROFILE="notary-profile" \
make release
```

`DEVELOPER_ID_APP` 完整字符串通过以下命令查看：

```bash
security find-identity -v -p codesigning
```

该步骤自动完成：
1. 运行预检
2. 从内到外对 `.app` 做 Developer ID 签名（Hardened Runtime + entitlements + timestamp）
3. 生成 DMG 并签名
4. 提交公证并等待结果
5. 对 `.app` 和 `.dmg` 做 staple 并验证

默认产物：`~/Downloads/NowCoiner.app`、`~/Downloads/NowCoiner.dmg`

> **关于 Entitlements**：使用 `NowCoiner.entitlements`，当前 app 仅需出站网络连接，无需额外声明。若将来新增麦克风、位置等系统权限，在该文件补充对应 key 即可。

---

## 渠道二：Mac App Store 发布

### 先决条件

- Apple 开发者账号：已加入 Apple Developer Program
- 证书（在 [developer.apple.com](https://developer.apple.com) → Certificates 中申请）：
  - `Mac App Distribution`（用于签名 `.app`）
  - `Mac Installer Distribution`（用于签名 `.pkg`）
- 已在 [App Store Connect](https://appstoreconnect.apple.com) 创建好 App 记录
- 已安装 [Transporter](https://apps.apple.com/app/transporter/id1450874784)

```bash
security find-identity -v -p codesigning
```

### 1. 打包 App

与直接分发相同，先打包：

```bash
cd <项目根目录>
make package
```

### 2. 签名 + 生成 .pkg

```bash
cd <项目根目录>
APPLE_DISTRIBUTION="Mac App Distribution: Your Name (TEAMID)" \
MAS_INSTALLER="Mac Installer Distribution: Your Name (TEAMID)" \
make mas-release
```

该步骤自动完成：
1. 运行预检
2. 从内到外对 `.app` 做 Mac App Distribution 签名（Hardened Runtime + App Sandbox entitlements）
3. 用 `productbuild` 打包为 `.pkg` 并用 Installer 证书签名

默认产物：`~/Downloads/NowCoiner.pkg`

> **关于沙盒 Entitlements**：MAS 版本使用 `NowCoiner-mas.entitlements`，已包含 `app-sandbox` 和 `network.client`。若将来新增系统权限，在该文件补充即可。

### 3. 用 Transporter 上传

1. 打开 Transporter，登录 Apple ID
2. 点击「Add App or Asset Pack」，选择 `~/Downloads/NowCoiner.pkg`
3. 点击「Deliver」，等待上传完成
4. 前往 App Store Connect → TestFlight / 版本发布，选择刚上传的构建版本

### 4. 发布前最终检查清单

- `swift test` 全部通过
- `make preflight` 通过
- 在非开发机安装并启动正常
- 网络权限弹窗（首次）正常、开机自启正常
- 关键功能验证：添加/删除币种、排序、实时价格更新、设置持久化

---

## 常见问题排查

### 问题：启动崩溃，提示找不到 resource bundle

处理：
1. 使用当前 `scripts/package_app.sh` 重新打包
2. 确认 `Localizable.strings` 在 `Contents/Resources/*.lproj`
3. 重新运行 `make preflight`

### 问题：`codesign` 失败，提示 bundle 根目录内容未封装

处理：
1. 删除非标准根目录资源
2. 资源统一放入 `Contents/Resources`
3. 重新打包并预检

### 问题：`spctl` 失败

说明：未公证前常见，公证 + staple 后应通过。MAS 版本无需公证，由 Apple 审核替代。

### 问题：MAS 签名失败，提示 entitlements 不匹配

处理：确认使用的是 `NowCoiner-mas.entitlements`（含 `app-sandbox`），而不是 `NowCoiner.entitlements`。

### 问题：`codesign` 报 `no identity found`

处理：
1. 先运行 `security find-identity -v -p codesigning`
2. 如果输出是 `0 valid identities found`，说明本机钥匙串里没有可用的签名身份，或者证书缺少对应私钥
3. 在 Apple Developer 后台申请并下载 `Mac App Distribution` 和 `Mac Installer Distribution` 证书
4. 确保这两张证书是用当前 Mac 上生成的 CSR 申请的，并已双击导入到登录钥匙串
5. 重新执行 `make mas-release`

---

## 相关脚本和文件

| 用途 | 文件 |
|---|---|
| 打包 | `scripts/package_app.sh` |
| 预检 | `scripts/release_preflight.sh` |
| Developer ID 发布 | `scripts/release_notarize.sh` |
| Mac App Store 发布 | `scripts/release_mas.sh` |
| 图标生成 | `scripts/generate_app_icon.sh` |
| Developer ID Entitlements | `NowCoiner.entitlements` |
| Mac App Store Entitlements | `NowCoiner-mas.entitlements` |
