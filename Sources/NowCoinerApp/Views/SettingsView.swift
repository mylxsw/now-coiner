import SwiftUI
import NowCoinerCore

struct SettingsView: View {
    @ObservedObject var viewModel: TickerViewModel
    let onClose: () -> Void
    let onQuit: () -> Void

    var body: some View {
        PanelSurface(width: 340, height: 500) {
            PanelHeader(title: L10n.tr("settings.title"), onClose: onClose)

            ScrollView {
                VStack(spacing: 12) {
                    settingsSection(title: L10n.tr("settings.section.general")) {
                        ToggleRow(title: L10n.tr("settings.launch_at_login"), isOn: Binding(
                            get: { viewModel.settings.launchAtLogin },
                            set: { value in
                                viewModel.updateSettings { $0.launchAtLogin = value }
                            }
                        ))

                        PickerRow(title: L10n.tr("settings.currency")) {
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

                        TextFieldRow(title: L10n.tr("settings.global_shortcut"), text: Binding(
                            get: { viewModel.settings.globalShortcut },
                            set: { value in
                                viewModel.updateSettings { $0.globalShortcut = value }
                            }
                        ))
                    }

                    settingsSection(title: L10n.tr("settings.section.display")) {
                        PickerRow(title: L10n.tr("settings.menu_bar_style")) {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.menuBarDisplayStyle },
                                set: { value in
                                    viewModel.updateSettings { $0.menuBarDisplayStyle = value }
                                }
                            )) {
                                ForEach(MenuBarStyle.allCases, id: \.self) { item in
                                    Text(localizedMenuBarStyle(item)).tag(item)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 160)
                        }

                        PickerRow(title: L10n.tr("settings.coin_display_mode")) {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.menuBarCoinDisplayMode },
                                set: { value in
                                    viewModel.updateSettings { $0.menuBarCoinDisplayMode = value }
                                }
                            )) {
                                ForEach(MenuBarCoinDisplayMode.allCases, id: \.self) { item in
                                    Text(localizedCoinDisplayMode(item)).tag(item)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 120)
                        }

                        PickerRow(title: L10n.tr("settings.price_color_scheme")) {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.priceColorScheme },
                                set: { value in
                                    viewModel.updateSettings { $0.priceColorScheme = value }
                                }
                            )) {
                                Text(L10n.tr("settings.price_color.green_up_red_down")).tag(PriceColorScheme.greenUpRedDown)
                                Text(L10n.tr("settings.price_color.red_up_green_down")).tag(PriceColorScheme.redUpGreenDown)
                            }
                            .labelsHidden()
                            .frame(width: 140)
                        }

                        PickerRow(title: L10n.tr("settings.appearance_mode")) {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.appearanceMode },
                                set: { value in
                                    viewModel.updateSettings { $0.appearanceMode = value }
                                }
                            )) {
                                Text(L10n.tr("settings.appearance.light")).tag(AppearanceMode.light)
                                Text(L10n.tr("settings.appearance.dark")).tag(AppearanceMode.dark)
                                Text(L10n.tr("settings.appearance.system")).tag(AppearanceMode.system)
                            }
                            .labelsHidden()
                            .frame(width: 140)
                        }

                        PickerRow(title: L10n.tr("settings.language")) {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.appLanguage },
                                set: { value in
                                    L10n.setLanguage(value)
                                    viewModel.updateSettings { $0.appLanguage = value }
                                }
                            )) {
                                ForEach(AppLanguage.allCases, id: \.self) { item in
                                    Text(localizedAppLanguage(item)).tag(item)
                                }
                            }
                            .labelsHidden()
                            .frame(width: 140)
                        }
                    }

                    settingsSection(title: L10n.tr("settings.section.data")) {
                        PickerRow(title: L10n.tr("settings.refresh_interval")) {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.refreshInterval },
                                set: { value in
                                    viewModel.updateSettings { $0.refreshInterval = value }
                                }
                            )) {
                                Text(L10n.tr("settings.refresh.realtime")).tag(RefreshInterval.realtime)
                                Text(L10n.tr("settings.refresh.seconds10")).tag(RefreshInterval.seconds10)
                                Text(L10n.tr("settings.refresh.seconds30")).tag(RefreshInterval.seconds30)
                                Text(L10n.tr("settings.refresh.minute1")).tag(RefreshInterval.minute1)
                                Text(L10n.tr("settings.refresh.minutes5")).tag(RefreshInterval.minutes5)
                            }
                            .labelsHidden()
                            .frame(width: 130)
                        }

                        PickerRow(title: L10n.tr("settings.default_exchange")) {
                            Picker("", selection: Binding(
                                get: { viewModel.settings.defaultExchange },
                                set: { value in
                                    viewModel.updateSettings { $0.defaultExchange = value }
                                }
                            )) {
                                Text(localizedExchange(.binance)).tag(Exchange.binance)
                                Text(localizedExchange(.coinbase)).tag(Exchange.coinbase)
                                Text(localizedExchange(.okx)).tag(Exchange.okx)
                            }
                            .labelsHidden()
                            .frame(width: 130)
                        }
                    }

                    Button(action: onQuit) {
                        Text(L10n.tr("settings.quit_app"))
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
            .id("settings-lang-\(viewModel.settings.appLanguage.rawValue)")
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
            TextField(L10n.tr("settings.shortcut.placeholder"), text: $text)
                .textFieldStyle(.roundedBorder)
                .frame(width: 140)
        }
    }
}

private func localizedMenuBarStyle(_ style: MenuBarStyle) -> String {
    switch style {
    case .priceOnly:
        return L10n.tr("settings.menu_bar_style.price_only")
    case .symbolAndPrice:
        return L10n.tr("settings.menu_bar_style.symbol_and_price")
    case .symbolAndChange:
        return L10n.tr("settings.menu_bar_style.symbol_and_change")
    case .full:
        return L10n.tr("settings.menu_bar_style.full")
    }
}

private func localizedCoinDisplayMode(_ mode: MenuBarCoinDisplayMode) -> String {
    switch mode {
    case .text:
        return L10n.tr("settings.coin_display.text")
    case .icon:
        return L10n.tr("settings.coin_display.icon")
    }
}

private func localizedExchange(_ exchange: Exchange) -> String {
    switch exchange {
    case .binance:
        return L10n.tr("settings.exchange.binance")
    case .coinbase:
        return L10n.tr("settings.exchange.coinbase")
    case .okx:
        return L10n.tr("settings.exchange.okx")
    }
}

private func localizedAppLanguage(_ language: AppLanguage) -> String {
    switch language {
    case .followSystem:
        return L10n.tr("settings.language.follow_system")
    case .zhHans:
        return "中文"
    case .en:
        return "English"
    }
}
