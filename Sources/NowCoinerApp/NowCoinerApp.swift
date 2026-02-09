import SwiftUI
import AppKit
import NowCoinerCore

@main
struct NowCoinerApp: App {
    @StateObject private var viewModel: TickerViewModel

    @State private var shortcutMonitor: GlobalShortcutMonitor?
    @State private var statusBarRightClickMonitor: StatusBarRightClickMonitor?
    @State private var floatingPanelController = FloatingPanelController()
    @State private var searchPanelController = AnchoredPanelController()
    @State private var settingsPanelController = AnchoredPanelController()
    @State private var didBootstrap = false

    init() {
        let container = AppContainer.makeDefault()
        _viewModel = StateObject(wrappedValue: container.viewModel)
    }

    var body: some Scene {
        MenuBarExtra {
            MainPanelView(
                viewModel: viewModel,
                onOpenSearch: openSearchFromMenu,
                onOpenSettings: openSettingsFromMenu
            )
            .preferredColorScheme(preferredColorScheme)
            .task {
                await bootstrapIfNeeded()
            }
            .onChange(of: viewModel.settings.globalShortcut) { _, newValue in
                shortcutMonitor?.update(shortcutText: newValue)
            }
            .onChange(of: viewModel.settings.launchAtLogin) { _, newValue in
                LaunchAtLoginManager.apply(enabled: newValue)
            }
            .onReceive(NotificationCenter.default.publisher(for: NSApplication.willTerminateNotification)) { _ in
                viewModel.persistStateSnapshot()
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
        configureStatusBarRightClick()
        LaunchAtLoginManager.apply(enabled: viewModel.settings.launchAtLogin)
    }

    private func configureGlobalShortcut() {
        if let shortcutMonitor {
            shortcutMonitor.update(shortcutText: viewModel.settings.globalShortcut)
            return
        }

        let monitor = GlobalShortcutMonitor {
            floatingPanelController.toggle {
                ShortcutPanelRootView(
                    viewModel: viewModel,
                    onOpenSearch: openSearchFromMenu,
                    onOpenSettings: openSettingsFromMenu
                )
            }
        }
        monitor.update(shortcutText: viewModel.settings.globalShortcut)
        monitor.start()
        self.shortcutMonitor = monitor
    }

    private func configureStatusBarRightClick() {
        if let statusBarRightClickMonitor {
            statusBarRightClickMonitor.start()
            return
        }

        let monitor = StatusBarRightClickMonitor(
            onOpenSettings: openSettingsFromMenu,
            onQuit: terminateApp
        )
        monitor.start()
        self.statusBarRightClickMonitor = monitor
    }

    private func openSearchFromMenu() {
        let anchor = MenuAnchorResolver.currentAnchor()
        shortcutMonitor?.stop()

        MenuAnchorResolver.endMenuTracking()
        MenuAnchorResolver.closeAllAppWindows()

        settingsPanelController.close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            searchPanelController.show(anchor: anchor, panelSize: CGSize(width: 300, height: 460)) {
                SearchPanelView(viewModel: viewModel, onClose: {
                    searchPanelController.close()
                    shortcutMonitor?.start()
                })
                .preferredColorScheme(preferredColorScheme)
            }
        }
    }

    private func openSettingsFromMenu() {
        let anchor = MenuAnchorResolver.currentAnchor()
        shortcutMonitor?.stop()

        MenuAnchorResolver.endMenuTracking()
        MenuAnchorResolver.closeAllAppWindows()

        searchPanelController.close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            settingsPanelController.show(anchor: anchor, panelSize: CGSize(width: 340, height: 500)) {
                SettingsView(viewModel: viewModel, onClose: {
                    settingsPanelController.close()
                    shortcutMonitor?.start()
                }, onQuit: terminateApp)
                .preferredColorScheme(preferredColorScheme)
            }
        }
    }

    private func terminateApp() {
        viewModel.persistStateSnapshot()
        statusBarRightClickMonitor?.stop()
        searchPanelController.close()
        settingsPanelController.close()
        MenuAnchorResolver.endMenuTracking()
        MenuAnchorResolver.closeAllAppWindows()
        NSApp.terminate(nil)
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
            return "NowCoiner"
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

        return parts.isEmpty ? "NowCoiner" : parts.joined(separator: " | ")
    }
}

private struct ShortcutPanelRootView: View {
    @ObservedObject var viewModel: TickerViewModel
    let onOpenSearch: () -> Void
    let onOpenSettings: () -> Void

    var body: some View {
        MainPanelView(
            viewModel: viewModel,
            onOpenSearch: onOpenSearch,
            onOpenSettings: onOpenSettings
        )
        .preferredColorScheme(preferredColorScheme)
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
