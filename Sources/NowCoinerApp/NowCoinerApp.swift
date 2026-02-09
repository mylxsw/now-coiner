import SwiftUI
import AppKit
import NowCoinerCore

@main
struct NowCoinerApp: App {
    @StateObject private var viewModel: TickerViewModel

    @State private var statusBarRightClickMonitor: StatusBarRightClickMonitor?
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
        L10n.setLanguage(viewModel.settings.appLanguage)
        configureStatusBarRightClick()
        LaunchAtLoginManager.apply(enabled: viewModel.settings.launchAtLogin)
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

        MenuAnchorResolver.endMenuTracking()
        MenuAnchorResolver.closeAllAppWindows()

        settingsPanelController.close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            searchPanelController.show(anchor: anchor, panelSize: CGSize(width: 300, height: 460)) {
                SearchPanelView(viewModel: viewModel, onClose: {
                    searchPanelController.close()
                })
                .preferredColorScheme(preferredColorScheme)
            }
        }
    }

    private func openSettingsFromMenu() {
        let anchor = MenuAnchorResolver.currentAnchor()

        MenuAnchorResolver.endMenuTracking()
        MenuAnchorResolver.closeAllAppWindows()

        searchPanelController.close()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.06) {
            settingsPanelController.show(anchor: anchor, panelSize: CGSize(width: 340, height: 500)) {
                SettingsView(viewModel: viewModel, onClose: {
                    settingsPanelController.close()
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
        nil
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
            return L10n.tr("app.name")
        }

        let parts: [String] = rows.compactMap { row in
            guard let price = row.price else { return nil }
            return PriceFormatter.menuBarText(
                symbol: row.coin.symbol,
                price: price.currentPrice,
                changePercent: price.priceChangePercent24h,
                currencyCode: viewModel.settings.vsCurrency,
                style: viewModel.settings.menuBarDisplayStyle
            )
        }

        return parts.isEmpty ? L10n.tr("app.name") : parts.joined(separator: " | ")
    }

    private var iconModeLabel: some View {
        Group {
            if let combinedImage {
                Image(nsImage: combinedImage)
            } else {
                Text(L10n.tr("app.name"))
                    .font(.system(size: 12, weight: .regular))
            }
        }
        .onAppear {
            // 初始加载
            Task { @MainActor in
                await refreshMenuBarIcons()
                updateCombinedImage()
            }
        }
        .onChange(of: viewModel.menuBarRows) { _, _ in
            // 数据变化时更新
            updateCombinedImage()
        }
        .onChange(of: iconMap) { _, _ in
            // 图标加载后更新
            updateCombinedImage()
        }
        .onChange(of: viewModel.settings.menuBarDisplayStyle) { _, _ in
            updateCombinedImage()
        }
    }

    @State private var combinedImage: NSImage?

    private func updateCombinedImage() {
        let rows = Array(viewModel.menuBarRows.prefix(3))
        guard !rows.isEmpty else {
            combinedImage = nil
            return
        }

        let metrics = iconMetrics(for: rows.count)
        combinedImage = drawCombinedImage(rows: rows, metrics: metrics)
    }

    private func drawCombinedImage(rows: [CoinRowState], metrics: (iconSize: CGFloat, iconTextSize: CGFloat, valueFontSize: CGFloat)) -> NSImage {
        let spacing: CGFloat = 8
        let innerSpacing: CGFloat = 4
        
        // 1. 准备数据和测量尺寸
        var items: [(icon: NSImage, text: NSAttributedString, width: CGFloat)] = []
        var totalWidth: CGFloat = 0
        
        for (index, row) in rows.enumerated() {
            // 准备图标
            let icon = iconMap[row.coin.id] ?? fallbackIconImage(for: row.coin, metrics: metrics)
            
            // 准备文字
            let textString = iconModeValueText(for: row.price)
            let font = NSFont.monospacedDigitSystemFont(ofSize: metrics.valueFontSize, weight: .regular)
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font,
                .foregroundColor: NSColor.labelColor // 自动适配深浅色模式
            ]
            let attrText = NSAttributedString(string: textString, attributes: attributes)
            let textSize = attrText.size()
            
            // 计算单个 Item 宽度
            let itemWidth = metrics.iconSize + innerSpacing + textSize.width
            items.append((icon, attrText, itemWidth))
            
            // 累加总宽度
            totalWidth += itemWidth
            if index < rows.count - 1 {
                totalWidth += spacing
            }
        }
        
        // 2. 开始绘制
        // 高度稍微多给一点点以容纳字体可能的溢出，通常18-22足够
        let height: CGFloat = 22 
        let image = NSImage(size: NSSize(width: totalWidth, height: height), flipped: false) { rect in
            var currentX: CGFloat = 0
            
            for (index, item) in items.enumerated() {
                // 绘制图标 (垂直居中)
                let iconY = (height - metrics.iconSize) / 2
                let iconRect = NSRect(x: currentX, y: iconY, width: metrics.iconSize, height: metrics.iconSize)
                item.icon.draw(in: iconRect)
                
                // 绘制文字 (垂直居中)
                let textY = (height - item.text.size().height) / 2 + 0.5 // +0.5 微调视觉平衡
                let textRect = NSRect(x: currentX + metrics.iconSize + innerSpacing, y: textY, width: item.text.size().width, height: item.text.size().height)
                item.text.draw(in: textRect)
                
                // 更新 X 坐标
                currentX += item.width
                if index < items.count - 1 {
                    currentX += spacing
                }
            }
            return true
        }
        
        image.isTemplate = false
        return image
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
        // 只有当图标缓存真正改变时才更新，避免无限循环
        if next != iconMap {
            iconMap = next
        }
    }

    private func fallbackIconImage(for coin: Coin, metrics: (iconSize: CGFloat, iconTextSize: CGFloat, valueFontSize: CGFloat)) -> NSImage {
        let size = metrics.iconSize
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            NSColor(deviceRed: 60/255, green: 60/255, blue: 62/255, alpha: 1.0).set()
            NSBezierPath(ovalIn: rect).fill()
            
            let letter = String(coin.symbol.uppercased().prefix(1))
            let attributes: [NSAttributedString.Key: Any] = [
                .font: NSFont.systemFont(ofSize: metrics.iconTextSize, weight: .bold),
                .foregroundColor: NSColor.white
            ]
            let string = NSAttributedString(string: letter, attributes: attributes)
            let stringSize = string.size()
            let drawPoint = NSPoint(
                x: (size - stringSize.width) / 2,
                y: (size - stringSize.height) / 2
            )
            string.draw(at: drawPoint)
            return true
        }
        image.isTemplate = false
        return image
    }

    private func resizedMenuBarImage(from source: NSImage, size: CGFloat) -> NSImage {
        let image = NSImage(size: NSSize(width: size, height: size), flipped: false) { rect in
            let path = NSBezierPath(ovalIn: rect)
            path.addClip()
            NSGraphicsContext.current?.imageInterpolation = .high
            source.draw(in: rect, from: NSRect(origin: .zero, size: source.size), operation: .sourceOver, fraction: 1.0)
            return true
        }
        image.isTemplate = false
        return image
    }


    private func iconMetrics(for count: Int) -> (iconSize: CGFloat, iconTextSize: CGFloat, valueFontSize: CGFloat) {
        switch count {
        case 3...:
            return (iconSize: 13, iconTextSize: 8.5, valueFontSize: 11)
        case 2:
            return (iconSize: 14.5, iconTextSize: 9.5, valueFontSize: 12)
        default:
            return (iconSize: 16, iconTextSize: 10.5, valueFontSize: 13.5)
        }
    }
}

private struct MenuBarTickerTextView: View {
    let rows: [CoinRowState]
    let currencyCode: String
    let style: MenuBarStyle

    var body: some View {
        Group {
            if rows.isEmpty {
                Text(L10n.tr("app.name"))
            } else {
                HStack(spacing: 0) {
                    ForEach(Array(rows.enumerated()), id: \.element.id) { index, row in
                        MenuBarTickerTextSegment(row: row, currencyCode: currencyCode, style: style)
                        if index < rows.count - 1 {
                            Text(" | ")
                        }
                    }
                }
            }
        }
        .font(.system(size: 12, weight: .regular))
        .monospacedDigit()
        .lineLimit(1)
        .truncationMode(.tail)
        .transaction { tx in
            tx.animation = nil
        }
    }
}

private struct MenuBarTickerTextSegment: View {
    let row: CoinRowState
    let currencyCode: String
    let style: MenuBarStyle

    var body: some View {
        if let price = row.price {
            switch style {
            case .priceOnly:
                Text(PriceFormatter.compactCurrency(price.currentPrice, code: currencyCode))
                    .contentTransition(.numericText())
            case .symbolAndPrice:
                HStack(spacing: 0) {
                    Text("\(row.coin.symbol.uppercased()) ")
                    Text(PriceFormatter.compactCurrency(price.currentPrice, code: currencyCode))
                        .contentTransition(.numericText())
                }
            case .symbolAndChange:
                HStack(spacing: 0) {
                    Text("\(row.coin.symbol.uppercased()) ")
                    Text(PriceFormatter.percent(price.priceChangePercent24h))
                        .contentTransition(.numericText())
                }
            case .full:
                HStack(spacing: 0) {
                    Text("\(row.coin.symbol.uppercased()) ")
                    Text(PriceFormatter.compactCurrency(price.currentPrice, code: currencyCode))
                        .contentTransition(.numericText())
                    Text(" ")
                    Text(PriceFormatter.percent(price.priceChangePercent24h))
                        .contentTransition(.numericText())
                }
            }
        } else {
            Text("--")
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
        nil
    }
}
