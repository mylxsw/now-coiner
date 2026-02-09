import SwiftUI
import AppKit
import NowCoinerCore

struct MainPanelView: View {
    @ObservedObject var viewModel: TickerViewModel
    let onOpenSearch: () -> Void
    let onOpenSettings: () -> Void
    @State private var detailCoinID: CoinDetailSheetItem?
    @State private var showPinLimitNotice = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                header

                if viewModel.visibleRows.isEmpty {
                    emptyView
                } else {
                    ScrollView {
                        ScrollViewBehaviorConfigurator()
                            .frame(height: 0)
                            .allowsHitTesting(false)

                        LazyVStack(spacing: 6) {
                            ForEach(viewModel.visibleRows) { row in
                                CoinRowView(
                                    row: row,
                                    currencyCode: viewModel.settings.vsCurrency,
                                    colorScheme: viewModel.settings.priceColorScheme,
                                    onTap: {
                                        viewModel.selectionToggle(coinID: row.coin.id)
                                    },
                                    onPinToggle: {
                                        let success = viewModel.togglePin(coinID: row.coin.id)
                                        if !success { showPinLimitNotice = true }
                                    },
                                    onOpenDetail: {
                                        detailCoinID = CoinDetailSheetItem(coinID: row.coin.id)
                                    },
                                    onMoveTop: {
                                        Task { await viewModel.moveCoinToTop(coinID: row.coin.id) }
                                    },
                                    onRemove: {
                                        Task { await viewModel.removeCoin(coinID: row.coin.id) }
                                    },
                                    onOpenTradingView: {
                                        openTradingView(for: row.coin)
                                    },
                                    onOpenExchange: {
                                        openExchange(for: row.coin)
                                    }
                                )
                            }
                        }
                        .padding(.horizontal, 8)
                        .padding(.vertical, 8)
                    }
                    .accessibilityLabel("Crypto Watchlist")
                }
            }

            if showPinLimitNotice {
                PinLimitOverlay(
                    maxPinnedCount: TickerViewModel.maxPinnedCount,
                    onConfirm: { showPinLimitNotice = false }
                )
                .transition(.opacity)
            }
        }
        .animation(.easeOut(duration: 0.12), value: showPinLimitNotice)
        .frame(width: 320, height: 420)
        .background(NowCoinerColors.panel)
        .onMoveCommand(perform: handleMoveCommand)
        .onDeleteCommand(perform: removeSelected)
        .onExitCommand {
            if showPinLimitNotice {
                showPinLimitNotice = false
            } else {
                viewModel.selectedCoinID = nil
            }
        }
        .background {
            Button("Open Selected Detail", action: openSelectedDetail)
                .keyboardShortcut(.return, modifiers: [])
                .hidden()
        }
        .popover(item: $detailCoinID, arrowEdge: .top) { item in
            CoinDetailView(viewModel: viewModel, coinID: item.coinID)
                .preferredColorScheme(resolvedColorScheme)
        }
        .task(id: prefetchIdentity) {
            await CoinIconCache.shared.prefetch(coins: viewModel.visibleRows.map(\.coin))
        }
    }

    private var resolvedColorScheme: ColorScheme? {
        switch viewModel.settings.appearanceMode {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    private var header: some View {
        PanelHeader(title: "NowCoiner") {
            HStack(spacing: 8) {
                PanelIconButton(systemName: "plus", action: onOpenSearch)
                .accessibilityLabel("Add Coin")

                PanelIconButton(systemName: "gearshape", action: onOpenSettings)
                .accessibilityLabel("Open Settings")
            }
        }
        .accessibilityAddTraits(.isHeader)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Text("暂无币种")
                .foregroundStyle(NowCoinerColors.textPrimary)
                .font(.system(size: 14, weight: .semibold))
            Text("点击右上角 + 添加你关注的币种")
                .foregroundStyle(NowCoinerColors.textSecondary)
                .font(.system(size: 11))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    private var prefetchIdentity: String {
        viewModel.visibleRows.map { "\($0.coin.id)|\($0.coin.imageURL ?? "")" }.joined(separator: ",")
    }

    private func handleMoveCommand(_ direction: MoveCommandDirection) {
        switch direction {
        case .down:
            viewModel.selectNextRow()
        case .up:
            viewModel.selectPreviousRow()
        default:
            break
        }
    }

    private func removeSelected() {
        guard let selected = viewModel.selectedCoinID else { return }
        Task {
            await viewModel.removeCoin(coinID: selected)
        }
    }

    private func openSelectedDetail() {
        guard let selected = viewModel.selectedCoinForDetail() else { return }
        detailCoinID = CoinDetailSheetItem(coinID: selected)
    }

    private func openTradingView(for coin: Coin) {
        guard let url = ExchangeURLBuilder.tradingView(symbol: coin.symbol, exchange: viewModel.settings.defaultExchange) else { return }
        NSWorkspace.shared.open(url)
    }

    private func openExchange(for coin: Coin) {
        guard let url = ExchangeURLBuilder.exchange(symbol: coin.symbol, coinID: coin.id, exchange: viewModel.settings.defaultExchange) else { return }
        NSWorkspace.shared.open(url)
    }
}

private struct CoinDetailSheetItem: Identifiable {
    let coinID: String
    var id: String { coinID }
}

private struct PinLimitOverlay: View {
    let maxPinnedCount: Int
    let onConfirm: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.18)
                .ignoresSafeArea()
                .onTapGesture {
                    onConfirm()
                }

            VStack(alignment: .leading, spacing: 14) {
                Text("置顶数量已达上限")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NowCoinerColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)

                Text("最多只能置顶 \(maxPinnedCount) 个币种，请先取消其他币种的置顶")
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(NowCoinerColors.textPrimary.opacity(0.95))
                    .fixedSize(horizontal: false, vertical: true)

                Button(action: onConfirm) {
                    Text("确定")
                        .font(.system(size: 13, weight: .semibold))
                        .frame(maxWidth: .infinity, minHeight: 38)
                        .background(Color.white.opacity(0.12))
                        .clipShape(Capsule())
                        .contentShape(Capsule())
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 18)
            .frame(width: 220)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .stroke(Color.white.opacity(0.1), lineWidth: 1)
            )
        }
    }
}

private struct ScrollViewBehaviorConfigurator: NSViewRepresentable {
    func makeNSView(context: Context) -> NSView {
        NSView(frame: .zero)
    }

    func updateNSView(_ nsView: NSView, context: Context) {
        DispatchQueue.main.async {
            guard let scrollView = enclosingScrollView(of: nsView) else { return }
            scrollView.autohidesScrollers = true
            scrollView.scrollerStyle = .overlay
            scrollView.hasVerticalScroller = true
            scrollView.verticalScrollElasticity = .automatic
            scrollView.horizontalScrollElasticity = .none
            scrollView.hasHorizontalScroller = false
        }
    }

    private func enclosingScrollView(of view: NSView) -> NSScrollView? {
        var parent = view.superview
        while let current = parent {
            if let scroll = current as? NSScrollView {
                return scroll
            }
            parent = current.superview
        }
        return nil
    }
}
