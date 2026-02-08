import SwiftUI
import TickerPadCore

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
        VStack(spacing: 0) {
            titleBar

            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(TickerPadColors.textSecondary)

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
            .background(TickerPadColors.secondaryPanel)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(searchVM.results.prefix(120), id: \.id) { coin in
                        row(coin: coin)
                        Divider()
                            .overlay(TickerPadColors.divider.opacity(0.35))
                            .padding(.leading, 56)
                    }
                }
                .padding(.vertical, 8)
            }
        }
        .frame(width: 300, height: 460)
        .background(TickerPadColors.panel)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }

    private var titleBar: some View {
        HStack {
            Text("添加币种")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TickerPadColors.textPrimary)
            Spacer()
            Button(action: onClose) {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(TickerPadColors.textSecondary)
                    .frame(width: 20, height: 20)
                    .background(TickerPadColors.secondaryPanel)
                    .clipShape(Circle())
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(TickerPadColors.secondaryPanel)
    }

    private func row(coin: Coin) -> some View {
        HStack(spacing: 12) {
            Circle()
                .fill(Color(hex: "3A3A3C"))
                .frame(width: 32, height: 32)
                .overlay(
                    Text(String(coin.symbol.uppercased().prefix(1)))
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(coin.name)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(TickerPadColors.textPrimary)
                Text(coin.symbol.uppercased())
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(TickerPadColors.textSecondary)
            }

            Spacer()

            if searchVM.isAdded(coin.id, watchlist: viewModel.watchlist) {
                Text("已添加")
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(TickerPadColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(TickerPadColors.secondaryPanel)
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
                        .background(TickerPadColors.blue)
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
                .buttonStyle(.plain)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
    }
}
