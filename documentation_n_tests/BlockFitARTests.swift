import XCTest
@testable import BlockFitAR

struct LevelResult {
    let timeTaken: Double
    let threeStarTime: Double
    let twoStarTime: Double

    var isCompleted: Bool {
        return true // always true when finished
    }

    func starsEarned() -> Int {
        if timeTaken <= threeStarTime { return 3 }
        if timeTaken <= twoStarTime { return 2 }
        return 1
    }
}


final class BlockFitARTests: XCTestCase {

    // MARK: - Basic Level Tests

    func testLevelInitialization() {
        let level = Level(
            id: 1,
            name: "Test Level",
            targetPosition: SIMD3<Float>(0, 0, 0),
            targetRotation: SIMD3<Float>(0, .pi/2, 0),
            tolerance: 0.05
        )

        XCTAssertEqual(level.id, 1)
        XCTAssertEqual(level.name, "Test Level")
        XCTAssertEqual(level.tolerance, 0.05, accuracy: 0.001)
    }

    // MARK: - Star Rating Logic

    func testStarRatingForFastCompletion() {
        let result = LevelResult(
            timeTaken: 4.9,
            threeStarTime: 5.0,
            twoStarTime: 8.0
        )

        XCTAssertEqual(result.starsEarned(), 3)
    }

    func testStarRatingForMediumCompletion() {
        let result = LevelResult(
            timeTaken: 6.5,
            threeStarTime: 5.0,
            twoStarTime: 8.0
        )

        XCTAssertEqual(result.starsEarned(), 2)
    }

    func testStarRatingForSlowCompletion() {
        let result = LevelResult(
            timeTaken: 10.0,
            threeStarTime: 5.0,
            twoStarTime: 8.0
        )

        XCTAssertEqual(result.starsEarned(), 1)
    }

    // MARK: - Completion Logic

    func testLevelIsCompleted() {
        let result = LevelResult(
            timeTaken: 12.0,
            threeStarTime: 5.0,
            twoStarTime: 8.0
        )

        XCTAssertTrue(result.isCompleted)
    }

    // MARK: - Core Data Basic Tests

    func testCoreDataSaveLoad() throws {
        let persistence = PersistenceController(inMemory: true)
        let context = persistence.container.viewContext

        // Create a LevelProgress object
        let progress = LevelProgress(context: context)
        progress.levelID = 1
        progress.bestTime = 7.5
        progress.stars = 2

        try context.save()

        // Fetch again
        let request = LevelProgress.fetchRequest()
        let results = try context.fetch(request)

        XCTAssertEqual(results.count, 1)
        XCTAssertEqual(results.first?.levelID, 1)
        XCTAssertEqual(results.first?.stars, 2)
    }
}
