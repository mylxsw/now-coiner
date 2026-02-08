import SwiftUI
import Charts
import TickerPadCore

struct CoinRowView: View {
    let row: CoinRowState
    let currencyCode: String
    let colorScheme: PriceColorScheme
    let onTap: () -> Void
    let onPinToggle: () -> Void
    let onOpenDetail: () -> Void
    let onMoveTop: () -> Void
    let onRemove: () -> Void
    let onOpenTradingView: () -> Void
    let onOpenExchange: () -> Void

    var body: some View {
        HStack(spacing: 12) {
            Circle()
                .fill(iconColor)
                .frame(width: 32, height: 32)
                .overlay(
                    Text(iconText)
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.white)
                )

            VStack(alignment: .leading, spacing: 2) {
                Text(row.coin.symbol.uppercased())
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)
                Text(row.coin.name)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(Color(hex: "8E8E93"))
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 2) {
                Text(priceText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(.white)

                Text(changeText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(changeColor)

                if let sparkline = row.sparkline?.prices, sparkline.count >= 2 {
                    MiniSparklineView(prices: sparkline, color: changeColor)
                        .frame(width: 50, height: 18)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(row.isSelected ? Color(hex: "9333EA33") : Color.clear)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(row.isSelected ? Color(hex: "9333EA") : Color.clear, lineWidth: 1)
        )
        .contentShape(Rectangle())
        .onTapGesture(perform: onTap)
        .contextMenu {
            Button(row.isPinned ? "Unpin" : "Pin", action: onPinToggle)
            Button("About \(row.coin.name)", action: onOpenDetail)
            Divider()
            Button("Move to top", action: onMoveTop)
            Button("View on TradingView", action: onOpenTradingView)
            Button("View on Exchange", action: onOpenExchange)
            Divider()
            Button("Remove from List", role: .destructive, action: onRemove)
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(accessibilitySummary)
        .accessibilityHint("Press Return to open detail, Delete to remove when selected")
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
            price = "Unknown price"
        }

        let change: String
        if let currentChange = row.price?.priceChangePercent24h {
            change = PriceFormatter.percent(currentChange)
        } else {
            change = "Unknown change"
        }

        return "\(row.coin.name), symbol \(row.coin.symbol.uppercased()), price \(price), change \(change)"
    }

    private var changeColor: Color {
        guard let value = row.price?.priceChangePercent24h else {
            return Color(hex: "8E8E93")
        }

        switch colorScheme {
        case .greenUpRedDown:
            return value >= 0 ? Color(hex: "34C759") : Color(hex: "FF453A")
        case .redUpGreenDown:
            return value >= 0 ? Color(hex: "FF453A") : Color(hex: "34C759")
        }
    }

    private var iconColor: Color {
        switch row.coin.symbol.lowercased() {
        case "btc": return Color(hex: "F7931A")
        case "eth": return Color(hex: "627EEA")
        case "bnb": return Color(hex: "F3BA2F")
        case "uni": return Color(hex: "FF007A")
        case "atom": return Color(hex: "2E3148")
        case "algo": return Color(hex: "000000")
        default: return Color(hex: "3A3A3C")
        }
    }

    private var iconText: String {
        switch row.coin.symbol.lowercased() {
        case "btc": return "₿"
        case "eth": return "Ξ"
        default: return String(row.coin.symbol.uppercased().prefix(1))
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
            .lineStyle(StrokeStyle(lineWidth: 1.5))
            .foregroundStyle(color)
        }
        .chartXAxis(.hidden)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartPlotStyle { plot in
            plot.background(.clear)
        }
    }
}
