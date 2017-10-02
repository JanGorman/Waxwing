//
//  Copyright (c) 2017 Jan Gorman. All rights reserved.
//

import UIKit
import XCTest
import Waxwing

class MockUserDefaults: UserDefaults {
  
  let migratedToKey = "com.schnaub.Waxwing.migratedTo"
  var version: String?
  
  override func set(_ value: Any?, forKey defaultName: String) {
    guard defaultName == migratedToKey else { return }
    version = value as? String
  }
  
  override func string(forKey defaultName: String) -> String? {
    guard defaultName == migratedToKey else { return nil }
    return version
  }
  
}

class MockBundle: Bundle {
  
  override func object(forInfoDictionaryKey key: String) -> Any? {
    if key == "CFBundleShortVersionString" {
      return "1.0.0"
    }
    return nil
  }
  
}

class WaxwingTests: XCTestCase {
  
  fileprivate static let KeyPath = "completedUnitCount"
  
  fileprivate lazy var observerContext = UnsafeMutableRawPointer.allocate(bytes: 1, alignedTo: 0)
  
  fileprivate var waxwing: Waxwing!
  fileprivate var progress: Progress?
  fileprivate var unitCount: Int!
  fileprivate var KVOAssertion = false
  
  override func setUp() {
    super.setUp()
    
    let mockBundle = MockBundle()
    let mockDefaults = MockUserDefaults()
    
    waxwing = Waxwing(bundle: mockBundle, defaults: mockDefaults)
  }
  
  override func tearDown() {
    super.tearDown()
    
    progress?.removeObserver(self, forKeyPath: WaxwingTests.KeyPath, context: observerContext)
    observerContext.deallocate(bytes: 1, alignedTo: 0)
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
    let expectation = self.expectation(description: "Migrate Queue")
    
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
    
    waitForExpectations(timeout: 0.5) { _  in
      XCTAssertTrue(didMigrate)
    }
  }
  
  func test_whenMigratingMultipleVersionWithQueue_itMigratesAll() {
    let expectation = self.expectation(description: "Migrate Queue")
    
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
    
    waitForExpectations(timeout: 0.5) { _  in
      XCTAssertEqual(migrationCount, 2)
    }
  }
  
}
