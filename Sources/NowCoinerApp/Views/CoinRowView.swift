import SwiftUI
import Charts
import NowCoinerCore

struct CoinRowView: View {
    let row: CoinRowState
    let currencyCode: String
    let colorScheme: PriceColorScheme
    let watchlistEditingEnabled: Bool
    let onTap: () -> Void
    let onPinToggle: () -> Void
    let onOpenDetail: () -> Void
    let onMoveTop: () -> Void
    let onRemove: () -> Void
    let onOpenTradingView: () -> Void
    let onOpenExchange: () -> Void

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(row.coin.symbol.uppercased())
                        .font(.headline)
                        .foregroundStyle(NowCoinerColors.textPrimary)
                    if row.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.caption2)
                            .foregroundStyle(NowCoinerColors.textSecondary)
                    }
                }
                Text(row.coin.name)
                    .font(.caption)
                    .foregroundStyle(NowCoinerColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 3) {
                Text(priceText)
                    .font(.headline)
                    .foregroundStyle(NowCoinerColors.textPrimary)

                Text(changeText)
                    .font(.caption)
                    .foregroundStyle(changeColor)

                if let sparkline = row.sparkline?.prices, sparkline.count >= 2 {
                    MiniSparklineView(prices: sparkline, color: changeColor)
                        .frame(width: 86, height: 18)
                }
            }
        }
        .padding(.vertical, 9)
        .padding(.horizontal, 10)
        .background(backgroundFill)
        .overlay(
            RoundedRectangle(cornerRadius: 7)
                .stroke(borderColor, lineWidth: row.isSelected ? 1 : 0)
        )
        .clipShape(RoundedRectangle(cornerRadius: 7))
        .contentShape(RoundedRectangle(cornerRadius: 7))
        .onTapGesture(perform: onTap)
        .onHover { isHovered = $0 }
        .contextMenu {
            Button(row.isPinned ? L10n.tr("coin_row.unpin") : L10n.tr("coin_row.pin"), action: onPinToggle)
                .disabled(!watchlistEditingEnabled)
            Button(L10n.tr("coin_row.about", row.coin.name), action: onOpenDetail)
            Divider()
            Button(L10n.tr("coin_row.move_top"), action: onMoveTop)
                .disabled(!watchlistEditingEnabled)
            Button(L10n.tr("coin_row.view_tradingview"), action: onOpenTradingView)
            Button(L10n.tr("coin_row.view_exchange"), action: onOpenExchange)
            Divider()
            Button(L10n.tr("coin_row.remove"), role: .destructive, action: onRemove)
                .disabled(!watchlistEditingEnabled)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint(L10n.tr("coin_row.accessibility.hint"))
    }

    private var backgroundFill: Color {
        if row.isSelected {
            return NowCoinerColors.selectionFill
        }
        return isHovered ? Color.white.opacity(0.08) : Color.clear
    }

    private var borderColor: Color {
        row.isSelected ? NowCoinerColors.selectionStroke : Color.clear
    }

    private var iconView: some View {
        CoinIconView(coin: row.coin, size: 32)
    }

    private var priceText: String {
        guard let currentPrice = row.price?.currentPrice else { return "--" }
        return PriceFormatter.currency(currentPrice, code: currencyCode)
    }

    private var changeText: String {
        guard let change = row.price?.priceChangePercent24h else { return "--" }
        return PriceFormatter.percent(change)
    }

    private var accessibilitySummary: String {
        let price: String
        if let currentPrice = row.price?.currentPrice {
            price = PriceFormatter.currency(currentPrice, code: currencyCode)
        } else {
            price = L10n.tr("coin_row.unknown_price")
        }

        let change: String
        if let currentChange = row.price?.priceChangePercent24h {
            change = PriceFormatter.percent(currentChange)
        } else {
            change = L10n.tr("coin_row.unknown_change")
        }

        return L10n.tr("coin_row.accessibility.summary", row.coin.name, row.coin.symbol.uppercased(), price, change)
    }

    private var changeColor: Color {
        guard let value = row.price?.priceChangePercent24h else {
            return NowCoinerColors.textSecondary
        }

        switch colorScheme {
        case .greenUpRedDown:
            return value >= 0 ? NowCoinerColors.green : NowCoinerColors.red
        case .redUpGreenDown:
            return value >= 0 ? NowCoinerColors.red : NowCoinerColors.green
        }
    }

}

private struct MiniSparklineView: View {
    let prices: [Double]
    let color: Color

    var body: some View {
        Chart(Array(prices.enumerated()), id: \.offset) { index, value in
            LineMark(
                x: .value("Index", index),
                y: .value("Price", value)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 1.6, lineCap: .round))
            .foregroundStyle(color)

            AreaMark(
                x: .value("Index", index),
                y: .value("Price", value)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [color.opacity(0.18), color.opacity(0.02)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartPlotStyle { plot in
            plot.background(.clear)
        }
    }
}
