import SwiftUI
import AppKit
import TickerPadCore

struct MainPanelView: View {
    @ObservedObject var viewModel: TickerViewModel
    @Binding var showingSearch: Bool
    @Binding var showingSettings: Bool
    @State private var detailCoinID: CoinDetailSheetItem?

    var body: some View {
        VStack(spacing: 0) {
            header
            Divider().overlay(Color(hex: "2C2C2E"))

            if viewModel.visibleRows.isEmpty {
                emptyView
            } else {
                ScrollView {
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
                                    Task { await viewModel.togglePin(coinID: row.coin.id) }
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
        .frame(width: 320, height: 420)
        .background(Color(hex: "1C1C1E"))
        .onMoveCommand(perform: handleMoveCommand)
        .onDeleteCommand(perform: removeSelected)
        .onExitCommand {
            viewModel.selectedCoinID = nil
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
    }

    private var resolvedColorScheme: ColorScheme? {
        switch viewModel.settings.appearanceMode {
        case .light: return .light
        case .dark: return .dark
        case .system: return nil
        }
    }

    private var header: some View {
        HStack(spacing: 8) {
            Text("TickerPad")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
                .accessibilityAddTraits(.isHeader)

            Spacer()

            Button {
                showingSearch = true
            } label: {
                Image(systemName: "plus")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "8E8E93"))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Add Coin")

            Button {
                showingSettings = true
            } label: {
                Image(systemName: "gearshape")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color(hex: "8E8E93"))
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Open Settings")
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }

    private var emptyView: some View {
        VStack(spacing: 10) {
            Text("暂无币种")
                .foregroundStyle(.white)
                .font(.system(size: 14, weight: .semibold))
            Text("点击右上角 + 添加你关注的币种")
                .foregroundStyle(Color(hex: "8E8E93"))
                .font(.system(size: 11))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
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
