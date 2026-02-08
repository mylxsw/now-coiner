import SwiftUI
import TickerPadCore

struct SettingsView: View {
    @ObservedObject var viewModel: TickerViewModel
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            Form {
                Section("通用") {
                    Toggle("开机自启动", isOn: Binding(
                        get: { viewModel.settings.launchAtLogin },
                        set: { value in
                            Task { await viewModel.updateSettings { $0.launchAtLogin = value } }
                        }
                    ))

                    Picker("计价货币", selection: Binding(
                        get: { viewModel.settings.vsCurrency },
                        set: { value in
                            Task { await viewModel.updateSettings { $0.vsCurrency = value } }
                            Task { await viewModel.refreshMarketData(includeSparkline: true) }
                        }
                    )) {
                        Text("USD").tag("usd")
                        Text("EUR").tag("eur")
                        Text("GBP").tag("gbp")
                        Text("CNY").tag("cny")
                        Text("JPY").tag("jpy")
                    }
                }

                Section("显示") {
                    Picker("菜单栏样式", selection: Binding(
                        get: { viewModel.settings.menuBarDisplayStyle },
                        set: { value in
                            Task { await viewModel.updateSettings { $0.menuBarDisplayStyle = value } }
                        }
                    )) {
                        ForEach(MenuBarStyle.allCases, id: \.self) { item in
                            Text(item.title).tag(item)
                        }
                    }

                    Picker("涨跌颜色", selection: Binding(
                        get: { viewModel.settings.priceColorScheme },
                        set: { value in
                            Task { await viewModel.updateSettings { $0.priceColorScheme = value } }
                        }
                    )) {
                        Text("绿涨红跌").tag(PriceColorScheme.greenUpRedDown)
                        Text("红涨绿跌").tag(PriceColorScheme.redUpGreenDown)
                    }
                }

                Section("数据") {
                    Picker("刷新间隔", selection: Binding(
                        get: { viewModel.settings.refreshInterval },
                        set: { value in
                            Task { await viewModel.updateSettings { $0.refreshInterval = value } }
                        }
                    )) {
                        Text("实时").tag(RefreshInterval.realtime)
                        Text("10 秒").tag(RefreshInterval.seconds10)
                        Text("30 秒").tag(RefreshInterval.seconds30)
                        Text("1 分钟").tag(RefreshInterval.minute1)
                        Text("5 分钟").tag(RefreshInterval.minutes5)
                    }

                    Picker("默认交易所", selection: Binding(
                        get: { viewModel.settings.defaultExchange },
                        set: { value in
                            Task { await viewModel.updateSettings { $0.defaultExchange = value } }
                        }
                    )) {
                        Text("Binance").tag(Exchange.binance)
                        Text("Coinbase").tag(Exchange.coinbase)
                        Text("OKX").tag(Exchange.okx)
                    }
                }
            }
            .navigationTitle("设置")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .frame(width: 420, height: 360)
    }
}
