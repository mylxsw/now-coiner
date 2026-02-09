import SwiftUI

struct PanelSurface<Content: View>: View {
    let width: CGFloat
    let height: CGFloat
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(spacing: 0, content: content)
            .frame(width: width, height: height)
            .background(NowCoinerColors.panel)
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
            .overlay(
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .stroke(NowCoinerColors.divider.opacity(0.6), lineWidth: 1)
            )
    }
}

struct PanelHeader<Trailing: View>: View {
    let title: String
    @ViewBuilder let trailing: () -> Trailing

    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(NowCoinerColors.textPrimary)
            Spacer()
            trailing()
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 11)
        .background(NowCoinerColors.secondaryPanel)
        .overlay(alignment: .bottom) {
            Divider().overlay(NowCoinerColors.divider)
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

    var body: some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(NowCoinerColors.textSecondary)
                .frame(width: 22, height: 22)
                .background(NowCoinerColors.panel.opacity(0.65))
                .clipShape(Circle())
        }
        .buttonStyle(.plain)
    }
}
