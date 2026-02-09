import SwiftUI
import NowCoinerCore

struct SettingsView: View {
    @ObservedObject var viewModel: TickerViewModel
    let onClose: () -> Void
    let onQuit: () -> Void

    var body: some View {
        PanelSurface(width: 340, height: 500) {
            PanelHeader(title: "设置", onClose: onClose)

            ScrollView {
                VStack(spacing: 12) {
                    settingsSection(title: "通用") {
                        ToggleRow(title: "开机自启动", isOn: Binding(
                            get: { viewModel.settings.launchAtLogin },
                            set: { value in
                                viewModel.updateSettings { $0.launchAtLogin = value }
                            }
                        ))

                        PickerRow(title: "计价货币") {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.vsCurrency },
                                set: { value in
                                    viewModel.updateSettings { $0.vsCurrency = value }
                                    Task { await viewModel.refreshMarketData(includeSparkline: true) }
                                }
                            )) {
                                Text("USD").tag("usd")
                                Text("EUR").tag("eur")
                                Text("GBP").tag("gbp")
                                Text("CNY").tag("cny")
                                Text("JPY").tag("jpy")
                            }
                            .labelsHidden()
                            .frame(width: 130)
                        }

                        TextFieldRow(title: "全局快捷键", text: Binding(
                            get: { viewModel.settings.globalShortcut },
                            set: { value in
                                viewModel.updateSettings { $0.globalShortcut = value }
                            }
                        ))
                    }

                    settingsSection(title: "显示") {
                        PickerRow(title: "菜单栏样式") {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.menuBarDisplayStyle },
                                set: { value in
                                    viewModel.updateSettings { $0.menuBarDisplayStyle = value }
                                }
                            )) {
                                ForEach(MenuBarStyle.allCases, id: \.self) { item in
                                    Text(item.title).tag(item)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 160)
                        }

                        PickerRow(title: "币种显示") {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.menuBarCoinDisplayMode },
                                set: { value in
                                    viewModel.updateSettings { $0.menuBarCoinDisplayMode = value }
                                }
                            )) {
                                ForEach(MenuBarCoinDisplayMode.allCases, id: \.self) { item in
                                    Text(item.title).tag(item)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 120)
                        }

                        PickerRow(title: "涨跌颜色") {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.priceColorScheme },
                                set: { value in
                                    viewModel.updateSettings { $0.priceColorScheme = value }
                                }
                            )) {
                                Text("绿涨红跌").tag(PriceColorScheme.greenUpRedDown)
                                Text("红涨绿跌").tag(PriceColorScheme.redUpGreenDown)
                            }
                            .labelsHidden()
                            .frame(width: 140)
                        }

                        PickerRow(title: "外观模式") {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.appearanceMode },
                                set: { value in
                                    viewModel.updateSettings { $0.appearanceMode = value }
                                }
                            )) {
                                Text("浅色").tag(AppearanceMode.light)
                                Text("深色").tag(AppearanceMode.dark)
                                Text("跟随系统").tag(AppearanceMode.system)
                            }
                            .labelsHidden()
                            .frame(width: 140)
                        }
                    }

                    settingsSection(title: "数据") {
                        PickerRow(title: "刷新间隔") {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.refreshInterval },
                                set: { value in
                                    viewModel.updateSettings { $0.refreshInterval = value }
                                }
                            )) {
                                Text("实时").tag(RefreshInterval.realtime)
                                Text("10 秒").tag(RefreshInterval.seconds10)
                                Text("30 秒").tag(RefreshInterval.seconds30)
                                Text("1 分钟").tag(RefreshInterval.minute1)
                                Text("5 分钟").tag(RefreshInterval.minutes5)
                            }
                            .labelsHidden()
                            .frame(width: 130)
                        }

                        PickerRow(title: "默认交易所") {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.defaultExchange },
                                set: { value in
                                    viewModel.updateSettings { $0.defaultExchange = value }
                                }
                            )) {
                                Text("Binance").tag(Exchange.binance)
                                Text("Coinbase").tag(Exchange.coinbase)
                                Text("OKX").tag(Exchange.okx)
                            }
                            .labelsHidden()
                            .frame(width: 130)
                        }
                    }

                    Button(action: onQuit) {
                        Text("退出应用")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.white)
                            .frame(maxWidth: .infinity, minHeight: 36)
                            .background(NowCoinerColors.red.opacity(0.9))
                            .clipShape(RoundedRectangle(cornerRadius: 8, style: .continuous))
                    }
                    .buttonStyle(.plain)
                }
                .padding(12)
            }
        }
    }

    @ViewBuilder
    private func settingsSection<Content: View>(title: String, @ViewBuilder content: () -> Content) -> some View {
        VStack(alignment: .leading, spacing: 10) {
            Text(title)
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(NowCoinerColors.textSecondary)

            content()
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(NowCoinerColors.secondaryPanel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}

private struct ToggleRow: View {
    let title: String
    @Binding var isOn: Bool

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(NowCoinerColors.textPrimary)
                .font(.system(size: 14))
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
        }
    }
}

private struct PickerRow<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(NowCoinerColors.textPrimary)
                .font(.system(size: 14))
            Spacer()
            content()
        }
    }
}

private struct TextFieldRow: View {
    let title: String
    @Binding var text: String

    var body: some View {
        HStack {
            Text(title)
                .foregroundStyle(NowCoinerColors.textPrimary)
                .font(.system(size: 14))
            Spacer()
            TextField("⌘⇧C", text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 140)
        }
    }
}
