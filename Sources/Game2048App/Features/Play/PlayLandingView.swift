import SwiftUI

struct PlayLandingView: View {
    @ObservedObject var model: GameViewModel
    @Environment(\.colorScheme) private var colorScheme
    let play: () -> Void

    var body: some View {
        VStack(spacing: 18) {
            VStack(alignment: .leading, spacing: 8) {
                Text("2048")
                    .font(.system(size: 58, weight: .black, design: .rounded))
                    .tracking(-2.5)
                    .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("Combine matching tiles and reach 2048.")
                    .font(.system(size: 17, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
                    .frame(maxWidth: .infinity, alignment: .center)
                Text("\(model.boardSize) × \(model.boardSize) board · arrow keys to move")
                    .font(.system(size: 13, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
                    .frame(maxWidth: .infinity, alignment: .center)
            }
            .padding(.bottom, 4)

            Button(action: play) {
                Label("Play", systemImage: "play.fill")
                    .font(.system(size: 16, weight: .semibold, design: .rounded))
                    .foregroundStyle(.white)
                    .frame(width: 220, height: 52)
                    .background(AppTheme.accent, in: RoundedRectangle(cornerRadius: 14, style: .continuous))
                    .contentShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
            }
            .buttonStyle(.plain)
            .keyboardShortcut(.defaultAction)

            HStack(spacing: 12) {
                homeMetric("BEST SCORE", value: model.bestScore.formatted(), symbol: "star.fill")
                homeMetric("GAMES WON", value: model.statistics.gamesWon.formatted(), symbol: "trophy.fill")
            }
            .frame(maxWidth: 440)
        }
        .padding(28)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
        .background(AppTheme.background(colorScheme == .dark).ignoresSafeArea())
    }

    private func homeMetric(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppTheme.accent)
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))
            Text(title)
                .font(.system(size: 10, weight: .bold, design: .rounded))
                .tracking(1)
                .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(18)
        .background(
            AppTheme.surface(colorScheme == .dark), in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(AppTheme.border(colorScheme == .dark), lineWidth: 1)
        }
    }

}
