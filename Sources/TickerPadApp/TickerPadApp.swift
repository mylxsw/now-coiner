import SwiftUI
import TickerPadCore

@main
struct TickerPadApp: App {
    @StateObject private var viewModel: TickerViewModel
    @State private var showingSearch = false
    @State private var showingSettings = false

    init() {
        let container = AppContainer.makeDefault()
        _viewModel = StateObject(wrappedValue: container.viewModel)
    }

    var body: some Scene {
        MenuBarExtra {
            MainPanelView(
                viewModel: viewModel,
                showingSearch: $showingSearch,
                showingSettings: $showingSettings
            )
            .task {
                await viewModel.load()
            }
            .sheet(isPresented: $showingSearch) {
                SearchPanelView(viewModel: viewModel)
            }
            .sheet(isPresented: $showingSettings) {
                SettingsView(viewModel: viewModel)
            }
        } label: {
            MenuBarTickerView(viewModel: viewModel)
        }
        .menuBarExtraStyle(.window)
    }
}

private struct MenuBarTickerView: View {
    @ObservedObject var viewModel: TickerViewModel

    var body: some View {
        Text(labelText)
            .font(.system(size: 12, weight: .regular))
            .lineLimit(1)
            .task {
                while true {
                    try? await Task.sleep(for: .seconds(viewModel.settings.refreshInterval.seconds))
                    await viewModel.refreshSimplePrices()
                }
            }
    }

    private var labelText: String {
        let rows = Array(viewModel.menuBarRows.prefix(3))
        if rows.isEmpty {
            return "TickerPad"
        }

        return rows.compactMap { row in
            guard let price = row.price else { return nil }
            return PriceFormatter.menuBarText(
                symbol: row.coin.symbol,
                price: price.currentPrice,
                changePercent: price.priceChangePercent24h,
                currencyCode: viewModel.settings.vsCurrency,
                style: viewModel.settings.menuBarDisplayStyle
            )
        }.joined(separator: " | ")
    }
}
