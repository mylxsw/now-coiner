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
        VStack(spacing: 0) {
            titleBar

            if isLoading {
                ProgressView("加载中...")
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if let detail {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        header(detail: detail)
                        sparklineCard
                        marketCard(detail: detail)
                        linksCard(detail: detail)
                        developerCard(detail: detail)
                    }
                    .padding(12)
                }
            } else {
                Text("加载失败")
                    .foregroundStyle(TickerPadColors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 360, height: 520)
        .background(TickerPadColors.panel)
        .task {
            await loadDetail()
        }
    }

    private var titleBar: some View {
        HStack {
            Text("币种详情")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(TickerPadColors.textPrimary)
            Spacer()
            Button("关闭") { dismiss() }
                .buttonStyle(.plain)
                .foregroundStyle(TickerPadColors.textSecondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(TickerPadColors.secondaryPanel)
    }

    private func loadDetail() async {
        isLoading = true
        defer { isLoading = false }
        detail = await viewModel.fetchCoinDetail(coinID: coinID)
    }

    private func header(detail: CoinDetail) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(detail.name) (\(detail.symbol.uppercased()))")
                .font(.system(size: 18, weight: .bold))
                .foregroundStyle(TickerPadColors.textPrimary)
            Text(PriceFormatter.currency(detail.currentPrice, code: viewModel.settings.vsCurrency))
                .font(.system(size: 24, weight: .semibold))
                .foregroundStyle(TickerPadColors.textPrimary)
            Text(PriceFormatter.percent(detail.priceChangePercentage24h))
                .foregroundStyle(detail.priceChangePercentage24h >= 0 ? TickerPadColors.green : TickerPadColors.red)
                .font(.system(size: 12, weight: .medium))
        }
    }

    private var sparklineCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("7 天走势")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(TickerPadColors.textPrimary)

            if let values = viewModel.sparklines[coinID]?.prices, values.count >= 2 {
                Chart(Array(values.enumerated()), id: \.offset) { index, value in
                    LineMark(
                        x: .value("Index", index),
                        y: .value("Price", value)
                    )
                    .interpolationMethod(.catmullRom)
                    .lineStyle(StrokeStyle(lineWidth: 2))
                    .foregroundStyle(TickerPadColors.blue)
                }
                .chartXAxis(.hidden)
                .chartYAxis(.hidden)
                .frame(height: 120)
            } else {
                Text("暂无图表数据")
                    .font(.system(size: 12))
                    .foregroundStyle(TickerPadColors.textSecondary)
            }
        }
        .padding(12)
        .background(TickerPadColors.secondaryPanel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func marketCard(detail: CoinDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("市场数据")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(TickerPadColors.textPrimary)
            keyValue("市值", PriceFormatter.currency(detail.marketCap, code: viewModel.settings.vsCurrency))
            keyValue("排名", "#\(detail.marketCapRank)")
            keyValue("24h 交易量", PriceFormatter.currency(detail.totalVolume, code: viewModel.settings.vsCurrency))
            keyValue("24h 高", PriceFormatter.currency(detail.high24h, code: viewModel.settings.vsCurrency))
            keyValue("24h 低", PriceFormatter.currency(detail.low24h, code: viewModel.settings.vsCurrency))
        }
        .padding(12)
        .background(TickerPadColors.secondaryPanel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func linksCard(detail: CoinDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("外部链接")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(TickerPadColors.textPrimary)
            linkRow("官网", detail.homepage)
            linkRow("白皮书", detail.whitepaper)
            linkRow("Reddit", detail.subredditURL)
            linkRow("GitHub", detail.githubRepos.first)
        }
        .padding(12)
        .background(TickerPadColors.secondaryPanel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func developerCard(detail: CoinDetail) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("开发者数据")
                .font(.system(size: 13, weight: .semibold))
                .foregroundStyle(TickerPadColors.textPrimary)
            keyValue("Stars", detail.githubStars.map(String.init) ?? "--")
            keyValue("Forks", detail.githubForks.map(String.init) ?? "--")
            keyValue("近四周提交", detail.commitCount4Weeks.map(String.init) ?? "--")
        }
        .padding(12)
        .background(TickerPadColors.secondaryPanel)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    private func keyValue(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .foregroundStyle(TickerPadColors.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(TickerPadColors.textPrimary)
        }
        .font(.system(size: 12, weight: .medium))
    }

    @ViewBuilder
    private func linkRow(_ title: String, _ value: String?) -> some View {
        if let value, let url = URL(string: value), !value.isEmpty {
            Link(title, destination: url)
                .font(.system(size: 12, weight: .medium))
        }
    }
}
