import SwiftUI

struct TrialBadgeView: View {
    var body: some View {
        Text(L10n.tr("trial.badge"))
            .font(.caption2.weight(.semibold))
            .foregroundStyle(NowCoinerColors.textPrimary)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(Color.white.opacity(0.08))
            .clipShape(Capsule())
    }
}

struct TrialModeFooterView: View {
    let isVisible: Bool
    let message: String

    var body: some View {
        if isVisible {
            Divider()

            HStack(spacing: 10) {
                TrialBadgeView()

                Text(message)
                    .font(.caption)
                    .foregroundStyle(NowCoinerColors.textSecondary)
                    .lineLimit(2)

                Spacer(minLength: 0)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .background(NowCoinerColors.groupedPanel)
        }
    }
}
