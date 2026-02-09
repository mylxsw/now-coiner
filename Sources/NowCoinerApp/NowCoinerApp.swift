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
    @State private var iconMap: [String: NSImage] = [:]

    var body: some View {
        Group {
            if viewModel.settings.menuBarCoinDisplayMode == .icon {
                iconModeLabel
            } else {
                Text(labelText)
                    .font(.system(size: 12, weight: .regular))
                    .monospacedDigit()
                    .lineLimit(1)
                    .truncationMode(.tail)
            }
        }
        .task(id: menuBarPrefetchIdentity) {
            await CoinIconCache.shared.prefetch(coins: viewModel.menuBarRows.map(\.coin))
            await refreshMenuBarIcons()
        }
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

    private var iconModeLabel: some View {
        let rows = Array(viewModel.menuBarRows.prefix(3))
        let metrics = iconMetrics(for: rows.count)
        return HStack(spacing: 3) {
            if rows.isEmpty {
                Text("NowCoiner")
                    .font(.system(size: 12, weight: .regular))
                    .lineLimit(1)
            } else {
                ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                    HStack(spacing: 1.5) {
                        menuBarIcon(for: row.coin, size: metrics.iconSize, textSize: metrics.iconTextSize)
                        Text(iconModeValueText(for: row.price))
                            .font(.system(size: metrics.valueFontSize, weight: .regular))
                            .lineLimit(1)
                            .minimumScaleFactor(0.6)
                    }
                    if index < rows.count - 1 {
                        Text(" ")
                            .font(.system(size: metrics.valueFontSize))
                    }
                }
            }
        }
        .lineLimit(1)
        .truncationMode(.tail)
    }

    private func iconModeValueText(for price: CoinPrice?) -> String {
        guard let price else { return "--" }
        let p = PriceFormatter.compactCurrency(price.currentPrice, code: viewModel.settings.vsCurrency)
        let c = PriceFormatter.percent(price.priceChangePercent24h)

        switch viewModel.settings.menuBarDisplayStyle {
        case .priceOnly:
            return p
        case .symbolAndPrice:
            return p
        case .symbolAndChange:
            return c
        case .full:
            return "\(p) \(c)"
        }
    }

    private var menuBarPrefetchIdentity: String {
        viewModel.menuBarRows.map { "\($0.coin.id)|\($0.coin.imageURL ?? "")" }.joined(separator: ",")
    }

    @MainActor
    private func refreshMenuBarIcons() async {
        var next: [String: NSImage] = [:]
        let size = iconMetrics(for: min(viewModel.menuBarRows.count, 3)).iconSize
        for row in viewModel.menuBarRows.prefix(3) {
            guard let data = await CoinIconCache.shared.imageData(coinID: row.coin.id, imageURL: row.coin.imageURL),
                  let image = NSImage(data: data) else { continue }
            next[row.coin.id] = resizedMenuBarImage(from: image, size: size)
        }
        iconMap = next
    }

    @ViewBuilder
    private func menuBarIcon(for coin: Coin, size: CGFloat, textSize: CGFloat) -> some View {
        if let image = iconMap[coin.id] {
            Image(nsImage: image)
                .frame(width: size, height: size)
                .clipShape(Circle())
        } else {
            Circle()
                .fill(Color(hex: "3A3A3C"))
                .frame(width: size, height: size)
                .overlay(
                    Text(String(coin.symbol.uppercased().prefix(1)))
                        .font(.system(size: textSize, weight: .bold))
                        .foregroundStyle(.white)
                )
        }
    }

    private func resizedMenuBarImage(from source: NSImage, size: CGFloat) -> NSImage {
        let targetSize = NSSize(width: size, height: size)
        let output = NSImage(size: targetSize)
        output.lockFocus()
        NSGraphicsContext.current?.imageInterpolation = .high

        let sourceRect = NSRect(origin: .zero, size: source.size)
        let destinationRect = NSRect(origin: .zero, size: targetSize)
        source.draw(in: destinationRect, from: sourceRect, operation: .sourceOver, fraction: 1.0)

        output.unlockFocus()
        output.isTemplate = false
        return output
    }

    private func iconMetrics(for count: Int) -> (iconSize: CGFloat, iconTextSize: CGFloat, valueFontSize: CGFloat) {
        switch count {
        case 3...:
            return (iconSize: 11, iconTextSize: 7, valueFontSize: 8.5)
        case 2:
            return (iconSize: 12, iconTextSize: 7.5, valueFontSize: 9)
        default:
            return (iconSize: 13, iconTextSize: 8, valueFontSize: 10)
        }
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
