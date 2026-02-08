import SwiftUI
import TickerPadCore

@main
struct TickerPadApp: App {
    @StateObject private var viewModel: TickerViewModel
    @State private var showingSearch = false
    @State private var showingSettings = false

    @State private var shortcutMonitor: GlobalShortcutMonitor?
    @State private var floatingPanelController = FloatingPanelController()
    @State private var didBootstrap = false

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
            .preferredColorScheme(preferredColorScheme)
            .task {
                await bootstrapIfNeeded()
            }
            .popover(isPresented: $showingSearch, arrowEdge: .top) {
                SearchPanelView(viewModel: viewModel)
                    .preferredColorScheme(preferredColorScheme)
            }
            .popover(isPresented: $showingSettings, arrowEdge: .top) {
                SettingsView(viewModel: viewModel)
                    .preferredColorScheme(preferredColorScheme)
            }
            .onChange(of: viewModel.settings.globalShortcut) { _, newValue in
                shortcutMonitor?.update(shortcutText: newValue)
            }
            .onChange(of: viewModel.settings.launchAtLogin) { _, newValue in
                LaunchAtLoginManager.apply(enabled: newValue)
            }
        } label: {
            MenuBarTickerView(viewModel: viewModel)
                .task {
                    await bootstrapIfNeeded()
                }
        }
        .menuBarExtraStyle(.window)
    }

    @MainActor
    private func bootstrapIfNeeded() async {
        guard !didBootstrap else { return }
        didBootstrap = true

        await viewModel.load()
        configureGlobalShortcut()
        LaunchAtLoginManager.apply(enabled: viewModel.settings.launchAtLogin)
    }

    private func configureGlobalShortcut() {
        if let shortcutMonitor {
            shortcutMonitor.update(shortcutText: viewModel.settings.globalShortcut)
            return
        }

        let monitor = GlobalShortcutMonitor {
            floatingPanelController.toggle {
                ShortcutPanelRootView(viewModel: viewModel)
            }
        }
        monitor.update(shortcutText: viewModel.settings.globalShortcut)
        monitor.start()
        self.shortcutMonitor = monitor
    }

    private var preferredColorScheme: ColorScheme? {
        switch viewModel.settings.appearanceMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}

private struct MenuBarTickerView: View {
    @ObservedObject var viewModel: TickerViewModel

    var body: some View {
        Text(labelText)
            .font(.system(size: 12, weight: .regular))
            .monospacedDigit()
            .lineLimit(1)
            .truncationMode(.tail)
    }

    private var labelText: String {
        let rows = Array(viewModel.menuBarRows.prefix(3))
        if rows.isEmpty {
            return "TickerPad"
        }

        let parts: [String] = rows.compactMap { (row: CoinRowState) -> String? in
            guard let price = row.price else { return nil }
            return PriceFormatter.menuBarText(
                symbol: row.coin.symbol,
                price: price.currentPrice,
                changePercent: price.priceChangePercent24h,
                currencyCode: viewModel.settings.vsCurrency,
                style: viewModel.settings.menuBarDisplayStyle
            )
        }

        return parts.isEmpty ? "TickerPad" : parts.joined(separator: " | ")
    }
}

private struct ShortcutPanelRootView: View {
    @ObservedObject var viewModel: TickerViewModel
    @State private var showingSearch = false
    @State private var showingSettings = false

    var body: some View {
        MainPanelView(
            viewModel: viewModel,
            showingSearch: $showingSearch,
            showingSettings: $showingSettings
        )
        .preferredColorScheme(preferredColorScheme)
        .popover(isPresented: $showingSearch, arrowEdge: .top) {
            SearchPanelView(viewModel: viewModel)
                .preferredColorScheme(preferredColorScheme)
        }
        .popover(isPresented: $showingSettings, arrowEdge: .top) {
            SettingsView(viewModel: viewModel)
                .preferredColorScheme(preferredColorScheme)
        }
    }

    private var preferredColorScheme: ColorScheme? {
        switch viewModel.settings.appearanceMode {
        case .light:
            return .light
        case .dark:
            return .dark
        case .system:
            return nil
        }
    }
}
