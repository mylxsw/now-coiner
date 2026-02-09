import SwiftUI
import AppKit
import NowCoinerCore

struct CoinIconView: View {
    let coin: Coin
    let size: CGFloat

    @StateObject private var loader = CoinIconLoader()

    var body: some View {
        Group {
            if let image = loader.image {
                Image(nsImage: image)
                    .resizable()
                    .scaledToFill()
            } else {
                Circle()
                    .fill(fallbackFill)
                    .overlay(
                        Text(fallbackText)
                            .font(.system(size: max(12, size * 0.45), weight: .bold))
                            .foregroundStyle(.white)
                    )
            }
        }
        .frame(width: size, height: size)
        .clipShape(Circle())
        .task(id: cacheIdentity) {
            loader.load(coinID: coin.id, imageURL: coin.imageURL)
        }
    }

    private var cacheIdentity: String {
        "\(coin.id)|\(coin.imageURL ?? "")"
    }

    private var fallbackFill: AnyShapeStyle {
        if coin.symbol.lowercased() == "sol" {
            return AnyShapeStyle(
                LinearGradient(
                    colors: [Color(hex: "9945FF"), Color(hex: "14F195")],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
        }
        return AnyShapeStyle(Color(hex: "3A3A3C"))
    }

    private var fallbackText: String {
        String(coin.symbol.uppercased().prefix(1))
    }
}
