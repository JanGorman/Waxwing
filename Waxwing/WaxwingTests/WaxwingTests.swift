//
//  Created by Jan Gorman on 05/02/15.
//  Copyright (c) 2015 Jan Gorman. All rights reserved.
//

import UIKit
import XCTest
import Waxwing

class MockUserDefaults: UserDefaults {
    
    let migratedToKey = "com.schnaub.Waxwing.migratedTo"
    var version: String?
    
    override func setValue(_ value: AnyObject?, forKey key: String) {
        if key == migratedToKey {
            version = value as? String
        }
    }
    
    override func value(forKey key: String) -> AnyObject? {
        if key == migratedToKey {
            return version
        }
        return nil
    }
    
}

class MockBundle: Bundle {
  
  override func objectForInfoDictionaryKey(_ key: String) -> AnyObject? {
    if key == "CFBundleShortVersionString" {
      return "1.0.0"
    }
    return nil
  }
    
}

class WaxwingTests: XCTestCase {
    
    private static let KeyPath = "completedUnitCount"
  
    private lazy var observerContext = UnsafeMutablePointer<Void>(allocatingCapacity: 1)
    
    private var waxwing: Waxwing!
    private var progress: Progress?
    private var unitCount: Int!
    private var KVOAssertion = false
    
    override func setUp() {
        super.setUp()
        
        let mockBundle = MockBundle()
        let mockDefaults = MockUserDefaults()
        
        waxwing = Waxwing(bundle: mockBundle, defaults: mockDefaults)
    }
    
    override func tearDown() {
        super.tearDown()

        progress?.removeObserver(self, forKeyPath: WaxwingTests.KeyPath, context: observerContext)
        observerContext.deallocateCapacity(1)
    }
    
    // MARK: Blocks
    
    func test_whenVersionIsGreaterThanAppVersion_itDoesNotMigrate() {
        var didMigrate = false
        waxwing.migrateToVersion("1.0.1") {
            didMigrate = true
        }
        
        XCTAssertFalse(didMigrate)
    }
    
    func test_whenVersionIsLessThanAppVersion_itDoesMigrate() {
        var didMigrate = false
        waxwing.migrateToVersion("0.9") {
            didMigrate = true
        }
        
        XCTAssertTrue(didMigrate)
    }
    
    func test_whenMigratingMultipleVersion_itMigratesAll() {
        var migrationCount = 0
        waxwing.migrateToVersion("0.8") {
            migrationCount += 1
        }
        
        waxwing.migrateToVersion("0.9") {
            migrationCount += 1
        }
        
        XCTAssertEqual(migrationCount, 2)
    }
    
    func test_whenVersionEqualsAppVersion_itDoesMigrate() {
        var didMigrate = false
        waxwing.migrateToVersion("1.0") {
            didMigrate = true
        }
        
        XCTAssertTrue(didMigrate)
    }
    
    func test_whenVersionMigratingSameVersionTwice_itOnlyRunsOnce() {
        var migrationCount = 0
        waxwing.migrateToVersion("1.0") {
            migrationCount += 1
        }
        
        waxwing.migrateToVersion("1.0") {
            migrationCount += 1
        }
        
        XCTAssertEqual(migrationCount, 1)
    }
    
    // MARK: Queue
    
    func test_whenVersionIsGreaterThanAppVersionWithQueue_itDoesNotMigrate() {
        var didMigrate = false
        
        let migration = Operation()
        migration.completionBlock = {
            didMigrate = true
        }
        
        waxwing.migrateToVersion("1.0.1", migrations: [migration])
        
        XCTAssertFalse(didMigrate)
    }
    
    func test_whenVersionIsLessThanAppVersionWithQueue_itDoesMigrate() {
        let expectation = self.expectation(withDescription: "Migrate Queue")
        
        var didMigrate = false
        let migration = Operation()
        migration.completionBlock = {
            didMigrate = true
        }
        let verification = Operation()
        verification.addDependency(migration)
        verification.completionBlock = {
            expectation.fulfill()
        }
        
        waxwing.migrateToVersion("0.9", migrations: [migration, verification])

        waitForExpectations(withTimeout: 0.5) {
            _  in
            XCTAssertTrue(didMigrate)
        }
    }
    
    func test_whenMigratingMultipleVersionWithQueue_itMigratesAll() {
        let expectation = self.expectation(withDescription: "Migrate Queue")
        
        var migrationCount = 0
        let migration = Operation()
        migration.completionBlock = {
            migrationCount += 1
        }
        
        waxwing.migrateToVersion("0.8", migrations: [migration])
        
        let secondMigration = Operation()
        secondMigration.completionBlock = {
            migrationCount += 1
        }
        
        let verification = Operation()
        verification.addDependency(secondMigration)
        verification.completionBlock = {
            expectation.fulfill()
        }

        waxwing.migrateToVersion("0.9", migrations: [secondMigration, verification])

        waitForExpectations(withTimeout: 0.5) {
            _  in
            XCTAssertEqual(migrationCount, 2)
        }
    }
    
}
