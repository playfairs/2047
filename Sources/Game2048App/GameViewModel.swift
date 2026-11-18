import Foundation
import OSLog
import SwiftUI

#if SWIFT_PACKAGE
import Game2048Core
#endif

@MainActor
final class GameViewModel: ObservableObject {
    @Published private(set) var game = GameEngine()
    @Published private(set) var bestScore: Int
    @Published private(set) var continuedAfterWin = false
    @Published private(set) var statistics: PlayerStatistics
    @Published private(set) var movesThisGame = 0
    @Published private(set) var mergesThisGame = 0

    private let bestScoreKey = "bestScore"
    private let statisticsKey = "playerStatistics"
    private static let logger = Logger(
        subsystem: Bundle.main.bundleIdentifier ?? "2048",
        category: "statistics"
    )
    private var gameStartedAt: Date
    private var elapsedBeforeSegment: TimeInterval = 0
    private var timerIsRunning = true
    private var hasRecordedOutcome = false

    init() {
        bestScore = UserDefaults.standard.integer(forKey: bestScoreKey)
        statistics = Self.loadStatistics()
        gameStartedAt = Date()
        statistics.gamesStarted += 1
        statistics.totalTilesSpawned += 2
        statistics.highestTile = max(statistics.highestTile, game.tiles.max() ?? 0)
        persistStatistics()
    }

    var isShowingWin: Bool {
        game.hasReached2048 && !continuedAfterWin
    }

    func elapsedTime(at date: Date = .now) -> TimeInterval {
        elapsedBeforeSegment
            + (timerIsRunning ? max(0, date.timeIntervalSince(gameStartedAt)) : 0)
    }

    func move(_ direction: MoveDirection) {
        guard !game.isGameOver, !isShowingWin else { return }
        var updatedGame = game
        let result = updatedGame.move(direction)
        guard result.changed else { return }
        let moveDate = Date()
        game = updatedGame
        movesThisGame += 1
        mergesThisGame += result.mergeCount
        statistics.totalMoves += 1
        statistics.totalMerges += result.mergeCount
        statistics.totalPoints += result.scoreGained
        statistics.totalTilesSpawned += result.spawnedTile == nil ? 0 : 1
        statistics.highestTile = max(statistics.highestTile, game.tiles.max() ?? 0)
        updateBestScore()

        if result.reached2048 {
            recordWin(at: moveDate)
        }
        if game.isGameOver {
            if !hasRecordedOutcome {
                recordLoss(at: moveDate)
            }
            pauseTimer(at: moveDate)
        }
        persistStatistics()
    }

    func continuePlaying() {
        continuedAfterWin = true
        resumeTimer(at: Date())
    }

    func startNewGame() {
        let startDate = Date()
        if timerIsRunning {
            pauseTimer(at: startDate)
            if !hasRecordedOutcome {
                statistics.gamesAbandoned += 1
            }
        }
        game = GameEngine()
        continuedAfterWin = false
        movesThisGame = 0
        mergesThisGame = 0
        gameStartedAt = startDate
        elapsedBeforeSegment = 0
        timerIsRunning = true
        hasRecordedOutcome = false
        statistics.gamesStarted += 1
        statistics.totalTilesSpawned += 2
        statistics.highestTile = max(statistics.highestTile, game.tiles.max() ?? 0)
        persistStatistics()
    }

    private func updateBestScore() {
        guard game.score > bestScore else { return }
        bestScore = game.score
        UserDefaults.standard.set(bestScore, forKey: bestScoreKey)
    }

    private func recordWin(at date: Date) {
        guard !hasRecordedOutcome else { return }
        hasRecordedOutcome = true
        statistics.gamesWon += 1
        statistics.currentWinStreak += 1
        statistics.bestWinStreak = max(statistics.bestWinStreak, statistics.currentWinStreak)
        let elapsed = elapsedTime(at: date)
        if let fastestWin = statistics.fastestWin {
            statistics.fastestWin = min(fastestWin, elapsed)
        } else {
            statistics.fastestWin = elapsed
        }
        pauseTimer(at: date)
    }

    private func recordLoss(at date: Date) {
        guard !hasRecordedOutcome else { return }
        hasRecordedOutcome = true
        statistics.gamesLost += 1
        statistics.currentWinStreak = 0
        pauseTimer(at: date)
    }

    private func pauseTimer(at date: Date) {
        guard timerIsRunning else { return }
        let segment = max(0, date.timeIntervalSince(gameStartedAt))
        elapsedBeforeSegment += segment
        statistics.totalPlayTime += segment
        timerIsRunning = false
    }

    private func resumeTimer(at date: Date) {
        guard !timerIsRunning else { return }
        gameStartedAt = date
        timerIsRunning = true
    }

    private func persistStatistics() {
        do {
            let data = try JSONEncoder().encode(statistics)
            UserDefaults.standard.set(data, forKey: statisticsKey)
        } catch {
            Self.logger.error("Could not save player statistics: \(String(describing: error), privacy: .public)")
        }
    }

    private static func loadStatistics() -> PlayerStatistics {
        guard let data = UserDefaults.standard.data(forKey: "playerStatistics") else {
            return PlayerStatistics()
        }
        do {
            return try JSONDecoder().decode(PlayerStatistics.self, from: data)
        } catch {
            logger.error("Could not load player statistics: \(String(describing: error), privacy: .public)")
            return PlayerStatistics()
        }
    }
}
