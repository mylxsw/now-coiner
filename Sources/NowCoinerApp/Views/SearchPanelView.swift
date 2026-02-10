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
            PanelHeader(title: L10n.tr("search.title"), onClose: onClose)

            VStack(spacing: 0) {
                AppKitTextField(
                    text: $searchVM.query,
                    placeholder: L10n.tr("search.placeholder"),
                    onTextChanged: {
                        searchVM.handleQueryChange()
                    }
                )
                .frame(height: 28)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)

                Divider()

                ScrollView {
                    LazyVStack(spacing: 0) {
                        ForEach(searchVM.results.prefix(120), id: \.id) { coin in
                            row(coin: coin)
                            Divider().padding(.leading, 56)
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
                    .font(.body.weight(.medium))
                    .foregroundStyle(NowCoinerColors.textPrimary)
                    .lineLimit(1)
                Text(coin.symbol.uppercased())
                    .font(.caption)
                    .foregroundStyle(NowCoinerColors.textSecondary)
                    .lineLimit(1)
            }

            Spacer()

            if searchVM.isAdded(coin.id, watchlist: viewModel.watchlist) {
                Text(L10n.tr("search.added"))
                    .font(.caption)
                    .foregroundStyle(NowCoinerColors.textSecondary)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.white.opacity(0.08))
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            } else {
                Button {
                    Task {
                        await viewModel.addCoin(coin)
                    }
                } label: {
                    Text(L10n.tr("search.add"))
                }
                .buttonStyle(.borderedProminent)
                .controlSize(.small)
            }
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 9)
    }
}
