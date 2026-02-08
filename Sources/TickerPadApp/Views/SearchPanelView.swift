import SwiftUI
import TickerPadCore

struct SearchPanelView: View {
    @ObservedObject var viewModel: TickerViewModel
    @StateObject private var searchVM: SearchViewModel
    @Environment(\.dismiss) private var dismiss

    init(viewModel: TickerViewModel) {
        self.viewModel = viewModel
        _searchVM = StateObject(wrappedValue: SearchViewModel(allCoins: viewModel.coins))
    }

    var body: some View {
        VStack(spacing: 0) {
            HStack(spacing: 8) {
                Image(systemName: "magnifyingglass")
                    .foregroundStyle(Color(hex: "8E8E93"))
                TextField("搜索币种名称或代号", text: $searchVM.query)
                    .textFieldStyle(.plain)
                    .foregroundStyle(.white)
                    .font(.system(size: 14, weight: .regular))
                    .onChange(of: searchVM.query) {
                        searchVM.handleQueryChange()
                    }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(Color(hex: "2C2C2E"))

            List(searchVM.results.prefix(100), id: \.id) { coin in
                HStack(spacing: 12) {
                    Circle()
                        .fill(Color(hex: "3A3A3C"))
                        .frame(width: 32, height: 32)
                        .overlay(Text(String(coin.symbol.uppercased().prefix(1))).foregroundStyle(.white))

                    VStack(alignment: .leading, spacing: 2) {
                        Text(coin.name)
                            .font(.system(size: 14, weight: .medium))
                            .foregroundStyle(.white)
                        Text(coin.symbol.uppercased())
                            .font(.system(size: 11, weight: .regular))
                            .foregroundStyle(Color(hex: "8E8E93"))
                    }

                    Spacer()

                    if searchVM.isAdded(coin.id, watchlist: viewModel.watchlist) {
                        Text("已添加")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color(hex: "8E8E93"))
                    } else {
                        Button("Add") {
                            Task {
                                await viewModel.addCoin(coin)
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(Color(hex: "007AFF"))
                    }
                }
                .padding(.vertical, 4)
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
        }
        .frame(width: 280, height: 440)
        .background(Color(hex: "1C1C1E"))
        .onExitCommand(perform: dismiss.callAsFunction)
    }
}
