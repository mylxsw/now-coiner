import SwiftUI

struct PanelSurface<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0, content: content)
            .frame(width: width - 2, height: height - 2)
            .background {
                RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: [
                                        Color.white.opacity(0.12),
                                        Color.clear
                                    ],
                                    startPoint: .top,
                                    endPoint: .center
                                )
                            )
                    )
            }
            .clipShape(RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: panelCornerRadius, style: .continuous)
                    .stroke(Color.white.opacity(0.22), lineWidth: 0.8)
            )
            .shadow(color: .black.opacity(0.14), radius: 14, x: 0, y: 8)
            .frame(width: width, height: height)
    }
}

private var panelCornerRadius: CGFloat { PanelMetrics.cornerRadius }

struct PanelHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack {
            Text(title)
                .font(.headline)
                .foregroundStyle(NowCoinerColors.textPrimary)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .background(Color.white.opacity(0.05))
        .overlay(alignment: .bottom) {
            Divider()
        }
    }
}

extension PanelHeader where Trailing == PanelCloseButton {
    init(title: String, onClose: @escaping () -> Void) {
        self.title = title
        self.trailing = { PanelCloseButton(action: onClose) }
    }
}

struct PanelCloseButton: View {
    let action: () -> Void

    var body: some View {
        PanelIconButton(systemName: "xmark", action: action)
    }
}

struct PanelIconButton: View {
    let systemName: String
    let action: () -> Void
    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(NowCoinerColors.textSecondary)
                .frame(width: 24, height: 24)
                .background(isHovered ? NowCoinerColors.hoverFill : Color.clear)
                .clipShape(RoundedRectangle(cornerRadius: 6, style: .continuous))
        }
        .buttonStyle(.plain)
        .onHover { isHovered = $0 }
    }
}
