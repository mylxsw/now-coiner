import SwiftUI
import Charts
import TickerPadCore

struct CoinDetailView: View {
    @ObservedObject var viewModel: TickerViewModel
    let coinID: String

    @Environment(\.dismiss) private var dismiss
    @State private var detail: CoinDetail?
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            Group {
                if isLoading {
                    ProgressView("加载中...")
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                } else if let detail {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 16) {
                            header(detail: detail)
                            sparklineCard
                            marketCard(detail: detail)
                            linksCard(detail: detail)
                            developerCard(detail: detail)
                        }
                        .padding(16)
                    }
                } else {
                    Text("加载失败")
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, maxHeight: .infinity)
                }
            }
            .navigationTitle("币种详情")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("关闭") { dismiss() }
                }
            }
        }
        .frame(width: 420, height: 620)
        .task {
            await loadDetail()
        }
    }

    private func loadDetail() async {
        isLoading = true
        defer { isLoading = false }
        detail = await viewModel.fetchCoinDetail(coinID: coinID)
    }

    private func header(detail: CoinDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("\(detail.name) (\(detail.symbol.uppercased()))")
                .font(.system(size: 18, weight: .bold))
            Text(PriceFormatter.currency(detail.currentPrice, code: viewModel.settings.vsCurrency))
                .font(.system(size: 24, weight: .semibold))
            Text(PriceFormatter.percent(detail.priceChangePercentage24h))
                .foregroundStyle(detail.priceChangePercentage24h >= 0 ? Color(hex: "34C759") : Color(hex: "FF453A"))
        }
    }

    private var sparklineCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7 天走势")
                .font(.system(size: 14, weight: .semibold))

            if let values = viewModel.sparklines[coinID]?.prices, values.count >= 2 {
                Chart(Array(values.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Price", value)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                }
                .frame(height: 140)
            } else {
                Text("暂无图表数据")
                    .font(.system(size: 12))
                    .foregroundStyle(.secondary)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func marketCard(detail: CoinDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("市场数据")
                .font(.system(size: 14, weight: .semibold))
            keyValue("市值", PriceFormatter.currency(detail.marketCap, code: viewModel.settings.vsCurrency))
            keyValue("排名", "#\(detail.marketCapRank)")
            keyValue("24h 交易量", PriceFormatter.currency(detail.totalVolume, code: viewModel.settings.vsCurrency))
            keyValue("24h 高", PriceFormatter.currency(detail.high24h, code: viewModel.settings.vsCurrency))
            keyValue("24h 低", PriceFormatter.currency(detail.low24h, code: viewModel.settings.vsCurrency))
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func linksCard(detail: CoinDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("外部链接")
                .font(.system(size: 14, weight: .semibold))
            if let homepage = detail.homepage, let url = URL(string: homepage) {
                Link("官网", destination: url)
            }
            if let whitepaper = detail.whitepaper, let url = URL(string: whitepaper) {
                Link("白皮书", destination: url)
            }
            if let sub = detail.subredditURL, let url = URL(string: sub) {
                Link("Reddit", destination: url)
            }
            if let firstGitHub = detail.githubRepos.first, let url = URL(string: firstGitHub) {
                Link("GitHub", destination: url)
            }
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func developerCard(detail: CoinDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("开发者数据")
                .font(.system(size: 14, weight: .semibold))
            keyValue("Stars", detail.githubStars.map(String.init) ?? "--")
            keyValue("Forks", detail.githubForks.map(String.init) ?? "--")
            keyValue("近四周提交", detail.commitCount4Weeks.map(String.init) ?? "--")
        }
        .padding(12)
        .background(Color.gray.opacity(0.1))
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func keyValue(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
        }
        .font(.system(size: 12, weight: .medium))
    }
}
