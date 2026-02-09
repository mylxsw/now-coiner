import SwiftUI
import NowCoinerCore

struct SearchPanelView: View {
    @ObservedObject var viewModel: TickerViewModel
    let onClose: () -> Void
    @StateObject private var searchVM: SearchViewModel

    init(viewModel: TickerViewModel, onClose: @escaping () -> Void) {
        self.viewModel = viewModel
        self.onClose = onClose
        _searchVM = StateObject(wrappedValue: SearchViewModel(allCoins: viewModel.coins))
    }

    var body: some View {
        PanelSurface(width: 300, height: 460) {
            PanelHeader(title: "添加币种", onClose: onClose)

            VStack(spacing: 0) {
                HStack(spacing: 8) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundStyle(NowCoinerColors.textSecondary)

                    AppKitTextField(
                        text: $searchVM.query,
                        placeholder: "搜索币种名称或代号",
                        onTextChanged: {
                            searchVM.handleQueryChange()
                        }
                    )
                    .frame(height: 22)
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 10)
                .background(NowCoinerColors.secondaryPanel)

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(searchVM.results.prefix(120), id: \.id) { coin in
                            row(coin: coin)
                            Divider()
                                .overlay(NowCoinerColors.divider.opacity(0.35))
                                .padding(.leading, 56)
                        }
                    }
                    .padding(.vertical, 8)
                }
            }
        }
    }

    private func row(coin: Coin) -> some View {
        HStack(spacing: 12) {
            CoinIconView(coin: coin, size: 32)

            VStack(alignment: .leading, spacing: 2) {
                Text(coin.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(NowCoinerColors.textPrimary)
                    .lineLimit(1)
                Text(coin.symbol.uppercased())
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(NowCoinerColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if searchVM.isAdded(coin.id, watchlist: viewModel.watchlist) {
                Text("已添加")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(NowCoinerColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(NowCoinerColors.secondaryPanel)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Button {
                    Task {
                        await viewModel.addCoin(coin)
                    }
                } label: {
                    Text("Add")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(NowCoinerColors.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
