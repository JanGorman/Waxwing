//
//  Created by Jan Gorman on 05/02/15.
//  Copyright (c) 2015 Jan Gorman. All rights reserved.
//

import UIKit
import XCTest
import Waxwing

class WaxwingTests: XCTestCase {

    override func tearDown() {
        NSUserDefaults.standardUserDefaults().removeObjectForKey("com.schnaub.Waxwing.migratedTo")
        NSUserDefaults.standardUserDefaults().synchronize()
        super.tearDown()
    }

    // MARK: Blocks

    func test_whenVersionIsGreaterThanAppVersion_itDoesNotMigrate() {
        var didMigrate = false
        Waxwing.migrateToVersion("1.0.1") {
            didMigrate = true
        }

        XCTAssertFalse(didMigrate)
    }

    func test_whenVersionIsLessThanAppVersion_itDoesMigrate() {
        var didMigrate = false
        Waxwing.migrateToVersion("0.9") {
            didMigrate = true
        }

        XCTAssertTrue(didMigrate)
    }

    func test_whenMigratingMultipleVersion_itMigratesAll() {
        var migrationCount = 0
        Waxwing.migrateToVersion("0.8") {
            migrationCount += 1
        }

        Waxwing.migrateToVersion("0.9") {
            migrationCount += 1
        }

        XCTAssertEqual(migrationCount, 2)
    }

    func test_whenVersionEqualsAppVersion_itDoesMigrate() {
        var didMigrate = false
        Waxwing.migrateToVersion("1.0") {
            didMigrate = true
        }

        XCTAssertTrue(didMigrate)
    }

    func test_whenVersionMigratingSameVersionTwice_itOnlyRunsOnce() {
        var migrationCount = 0
        Waxwing.migrateToVersion("1.0") {
            migrationCount += 1
        }

        Waxwing.migrateToVersion("1.0") {
            migrationCount += 1
        }

        XCTAssertEqual(migrationCount, 1)
    }

    // MARK: Queue

    func test_whenVersionIsGreaterThanAppVersionWithQueue_itDoesNotMigrate() {
        var didMigrate = false

        let migration = NSOperation()
        migration.completionBlock = {
            didMigrate = true
        }

        Waxwing.migrateToVersion("1.0.1", migrations: [migration])

        XCTAssertFalse(didMigrate)
    }

    func test_whenVersionIsLessThanAppVersionWithQueue_itDoesMigrate() {
        let expectation = expectationWithDescription("Migrate Queue")

        var didMigrate = false
        let migration = NSOperation()
        migration.completionBlock = {
            didMigrate = true
        }
        let verification = NSOperation()
        verification.addDependency(migration)
        verification.completionBlock = {
            expectation.fulfill()
        }

        Waxwing.migrateToVersion("0.9", migrations: [migration, verification])


        waitForExpectationsWithTimeout(0.5) {
            (_) in
            XCTAssertTrue(didMigrate)
        }
    }

    func test_whenMigratingMultipleVersionWithQueue_itMigratesAll() {
        let expectation = expectationWithDescription("Migrate Queue")

        var migrationCount = 0
        let migration = NSOperation()
        migration.completionBlock = {
            migrationCount += 1
        }

        Waxwing.migrateToVersion("0.8", migrations: [migration])

        let secondMigration = NSOperation()
        secondMigration.completionBlock = {
            migrationCount += 1
        }

        let verification = NSOperation()
        verification.addDependency(secondMigration)
        verification.completionBlock = {
            expectation.fulfill()
        }

        Waxwing.migrateToVersion("0.9", migrations: [secondMigration, verification])

        waitForExpectationsWithTimeout(0.5) {
            (_) in
            XCTAssertEqual(migrationCount, 2)
        }
    }

}
