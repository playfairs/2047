import Game2048Core
import XCTest

final class GameEngineTests: XCTestCase {
    func testNewGameStartsWithTwoTiles() {
        let game = GameEngine(random: { 1 })

        XCTAssertEqual(game.tiles.filter { $0 != 0 }.count, 2)
        XCTAssertEqual(game.tiles.filter { $0 == 2 }.count, 2)
        XCTAssertEqual(game.score, 0)
    }

    func testMoveMergesMatchingTilesAndAwardsPoints() {
        var game = GameEngine(tiles: [2, 2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

        let result = game.move(.left, random: predictableRandom())

        XCTAssertTrue(result.changed)
        XCTAssertEqual(result.scoreGained, 4)
        XCTAssertEqual(result.mergeCount, 1)
        XCTAssertEqual(game.score, 4)
        XCTAssertEqual(Array(game.tiles.prefix(4)), [4, 2, 2, 0])
        XCTAssertEqual(result.spawnedTile?.value, 2)
    }

    func testMergeDoesNotMergeTheSameTileTwiceInOneMove() {
        var game = GameEngine(tiles: [2, 2, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

        game.move(.left, random: predictableRandom())

        XCTAssertEqual(Array(game.tiles.prefix(4)), [4, 4, 2, 0])
        XCTAssertEqual(game.score, 4)
    }

    func testMergeCountIncludesEveryPairMergedInOneMove() {
        var game = GameEngine(tiles: [2, 2, 4, 4, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])

        let result = game.move(.left, random: predictableRandom())

        XCTAssertEqual(result.mergeCount, 2)
        XCTAssertEqual(result.scoreGained, 12)
        XCTAssertEqual(Array(game.tiles.prefix(4)), [4, 8, 2, 0])
    }

    func testRightAndDownMovesMergeTowardTheCorrectEdge() {
        var rightGame = GameEngine(tiles: [2, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        rightGame.move(.right, random: predictableRandom())

        XCTAssertEqual(Array(rightGame.tiles.prefix(4)), [2, 0, 0, 4])

        var downGame = GameEngine(tiles: [2, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        downGame.move(.down, random: predictableRandom())

        XCTAssertEqual(downGame.tiles[0], 2)
        XCTAssertEqual(downGame.tiles[12], 4)
    }

    func testTileIdentityFollowsMovesAndTheFirstMergedTileSurvives() {
        var movedGame = GameEngine(tiles: [0, 0, 0, 0, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        let movedID = movedGame.tileIDs[4]
        movedGame.move(.up, random: predictableRandom())

        XCTAssertEqual(movedGame.tileIDs[0], movedID)
        XCTAssertNotEqual(movedGame.tileIDs[4], movedID)

        var mergedGame = GameEngine(tiles: [2, 2, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        let survivingID = mergedGame.tileIDs[0]
        let mergedID = mergedGame.tileIDs[1]
        mergedGame.move(.left, random: predictableRandom())

        XCTAssertEqual(mergedGame.tileIDs[0], survivingID)
        XCTAssertNotEqual(mergedGame.tileIDs[0], mergedID)
    }

    func testUnchangedMoveDoesNotSpawnOrChangeScore() {
        var game = GameEngine(tiles: [2, 4, 8, 16, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0])
        let originalTiles = game.tiles

        let result = game.move(.left, random: predictableRandom())

        XCTAssertFalse(result.changed)
        XCTAssertNil(result.spawnedTile)
        XCTAssertEqual(game.tiles, originalTiles)
        XCTAssertEqual(game.score, 0)
    }

    func testWinningTileIsReportedOnceAndPlayCanContinue() {
        var game = GameEngine(
            tiles: [1024, 1024, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0],
            score: 1024
        )

        let result = game.move(.left, random: { 0 })

        XCTAssertTrue(result.reached2048)
        XCTAssertEqual(game.score, 3072)
        XCTAssertTrue(game.hasReached2048)
        XCTAssertFalse(game.isGameOver)
    }

    func testFullBoardWithoutMovesIsGameOver() {
        var game = GameEngine(
            tiles: [2, 4, 2, 4, 4, 2, 4, 2, 2, 4, 2, 4, 4, 2, 4, 2]
        )

        XCTAssertTrue(game.isGameOver)
        XCTAssertFalse(game.move(.left, random: { 1 }).changed)
    }

    private func predictableRandom() -> () -> Int {
        let values = [0, 1]
        var index = 0
        return {
            defer { index += 1 }
            return values[index % values.count]
        }
    }
}
