import SwiftUI

struct PanelSurface<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0, content: content)
            .frame(width: width, height: height)
            .background(.regularMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(NowCoinerColors.divider.opacity(0.8), lineWidth: 1)
            )
    }
}

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
        .background(NowCoinerColors.groupedPanel)
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
