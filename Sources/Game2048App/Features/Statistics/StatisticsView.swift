import SwiftUI

private struct StatisticItem: Identifiable {
    let title: String
    let value: String
    let symbol: String

    var id: String { title }
}

struct StatisticsView: View {
    @ObservedObject var model: GameViewModel
    @Environment(\.horizontalSizeClass) private var horizontalSizeClass
    @Environment(\.colorScheme) private var colorScheme

    private var columns: [GridItem] {
        let count = horizontalSizeClass == .regular ? 3 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 12), count: count)
    }

    var body: some View {
        TimelineView(.periodic(from: .now, by: 1)) { context in
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    overview
                    section(
                        "This game",
                        items: [
                            StatisticItem(
                                title: "Elapsed",
                                value: formattedGameTime(model.elapsedTime(at: context.date)),
                                symbol: "timer"
                            ),
                            StatisticItem(
                                title: "Score", value: model.game.score.formatted(), symbol: "plus"),
                            StatisticItem(
                                title: "Moves", value: model.movesThisGame.formatted(),
                                symbol: "arrow.left.arrow.right"),
                            StatisticItem(
                                title: "Merges", value: model.mergesThisGame.formatted(),
                                symbol: "square.2.layers.3d"),
                            StatisticItem(
                                title: "Top tile",
                                value: (model.game.tiles.max() ?? 0).formatted(),
                                symbol: "arrow.up.forward"
                            ),
                        ])

                    section("All time", items: allTimeItems)
                }
                .frame(maxWidth: 960, alignment: .leading)
                .padding(24)
                .frame(maxWidth: .infinity, alignment: .topLeading)
            }
            .scrollIndicators(.hidden)
        }
        .background(AppTheme.background(colorScheme == .dark).ignoresSafeArea())
        #if os(macOS)
            .frame(minWidth: 520, minHeight: 560)
        #endif
    }

    private var overview: some View {
        HStack(spacing: 12) {
            overviewCard("Games", value: model.statistics.gamesStarted.formatted(), symbol: "square.grid.2x2")
            overviewCard("Wins", value: model.statistics.gamesWon.formatted(), symbol: "trophy.fill")
            overviewCard("Best score", value: model.bestScore.formatted(), symbol: "star.fill")
        }
    }

    private func overviewCard(_ title: String, value: String, symbol: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Image(systemName: symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(red: 0.67, green: 0.50, blue: 0.30))
            Text(value)
                .font(.system(size: 24, weight: .bold, design: .rounded))
                .monospacedDigit()
                .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))
                .lineLimit(1)
                .minimumScaleFactor(0.7)
            Text(title)
                .font(.system(size: 12, weight: .medium, design: .rounded))
                .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
        }
        .frame(maxWidth: .infinity, minHeight: 112, alignment: .leading)
        .padding(16)
        .background(
            AppTheme.surface(colorScheme == .dark), in: RoundedRectangle(cornerRadius: 20, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .strokeBorder(AppTheme.border(colorScheme == .dark), lineWidth: 1)
        }
    }

    private var allTimeItems: [StatisticItem] {
        let stats = model.statistics
        let completedGames = stats.gamesWon + stats.gamesLost
        let winRate =
            completedGames == 0
            ? 0
            : Int((Double(stats.gamesWon) / Double(completedGames) * 100).rounded())

        return [
            StatisticItem(title: "Games started", value: stats.gamesStarted.formatted(), symbol: "play"),
            StatisticItem(title: "Wins", value: stats.gamesWon.formatted(), symbol: "trophy"),
            StatisticItem(title: "Losses", value: stats.gamesLost.formatted(), symbol: "xmark"),
            StatisticItem(
                title: "Abandoned", value: stats.gamesAbandoned.formatted(), symbol: "arrow.uturn.backward"),
            StatisticItem(title: "Win rate", value: "\(winRate)%", symbol: "chart.pie"),
            StatisticItem(title: "Best score", value: model.bestScore.formatted(), symbol: "star"),
            StatisticItem(
                title: "Highest tile", value: stats.highestTile.formatted(), symbol: "arrow.up.forward"),
            StatisticItem(
                title: "Total moves", value: stats.totalMoves.formatted(), symbol: "arrow.left.arrow.right"),
            StatisticItem(
                title: "Total merges", value: stats.totalMerges.formatted(), symbol: "square.2.layers.3d"),
            StatisticItem(
                title: "Tiles spawned", value: stats.totalTilesSpawned.formatted(), symbol: "plus.square"),
            StatisticItem(title: "Points earned", value: stats.totalPoints.formatted(), symbol: "sparkle"),
            StatisticItem(
                title: "Time played", value: formattedGameTime(stats.totalPlayTime), symbol: "clock"),
            StatisticItem(
                title: "Fastest win",
                value: stats.fastestWin.map(formattedGameTime) ?? "—",
                symbol: "bolt"
            ),
            StatisticItem(
                title: "Current streak", value: stats.currentWinStreak.formatted(), symbol: "flame"),
            StatisticItem(title: "Best streak", value: stats.bestWinStreak.formatted(), symbol: "flame.fill"),
        ]
    }

    private func section(_ title: String, items: [StatisticItem]) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.system(size: 19, weight: .bold, design: .rounded))
                .tracking(1.2)
                .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))

            LazyVGrid(columns: columns, spacing: 12) {
                ForEach(items) { item in
                    statisticCard(item)
                }
            }
        }
    }

    private func statisticCard(_ item: StatisticItem) -> some View {
        HStack(spacing: 12) {
            Image(systemName: item.symbol)
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color(red: 0.67, green: 0.50, blue: 0.30))
                .frame(width: 24)

            VStack(alignment: .leading, spacing: 3) {
                Text(item.title)
                    .font(.system(size: 12, weight: .medium, design: .rounded))
                    .foregroundStyle(AppTheme.secondaryText(colorScheme == .dark))
                Text(item.value)
                    .font(.system(size: 18, weight: .bold, design: .rounded))
                    .monospacedDigit()
                    .contentTransition(.numericText())
                    .foregroundStyle(AppTheme.primaryText(colorScheme == .dark))
                    .lineLimit(1)
                    .minimumScaleFactor(0.75)
            }
            Spacer(minLength: 0)
        }
        .padding(.horizontal, 14)
        .frame(maxWidth: .infinity, minHeight: 70, alignment: .leading)
        .background(
            AppTheme.surface(colorScheme == .dark), in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppTheme.border(colorScheme == .dark), lineWidth: 1)
        }
    }
}
