import SwiftUI
import Charts
import NowCoinerCore

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

    @State private var isHovered = false

    var body: some View {
        HStack(spacing: 12) {
            iconView

            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Text(row.coin.symbol.uppercased())
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(NowCoinerColors.textPrimary)
                    if row.isPinned {
                        Image(systemName: "pin.fill")
                            .font(.system(size: 9))
                            .foregroundStyle(NowCoinerColors.textSecondary)
                    }
                }
                Text(row.coin.name)
                    .font(.system(size: 11, weight: .regular))
                    .foregroundStyle(NowCoinerColors.textSecondary)
                    .lineLimit(1)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            VStack(alignment: .trailing, spacing: 3) {
                Text(priceText)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(NowCoinerColors.textPrimary)

                Text(changeText)
                    .font(.system(size: 11, weight: .medium))
                    .foregroundStyle(changeColor)

                if let sparkline = row.sparkline?.prices, sparkline.count >= 2 {
                    MiniSparklineView(prices: sparkline, color: changeColor)
                        .frame(width: 86, height: 18)
                }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 12)
        .background(backgroundFill)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(borderColor, lineWidth: row.isSelected ? 1 : 0.5)
        )
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .contentShape(RoundedRectangle(cornerRadius: 8))
        .onTapGesture(perform: onTap)
        .onHover { isHovered = $0 }
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

    private var backgroundFill: Color {
        if row.isSelected {
            return NowCoinerColors.selectionFill
        }
        return isHovered ? NowCoinerColors.secondaryPanel.opacity(0.45) : Color.clear
    }

    private var borderColor: Color {
        row.isSelected ? NowCoinerColors.selectionStroke : NowCoinerColors.divider.opacity(0.15)
    }

    private var iconView: some View {
        Circle()
            .fill(iconFill)
            .frame(width: 32, height: 32)
            .overlay(
                Text(iconText)
                    .font(.system(size: 16, weight: .bold))
                    .foregroundStyle(.white)
            )
    }

    private var iconFill: AnyShapeStyle {
        if row.coin.symbol.lowercased() == "sol" {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(hex: "9945FF"), Color(hex: "14F195")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(iconColor)
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
            return NowCoinerColors.textSecondary
        }

        switch colorScheme {
        case .greenUpRedDown:
            return value >= 0 ? NowCoinerColors.green : NowCoinerColors.red
        case .redUpGreenDown:
            return value >= 0 ? NowCoinerColors.red : NowCoinerColors.green
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
