//
//  Copyright (c) 2017 Jan Gorman. All rights reserved.
//

import Foundation

public typealias WaxwingMigrationBlock = () -> Void

public final class Waxwing {
  
  private let migratedToKey = "com.schnaub.Waxwing.migratedTo"
  private let migrationQueueLabel = "com.schnaub.Waxwing.queue"

  private let bundle: Bundle
  private let defaults: UserDefaults
  private var progress: Progress
  private lazy var underlyingQueue = DispatchQueue(label: migrationQueueLabel, attributes: .concurrent)
  private lazy var queue: OperationQueue = {
    let queue = OperationQueue()
    queue.underlyingQueue = underlyingQueue
    return queue
  }()
  
  public init(bundle: Bundle = .main, defaults: UserDefaults = .standard) {
    self.bundle = bundle
    self.defaults = defaults
    
    progress = Progress()
    progress.isPausable = false
    progress.isCancellable = false
  }
  
  public func migrateToVersion(_ version: String, migrationBlock: WaxwingMigrationBlock) {
    if canUpdateTo(version as NSString) {
      progress.totalUnitCount = 1
      migrationBlock()
      migratedTo(version)
      progress.completedUnitCount = 1
    }
  }
  
  public func migrateToVersion(_ version: String, migrations: [Operation]) {
    if canUpdateTo(version as NSString) && !migrations.isEmpty {
      progress.totalUnitCount = Int64(migrations.count)

      for migration in migrations {
        let counter = ProgressCounter(progress: progress)
        counter.addDependency(migration)
        queue.addOperation(counter)
      }
      
      let didMigrateOperation = DidMigrateOperation(waxwing: self, version: version)
      didMigrateOperation.addDependency(migrations.last!)
      queue.addOperation(didMigrateOperation)
      
      queue.addOperations(migrations, waitUntilFinished: true)
    }
  }
  
  private func canUpdateTo(_ version: NSString) -> Bool {
    return version.compare(migratedTo(), options: .numeric) == .orderedDescending
      && version.compare(appVersion(), options: .numeric) != .orderedDescending
  }
  
  private func migratedTo() -> String {
    let migratedTo = defaults.string(forKey: migratedToKey)
    progress.completedUnitCount += 1
    return migratedTo ?? ""
  }
  
  private func migratedTo(_ version: String) {
    defaults.set(version, forKey: migratedToKey)
  }
  
  private func appVersion() -> String {
    return bundle.object(forInfoDictionaryKey: "CFBundleShortVersionString") as! String
  }
  
  private class DidMigrateOperation: Operation {
    
    let waxwing: Waxwing
    let version: String
    
    init(waxwing: Waxwing, version: String) {
      self.waxwing = waxwing
      self.version = version
    }
    
    override func start() {
      waxwing.migratedTo(version)
    }
    
  }
  
  private class ProgressCounter: Operation {
    
    let progress: Progress
    
    init(progress: Progress) {
      self.progress = progress
    }
    
    override func start() {
      progress.completedUnitCount += 1
    }
    
  }
  
}
