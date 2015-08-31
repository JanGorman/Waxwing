//
//  Created by Jan Gorman on 05/02/15.
//  Copyright (c) 2015 Jan Gorman. All rights reserved.
//

import Foundation

public typealias WaxwingMigrationBlock = () -> Void

public class Waxwing {

    private let migratedToKey = "com.schnaub.Waxwing.migratedTo"
    private let migrationQueue = "com.schnaub.Waxwing.queue"

    private let bundle: NSBundle
    private let defaults: NSUserDefaults
    private var progress: NSProgress

    public init(bundle: NSBundle, defaults: NSUserDefaults) {
        self.bundle = bundle
        self.defaults = defaults
        
        progress = NSProgress()
        progress.pausable = false
        progress.cancellable = false
    }
    
    public func migrateToVersion(version: String, migrationBlock: WaxwingMigrationBlock) {
        if canUpdateTo(version) {
            progress.totalUnitCount = 1
            migrationBlock()
            migratedTo(version)
            progress.completedUnitCount = 1
        }
    }
    
    public func migrateToVersion(version: String, migrations: [NSOperation]) {
        if canUpdateTo(version) && !migrations.isEmpty {
            progress.totalUnitCount = Int64(migrations.count)

            let queue = NSOperationQueue()
            queue.underlyingQueue = dispatch_queue_create(migrationQueue, DISPATCH_QUEUE_CONCURRENT)
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

    private func canUpdateTo(version: NSString) -> Bool {
        return version.compare(migratedTo(), options: .NumericSearch) == NSComparisonResult.OrderedDescending
            && version.compare(appVersion(), options: .NumericSearch) != NSComparisonResult.OrderedDescending
    }
    
    private func migratedTo() -> String {
        let migratedTo = defaults.valueForKey(migratedToKey) as? String
        progress.completedUnitCount++
        return migratedTo ?? ""
    }
    
    private func migratedTo(version: String) {
        defaults.setValue(version, forKey: migratedToKey)
        defaults.synchronize()
    }
    
    private func appVersion() -> String {
        return bundle.objectForInfoDictionaryKey("CFBundleShortVersionString") as! String
    }
    
    private class DidMigrateOperation: NSOperation {
        
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
    
    private class ProgressCounter: NSOperation {

        let progress: NSProgress
        
        init(progress: NSProgress) {
            self.progress = progress
        }
        
        override func start() {
            progress.completedUnitCount++
        }

    }
    
}
