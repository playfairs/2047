import Foundation

struct PlayerStatistics: Codable, Equatable {
    var gamesStarted = 0
    var gamesWon = 0
    var gamesLost = 0
    var gamesAbandoned = 0
    var totalMoves = 0
    var totalMerges = 0
    var totalPoints = 0
    var totalTilesSpawned = 0
    var highestTile = 0
    var totalPlayTime: TimeInterval = 0
    var fastestWin: TimeInterval?
    var currentWinStreak = 0
    var bestWinStreak = 0
}

func formattedGameTime(_ time: TimeInterval) -> String {
    let seconds = max(0, Int(time))
    let hours = seconds / 3_600
    let minutes = (seconds % 3_600) / 60
    let remainingSeconds = seconds % 60

    if hours > 0 {
        return String(format: "%d:%02d:%02d", hours, minutes, remainingSeconds)
    }
    return String(format: "%02d:%02d", seconds / 60, remainingSeconds)
}
