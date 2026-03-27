import SwiftUI
import Charts
import NowCoinerCore

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
                ProgressView(L10n.tr("common.loading"))
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
                Text(L10n.tr("common.load_failed"))
                    .foregroundStyle(NowCoinerColors.textSecondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .frame(width: 360, height: 520)
        .background(NowCoinerColors.panel)
        .task {
            await loadDetail()
        }
    }

    private var titleBar: some View {
        HStack {
            Text(L10n.tr("detail.title"))
                .font(.headline)
                .foregroundStyle(NowCoinerColors.textPrimary)
            Spacer()
            Button(L10n.tr("common.close")) { dismiss() }.buttonStyle(.bordered)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 8)
        .background(NowCoinerColors.groupedPanel)
    }

    private func loadDetail() async {
        isLoading = true
        defer { isLoading = false }
        detail = await viewModel.fetchCoinDetail(coinID: coinID)
    }

    private func header(detail: CoinDetail) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("\(detail.name) (\(detail.symbol.uppercased()))")
                .font(.title3.weight(.semibold))
                .foregroundStyle(NowCoinerColors.textPrimary)
            Text(PriceFormatter.currency(detail.currentPrice, code: viewModel.settings.vsCurrency))
                .font(.title2.weight(.semibold))
                .foregroundStyle(NowCoinerColors.textPrimary)
            Text(PriceFormatter.percent(detail.priceChangePercentage24h))
                .foregroundStyle(detail.priceChangePercentage24h >= 0 ? NowCoinerColors.green : NowCoinerColors.red)
                .font(.subheadline.weight(.medium))
        }
    }

    private var sparklineCard: some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                if let values = viewModel.sparklines[coinID]?.prices, values.count >= 2 {
                    Chart(Array(values.enumerated()), id: \.offset) { index, value in
                        LineMark(
                            x: .value("Index", index),
                            y: .value("Price", value)
                        )
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))
                        .foregroundStyle(NowCoinerColors.blue)
                    }
                    .chartXAxis(.hidden)
                    .chartYAxis(.hidden)
                    .frame(height: 120)
                } else {
                    Text(L10n.tr("detail.no_chart_data"))
                        .font(.subheadline)
                        .foregroundStyle(NowCoinerColors.textSecondary)
                }
            }
        } label: {
            Text(L10n.tr("detail.sparkline_7d"))
                .font(.subheadline.weight(.semibold))
        }
    }

    private func marketCard(detail: CoinDetail) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                keyValue(L10n.tr("detail.market_cap"), PriceFormatter.currency(detail.marketCap, code: viewModel.settings.vsCurrency))
                keyValue(L10n.tr("detail.rank"), "#\(detail.marketCapRank)")
                keyValue(L10n.tr("detail.volume_24h"), PriceFormatter.currency(detail.totalVolume, code: viewModel.settings.vsCurrency))
                keyValue(L10n.tr("detail.high_24h"), PriceFormatter.currency(detail.high24h, code: viewModel.settings.vsCurrency))
                keyValue(L10n.tr("detail.low_24h"), PriceFormatter.currency(detail.low24h, code: viewModel.settings.vsCurrency))
            }
        } label: {
            Text(L10n.tr("detail.market_data"))
                .font(.subheadline.weight(.semibold))
        }
    }

    private func linksCard(detail: CoinDetail) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                linkRow(L10n.tr("detail.website"), detail.homepage)
                linkRow(L10n.tr("detail.whitepaper"), detail.whitepaper)
                linkRow("Reddit", detail.subredditURL)
                linkRow("GitHub", detail.githubRepos.first)
            }
        } label: {
            Text(L10n.tr("detail.links"))
                .font(.subheadline.weight(.semibold))
        }
    }

    private func developerCard(detail: CoinDetail) -> some View {
        GroupBox {
            VStack(alignment: .leading, spacing: 8) {
                keyValue("Stars", detail.githubStars.map(String.init) ?? "--")
                keyValue("Forks", detail.githubForks.map(String.init) ?? "--")
                keyValue(L10n.tr("detail.commits_4w"), detail.commitCount4Weeks.map(String.init) ?? "--")
            }
        } label: {
            Text(L10n.tr("detail.developer_data"))
                .font(.subheadline.weight(.semibold))
        }
    }

    private func keyValue(_ key: String, _ value: String) -> some View {
        HStack {
            Text(key)
                .foregroundStyle(NowCoinerColors.textSecondary)
            Spacer()
            Text(value)
                .foregroundStyle(NowCoinerColors.textPrimary)
        }
        .font(.subheadline.weight(.medium))
    }

    @ViewBuilder
    private func linkRow(_ title: String, _ value: String?) -> some View {
        if let url = URLSafety.validatedExternalWebURL(from: value) {
            Link(title, destination: url)
                .font(.subheadline.weight(.medium))
        }
    }
}
